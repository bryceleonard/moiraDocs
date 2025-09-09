# MoiraMVP Data Pipeline PRD
## Healthcare Data Lake & Real-Time Processing Architecture

**Document Version**: 1.0  
**Last Updated**: August 29, 2025  
**Owner**: Technical Architecture Team

---

## 1. Executive Summary

### **Problem Statement**
MoiraMVP requires a sophisticated data pipeline to support hybrid healthcare delivery:
- **Virtual practice appointments** via Healthie + Zoom with automated recording and AI analysis
- **In-person external specialist visits** with mobile recording and post-visit coordination
- **Unified care coordination** across all healthcare touchpoints
- **HIPAA-compliant processing** of sensitive medical data

### **Solution Overview**
A dual-pipeline architecture leveraging Healthie's native Zoom integration for virtual care recording with batch AI processing, plus mobile recording pipeline for in-person visits, unified through a healthcare data lake with BitQuery analytics integration.

### **Key Architecture Discovery**
✅ **CONFIRMED**: Healthie provides full Zoom integration with:
- Automatic Zoom meeting creation and recording
- Direct access to cloud recording files (MP4, M4A, TRANSCRIPT)
- Download URLs available through GraphQL API
- Multiple recording file types and metadata

### **Business Value**
- **Complete Patient Context**: 360-degree view of patient health across all care modalities
- **AI-Powered Coordination**: Automated care coordination reducing medical errors
- **Provider Efficiency**: Real-time insights during virtual consultations
- **Patient Experience**: Unified health timeline with AI-generated insights

---

## 2. Data Sources & Classification

### **Primary Data Sources**

#### **2.1 Virtual Practice Data (Healthie + Zoom Integration)**
```typescript
interface VirtualPracticeData {
  // Healthie appointments with Zoom integration
  healthieZoomAppointments: {
    // CONFIRMED: Actual Healthie GraphQL fields
    id: string;
    patient_id: string;
    provider_id: string;
    appointment_type_id: string;
    contact_type: 'video_chat';
    use_zoom: boolean;
    
    // CONFIRMED: Zoom meeting data available in Healthie
    zoom_meeting_id: string;
    zoom_join_url: string;
    zoom_start_url: string;
    zoom_dial_in_info: string;
    is_zoom_chat: boolean;
    
    // CONFIRMED: Recording access through Healthie
    zoom_cloud_recording_urls: string[];
    zoom_cloud_recording_files: {
      id: string;
      download_url: string;           // Direct download access!
      file_type: 'MP4' | 'M4A' | 'TRANSCRIPT' | 'CHAT' | 'CC' | 'TIMELINE';
      file_size: number;
      recording_start: string;
      recording_end: string;
      status: string;
    }[];
    
    // CONFIRMED: Meeting metadata
    zoom_appointment: {
      id: string;
      start_time: string;
      end_time: string;
      duration: number;               // Total minutes
      participants_count: number;
      total_minutes: number;
    };
  };
  
  // Standard Healthie EHR data
  healthieData: {
    patientRecords: HealthiePatient[];
    appointments: HealthieAppointment[];
    clinicalNotes: ClinicalNote[];
    medications: Medication[];
    assessments: Assessment[];
  };
}
```

#### **2.2 External In-Person Care Data (Batch Processing)**
```typescript
interface ExternalCareData {
  // Mobile-captured in-person appointments
  inPersonRecordings: {
    recordingId: string;
    patientId: string;
    appointmentMetadata: {
      providerName: string;
      facilityName: string;
      specialty: string;
      appointmentDate: Date;
      estimatedDuration: number;
    };
    audioData: {
      rawAudioFile: AudioFile;
      processingMetadata: {
        deviceType: string;
        audioQuality: QualityMetrics;
        backgroundNoiseLevel: number;
        speakerCount: number;
      };
    };
    patientContext: {
      reasonForVisit: string;
      currentMedications: Medication[];
      relevantHistory: string[];
    };
  };
}
```

#### **2.3 AI-Generated Intelligence Data**
```typescript
interface AIIntelligenceData {
  // AI analysis outputs
  medicalAnalysis: {
    analysisId: string;
    sourceAppointmentId: string;
    sourceType: 'virtual' | 'in-person';
    analysisResults: {
      clinicalFindings: ClinicalFinding[];
      emergencyFlags: EmergencyFlag[];
      medicationChanges: MedicationChange[];
      careCoordinationNeeds: CoordinationNeed[];
      patientSummary: PatientFriendlySummary;
    };
    confidence: ConfidenceMetrics;
    processingTime: ProcessingMetrics;
  };
  
  // Cross-care insights
  coordinationIntelligence: {
    correlationId: string;
    patientId: string;
    timeWindow: string;
    crossCareInsights: {
      medicationConflicts: MedicationConflict[];
      treatmentAlignment: TreatmentAlignment[];
      careGaps: CareGap[];
      followUpRecommendations: FollowUpRecommendation[];
    };
  };
}
```

### **Secondary Data Sources**

#### **2.4 Reference & Context Data**
- Medical knowledge bases (ICD-10, CPT, drug databases)
- Clinical guidelines (AHA, ADA, specialty society recommendations)
- Public health data (CDC, local health departments)
- Insurance and payer information
- Environmental health data (air quality, allergen levels)

---

## 3. Data Lake Architecture with BitQuery Integration

### **3.1 Healthcare Data Lake Structure**

#### **Raw Data Layer (Bronze)**
```sql
-- S3/Cloud Storage organization
moira-healthcare-datalake/
├── raw/
│   ├── virtual-appointments/
│   │   ├── year=2024/month=08/day=29/
│   │   │   ├── audio-streams/        # Real-time audio chunks
│   │   │   ├── video-metadata/       # Meeting platform data
│   │   │   └── healthie-sync/        # EHR data snapshots
│   ├── in-person-appointments/
│   │   ├── year=2024/month=08/day=29/
│   │   │   ├── mobile-recordings/    # Patient-captured audio
│   │   │   ├── appointment-metadata/ # Specialist visit context
│   │   │   └── patient-context/      # Pre-visit patient state
│   ├── ai-analysis/
│   │   ├── real-time-insights/       # Live virtual care analysis
│   │   ├── batch-analysis/           # Post-visit in-person analysis
│   │   └── cross-care-correlation/   # Multi-appointment insights
│   └── reference-data/
│       ├── medical-knowledge/        # Clinical databases
│       ├── drug-interactions/        # Medication safety data
│       └── clinical-guidelines/      # Evidence-based protocols
```

#### **Processed Data Layer (Silver)**
```sql
-- Cleaned and standardized healthcare data
CREATE TABLE processed_appointments (
    appointment_id UUID PRIMARY KEY,
    patient_id UUID,
    appointment_type ENUM('virtual_practice', 'in_person_external'),
    appointment_date TIMESTAMP,
    provider_info JSONB,
    
    -- Standardized clinical data
    transcription TEXT,
    clinical_findings JSONB,
    medications JSONB,
    vital_signs JSONB,
    
    -- AI analysis results
    ai_analysis_id UUID,
    emergency_flags JSONB,
    care_coordination_needs JSONB,
    
    -- Processing metadata
    audio_quality_score DECIMAL,
    transcription_confidence DECIMAL,
    processing_completed_at TIMESTAMP
);

CREATE TABLE care_coordination_events (
    event_id UUID PRIMARY KEY,
    patient_id UUID,
    trigger_appointment_id UUID,
    event_type VARCHAR(100),
    priority ENUM('low', 'medium', 'high', 'urgent'),
    
    -- Cross-care insights
    virtual_care_context JSONB,
    external_care_context JSONB,
    ai_recommendations JSONB,
    
    -- Coordination status
    status ENUM('detected', 'notified', 'scheduled', 'completed'),
    created_at TIMESTAMP,
    resolved_at TIMESTAMP
);
```

#### **Analytics Data Layer (Gold) - BitQuery Integration**
```sql
-- BitQuery-powered healthcare analytics tables
CREATE TABLE patient_health_analytics (
    patient_id UUID,
    analysis_date DATE,
    
    -- Cross-care analytics
    total_appointments INTEGER,
    virtual_appointments INTEGER,
    in_person_appointments INTEGER,
    
    -- Health trend analytics
    medication_changes_count INTEGER,
    emergency_flags_count INTEGER,
    care_coordination_events INTEGER,
    
    -- Predictive analytics
    risk_scores JSONB,
    health_trends JSONB,
    care_gaps JSONB,
    
    -- Provider network analytics
    provider_network JSONB,
    care_team_coordination_score DECIMAL
);

CREATE TABLE provider_performance_analytics (
    provider_id UUID,
    analysis_date DATE,
    appointment_type VARCHAR(50),
    
    -- Virtual care metrics
    virtual_consultation_quality DECIMAL,
    patient_satisfaction DECIMAL,
    care_plan_adherence DECIMAL,
    
    -- AI assistance metrics
    ai_insight_utilization DECIMAL,
    care_coordination_effectiveness DECIMAL,
    
    -- Cross-care coordination metrics
    external_care_integration_score DECIMAL
);
```

### **3.2 BitQuery Integration Architecture**

#### **Healthcare-Specific BitQuery Schemas**
```sql
-- BitQuery tables for complex healthcare analytics
CREATE OR REPLACE VIEW bitquery_patient_journey AS
WITH patient_care_timeline AS (
  SELECT 
    patient_id,
    appointment_date,
    appointment_type,
    provider_info->>'name' as provider_name,
    provider_info->>'specialty' as specialty,
    ai_analysis->>'severity_score' as severity_score,
    medications,
    care_coordination_needs
  FROM processed_appointments
),
care_coordination_effectiveness AS (
  SELECT
    patient_id,
    COUNT(*) as coordination_events,
    AVG(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as resolution_rate,
    AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600) as avg_resolution_hours
  FROM care_coordination_events
  GROUP BY patient_id
)
SELECT 
  pct.*,
  cce.coordination_events,
  cce.resolution_rate,
  cce.avg_resolution_hours
FROM patient_care_timeline pct
LEFT JOIN care_coordination_effectiveness cce ON pct.patient_id = cce.patient_id;

-- BitQuery for medication safety across care types
CREATE OR REPLACE VIEW bitquery_medication_safety AS
SELECT 
  patient_id,
  virtual_medications.medication_name as virtual_med,
  in_person_medications.medication_name as external_med,
  drug_interactions.severity,
  drug_interactions.clinical_significance
FROM (
  SELECT patient_id, jsonb_array_elements_text(medications) as medication_name
  FROM processed_appointments 
  WHERE appointment_type = 'virtual_practice'
) virtual_medications
FULL OUTER JOIN (
  SELECT patient_id, jsonb_array_elements_text(medications) as medication_name  
  FROM processed_appointments
  WHERE appointment_type = 'in_person_external'
) in_person_medications ON virtual_medications.patient_id = in_person_medications.patient_id
JOIN drug_interactions ON (
  drug_interactions.drug_a = virtual_medications.medication_name AND
  drug_interactions.drug_b = in_person_medications.medication_name
);
```

---

## 4. Data Pipeline Workflows

### **4.1 Real-Time Pipeline: Virtual Care Processing**

#### **Stream Processing Architecture**
```yaml
# Kafka/Kinesis stream configuration for virtual care
virtual_care_streams:
  audio_stream:
    topic: "virtual-appointment-audio"
    partitions: 12  # Scale for concurrent appointments
    retention: "24h"  # HIPAA compliance - limited retention
    
  transcription_stream:
    topic: "live-transcription"
    partitions: 12
    consumer_groups: ["ai-analysis", "provider-dashboard", "ehr-integration"]
    
  ai_insights_stream:
    topic: "live-ai-insights"
    partitions: 4
    consumers: ["provider-dashboard", "care-coordination", "patient-app"]

# Real-time processing workflow
virtual_care_pipeline:
  1_audio_capture:
    source: "virtual-meeting-platform"
    processing: "real-time-stream"
    destination: "audio_stream"
    
  2_transcription:
    source: "audio_stream"
    processing: "deepgram-live-transcription"
    destination: "transcription_stream"
    latency_target: "<2 seconds"
    
  3_ai_analysis:
    source: "transcription_stream"
    processing: "medical-ai-analysis"
    destination: "ai_insights_stream"
    latency_target: "<5 seconds"
    
  4_provider_integration:
    source: "ai_insights_stream"
    processing: "provider-dashboard-update"
    destination: "provider-interface"
    latency_target: "<1 second"
    
  5_ehr_integration:
    source: ["transcription_stream", "ai_insights_stream"]
    processing: "healthie-integration"
    destination: "healthie-ehr"
    latency_target: "<10 seconds"
```

### **4.2 Batch Pipeline: In-Person Care Processing**

#### **ETL Pipeline for Mobile Recordings**
```yaml
# Airflow DAG for in-person appointment processing
in_person_care_pipeline:
  schedule: "*/5 minutes"  # Check for new recordings every 5 minutes
  
  extract:
    source: "mobile-app-uploads"
    location: "s3://moira-recordings/in-person/"
    format: "audio files (m4a, wav, mp3)"
    
  transform:
    audio_enhancement:
      - noise_reduction
      - speaker_separation  
      - audio_normalization
      
    transcription:
      service: "deepgram-batch"
      model: "medical-specialized"
      language: "en-US"
      
    ai_analysis:
      medical_terminology_extraction: true
      emergency_detection: true
      medication_analysis: true
      care_coordination_needs: true
      
  load:
    destinations:
      - data_lake: "s3://moira-datalake/processed/"
      - operational_db: "postgresql://moira-db/appointments"
      - analytics_warehouse: "snowflake://moira-analytics/"
      
  notification:
    patient_summary: "within 30 minutes"
    provider_alerts: "immediate for urgent findings"
    care_coordination: "within 2 hours"
```

### **4.3 Cross-Care Correlation Pipeline**

#### **Care Coordination Intelligence**
```sql
-- Automated care coordination pipeline
CREATE OR REPLACE FUNCTION process_care_coordination() 
RETURNS TRIGGER AS $$
BEGIN
  -- Detect care coordination opportunities
  INSERT INTO care_coordination_events (
    patient_id,
    trigger_appointment_id,
    event_type,
    priority,
    virtual_care_context,
    external_care_context,
    ai_recommendations
  )
  SELECT 
    NEW.patient_id,
    NEW.appointment_id,
    detect_coordination_type(NEW.ai_analysis),
    calculate_priority(NEW.emergency_flags),
    get_recent_virtual_context(NEW.patient_id),
    NEW.ai_analysis,
    generate_coordination_recommendations(NEW.patient_id, NEW.ai_analysis)
  WHERE should_trigger_coordination(NEW.ai_analysis);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on new AI analysis completion
CREATE TRIGGER care_coordination_trigger
  AFTER INSERT ON processed_appointments
  FOR EACH ROW EXECUTE FUNCTION process_care_coordination();
```

---

## 5. BitQuery Integration Design

### **5.1 Healthcare Analytics Queries**

#### **Patient Care Journey Analytics**
```sql
-- BitQuery: Patient care journey across virtual and in-person visits
WITH patient_journey_analysis AS (
  SELECT 
    p.patient_id,
    p.appointment_date,
    p.appointment_type,
    p.provider_info->>'specialty' as specialty,
    
    -- AI analysis metrics
    (p.ai_analysis->>'emergency_score')::decimal as emergency_score,
    (p.ai_analysis->>'medication_changes')::int as med_changes,
    
    -- Care coordination metrics
    LAG(p.appointment_type) OVER (
      PARTITION BY p.patient_id 
      ORDER BY p.appointment_date
    ) as prev_appointment_type,
    
    -- Time between care types
    p.appointment_date - LAG(p.appointment_date) OVER (
      PARTITION BY p.patient_id 
      ORDER BY p.appointment_date
    ) as time_between_visits
    
  FROM processed_appointments p
  WHERE p.appointment_date >= CURRENT_DATE - INTERVAL '90 days'
),
care_coordination_effectiveness AS (
  SELECT
    patient_id,
    -- Virtual to in-person coordination
    COUNT(CASE WHEN prev_appointment_type = 'virtual_practice' 
               AND appointment_type = 'in_person_external'
               AND time_between_visits <= INTERVAL '7 days' 
          THEN 1 END) as virtual_to_external_rapid_follow_ups,
    
    -- In-person to virtual coordination  
    COUNT(CASE WHEN prev_appointment_type = 'in_person_external'
               AND appointment_type = 'virtual_practice' 
               AND time_between_visits <= INTERVAL '3 days'
          THEN 1 END) as external_to_virtual_coordination,
    
    -- Emergency detection across care types
    SUM(emergency_score) as total_emergency_score,
    AVG(med_changes) as avg_medication_changes_per_visit
    
  FROM patient_journey_analysis
  GROUP BY patient_id
)
SELECT * FROM care_coordination_effectiveness;
```

#### **Provider Network Effectiveness Analytics**
```sql
-- BitQuery: Analyze provider network and care coordination
CREATE VIEW bitquery_provider_network_analytics AS
WITH provider_coordination_metrics AS (
  SELECT 
    pa.provider_info->>'name' as provider_name,
    pa.provider_info->>'specialty' as specialty,
    pa.appointment_type,
    
    -- Care quality metrics
    COUNT(*) as total_appointments,
    AVG((pa.ai_analysis->>'patient_satisfaction')::decimal) as avg_satisfaction,
    AVG((pa.ai_analysis->>'care_plan_adherence')::decimal) as care_adherence,
    
    -- Coordination effectiveness
    COUNT(cce.event_id) as coordination_events_triggered,
    AVG(CASE WHEN cce.status = 'completed' THEN 1 ELSE 0 END) as resolution_rate,
    
    -- Emergency response
    SUM((pa.ai_analysis->>'emergency_flags_count')::int) as emergency_flags,
    AVG(EXTRACT(EPOCH FROM cce.resolved_at - cce.created_at)/60) as avg_response_time_minutes
    
  FROM processed_appointments pa
  LEFT JOIN care_coordination_events cce ON pa.appointment_id = cce.trigger_appointment_id
  WHERE pa.appointment_date >= CURRENT_DATE - INTERVAL '30 days'
  GROUP BY provider_name, specialty, appointment_type
)
SELECT 
  *,
  -- Network effect scoring
  CASE 
    WHEN appointment_type = 'virtual_practice' THEN 'Primary Care Hub'
    WHEN coordination_events_triggered > 5 THEN 'High Coordination Specialist'
    WHEN resolution_rate > 0.9 THEN 'Effective Care Partner'
    ELSE 'Standard Network Provider'
  END as provider_network_role
FROM provider_coordination_metrics;
```

### **5.2 Real-Time Analytics Dashboard Queries**

#### **Live Care Coordination Dashboard**
```sql
-- BitQuery: Real-time care coordination monitoring
CREATE MATERIALIZED VIEW real_time_care_coordination AS
SELECT 
  -- Active virtual appointments needing attention
  active_virtual_care AS (
    SELECT 
      pa.session_id,
      pa.patient_id,
      pa.provider_info->>'name' as provider,
      pa.real_time_events->>'current_emergency_score' as emergency_score,
      pa.real_time_events->>'ai_recommendations' as live_recommendations
    FROM virtual_appointment_streams va
    JOIN processed_appointments pa ON va.session_id = pa.session_id
    WHERE va.status = 'active'
    AND (pa.real_time_events->>'current_emergency_score')::decimal > 0.7
  ),
  
  -- Recent in-person visits needing coordination
  pending_coordination AS (
    SELECT 
      pa.appointment_id,
      pa.patient_id,
      pa.provider_info->>'name' as external_provider,
      cce.event_type,
      cce.priority,
      EXTRACT(EPOCH FROM NOW() - cce.created_at)/60 as minutes_pending
    FROM processed_appointments pa
    JOIN care_coordination_events cce ON pa.appointment_id = cce.trigger_appointment_id
    WHERE cce.status IN ('detected', 'notified')
    AND pa.appointment_type = 'in_person_external'
    AND cce.created_at >= NOW() - INTERVAL '24 hours'
  );

-- Update every 30 seconds for real-time dashboard
REFRESH MATERIALIZED VIEW real_time_care_coordination;
```

---

## 6. Data Processing Pipelines

### **6.1 Virtual Care Pipeline (Healthie + Zoom Integration)**

#### **REVISED: Zoom Recording Batch Processing**
```yaml
# Virtual care pipeline leveraging Healthie's Zoom integration
virtual_care_pipeline_revised:
  
  # Appointment lifecycle
  appointment_creation:
    source: "healthie_graphql_api"
    mutation: "createAppointment"
    zoom_integration: {
      use_zoom: true,
      auto_recording: true,
      default_video_service: "zoom"
    }
    output: {
      appointment_id: "healthie_appointment_id",
      zoom_meeting_id: "zoom_meeting_identifier", 
      zoom_join_url: "patient_join_link",
      zoom_start_url: "provider_start_link"
    }
    
  # Meeting execution (handled by Zoom/Healthie)
  meeting_execution:
    platform: "zoom_via_healthie"
    recording: "automatic_cloud_recording"
    transcript: "zoom_auto_transcription"  # If enabled
    storage: "zoom_cloud_storage"
    
  # Post-meeting processing (our pipeline)
  recording_processing:
    trigger: "polling_healthie_for_recordings"  # Check every 5 minutes
    schedule: "*/5 * * * *"  # Cron schedule
    
    steps:
      1_detect_new_recordings:
        query: "healthie_graphql"
        check_field: "zoom_cloud_recording_files"
        filter: "status = completed AND not_processed = true"
        
      2_download_recordings:
        source: "zoom_cloud_recording_files.download_url"
        file_types: ["M4A", "TRANSCRIPT", "MP4"]  # Audio, transcript, video
        authentication: "healthie_provides_access"  # No separate Zoom auth needed!
        
      3_ai_medical_analysis:
        input: ["m4a_audio_file", "zoom_transcript", "appointment_context"]
        processing: "claude_medical_specialist"
        enhanced_transcript: "if zoom_transcript quality low, re-transcribe with Deepgram"
        
      4_healthie_integration:
        mutation: "updateAppointment"
        fields: {
          notes: "ai_clinical_summary",
          metadata: "ai_analysis_results",
          follow_up_actions: "recommended_care_coordination"
        }
        
      5_care_coordination_detection:
        analyze: "cross_reference_with_external_appointments"
        trigger: "coordination_events_if_needed"
        alert: "providers_if_urgent_findings"
        
      6_patient_notification:
        delivery: "mobile_app_push + sms"
        content: "patient_friendly_summary"
        timeline: "within_30_minutes_of_recording_completion"
```

#### **Healthie-Zoom Integration Service**
```typescript
// REVISED: Healthie-Zoom recording processor
class HealthieZoomRecordingProcessor {
  private healthieClient: HealthieGraphQLClient;
  private medicalAI: MedicalAIService;
  
  async processNewRecordings(): Promise<ProcessingResult[]> {
    // Query Healthie for appointments with new recordings
    const appointmentsWithRecordings = await this.healthieClient.query(`
      query GetAppointmentsWithRecordings {
        appointments(
          filter: {
            contact_type: "video_chat",
            use_zoom: true,
            date: { gte: "${this.getLastProcessedDate()}" }
          }
        ) {
          id
          patient_id
          provider_id
          date
          zoom_meeting_id
          
          # CONFIRMED: Available recording data
          zoom_cloud_recording_files {
            id
            download_url          # Direct download access!
            file_type            # M4A, TRANSCRIPT, MP4, etc.
            file_size
            recording_start
            recording_end
            status
          }
          
          zoom_appointment {
            start_time
            end_time
            duration
            participants_count
          }
        }
      }
    `);
    
    const results = [];
    for (const appointment of appointmentsWithRecordings) {
      // Process each appointment with recordings
      const result = await this.processAppointmentRecording(appointment);
      results.push(result);
    }
    
    return results;
  }
  
  private async processAppointmentRecording(appointment: HealthieAppointment): Promise<ProcessingResult> {
    // Download recording files using Healthie-provided URLs
    const recordings = await Promise.all(
      appointment.zoom_cloud_recording_files.map(async (file) => {
        if (file.file_type === 'M4A') {
          return {
            type: 'audio',
            data: await this.downloadFile(file.download_url),
            metadata: file
          };
        }
        if (file.file_type === 'TRANSCRIPT') {
          return {
            type: 'transcript', 
            data: await this.downloadFile(file.download_url),
            metadata: file
          };
        }
      })
    );
    
    // Extract audio and transcript
    const audioFile = recordings.find(r => r.type === 'audio');
    const transcriptFile = recordings.find(r => r.type === 'transcript');
    
    // AI medical analysis
    const aiAnalysis = await this.medicalAI.analyzeVirtualAppointment({
      appointmentId: appointment.id,
      patientId: appointment.patient_id,
      providerId: appointment.provider_id,
      audioData: audioFile?.data,
      transcript: transcriptFile?.data,
      meetingMetadata: appointment.zoom_appointment,
      appointmentContext: {
        duration: appointment.zoom_appointment.duration,
        participants: appointment.zoom_appointment.participants_count
      }
    });
    
    // Update Healthie appointment with AI results
    await this.healthieClient.mutate(`
      mutation UpdateAppointmentWithAI($appointmentId: ID!, $analysis: String!) {
        updateAppointment(input: {
          id: $appointmentId,
          notes: $analysis,
          metadata: "${JSON.stringify(aiAnalysis)}"
        }) {
          appointment { id }
        }
      }
    `, {
      appointmentId: appointment.id,
      analysis: aiAnalysis.clinicalSummary
    });
    
    // Check for care coordination needs
    await this.checkCareCoordinationNeeds(appointment.patient_id, aiAnalysis);
    
    return {
      appointmentId: appointment.id,
      processed: true,
      aiAnalysis,
      recordingFiles: recordings.length
    };
  }
}
```

### **6.2 In-Person Care Batch Pipeline**

#### **ETL Processing Workflow**
```yaml
# Apache Airflow DAG for in-person appointment processing
in_person_processing_dag:
  dag_id: "in_person_care_etl"
  schedule_interval: "*/10 minutes"
  max_active_runs: 3
  
  tasks:
    extract_mobile_recordings:
      operator: "S3Sensor"
      bucket: "moira-mobile-recordings"
      prefix: "in-person/{{ ds }}"
      timeout: 600
      
    enhance_audio_quality:
      operator: "PythonOperator"
      python_callable: "audio_enhancement.enhance_clinical_recording"
      resources:
        memory: "8GB"
        cpu: "4 cores"
        
    transcribe_conversation:
      operator: "DeepgramOperator"
      model: "medical-conversation"
      language: "en-US"
      punctuation: true
      diarization: true
      
    medical_ai_analysis:
      operator: "ClaudeOperator"
      model: "claude-3-sonnet"
      system_prompt: "medical-analysis-specialist"
      temperature: 0.1
      
    detect_care_coordination_needs:
      operator: "PythonOperator" 
      python_callable: "care_coordination.detect_coordination_needs"
      
    update_patient_record:
      operator: "PostgresOperator"
      sql: "INSERT INTO processed_appointments ..."
      
    trigger_care_coordination:
      operator: "PythonOperator"
      python_callable: "care_coordination.trigger_coordination_events"
      trigger_rule: "all_success"
      
    notify_patient:
      operator: "SlackWebhookOperator"  # Or mobile app notification
      message: "Your specialist visit summary is ready"
      
  dependencies:
    extract_mobile_recordings >> enhance_audio_quality >> transcribe_conversation
    transcribe_conversation >> medical_ai_analysis >> detect_care_coordination_needs
    [medical_ai_analysis, detect_care_coordination_needs] >> update_patient_record
    update_patient_record >> [trigger_care_coordination, notify_patient]
```

### **6.3 Cross-Care Intelligence Pipeline**

#### **Care Coordination Data Processing**
```python
# Daily cross-care analysis pipeline
class CrossCareIntelligenceProcessor:
    def __init__(self):
        self.bitquery = BitQueryClient()
        self.medical_ai = MedicalAIService()
        self.care_coordinator = CareCoordinationService()
        
    async def process_daily_coordination(self, date: str):
        """Analyze all appointments from the day for care coordination opportunities"""
        
        # Extract all appointments from the day
        daily_appointments = await self.bitquery.query(f"""
            SELECT * FROM processed_appointments 
            WHERE appointment_date::date = '{date}'
            ORDER BY patient_id, appointment_date
        """)
        
        # Group by patient for cross-care analysis
        by_patient = self.group_by_patient(daily_appointments)
        
        coordination_insights = []
        for patient_id, appointments in by_patient.items():
            # Analyze care coordination needs
            insights = await self.medical_ai.analyze_cross_care_coordination(
                virtual_appointments=[a for a in appointments if a.type == 'virtual_practice'],
                in_person_appointments=[a for a in appointments if a.type == 'in_person_external']
            )
            
            # Generate coordination recommendations
            recommendations = await self.care_coordinator.generate_recommendations(
                patient_id, insights
            )
            
            coordination_insights.append({
                'patient_id': patient_id,
                'insights': insights,
                'recommendations': recommendations
            })
            
        # Load results to analytics layer
        await self.load_to_gold_layer(coordination_insights, date)
        
        return coordination_insights
```

---

## 7. Data Governance & HIPAA Compliance

### **7.1 Data Security Pipeline**

#### **Encryption and Access Control**
```yaml
# Data security configuration
data_security:
  encryption:
    at_rest: "AES-256-GCM"
    in_transit: "TLS 1.3"
    key_management: "AWS KMS / Google Cloud KMS"
    
  access_control:
    patient_data:
      - role: "patient"
        permissions: ["read_own_data", "control_sharing"]
      - role: "provider" 
        permissions: ["read_assigned_patients", "write_clinical_notes"]
      - role: "ai_service"
        permissions: ["process_anonymized_data"]
        
  audit_logging:
    all_data_access: true
    ai_processing_decisions: true
    care_coordination_events: true
    patient_consent_changes: true
    
  retention_policies:
    audio_recordings: "7 years"  # HIPAA requirement
    transcriptions: "7 years"
    ai_analysis: "7 years"
    audit_logs: "10 years"
```

### **7.2 Patient Consent Management Pipeline**

#### **Consent Tracking for Hybrid Care**
```sql
-- Patient consent tracking for different care types
CREATE TABLE patient_consent (
    consent_id UUID PRIMARY KEY,
    patient_id UUID,
    
    -- Virtual care consent
    virtual_recording_consent BOOLEAN,
    virtual_ai_analysis_consent BOOLEAN,
    virtual_provider_sharing_consent BOOLEAN,
    
    -- In-person care consent  
    in_person_recording_consent BOOLEAN,
    in_person_ai_analysis_consent BOOLEAN,
    external_provider_sharing_consent BOOLEAN,
    
    -- Care coordination consent
    cross_care_coordination_consent BOOLEAN,
    emergency_override_consent BOOLEAN,
    
    -- Consent metadata
    consent_date TIMESTAMP,
    expiration_date TIMESTAMP,
    withdrawal_date TIMESTAMP,
    consent_method ENUM('digital_signature', 'verbal_recorded', 'written_form')
);

-- Consent validation function for pipeline
CREATE OR REPLACE FUNCTION validate_processing_consent(
    patient_id UUID, 
    processing_type VARCHAR(50)
) RETURNS BOOLEAN AS $$
DECLARE
    consent_valid BOOLEAN := FALSE;
BEGIN
    SELECT 
        CASE processing_type
            WHEN 'virtual_recording' THEN virtual_recording_consent
            WHEN 'virtual_ai_analysis' THEN virtual_ai_analysis_consent  
            WHEN 'in_person_recording' THEN in_person_recording_consent
            WHEN 'in_person_ai_analysis' THEN in_person_ai_analysis_consent
            WHEN 'care_coordination' THEN cross_care_coordination_consent
            ELSE FALSE
        END INTO consent_valid
    FROM patient_consent 
    WHERE patient_consent.patient_id = validate_processing_consent.patient_id
    AND consent_date <= NOW()
    AND (expiration_date IS NULL OR expiration_date > NOW())
    AND withdrawal_date IS NULL;
    
    RETURN COALESCE(consent_valid, FALSE);
END;
$$ LANGUAGE plpgsql;
```

---

## 8. Monitoring & Observability

### **8.1 Pipeline Health Monitoring**

#### **Key Performance Indicators**
```yaml
pipeline_monitoring:
  virtual_care_metrics:
    audio_stream_latency: "<2s (p95)"
    transcription_accuracy: ">95%"
    ai_analysis_latency: "<5s (p95)"
    provider_dashboard_updates: "<1s (p95)"
    
  in_person_care_metrics:
    upload_success_rate: ">99%"
    audio_enhancement_quality: ">80% SNR improvement"
    transcription_accuracy: ">90% (challenging audio)"
    processing_completion_time: "<30min (p90)"
    
  cross_care_coordination:
    correlation_accuracy: ">95%"
    care_coordination_trigger_precision: ">90%"
    provider_response_time: "<4h (p90)"
    patient_satisfaction_with_coordination: ">4.5/5"
    
  data_governance:
    consent_validation_accuracy: "100%"
    audit_log_completeness: "100%"
    encryption_compliance: "100%"
    retention_policy_adherence: "100%"
```

### **8.2 BitQuery Performance Optimization**

#### **Query Optimization for Healthcare Analytics**
```sql
-- Optimized BitQuery indexes for healthcare data
CREATE INDEX CONCURRENTLY idx_appointments_patient_date 
ON processed_appointments (patient_id, appointment_date DESC);

CREATE INDEX CONCURRENTLY idx_appointments_type_priority
ON processed_appointments (appointment_type, (ai_analysis->>'priority'));

CREATE INDEX CONCURRENTLY idx_care_coordination_status_priority  
ON care_coordination_events (status, priority, created_at);

-- Partitioning strategy for large datasets
CREATE TABLE processed_appointments_partitioned (
    LIKE processed_appointments INCLUDING ALL
) PARTITION BY RANGE (appointment_date);

-- Monthly partitions for efficient queries
CREATE TABLE appointments_2024_08 PARTITION OF processed_appointments_partitioned
FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
```

---

## 9. Implementation Roadmap

### **Phase 1: Foundation (Weeks 1-4)**
- [ ] Set up data lake infrastructure (S3/GCS + Delta Lake)
- [ ] **REVISED**: Implement Healthie-Zoom recording polling and download pipeline
- [ ] Build basic in-person recording upload and processing
- [ ] Create shared data schemas and BitQuery basic queries
- [ ] Implement HIPAA-compliant data encryption and access controls
- [ ] **NEW**: Set up Healthie GraphQL client with recording file access

### **Phase 2: AI Integration (Weeks 5-8)**
- [ ] Deploy medical AI analysis services
- [ ] Implement emergency detection for both care types
- [ ] Build care coordination trigger system
- [ ] Create patient and provider notification systems
- [ ] Develop BitQuery analytics dashboards

### **Phase 3: Advanced Analytics (Weeks 9-12)**
- [ ] Implement predictive health analytics
- [ ] Build provider network effectiveness analytics
- [ ] Deploy automated care coordination recommendations
- [ ] Create comprehensive patient health insights
- [ ] Optimize BitQuery performance for large-scale analytics

### **Phase 4: Optimization & Scaling (Weeks 13-16)**
- [ ] Implement real-time stream processing optimizations
- [ ] Build advanced BitQuery analytics for population health
- [ ] Deploy machine learning models for care prediction
- [ ] Create comprehensive compliance and audit reporting
- [ ] Scale infrastructure for production healthcare workloads

---

## 10. Technical Architecture Summary

### **REVISED Data Flow Architecture**
```mermaid
graph TB
    subgraph "Virtual Care (Healthie + Zoom)"
        HC[Healthie Appointment] → ZM[Zoom Meeting Auto-Created]
        ZM → ZR[Zoom Auto-Recording] → ZS[Zoom Cloud Storage]
        ZS → HD[Healthie Download URLs] → AI[AI Analysis]
        AI → HU[Healthie Update] → EHR[EHR Storage]
    end
    
    subgraph "In-Person Care (Mobile)"
        IP[In-Person Recording] → MU[Mobile Upload] → AE[Audio Enhancement]
        AE → BT[Batch Transcription] → BA[Batch AI Analysis]
        BA → CC[Care Coordination] → VT[Virtual Follow-up Trigger]
    end
    
    subgraph "Data Lake & Analytics"
        DL[(Healthcare Data Lake)] → BQ[BitQuery Analytics] → AD[Analytics Dashboard]
        AI → DL
        BA → DL
        BQ → CI[Cross-Care Insights]
    end
    
    subgraph "Unified Care Coordination"
        CI → CCE[Coordination Events] → PN[Provider Notifications]
        CCE → PS[Patient Summaries] → MA[Mobile App]
        VT → HC
    end
```

### **Technology Stack**
- **Virtual Care Processing**: Healthie GraphQL API + Zoom Cloud Recordings (batch processing)
- **In-Person Care Processing**: React Native mobile recording + Apache Airflow ETL
- **Data Lake**: AWS S3/Google Cloud Storage + Delta Lake
- **Analytics**: BitQuery + Snowflake/BigQuery
- **AI Services**: Claude (Anthropic), Deepgram (for enhanced transcription)
- **EHR Integration**: Healthie GraphQL API (native Zoom integration)
- **Mobile Platform**: React Native with audio recording for in-person visits
- **Recording Management**: Zoom cloud storage accessed via Healthie download URLs

This hybrid care data pipeline architecture supports the unique requirements of virtual practice appointments with real-time AI assistance and in-person external care coordination, all unified through a comprehensive healthcare data lake with BitQuery analytics.
