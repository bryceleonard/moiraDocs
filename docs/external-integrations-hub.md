# External Integrations - Complete Reference

## 🎯 Overview

This document consolidates all external system integrations for the Moira healthcare platform, providing a comprehensive reference for authentication, EHR integration, virtual meeting recording, and future device monitoring capabilities.

---

## 🏥 1. Healthie EHR Integration (Authentication + API)

### **Core Integration Strategy**

**Healthie serves as the Single Source of Truth** for:
- ✅ **Patient Authentication** (login/logout, password management)  
- ✅ **Patient Identity** (official patient records, medical data)
- ✅ **Appointments** (scheduling, provider assignments)
- ✅ **Clinical Data** (EHR, provider notes, medical history)

**Moira extends Healthie with**:
- 🎙️ **Recording Consent Management** (audio recording permissions)
- 🤖 **AI Analysis Consent** (consent for AI processing)
- 👥 **Family Access Control** (family member permissions)
- 📱 **Mobile App Preferences** (notification settings, app behavior)
- ⌚ **Wearable Integration** (HealthKit authorization, device connections)

### **Healthie GraphQL API Capabilities**

#### **Patient and Appointment Management**
```graphql
# Core appointment creation with Zoom integration
mutation createAppointment($input: CreateAppointmentInput!) {
  createAppointment(input: {
    patient_id: $patientId
    provider_id: $providerId  # null for external appointments
    appointment_type_id: $virtualConsultationTypeId
    date: $scheduledDate
    contact_type: "video_chat"
    use_zoom: true  # Enable Zoom for this appointment
  }) {
    appointment {
      id
      patient { name, email }
      provider { name, credentials }
      
      # Zoom integration fields
      zoom_meeting_id
      zoom_join_url
      zoom_start_url
      zoom_dial_in_info
      is_zoom_chat
      
      # Recording capabilities
      zoom_cloud_recording_urls
      zoom_cloud_recording_files {
        id
        download_url
        file_type  # MP4, M4A, TRANSCRIPT, CHAT, CC
        file_size
        recording_start
        recording_end
        recording_type
        status
      }
      
      # Meeting metadata
      zoom_appointment {
        id
        start_time
        end_time
        duration
        participants_count
        total_minutes
      }
    }
  }
}
```

#### **Patient Data Access**
```graphql
query getPatient($id: ID!) {
  patient(id: $id) {
    id
    first_name
    last_name
    email
    phone
    date_of_birth
    
    # Clinical information
    medications {
      name
      dosage
      frequency
    }
    
    conditions {
      name
      diagnosed_date
    }
    
    appointments {
      id
      date
      provider { name }
      notes
    }
    
    # Custom fields for phone onboarding
    custom_module_fields {
      label
      value
    }
  }
}
```

### **Authentication Architecture**

#### **Hybrid Authentication Flow**
```typescript
class HealthieAuthService {
  async authenticateUser(authToken: string): Promise<AuthResult> {
    // 1. Verify token with Healthie
    const healthiePatient = await this.healthieAPI.getCurrentUser(authToken);
    
    // 2. Get or create extended profile in PostgreSQL
    let extendedProfile = await this.getExtendedProfile(healthiePatient.id);
    if (!extendedProfile) {
      extendedProfile = await this.createExtendedProfile({
        healthie_patient_id: healthiePatient.id,
        // Set defaults for phone onboarded users
        audio_recording_consent: false,
        ai_analysis_consent: false,
        family_sharing_consent: false,
        onboarding_method: 'phone',
        requires_password_reset: true
      });
    }
    
    return {
      healthiePatient,
      extendedProfile,
      isAuthenticated: true
    };
  }
}
```

#### **Data Access Pattern**
```
Mobile App Request
   ↓
Check Auth Token (Healthie)
   ↓
Get healthie_patient_id from token
   ↓
Query patient_extended_profiles WHERE healthie_patient_id = ?
   ↓
Fetch additional data as needed:
   ├── Healthie GraphQL API (appointments, clinical data)
   ├── PostgreSQL (recording sessions, AI analysis, family access)
   └── BigQuery (analytics, trends)
```

### **Database Schema Integration**

```sql
-- Extended patient profiles that link to Healthie
CREATE TABLE patient_extended_profiles (
    user_id UUID PRIMARY KEY,
    healthie_patient_id VARCHAR(255) UNIQUE NOT NULL,  -- Links to Healthie
    
    -- Consent management (Healthie doesn't handle granularly)
    audio_recording_consent BOOLEAN DEFAULT false,
    ai_analysis_consent BOOLEAN DEFAULT false,
    family_sharing_consent BOOLEAN DEFAULT false,
    
    -- Phone onboarding specific fields
    onboarding_method 'phone' | 'self_service' DEFAULT 'phone',
    onboarding_coordinator VARCHAR(255),
    phone_intake_notes TEXT,
    requires_password_reset BOOLEAN DEFAULT true,
    
    -- Mobile app preferences
    push_notifications_enabled BOOLEAN DEFAULT true,
    preferred_notification_times TEXT[],
    
    -- Wearable integration (not in Healthie)
    healthkit_authorized BOOLEAN DEFAULT false,
    authorized_data_types TEXT[],
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## 📹 2. Zoom Healthcare API Integration

### **Virtual Meeting Recording Architecture**

#### **Recording Workflow**
```
Healthie EHR → Generate Zoom Meeting → Patient/Provider Join → 
Auto-Record to Cloud → Generate Transcript → Store in Zoom Cloud → 
Webhook: Recording Available → Download Audio/Transcript → AI Analysis → 
Update Healthie EHR → Patient Summary
```

### **Zoom Recording Service**

```typescript
class ZoomRecordingService {
  private zoomAPI: ZoomAPI;
  private healthieAPI: HealthieAPI;
  
  async processCompletedMeeting(meetingId: string): Promise<ProcessingResult> {
    // Get meeting details from Healthie
    const appointment = await this.healthieAPI.getAppointmentByZoomId(meetingId);
    
    // Retrieve recording from Zoom
    const recordings = await this.zoomAPI.recordings.get(meetingId);
    
    // Download audio and transcript files
    const audioFile = await this.downloadZoomAudio(recordings.audio_file_url);
    const transcript = await this.downloadZoomTranscript(recordings.transcript_file_url);
    
    // Process through AI pipeline
    const aiAnalysis = await this.processVirtualAppointmentAudio({
      appointmentId: appointment.id,
      patientId: appointment.patient_id,
      providerId: appointment.provider_id,
      audioFile,
      transcript,
      meetingMetadata: recordings.metadata
    });
    
    // Update Healthie with AI analysis
    await this.healthieAPI.updateAppointmentNotes(appointment.id, {
      ai_summary: aiAnalysis.clinicalSummary,
      key_findings: aiAnalysis.keyFindings,
      action_items: aiAnalysis.actionItems,
      medications_discussed: aiAnalysis.medications
    });
    
    return aiAnalysis;
  }
  
  private async downloadZoomAudio(audioUrl: string): Promise<AudioFile> {
    const response = await fetch(audioUrl, {
      headers: {
        'Authorization': `Bearer ${this.zoomAPI.accessToken}`
      }
    });
    return response.buffer();
  }
}
```

### **Webhook Handler for Real-Time Processing**

```typescript
class ZoomWebhookHandler {
  async handleRecordingCompleted(webhook: ZoomWebhook): Promise<void> {
    const { meeting_id, recording_files } = webhook.payload.object;
    
    // Verify this is a healthcare appointment
    const appointment = await this.healthieAPI.getAppointmentByZoomId(meeting_id);
    if (!appointment) {
      console.log(`No Healthie appointment found for Zoom meeting ${meeting_id}`);
      return;
    }
    
    // Check patient consent for AI processing
    const hasConsent = await this.validatePatientConsent(
      appointment.patient_id, 
      'virtual_recording_ai_analysis'
    );
    
    if (!hasConsent) {
      console.log(`Patient ${appointment.patient_id} has not consented to AI analysis`);
      return;
    }
    
    // Process the recording
    await this.zoomRecordingService.processCompletedMeeting(meeting_id);
  }
  
  private async validatePatientConsent(patientId: string, consentType: string): Promise<boolean> {
    const extendedProfile = await this.getExtendedProfile(patientId);
    
    switch (consentType) {
      case 'virtual_recording_ai_analysis':
        return extendedProfile.audio_recording_consent && extendedProfile.ai_analysis_consent;
      default:
        return false;
    }
  }
}
```

### **Zoom Healthcare API Interface**

```typescript
interface ZoomHealthcareAPI {
  // Meeting management with healthcare compliance
  meetings: {
    create: (meeting: HealthcareMeeting) => ZoomMeeting;
    start_recording: (meetingId: string, settings: RecordingSettings) => Recording;
    get_recordings: (meetingId: string) => Recording[];
    get_transcript: (recordingId: string) => Transcript;
  };
  
  // Healthcare-specific features
  healthcare: {
    enable_hipaa_compliance: (accountId: string) => ComplianceStatus;
    manage_consent: (meetingId: string, consent: ConsentSettings) => ConsentRecord;
    audit_trail: (meetingId: string) => AuditLog[];
  };
  
  // Recording management
  recordings: {
    download_audio: (recordingId: string) => AudioFile;
    download_transcript: (recordingId: string) => TranscriptFile;
    set_retention_policy: (recordingId: string, policy: RetentionPolicy) => void;
    delete_recording: (recordingId: string) => void;
  };
}
```

---

## ⚖️ 3. Withings Device Integration (Future Enhancement)

### **Strategic Overview**

Withings integration transforms Moira from recording/AI analysis platform into comprehensive remote patient monitoring solution by adding:
- **Withings Body+ Scale** (~$99): Weight, BMI, body fat %, muscle mass
- **Withings BPM Connect** (~$99): Blood pressure and heart rate monitoring
- **Total per patient**: ~$200 + shipping/handling

### **Enhanced Phone Onboarding with Devices**

```
📞 PHONE INTAKE CALL (Enhanced with Device Assessment)
├── Standard medical history & consent discussion
├── Technology comfort level evaluation
├── Device eligibility determination
│   ├── Age-based criteria (65+)
│   ├── Condition-based (hypertension, diabetes)
│   └── Family caregiver availability assessment
├── Device shipping address confirmation
├── Expected delivery timeline discussion
└── Device setup support scheduling

🚚 DEVICE LOGISTICS INTEGRATION
├── Automatic device order placement during account creation
├── Inventory management system integration
├── Shipping tracking and delivery notifications
├── Delivery confirmation triggering setup support
└── Device pairing integration with app onboarding
```

### **Database Schema Extensions**

#### **Device Management Tables**
```sql
-- Device assignment and lifecycle tracking
CREATE TABLE patient_devices (
    device_id UUID PRIMARY KEY,
    patient_id UUID REFERENCES patient_extended_profiles(user_id),
    
    -- Device details
    device_type 'withings_scale' | 'withings_bp_monitor' | 'withings_thermometer',
    withings_device_id VARCHAR(255) UNIQUE,
    device_model VARCHAR(100),
    serial_number VARCHAR(255),
    
    -- Logistics tracking
    ordered_date TIMESTAMP,
    shipped_date TIMESTAMP,
    delivered_date TIMESTAMP,
    setup_completed_date TIMESTAMP,
    
    -- Device status
    device_status 'ordered' | 'shipped' | 'delivered' | 'setup_in_progress' | 'active' | 'inactive',
    last_sync_date TIMESTAMP,
    connectivity_status 'connected' | 'disconnected' | 'setup_required',
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Withings health measurements
CREATE TABLE withings_measurements (
    measurement_id UUID PRIMARY KEY,
    patient_id UUID REFERENCES patient_extended_profiles(user_id),
    device_id UUID REFERENCES patient_devices(device_id),
    
    -- Measurement details
    measurement_type 'weight' | 'body_fat' | 'systolic_bp' | 'diastolic_bp' | 'heart_rate',
    value DECIMAL(10,2),
    unit VARCHAR(20),
    measured_at TIMESTAMP,
    synced_at TIMESTAMP DEFAULT NOW(),
    
    -- Quality and analysis flags
    measurement_quality 'good' | 'fair' | 'poor',
    is_outlier BOOLEAN DEFAULT false,
    emergency_threshold_exceeded BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- Daily health summaries for analytics
CREATE TABLE daily_health_summaries (
    summary_id UUID PRIMARY KEY,
    patient_id UUID REFERENCES patient_extended_profiles(user_id),
    summary_date DATE,
    
    -- Aggregated metrics
    weight_avg DECIMAL(10,2),
    systolic_avg DECIMAL(10,2),
    diastolic_avg DECIMAL(10,2),
    heart_rate_avg DECIMAL(10,2),
    
    -- Compliance tracking
    measurements_taken INTEGER,
    expected_measurements INTEGER,
    compliance_percentage DECIMAL(5,2),
    
    -- AI-generated insights
    health_score DECIMAL(3,2),
    care_coordination_needed BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP DEFAULT NOW()
);
```

### **AI Enhancement with Device Data**

```typescript
interface EnhancedAppointmentAnalysis {
  // Existing appointment analysis
  clinicalSummary: string;
  medications: MedicationDiscussion[];
  actionItems: ActionItem[];
  
  // Enhanced with device data context
  deviceContextualInsights: {
    weightTrend: {
      direction: 'increasing' | 'stable' | 'decreasing';
      changeAmount: number;
      timeframe: string;
      clinicalSignificance: 'concerning' | 'normal' | 'positive';
    };
    
    bloodPressureContext: {
      averageReadings: { systolic: number; diastolic: number };
      controlStatus: 'well_controlled' | 'borderline' | 'uncontrolled';
      medicationEffectiveness: 'effective' | 'needs_adjustment' | 'unknown';
    };
    
    complianceAssessment: {
      measurementFrequency: 'excellent' | 'good' | 'poor';
      engagementTrend: 'improving' | 'stable' | 'declining';
      familyInvolvement: 'active' | 'minimal' | 'none';
    };
  };
  
  // Enhanced care coordination
  deviceTriggeredActions: {
    urgentFollowUpNeeded: boolean;
    medicationReviewSuggested: boolean;
    familyEngagementNeeded: boolean;
    deviceSupportRequired: boolean;
  };
}
```

### **Strategic Questions for Implementation**

#### **Device Distribution Strategy**
- **Eligibility criteria**: Age-based (65+) vs. condition-based (hypertension, diabetes)?
- **Distribution timing**: During phone intake vs. after app engagement?
- **Ownership model**: Permanent vs. loaner program vs. insurance reimbursement?

#### **Business Model Implications** 
- **Cost structure**: ~$200/patient device cost + operational overhead
- **Revenue enhancement**: Premium subscription tier vs. insurance RPM billing?
- **Support model**: White-glove setup vs. self-service vs. family-assisted?

#### **Technical Integration Depth**
- **Sync frequency**: Real-time vs. daily batch vs. on-demand?
- **AI enhancement level**: Basic trends vs. advanced correlation vs. predictive modeling?
- **Care coordination triggers**: Manual review vs. automated alerts vs. emergency protocols?

---

## 🌐 4. Other Integration APIs

### **Weather API Integration**
```typescript
interface WeatherHealthCorrelation {
  // Weather impact on patient health metrics
  barometricPressure: {
    value: number;
    healthImpact: 'headache_trigger' | 'joint_pain_correlation' | 'mood_influence';
  };
  
  temperature: {
    value: number;
    exerciseRecommendation: 'indoor' | 'outdoor_with_caution' | 'optimal_outdoor';
  };
  
  // Integration with care recommendations
  weatherBasedNudges: string[];
  appointmentSchedulingConsiderations: string[];
}
```

### **Twilio SMS/Voice Integration**
```typescript
interface TwilioHealthcareMessaging {
  // Patient notifications
  appointmentReminders: {
    sms: boolean;
    voice: boolean;
    timingPreferences: string[];
  };
  
  // Family emergency alerts
  emergencyNotifications: {
    recipients: FamilyMember[];
    escalationProtocol: NotificationEscalation[];
    consentRequired: boolean;
  };
  
  // Care coordinator communications
  coordinatorAlerts: {
    patientStatusChanges: boolean;
    deviceIssues: boolean;
    appointmentNoShows: boolean;
  };
}
```

### **HealthKit & Wearable APIs**
```typescript
interface WearableDataIntegration {
  // Supported platforms
  healthKit: {
    dataTypes: ['heart_rate', 'steps', 'sleep', 'blood_pressure', 'weight'];
    syncFrequency: 'real_time' | 'hourly' | 'daily';
    backgroundSync: boolean;
  };
  
  // Third-party devices
  supportedDevices: {
    oura: ['sleep', 'heart_rate_variability', 'activity'];
    fitbit: ['steps', 'heart_rate', 'sleep', 'weight'];
    withings: ['weight', 'blood_pressure', 'heart_rate', 'body_composition'];
  };
  
  // Data consolidation
  healthScore: {
    algorithm: 'composite' | 'weighted_average' | 'ml_prediction';
    factors: string[];
    familyVisibility: boolean;
  };
}
```

---

## 🔐 5. Integration Security & Compliance

### **HIPAA Compliance Framework**

#### **Data Encryption Standards**
- **At Rest**: AES-256 encryption for all stored integration data
- **In Transit**: TLS 1.3 for all API communications
- **Key Management**: Separate encryption keys for each integration
- **Audit Logging**: Complete access logs for all external API calls

#### **OAuth and API Security**
```typescript
interface IntegrationSecurity {
  healthie: {
    authMethod: 'GraphQL_with_JWT';
    tokenRefresh: 'automatic';
    scopeRestrictions: ['read_patients', 'write_appointments', 'read_recordings'];
  };
  
  zoom: {
    authMethod: 'OAuth2';
    webhookSecurity: 'signature_verification';
    dataRetention: 'auto_delete_after_processing';
  };
  
  withings: {
    authMethod: 'OAuth2';
    dataMinimization: 'health_metrics_only';
    patientConsent: 'explicit_per_device';
  };
}
```

### **Patient Consent Management**
```sql
-- Granular consent tracking for all integrations
CREATE TABLE integration_consents (
    consent_id UUID PRIMARY KEY,
    patient_id UUID REFERENCES patient_extended_profiles(user_id),
    
    -- Integration-specific consents
    healthie_ehr_access BOOLEAN DEFAULT true,  -- Required for core functionality
    zoom_recording_consent BOOLEAN DEFAULT false,
    zoom_ai_analysis_consent BOOLEAN DEFAULT false,
    withings_device_data_consent BOOLEAN DEFAULT false,
    weather_location_consent BOOLEAN DEFAULT false,
    
    -- Consent audit trail
    consent_given_date TIMESTAMP DEFAULT NOW(),
    consent_method 'phone_intake' | 'app_settings' | 'coordinator_call',
    consent_witness VARCHAR(255),  -- Care coordinator name if applicable
    
    -- Consent modifications
    last_modified_date TIMESTAMP,
    modification_reason TEXT,
    
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 📊 6. Integration Monitoring & Analytics

### **API Performance Tracking**
```sql
CREATE TABLE integration_api_metrics (
    metric_id UUID PRIMARY KEY,
    integration_name VARCHAR(50),
    api_endpoint VARCHAR(200),
    
    -- Performance metrics
    response_time_ms INTEGER,
    success_rate DECIMAL(5,2),
    error_count INTEGER,
    data_volume_bytes BIGINT,
    
    -- Business metrics
    patient_impact_count INTEGER,
    care_coordination_events_triggered INTEGER,
    
    measured_at TIMESTAMP DEFAULT NOW()
);
```

### **Integration Health Dashboard**
```typescript
interface IntegrationHealthStatus {
  healthie: {
    status: 'operational' | 'degraded' | 'down';
    lastSuccessfulSync: Date;
    activePatients: number;
    todaysAppointments: number;
  };
  
  zoom: {
    status: 'operational' | 'degraded' | 'down';
    recordingsProcessedToday: number;
    averageProcessingTime: number;
    queueBacklog: number;
  };
  
  withings: {
    status: 'operational' | 'degraded' | 'down';
    devicesOnline: number;
    measurementsToday: number;
    syncFailures: number;
  };
}
```

---

## 🚀 Implementation Roadmap

### **September 2025 - Foundation**
- **Week 1**: Healthie EHR integration and authentication setup
- **Week 2**: Zoom recording webhook and processing pipeline
- **Week 3**: Patient consent management and extended profiles
- **Week 4**: Integration monitoring and error handling

### **October 2025 - Enhancement**
- **Week 1**: Weather API and location services integration
- **Week 2**: Advanced Healthie GraphQL optimization
- **Week 3**: Zoom recording quality improvements
- **Week 4**: Integration security hardening

### **Q4 2025/Q1 2026 - Device Integration**
- **Month 1**: Withings device integration strategic planning
- **Month 2**: Device logistics and shipping integration
- **Month 3**: Device data pipeline and AI enhancement
- **Month 4**: Family dashboard device visibility and alerts

This comprehensive integration hub provides the foundation for seamless external system connectivity while maintaining security, compliance, and optimal performance across all touchpoints in the Moira healthcare ecosystem.
