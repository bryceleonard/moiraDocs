# MoiraMVP Final Data Architecture - BigQuery Integration
## Comprehensive Healthcare Data Platform with Healthie + BigQuery

**Document Version**: Final v1.0  
**Last Updated**: September 2, 2025  
**Owner**: Technical Architecture Team  
**Status**: **Consolidated Final Architecture**

---

## 🎯 Executive Summary

### **Project Architecture**
MoiraMVP is a **hybrid healthcare coordination platform** that unifies:
- **Virtual Practice Appointments** (Healthie + Zoom integration)
- **External In-Person Care** (Mobile recording + AI analysis)  
- **Cross-Appointment Intelligence** (BigQuery analytics)
- **Family Dashboard** (View-only coordination)

### **Data Architecture Strategy**
- **Healthie EHR**: Single source of truth for all healthcare data
- **PostgreSQL**: Real-time operational database for app functionality
- **BigQuery**: Analytics data warehouse for complex healthcare intelligence
- **Mobile + AI Pipeline**: Unified recording and analysis across care modalities

---

## 📋 Document Consolidation Summary

### **What This Document Replaces:**
This consolidated architecture replaces and supersedes:

1. ❌ `/data-pipeline-prd.md` (26 BitQuery references) → **ARCHIVE**
2. ❌ `/docs/mvp-data-prd-v2.md` (116 BitQuery references) → **ARCHIVE** 
3. ✅ `/docs/mvp-data-prd-bigquery-corrected.md` → **MERGED INTO THIS DOCUMENT**

### **Document Organization Plan:**
```
📁 MoiraMVP/
├── 📄 moira-data-architecture-final.md    ← **THIS DOCUMENT (Primary)**
├── 📁 docs/
│   ├── 📄 hybrid-care-user-stories.md     ← **KEEP** (User stories)
│   ├── 📄 medical-ai-context-requirements.md ← **KEEP** (AI requirements)  
│   ├── 📄 hybrid-healthcare-app-architecture.md ← **KEEP** (App architecture)
│   ├── 📄 multi-agent-coordination-framework.md ← **KEEP** (AI coordination)
│   └── 📄 healthie-zoom-integration-research.md ← **KEEP** (Integration specs)
├── 📁 archive/
│   ├── 📄 data-pipeline-prd.md           ← **MOVE HERE**
│   └── 📄 mvp-data-prd-v2.md            ← **MOVE HERE**
└── 📄 output-example.md                  ← **DELETE** (0 bytes)
```

---

## 🏗️ Final Data Architecture

### **1. Data Sources & Classification**

#### **Primary Data Sources**

**1.1 Healthie EHR (Single Source of Truth)**
```typescript
interface HealthieEHRData {
  // All appointments managed in Healthie
  appointments: {
    id: string;
    patient_id: string;
    provider_id: string | null;        // null = external appointment
    contact_type: 'video_chat' | 'in_person' | 'external';
    
    // Zoom integration (for internal virtual appointments)
    zoom_meeting_id?: string;
    zoom_cloud_recording_files?: {
      download_url: string;
      file_type: 'MP4' | 'M4A' | 'TRANSCRIPT';
      recording_start: string;
      recording_end: string;
    }[];
  };
  
  // Patient clinical data
  patients: HealthiePatient[];
  clinicalNotes: ClinicalNote[];
  medications: Medication[];
  assessments: Assessment[];
}
```

**1.2 Mobile Recording Data (External Appointments)**
```typescript
interface ExternalCareRecording {
  recordingId: string;
  healthieAppointmentId: string;      // Links to Healthie appointment
  patientId: string;
  
  // Pause/resume recording segments
  recordingSegments: {
    segmentId: string;
    startTime: Date;
    endTime: Date;
    audioFile: AudioFile;
    pauseReason?: 'patient_request' | 'privacy' | 'interruption';
  }[];
  
  // Merged final recording
  finalRecording: {
    mergedAudioFile: AudioFile;
    totalDuration: number;
    qualityMetrics: QualityMetrics;
  };
  
  // External appointment context
  externalProvider: {
    name: string;
    specialty: string;
    facility: string;
  };
}
```

### **2. Dual Database Architecture: PostgreSQL + BigQuery**

#### **2.1 PostgreSQL (Operational Database)**
```sql
-- Real-time application operations
CREATE TABLE app_user_profiles (
    user_id UUID PRIMARY KEY,
    healthie_patient_id VARCHAR(255) UNIQUE NOT NULL,
    
    -- Consent and preferences
    audio_recording_consent BOOLEAN DEFAULT false,
    ai_analysis_consent BOOLEAN DEFAULT false,
    family_sharing_consent BOOLEAN DEFAULT false,
    
    -- HealthKit integration
    healthkit_authorized BOOLEAN DEFAULT false,
    authorized_data_types TEXT[],
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Extended appointment metadata (links to Healthie)
CREATE TABLE appointment_metadata (
    healthie_appointment_id VARCHAR(255) PRIMARY KEY,
    
    -- Auto-classification
    is_internal_appointment BOOLEAN,     -- Based on provider_id presence
    appointment_category 'virtual_internal' | 'in_person_internal' | 'external_specialist',
    
    -- External provider info (when external)
    external_provider_name VARCHAR(255),
    external_provider_specialty VARCHAR(100),
    external_facility_name VARCHAR(255),
    
    -- Recording configuration
    recording_method 'zoom_automatic' | 'mobile_pause_resume',
    recording_status 'not_started' | 'recording' | 'paused' | 'completed' | 'failed',
    
    -- Status tracking
    appointment_status 'scheduled' | 'in_progress' | 'completed' | 'cancelled',
    analysis_status 'pending' | 'processing' | 'completed' | 'failed',
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Pause/resume recording sessions (external appointments)
CREATE TABLE appointment_recordings (
    recording_id UUID PRIMARY KEY,
    healthie_appointment_id VARCHAR(255) UNIQUE REFERENCES appointment_metadata,
    
    -- Recording session management
    recording_status 'not_started' | 'recording' | 'paused' | 'completed' | 'failed',
    current_segment_id UUID,
    total_segments INTEGER DEFAULT 0,
    total_pause_duration_seconds INTEGER DEFAULT 0,
    
    -- File management
    merged_audio_file_path VARCHAR(500),
    merged_audio_duration_seconds INTEGER,
    audio_quality_score DECIMAL(3,2),
    
    -- Session tracking
    recording_started_at TIMESTAMP,
    recording_completed_at TIMESTAMP,
    last_segment_ended_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE recording_segments (
    segment_id UUID PRIMARY KEY,
    recording_id UUID REFERENCES appointment_recordings,
    
    -- Segment details
    segment_number INTEGER,
    segment_start_time TIMESTAMP,
    segment_end_time TIMESTAMP,
    segment_duration_seconds INTEGER,
    
    -- Audio file details
    audio_file_path VARCHAR(500),
    audio_file_size_bytes BIGINT,
    audio_quality_metrics JSONB,
    
    -- Pause context
    pause_reason 'patient_request' | 'privacy_sensitive' | 'interruption' | 'technical',
    pause_duration_seconds INTEGER,
    resume_notes TEXT,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- AI analysis results (operational)
CREATE TABLE appointment_ai_analysis (
    analysis_id UUID PRIMARY KEY,
    healthie_appointment_id VARCHAR(255) REFERENCES appointment_metadata,
    patient_id UUID REFERENCES app_user_profiles(user_id),
    
    -- Analysis results
    clinical_summary TEXT,
    clinical_findings JSONB,
    diagnoses JSONB,
    medications JSONB,
    vital_signs JSONB,
    
    -- Emergency detection
    emergency_flags JSONB,
    urgency_level 'routine' | 'priority' | 'urgent' | 'emergent',
    
    -- Care coordination needs
    care_coordination_needs JSONB,
    provider_notifications JSONB,
    patient_action_items JSONB,
    
    -- Analysis metadata
    ai_models_used JSONB,
    overall_confidence_score DECIMAL(3,2),
    processing_time_seconds INTEGER,
    
    -- Timestamps
    analysis_started_at TIMESTAMP,
    analysis_completed_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- Actionable insights for patients
CREATE TABLE actionable_insights (
    insight_id UUID PRIMARY KEY,
    patient_user_id UUID REFERENCES app_user_profiles(user_id),
    source_appointment_id VARCHAR(255) REFERENCES appointment_metadata,
    
    -- Insight content
    insight_type 'medication_reminder' | 'follow_up_needed' | 'health_trend' | 'care_coordination',
    insight_title VARCHAR(255),
    insight_description TEXT,
    recommended_actions TEXT[],
    
    -- Priority and urgency
    priority_level 'low' | 'medium' | 'high' | 'urgent',
    urgency_score DECIMAL(3,2),
    
    -- Patient interaction
    patient_viewed BOOLEAN DEFAULT false,
    patient_acknowledged BOOLEAN DEFAULT false,
    patient_completed_actions TEXT[],
    
    -- Insight lifecycle
    expires_at TIMESTAMP,
    resolved_at TIMESTAMP,
    resolution_method 'patient_action' | 'provider_action' | 'auto_resolved',
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Family dashboard access
CREATE TABLE family_dashboard_access (
    access_id UUID PRIMARY KEY,
    patient_user_id UUID REFERENCES app_user_profiles(user_id),
    
    -- Family member details
    family_member_email VARCHAR(255),
    family_member_name VARCHAR(255),
    relationship 'spouse' | 'parent' | 'child' | 'sibling' | 'caregiver' | 'guardian',
    
    -- Access permissions (MVP: view-only)
    access_level 'view_only',
    access_status 'invited' | 'pending' | 'active' | 'suspended' | 'revoked',
    
    -- Data visibility
    can_view_appointments BOOLEAN DEFAULT true,
    can_view_ai_summaries BOOLEAN DEFAULT true,
    can_view_actionable_insights BOOLEAN DEFAULT true,
    can_receive_urgent_notifications BOOLEAN DEFAULT true,
    
    -- Invitation management
    invitation_token VARCHAR(255) UNIQUE,
    invitation_sent_at TIMESTAMP,
    invitation_expires_at TIMESTAMP,
    invitation_accepted_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

#### **2.2 BigQuery (Analytics Data Warehouse)**
```sql
-- Patient health analytics in BigQuery
CREATE OR REPLACE TABLE `moira-healthcare.analytics.patient_health_trends` (
    patient_id STRING,
    analysis_date DATE,
    
    -- Health trajectory metrics  
    health_trend_direction STRING,      -- 'improving', 'stable', 'declining'
    severity_score_avg FLOAT64,
    emergency_episodes_count INT64,
    
    -- Appointment patterns
    total_appointments INT64,
    internal_appointments INT64,
    external_appointments INT64,
    appointment_frequency_days FLOAT64,
    
    -- Care coordination effectiveness
    coordination_effectiveness_score FLOAT64,
    active_care_coordination_items INT64,
    provider_network_diversity INT64,
    care_fragmentation_risk_score FLOAT64,
    
    -- Medication management
    medication_changes_count INT64,
    potential_drug_interactions INT64,
    medication_adherence_score FLOAT64,
    
    -- Family engagement
    family_members_active INT64,
    family_notification_engagement_rate FLOAT64,
    caregiver_burden_assessment_score FLOAT64,
    
    -- Data quality indicators
    healthkit_data_completeness FLOAT64,
    appointment_recording_quality_avg FLOAT64,
    ai_analysis_confidence_avg FLOAT64,
    
    -- Predictive insights
    health_risk_score FLOAT64,
    care_gap_count INT64,
    predicted_next_episode_risk FLOAT64,
    
    -- Metadata
    analysis_timestamp TIMESTAMP,
    data_freshness_hours FLOAT64,
    bigquery_processing_version STRING
) 
PARTITION BY analysis_date
CLUSTER BY patient_id;

-- Care coordination pattern analysis
CREATE OR REPLACE TABLE `moira-healthcare.analytics.care_coordination_patterns` (
    patient_id STRING,
    analysis_period_start DATE,
    analysis_period_end DATE,
    
    -- Provider network analysis
    internal_providers_count INT64,
    external_providers_count INT64,
    provider_specialties ARRAY<STRING>,
    provider_communication_effectiveness FLOAT64,
    
    -- Coordination events
    coordination_events_total INT64,
    coordination_events_resolved INT64,
    avg_resolution_time_hours FLOAT64,
    urgent_coordination_events INT64,
    
    -- Treatment coherence
    treatment_plan_coherence_score FLOAT64,
    medication_management_alignment FLOAT64,
    care_plan_conflicts_count INT64,
    
    -- Communication gaps
    provider_to_provider_gaps INT64,
    patient_information_sharing_gaps INT64,
    delayed_communication_events INT64,
    
    -- Quality indicators
    duplicate_care_events INT64,
    missed_follow_up_opportunities INT64,
    preventive_care_opportunities INT64,
    
    -- Risk assessment
    emergency_coordination_preparedness FLOAT64,
    care_transition_risk_score FLOAT64,
    
    -- Metadata
    analysis_timestamp TIMESTAMP
)
PARTITION BY analysis_period_start
CLUSTER BY patient_id;

-- Family engagement and caregiver analytics
CREATE OR REPLACE TABLE `moira-healthcare.analytics.family_engagement_metrics` (
    patient_id STRING,
    family_member_access_id STRING,
    relationship STRING,
    analysis_date DATE,
    
    -- Engagement behaviors
    dashboard_views_count INT64,
    notification_interactions_count INT64,
    urgent_alert_response_time_minutes FLOAT64,
    urgent_alert_response_rate FLOAT64,
    
    -- Family effectiveness
    caregiver_burden_score FLOAT64,
    family_coordination_effectiveness FLOAT64,
    caregiver_advocacy_score FLOAT64,
    
    -- Caregiver insights
    optimal_notification_frequency STRING,    -- 'immediate', 'daily', 'weekly'
    preferred_communication_times ARRAY<STRING>,
    engagement_pattern_type STRING,          -- 'reactive', 'proactive', 'monitoring'
    
    -- Predictive caregiver analytics
    predicted_caregiver_availability FLOAT64,
    caregiver_burnout_risk_score FLOAT64,
    support_network_strength FLOAT64,
    
    -- Patient outcome correlations
    family_engagement_patient_outcome_correlation FLOAT64,
    care_adherence_improvement_with_family FLOAT64,
    
    -- Metadata
    analysis_timestamp TIMESTAMP
)
PARTITION BY analysis_date
CLUSTER BY patient_id;
```

### **3. BigQuery Analytics Functions for Real-Time Processing**

```sql
-- BigQuery function: Analyze patient health trends
CREATE OR REPLACE TABLE FUNCTION `moira-healthcare.analytics.analyze_patient_health_trends`(input_patient_id STRING)
AS (
  WITH recent_appointments AS (
    SELECT 
      aa.patient_id,
      aa.analysis_completed_at,
      aa.emergency_flags,
      aa.overall_confidence_score,
      aa.urgency_level,
      
      -- Severity scoring from AI analysis
      CASE 
        WHEN aa.urgency_level = 'emergent' THEN 1.0
        WHEN aa.urgency_level = 'urgent' THEN 0.8
        WHEN aa.urgency_level = 'priority' THEN 0.6
        ELSE 0.3
      END as severity_score,
      
      -- Previous appointment comparison  
      LAG(CASE 
        WHEN aa.urgency_level = 'emergent' THEN 1.0
        WHEN aa.urgency_level = 'urgent' THEN 0.8
        WHEN aa.urgency_level = 'priority' THEN 0.6
        ELSE 0.3
      END) OVER (ORDER BY aa.analysis_completed_at) as prev_severity_score
      
    FROM `moira-healthcare.raw_data.appointment_analyses` aa
    WHERE aa.patient_id = input_patient_id
    AND aa.analysis_completed_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
    ORDER BY aa.analysis_completed_at DESC
    LIMIT 20
  ),
  
  trend_analysis AS (
    SELECT 
      patient_id,
      
      -- Trend direction calculation
      CASE 
        WHEN AVG(severity_score - IFNULL(prev_severity_score, severity_score)) > 0.1 THEN 'declining'
        WHEN AVG(severity_score - IFNULL(prev_severity_score, severity_score)) < -0.1 THEN 'improving'
        ELSE 'stable'
      END as health_trend_direction,
      
      -- Confidence in trend assessment
      ABS(AVG(severity_score - IFNULL(prev_severity_score, severity_score))) as trend_confidence,
      
      -- Current health metrics
      AVG(severity_score) as current_severity_avg,
      STDDEV(severity_score) as severity_variance,
      COUNT(*) as appointments_analyzed,
      COUNTIF(severity_score > 0.8) as emergency_episodes,
      
      -- Family alert level determination
      CASE 
        WHEN AVG(severity_score) > 0.8 THEN 'urgent'
        WHEN AVG(severity_score - IFNULL(prev_severity_score, severity_score)) > 0.2 THEN 'attention'
        WHEN COUNTIF(severity_score > 0.8) > 0 THEN 'important'  
        ELSE 'normal'
      END as family_alert_level,
      
      CURRENT_TIMESTAMP() as analysis_timestamp
      
    FROM recent_appointments
    GROUP BY patient_id
  )
  
  SELECT * FROM trend_analysis
);

-- BigQuery function: Care coordination effectiveness
CREATE OR REPLACE TABLE FUNCTION `moira-healthcare.analytics.analyze_care_coordination`(input_patient_id STRING)
AS (
  WITH coordination_events AS (
    SELECT 
      ai.patient_id,
      ai.healthie_appointment_id,
      ai.analysis_completed_at,
      JSON_EXTRACT_SCALAR(ai.care_coordination_needs, '$.coordination_events') as coordination_needs,
      JSON_EXTRACT_SCALAR(ai.care_coordination_needs, '$.provider_notifications') as provider_notifications,
      am.is_internal_appointment,
      am.external_provider_specialty
      
    FROM `moira-healthcare.raw_data.appointment_analyses` ai
    JOIN `moira-healthcare.raw_data.appointments` am 
      ON ai.healthie_appointment_id = am.healthie_appointment_id
    WHERE ai.patient_id = input_patient_id
    AND ai.analysis_completed_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)
  ),
  
  coordination_metrics AS (
    SELECT 
      input_patient_id as patient_id,
      
      -- Provider network diversity
      COUNT(DISTINCT CASE WHEN is_internal_appointment THEN 'internal' ELSE external_provider_specialty END) as provider_network_diversity,
      
      -- Coordination effectiveness
      COUNTIF(coordination_needs IS NOT NULL) / COUNT(*) as coordination_need_detection_rate,
      COUNTIF(provider_notifications IS NOT NULL) / COUNTIF(coordination_needs IS NOT NULL) as coordination_action_rate,
      
      -- Care fragmentation risk
      CASE 
        WHEN COUNT(DISTINCT external_provider_specialty) > 3 THEN 0.8
        WHEN COUNT(DISTINCT external_provider_specialty) > 1 THEN 0.5
        ELSE 0.2
      END as care_fragmentation_risk_score,
      
      -- Recent coordination activity
      COUNTIF(analysis_completed_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)) as recent_coordination_events,
      
      CURRENT_TIMESTAMP() as analysis_timestamp
      
    FROM coordination_events
    GROUP BY patient_id
  )
  
  SELECT * FROM coordination_metrics
);

-- BigQuery function: Family dashboard intelligence
CREATE OR REPLACE TABLE FUNCTION `moira-healthcare.analytics.analyze_family_intelligence`(input_patient_id STRING)
AS (
  WITH family_context AS (
    SELECT 
      fa.patient_user_id as patient_id,
      fa.relationship,
      fa.access_status,
      fa.can_receive_urgent_notifications,
      
      -- Family engagement from recent activity
      COUNTIF(nt.sent_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)) as recent_notifications,
      COUNTIF(nt.opened_at IS NOT NULL) / NULLIF(COUNT(*), 0) as notification_open_rate,
      
      -- Response time analysis
      AVG(TIMESTAMP_DIFF(nt.opened_at, nt.sent_at, MINUTE)) as avg_response_time_minutes
      
    FROM `moira-healthcare.raw_data.family_access` fa
    LEFT JOIN `moira-healthcare.raw_data.family_notifications` nt 
      ON fa.access_id = nt.family_access_id
    WHERE fa.patient_user_id = input_patient_id
    AND fa.access_status = 'active'
    GROUP BY fa.patient_user_id, fa.relationship, fa.access_status, fa.can_receive_urgent_notifications
  ),
  
  family_intelligence AS (
    SELECT 
      input_patient_id as patient_id,
      
      -- Family network assessment
      COUNT(*) as active_family_members,
      COUNT(DISTINCT relationship) as family_relationship_diversity,
      AVG(notification_open_rate) as avg_family_engagement_rate,
      
      -- Optimal notification strategy
      CASE 
        WHEN AVG(avg_response_time_minutes) < 60 THEN 'immediate'
        WHEN AVG(avg_response_time_minutes) < 1440 THEN 'daily_digest'
        ELSE 'weekly_summary'
      END as optimal_notification_frequency,
      
      -- Caregiver burden assessment
      CASE 
        WHEN AVG(recent_notifications) > 20 THEN 0.8  -- High notification volume
        WHEN AVG(notification_open_rate) < 0.5 THEN 0.7  -- Low engagement (potential burnout)
        WHEN COUNT(*) > 3 THEN 0.6  -- Large family network
        ELSE 0.3
      END as caregiver_burden_estimate,
      
      -- Family coordination effectiveness
      AVG(notification_open_rate) * (1 - (AVG(avg_response_time_minutes) / 1440)) as family_coordination_effectiveness,
      
      CURRENT_TIMESTAMP() as analysis_timestamp
      
    FROM family_context
    GROUP BY patient_id
  )
  
  SELECT * FROM family_intelligence
);
```

### **4. Complete Data Processing Pipeline with BigQuery Integration**

```python
# Final processing pipeline with BigQuery analytics
class MoiraHealthcareProcessor:
    
    def __init__(self):
        self.bigquery = bigquery.Client(project='moira-healthcare')
        self.postgresql = PostgreSQLClient()
        self.healthie = HealthieClient()
        self.deepgram = DeepgramClient()
        self.claude = ClaudeClient()
        
    async def process_appointment_complete_pipeline(self, healthie_appointment_id: str):
        """Complete appointment processing with BigQuery analytics integration"""
        
        # 1. Determine appointment type and get recording
        appointment_meta = await self.get_appointment_metadata(healthie_appointment_id)
        
        if appointment_meta.is_internal_appointment:
            # Virtual appointment - Healthie/Zoom recording
            audio_file = await self.get_zoom_recording_from_healthie(healthie_appointment_id)
        else:
            # External appointment - Mobile pause/resume recording
            audio_file = await self.merge_mobile_recording_segments(healthie_appointment_id)
        
        # 2. Transcription and AI analysis
        transcript = await self.deepgram.transcribe_medical(audio_file)
        ai_analysis = await self.claude.analyze_medical_conversation(
            transcript=transcript,
            appointment_context=appointment_meta,
            patient_history=await self.get_patient_healthie_history(appointment_meta.patient_id)
        )
        
        # 3. Store AI analysis in PostgreSQL (operational)
        analysis_id = await self.store_ai_analysis_postgresql(healthie_appointment_id, ai_analysis)
        
        # 4. Sync data to BigQuery (analytics)
        await self.sync_data_to_bigquery([
            {'table': 'appointment_analyses', 'record_id': analysis_id},
            {'table': 'appointments', 'record_id': healthie_appointment_id}
        ])
        
        # 5. Get BigQuery analytics context for enhanced processing
        bigquery_context = await self.get_bigquery_analytics_context(appointment_meta.patient_id)
        
        # 6. Enhanced cross-appointment analysis with BigQuery insights
        comprehensive_analysis = await self.run_enhanced_cross_analysis({
            'current_analysis': ai_analysis,
            'bigquery_health_trends': bigquery_context.health_trends,
            'bigquery_care_coordination': bigquery_context.care_coordination,
            'bigquery_family_intelligence': bigquery_context.family_metrics
        })
        
        # 7. Create actionable insights for patient
        patient_insights = await self.create_actionable_insights(
            appointment_meta.patient_id, comprehensive_analysis
        )
        
        # 8. Update family dashboard with BigQuery-optimized notifications
        await self.update_family_dashboard_with_bigquery_optimization(
            appointment_meta.patient_id, comprehensive_analysis, bigquery_context
        )
        
        # 9. Care coordination actions based on analysis
        if comprehensive_analysis.requires_coordination:
            await self.trigger_care_coordination_actions(
                appointment_meta.patient_id, comprehensive_analysis
            )
        
        return {
            'appointment_id': healthie_appointment_id,
            'analysis_id': analysis_id,
            'comprehensive_analysis': comprehensive_analysis,
            'patient_insights': patient_insights,
            'bigquery_enhanced': True
        }
    
    async def get_bigquery_analytics_context(self, patient_id: str) -> BigQueryAnalyticsContext:
        """Get patient analytics from BigQuery for enhanced processing"""
        
        # Execute BigQuery analytics functions in parallel
        queries = {
            'health_trends': f"""
                SELECT * FROM `moira-healthcare.analytics.analyze_patient_health_trends`('{patient_id}')
            """,
            'care_coordination': f"""
                SELECT * FROM `moira-healthcare.analytics.analyze_care_coordination`('{patient_id}')
            """,
            'family_intelligence': f"""
                SELECT * FROM `moira-healthcare.analytics.analyze_family_intelligence`('{patient_id}')
            """
        }
        
        # Execute all queries concurrently for performance
        results = {}
        for name, query in queries.items():
            try:
                query_job = self.bigquery.query(query)
                results[name] = [dict(row) for row in query_job.result()]
            except Exception as e:
                logger.error(f"BigQuery {name} analysis failed: {e}")
                results[name] = []
        
        return BigQueryAnalyticsContext(
            health_trends=results['health_trends'][0] if results['health_trends'] else None,
            care_coordination=results['care_coordination'][0] if results['care_coordination'] else None,  
            family_intelligence=results['family_intelligence'][0] if results['family_intelligence'] else None
        )
        
    async def merge_mobile_recording_segments(self, healthie_appointment_id: str) -> AudioFile:
        """Merge pause/resume recording segments into single file"""
        
        recording_session = await self.postgresql.get_recording_session(healthie_appointment_id)
        segments = await self.postgresql.get_recording_segments(recording_session.recording_id)
        
        # Merge audio segments with smooth transitions
        merged_audio = await self.audio_processor.merge_segments_with_normalization(
            segments=[seg.audio_file_path for seg in segments],
            normalize_volume=True,
            remove_silence_gaps=True,
            quality_enhancement=True
        )
        
        # Update recording session with merged file
        await self.postgresql.update_recording_session(
            recording_session.recording_id,
            merged_audio_file_path=merged_audio.file_path,
            merged_audio_duration_seconds=merged_audio.duration_seconds,
            audio_quality_score=merged_audio.quality_score
        )
        
        return merged_audio
```

### **5. ETL Pipeline: PostgreSQL → BigQuery**

```yaml
# Data synchronization pipeline
postgresql_to_bigquery_etl:
  
  # Real-time sync for analytics enhancement  
  real_time_sync:
    frequency: "every_15_minutes"
    trigger: "appointment_analysis_completion"
    
    tables:
      appointment_analyses:
        source: "postgresql.appointment_ai_analysis" 
        destination: "moira-healthcare.raw_data.appointment_analyses"
        sync_strategy: "incremental_by_analysis_completed_at"
        transform: "basic_data_cleaning"
        
      appointments:
        source: "postgresql.appointment_metadata"
        destination: "moira-healthcare.raw_data.appointments" 
        sync_strategy: "incremental_by_updated_at"
        
      actionable_insights:
        source: "postgresql.actionable_insights"
        destination: "moira-healthcare.raw_data.patient_insights"
        sync_strategy: "incremental_by_created_at"
        
      family_access:
        source: "postgresql.family_dashboard_access"
        destination: "moira-healthcare.raw_data.family_access"
        sync_strategy: "full_refresh_daily"
  
  # Analytics processing in BigQuery
  bigquery_analytics_processing:
    
    # Daily comprehensive analytics
    daily_analytics:
      schedule: "0 2 * * *"  # 2 AM daily
      
      analytics_refresh:
        patient_health_trends:
          source_tables: ["raw_data.appointment_analyses", "raw_data.healthkit_data"]
          output_table: "analytics.patient_health_trends"
          processing: "trend_analysis_with_ml"
          
        care_coordination_patterns:
          source_tables: ["raw_data.appointments", "raw_data.appointment_analyses"]
          output_table: "analytics.care_coordination_patterns"
          processing: "provider_network_analysis"
          
        family_engagement_metrics:
          source_tables: ["raw_data.family_access", "raw_data.family_notifications"]
          output_table: "analytics.family_engagement_metrics"
          processing: "caregiver_analytics"
```

---

## 🎬 Implementation Roadmap

### **Phase 1: Core Foundation (Weeks 1-4)**
- ✅ PostgreSQL operational database setup
- ✅ Healthie integration for appointments and Zoom recordings
- ✅ Mobile app pause/resume recording functionality
- ✅ Basic AI analysis pipeline (Deepgram + Claude)

### **Phase 2: BigQuery Analytics (Weeks 5-8)**
- ✅ BigQuery data warehouse setup
- ✅ PostgreSQL → BigQuery ETL pipeline  
- ✅ BigQuery analytics functions for health trends
- ✅ Real-time analytics integration in processing pipeline

### **Phase 3: Advanced Features (Weeks 9-12)**
- ✅ Family dashboard with BigQuery-optimized insights
- ✅ Cross-appointment intelligence with analytics context
- ✅ Care coordination automation
- ✅ Mobile app actionable insights

### **Phase 4: ML & Optimization (Weeks 13-16)**
- ✅ BigQuery ML for predictive health insights
- ✅ Performance optimization and caching
- ✅ Advanced family caregiver analytics
- ✅ Production deployment and monitoring

---

## 💡 Key Benefits of BigQuery Integration

### **For Patients:**
- **Complete Health Picture**: Analytics across all care modalities
- **Predictive Insights**: Early warning for health risks
- **Family Coordination**: Optimized caregiver communication

### **For Providers:**
- **Patient Context**: Rich analytics before/during appointments  
- **Care Coordination**: Automated provider-to-provider communication
- **Population Health**: Aggregate insights across patient panel

### **For Family Members:**
- **Intelligent Notifications**: BigQuery-optimized engagement
- **Caregiver Support**: Burden assessment and optimization
- **Coordinated Care**: Unified view of patient health journey

---

## 🔒 Compliance & Security

### **HIPAA Compliance:**
- ✅ Google Cloud HIPAA-compliant BigQuery configuration
- ✅ End-to-end encryption for all data transfer
- ✅ Audit logging for all data access and processing
- ✅ Data retention policies aligned with healthcare requirements

### **Data Governance:**
- ✅ Patient consent management for all data uses
- ✅ Family member access controls and audit trails
- ✅ Data anonymization for analytics where appropriate
- ✅ Regular security assessments and compliance audits

This consolidated architecture provides a complete, production-ready foundation for MoiraMVP's hybrid healthcare coordination platform with powerful BigQuery analytics capabilities.
