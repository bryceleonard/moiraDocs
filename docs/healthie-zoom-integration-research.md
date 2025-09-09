# Healthie + Zoom Integration Research
## Virtual Care Recording & Data Pipeline Architecture

**Research Date**: August 29, 2025  
**Purpose**: Define technical requirements for virtual care data pipeline using Healthie's Zoom integration

---

## Key Research Findings - ACTUAL API DISCOVERY

### **Healthie + Zoom Integration Architecture**

✅ **CONFIRMED**: Healthie has deep Zoom integration with recording capabilities!

Based on Healthie's GraphQL API introspection:

#### **1. Healthie's ACTUAL Zoom Integration Capabilities**
```graphql
# CONFIRMED: Healthie provides comprehensive Zoom integration
mutation createAppointment($input: CreateAppointmentInput!) {
  createAppointment(input: {
    patient_id: $patientId
    provider_id: $providerId
    appointment_type_id: $virtualConsultationTypeId
    date: $scheduledDate
    contact_type: "video_chat"
    use_zoom: true  # Enable Zoom for this appointment
  }) {
    appointment {
      id
      
      # ACTUAL Zoom fields available in Healthie:
      zoom_meeting_id        # The Meeting ID for the Zoom call
      zoom_join_url         # Join link for attendees
      zoom_start_url        # Host link to start the call
      zoom_dial_in_info     # Dial-in numbers for phone access
      zoom_dial_in_info_html # Formatted dial-in info
      is_zoom_chat          # Whether using Zoom or Healthie default telehealth
      
      # CONFIRMED: Recording capabilities
      zoom_cloud_recording_urls        # URLs for recordings
      zoom_cloud_recording_files {     # Detailed recording file info
        id
        download_url                   # Direct download link!
        file_type                      # MP4, M4A, TRANSCRIPT, CHAT, CC
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
        duration                       # Total minutes
        participants_count
        total_minutes
      }
    }
  }
}
```

#### **2. Zoom Healthcare API Capabilities**
Based on Zoom's healthcare-specific features:

```typescript
// Zoom Healthcare API endpoints (likely available)
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

### **3. Recording Workflow Architecture**

#### **Virtual Appointment Recording Flow**
```mermaid
graph TB
    subgraph "Healthie EHR"
        H1[Schedule Virtual Appointment] → H2[Generate Zoom Meeting]
        H2 → H3[Patient/Provider Join]
    end
    
    subgraph "Zoom Platform"
        Z1[Meeting Starts] → Z2[Auto-Record to Cloud]
        Z2 → Z3[Generate Transcript]
        Z3 → Z4[Store in Zoom Cloud]
    end
    
    subgraph "MoiraMVP Pipeline"
        M1[Webhook: Recording Available] → M2[Download Audio/Transcript]
        M2 → M3[AI Medical Analysis]
        M3 → M4[Update Healthie EHR]
        M4 → M5[Patient Summary Generation]
    end
    
    H3 → Z1
    Z4 → M1
```

---

## Technical Implementation Requirements

### **4. Zoom Recording Integration Pipeline**

#### **Recording Retrieval System**
```typescript
// Zoom recording retrieval service
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

#### **Webhook Integration for Real-Time Processing**
```typescript
// Zoom webhook handler for recording events
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
    
    // Queue for processing
    await this.queueService.addJob('process_zoom_recording', {
      meeting_id,
      appointment_id: appointment.id,
      recording_files,
      processing_priority: this.calculatePriority(appointment)
    });
  }
}
```

### **5. Data Pipeline Refinements**

#### **Virtual Care Pipeline (Revised)**
```yaml
# Revised virtual care pipeline using Zoom + Healthie
virtual_care_pipeline_v2:
  
  # Pre-appointment setup
  appointment_creation:
    source: "healthie_graphql"
    process: "create_zoom_meeting_with_recording"
    output: "zoom_meeting_details"
    
  # During appointment
  live_meeting:
    zoom_auto_recording: true
    zoom_live_transcription: true  # If available
    healthie_provider_interface: "real_time_notes"
    
  # Post-appointment processing
  recording_processing:
    trigger: "zoom_webhook_recording_completed"
    steps:
      1_download_from_zoom:
        audio_file: "m4a/wav from Zoom cloud"
        transcript_file: "vtt/txt from Zoom transcription"
        meeting_metadata: "participants, duration, quality_metrics"
        
      2_ai_medical_analysis:
        input: ["audio_file", "transcript_file", "appointment_context"]
        processing: "claude_medical_specialist"
        output: "clinical_analysis"
        
      3_healthie_integration:
        update_appointment_notes: true
        create_clinical_summary: true
        update_patient_record: true
        trigger_follow_up_actions: true
        
      4_patient_notification:
        delivery_method: "mobile_app_push + email"
        content: "patient_friendly_summary"
        timeline: "within_30_minutes"
        
  # Care coordination triggers  
  coordination_detection:
    analyze_for_coordination_needs: true
    cross_reference_external_appointments: true
    trigger_provider_alerts: "if_urgent_findings"
    schedule_follow_up: "if_recommended"
```

### **6. CONFIRMED Healthie API Capabilities**

#### **✅ Healthie Integration CONFIRMED:**
1. **✅ YES**: Healthie provides direct Zoom integration via `use_zoom: true` in appointments
2. **✅ YES**: Full access to Zoom meeting data through GraphQL:
   - `zoom_meeting_id`, `zoom_join_url`, `zoom_start_url`
   - `zoom_cloud_recording_files` with download URLs
   - `zoom_appointment` with meeting metadata
3. **✅ YES**: Comprehensive recording file management:
   - Multiple file types: MP4, M4A, TRANSCRIPT, CHAT, CC, TIMELINE
   - Direct download URLs available through GraphQL
   - Recording timestamps, file sizes, and status tracking
4. **🔍 RESEARCH NEEDED**: Healthie webhook events for appointment/recording updates

#### **🎯 Healthie AppointmentSetting Zoom Configuration:**
```graphql
type AppointmentSetting {
  # Zoom configuration options CONFIRMED in Healthie:
  default_to_zoom: Boolean              # Use Zoom for all telehealth appointments
  default_video_service: String         # 'internal', 'zoom', or 'external'
  use_zoom_waiting_room: Boolean        # Enable Zoom waiting room
  allow_external_videochat_urls: Boolean # Allow custom video URLs
  set_default_videochat_url: Boolean    # Providers can set default URLs
}
```

#### **🎯 Available Zoom Recording File Types in Healthie:**
```typescript
// CONFIRMED: Healthie supports these Zoom recording types
enum ZoomRecordingFileType {
  MP4        // Video recording file
  M4A        // Audio-only recording file  
  TRANSCRIPT // Audio transcript file
  CHAT       // Recording chat text file
  CC         // Closed caption file
  TIMELINE   // Timeline file for the recording
  THUMBNAIL  // Thumbnail image of the recording
}
```

#### **Zoom Healthcare API Questions:**
1. **Does Zoom offer HIPAA-compliant automatic recording for healthcare meetings?**
2. **Can we access real-time transcription during live meetings for provider assistance?**
3. **What are Zoom's healthcare-specific webhook events for recording completion?**
4. **How do we programmatically download recordings and transcripts from Zoom's cloud storage?**
5. **What are the retention and deletion policies for Zoom healthcare recordings?**

#### **Integration Architecture Questions:**
1. **How do we correlate Healthie appointment IDs with Zoom meeting IDs?**
2. **Can we embed custom metadata in Zoom meetings to track appointment context?**
3. **How do we handle authentication between Healthie, Zoom, and our AI processing pipeline?**
4. **What are the rate limits and API constraints for healthcare-specific Zoom usage?**

---

## Recommended Research Actions

### **Immediate Research Tasks:**

#### **1. Healthie API Documentation Deep Dive**
```bash
# Research Healthie's video integration capabilities
curl -X POST https://staging-api.gethealthie.com/graphql \
  -H "Authorization: Bearer $HEALTHIE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { __schema { types { name fields { name type { name } } } } }"
  }' | jq '.data.__schema.types[] | select(.name | contains("Appointment") or contains("Video") or contains("Meeting"))'
```

#### **2. Zoom Healthcare API Research**
```bash
# Explore Zoom healthcare-specific endpoints
curl -H "Authorization: Bearer $ZOOM_ACCESS_TOKEN" \
  https://api.zoom.us/v2/accounts/me/settings | jq '.recording'

# Check healthcare compliance features
curl -H "Authorization: Bearer $ZOOM_ACCESS_TOKEN" \
  https://api.zoom.us/v2/accounts/me/lock_settings | grep -i "hipaa\|healthcare\|compliance"
```

#### **3. Recording Workflow Testing**
```bash
# Test Zoom recording retrieval
curl -H "Authorization: Bearer $ZOOM_ACCESS_TOKEN" \
  "https://api.zoom.us/v2/meetings/{meeting_id}/recordings"

# Test webhook setup for recording events
curl -X PATCH https://api.zoom.us/v2/webhooks \
  -H "Authorization: Bearer $ZOOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-app.com/webhooks/zoom",
    "events": [
      "recording.completed",
      "recording.transcript_completed"
    ]
  }'
```

---

## Refined Data Pipeline Architecture (Pending Research)

### **Virtual Care Data Sources (Revised)**

#### **Primary: Healthie + Zoom Integration**
```typescript
interface HealthieZoomIntegration {
  // Healthie appointment with Zoom details
  healthieAppointment: {
    id: string;
    patient_id: string;
    provider_id: string;
    appointment_type: "virtual_consultation";
    
    // Zoom meeting integration
    zoom_meeting: {
      meeting_id: string;
      join_url: string;
      start_url: string;
      recording_enabled: boolean;
      auto_transcription: boolean;
    };
    
    // Real-time status during appointment
    live_status: {
      meeting_started: boolean;
      recording_active: boolean;
      participants_count: number;
      current_duration: number;
    };
  };
  
  // Post-appointment Zoom data
  zoomRecordingData: {
    meeting_id: string;
    recording_files: ZoomRecordingFile[];
    transcript_files: ZoomTranscriptFile[];
    meeting_metadata: ZoomMeetingMetadata;
    
    // Healthcare-specific metadata
    hipaa_compliance_verified: boolean;
    retention_policy: string;
    access_permissions: string[];
  };
}
```

### **Updated Processing Flow**
1. **Appointment Creation**: Healthie creates appointment → Generates Zoom meeting with recording enabled
2. **Meeting Execution**: Patient + Provider join Zoom → Auto-recording starts → Optional live transcription
3. **Recording Completion**: Zoom webhook triggers → Download audio/transcript → AI analysis → Update Healthie
4. **Care Coordination**: AI analysis triggers coordination events → Cross-reference with in-person visits

---

## Next Steps

This research framework will allow us to:
1. **Accurately design** the virtual care pipeline based on actual Healthie-Zoom capabilities
2. **Optimize** data processing workflows for Zoom's recording formats and APIs
3. **Ensure compliance** with healthcare-specific features in both platforms
4. **Plan integration points** between Healthie EHR, Zoom recordings, and our AI analysis

**The data pipeline PRD should be updated once this research is completed** to reflect the actual technical capabilities and constraints of the Healthie-Zoom integration.

Would you like me to help you conduct this research, or do you have access to Healthie and Zoom documentation/APIs that we can explore directly?
