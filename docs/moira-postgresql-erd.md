# Moira Healthcare - PostgreSQL Operational Database ERD

## Entity Relationship Diagram - Operational Database

```mermaid
erDiagram
    %% Core User and Patient Management (Phone Onboarding Architecture)
    patient_extended_profiles {
        UUID user_id PK
        VARCHAR healthie_patient_id UK "Links to Healthie EHR"
        BOOLEAN audio_recording_consent "Default false"
        BOOLEAN ai_analysis_consent "Default false"
        BOOLEAN family_sharing_consent "Default false"
        BOOLEAN healthkit_authorized "Default false"
        TEXT[] authorized_data_types "HealthKit data types"
        ENUM onboarding_method "phone|self_service - Default phone"
        VARCHAR onboarding_coordinator "Care coordinator who onboarded patient"
        TEXT phone_intake_notes "Notes from intake call"
        BOOLEAN requires_password_reset "Default true for phone onboarding"
        TIMESTAMP first_login_date "When patient first accessed app"
        TIMESTAMP onboarding_completed_date "When onboarding finished"
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    %% Appointment Management and Recording
    appointment_metadata {
        VARCHAR healthie_appointment_id PK "Links to Healthie"
        BOOLEAN is_internal_appointment "Internal vs external provider"
        ENUM appointment_category "virtual_internal|in_person_internal|external_specialist"
        VARCHAR external_provider_name "When external"
        VARCHAR external_provider_specialty "Cardiology, etc"
        VARCHAR external_facility_name "Hospital/clinic name"
        ENUM recording_method "zoom_automatic|mobile_pause_resume"
        ENUM recording_status "not_started|recording|paused|completed|failed"
        ENUM appointment_status "scheduled|in_progress|completed|cancelled"
        ENUM analysis_status "pending|processing|completed|failed"
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    appointment_recordings {
        UUID recording_id PK
        VARCHAR healthie_appointment_id FK,UK "One-to-one with appointment"
        ENUM recording_status "Current recording state"
        UUID current_segment_id "Active segment"
        INTEGER total_segments "Number of pause/resume segments"
        INTEGER total_pause_duration_seconds "Total pause time"
        VARCHAR merged_audio_file_path "Final merged audio file"
        INTEGER merged_audio_duration_seconds "Total recording length"
        DECIMAL audio_quality_score "0.00-1.00 quality score"
        TIMESTAMP recording_started_at
        TIMESTAMP recording_completed_at
        TIMESTAMP last_segment_ended_at
        TIMESTAMP created_at
    }

    recording_segments {
        UUID segment_id PK
        UUID recording_id FK "Belongs to recording session"
        INTEGER segment_number "Sequence number"
        TIMESTAMP segment_start_time
        TIMESTAMP segment_end_time
        INTEGER segment_duration_seconds
        VARCHAR audio_file_path "Individual segment file"
        BIGINT audio_file_size_bytes
        JSONB audio_quality_metrics "Technical audio metrics"
        ENUM pause_reason "patient_request|privacy_sensitive|interruption|technical"
        INTEGER pause_duration_seconds "Time paused before this segment"
        TEXT resume_notes "Context notes for resume"
        TIMESTAMP created_at
    }

    %% AI Analysis and Insights
    appointment_ai_analysis {
        UUID analysis_id PK
        VARCHAR healthie_appointment_id FK "Links to appointment"
        UUID patient_id FK "Links to user profile"
        TEXT clinical_summary "AI-generated clinical summary"
        JSONB clinical_findings "Structured medical findings"
        JSONB diagnoses "Potential diagnoses identified"
        JSONB medications "Medications discussed/prescribed"
        JSONB vital_signs "Vital signs mentioned"
        JSONB emergency_flags "Emergency/urgent findings"
        ENUM urgency_level "routine|priority|urgent|emergent"
        JSONB care_coordination_needs "Cross-provider coordination"
        JSONB provider_notifications "Alerts for providers"
        JSONB patient_action_items "Patient follow-up tasks"
        JSONB ai_models_used "AI processing metadata"
        DECIMAL overall_confidence_score "0.00-1.00 analysis confidence"
        INTEGER processing_time_seconds "Analysis duration"
        TIMESTAMP analysis_started_at
        TIMESTAMP analysis_completed_at
        TIMESTAMP created_at
    }

    actionable_insights {
        UUID insight_id PK
        UUID patient_user_id FK "Patient this insight is for"
        VARCHAR source_appointment_id FK "Appointment that generated insight"
        ENUM insight_type "medication_reminder|follow_up_needed|health_trend|care_coordination"
        VARCHAR insight_title "Display title"
        TEXT insight_description "Detailed description"
        TEXT[] recommended_actions "Array of action items"
        ENUM priority_level "low|medium|high|urgent"
        DECIMAL urgency_score "0.00-1.00 urgency rating"
        BOOLEAN patient_viewed "Has patient seen this"
        BOOLEAN patient_acknowledged "Patient acknowledged"
        TEXT[] patient_completed_actions "Actions marked complete"
        TIMESTAMP expires_at "When insight becomes irrelevant"
        TIMESTAMP resolved_at "When insight was resolved"
        ENUM resolution_method "patient_action|provider_action|auto_resolved"
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    %% Family Dashboard and Access
    family_dashboard_access {
        UUID access_id PK
        UUID patient_user_id FK "Patient being monitored"
        VARCHAR family_member_email "Family member email"
        VARCHAR family_member_name "Family member name"
        ENUM relationship "spouse|parent|child|sibling|caregiver|guardian"
        ENUM access_level "view_only" "MVP: read-only access"
        ENUM access_status "invited|pending|active|suspended|revoked"
        BOOLEAN can_view_appointments "Permission: see appointments"
        BOOLEAN can_view_ai_summaries "Permission: see AI analysis"
        BOOLEAN can_view_actionable_insights "Permission: see insights"
        BOOLEAN can_receive_urgent_notifications "Permission: urgent alerts"
        VARCHAR invitation_token UK "Unique invitation link"
        TIMESTAMP invitation_sent_at "When invitation sent"
        TIMESTAMP invitation_expires_at "Invitation expiry"
        TIMESTAMP invitation_accepted_at "When accepted"
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    %% Phone Onboarding Management
    phone_intake_sessions {
        UUID intake_id PK
        UUID patient_id FK "Links to patient_extended_profiles"
        VARCHAR coordinator_id "Care coordinator ID"
        TIMESTAMP intake_date "When intake call occurred"
        INTEGER call_duration_minutes "Length of intake call"
        TEXT intake_notes "Detailed notes from call"
        TIMESTAMP follow_up_scheduled "When follow-up call scheduled"
        TIMESTAMP follow_up_completed "When follow-up completed"
        ENUM onboarding_status "scheduled|completed|requires_follow_up|cancelled"
        TIMESTAMP created_at
    }

    %% Relationships
    patient_extended_profiles ||--o{ appointment_ai_analysis : "patient has analyses"
    patient_extended_profiles ||--o{ actionable_insights : "patient receives insights"
    patient_extended_profiles ||--o{ family_dashboard_access : "patient grants family access"
    patient_extended_profiles ||--o{ phone_intake_sessions : "patient has phone intake session"
    
    appointment_metadata ||--o| appointment_recordings : "appointment may have recording"
    appointment_metadata ||--o{ appointment_ai_analysis : "appointment analyzed by AI"
    appointment_metadata ||--o{ actionable_insights : "appointment generates insights"
    
    appointment_recordings ||--o{ recording_segments : "recording has multiple segments"
    
```

## Key Relationships & Data Flow

### **1. Phone Onboarding Flow**
```
phone_intake_sessions (Care coordinator intake call)
    ↓ (creates)
patient_extended_profiles (Patient with consents & preferences)
    ↓ (links to)
Healthie patient account (EHR identity & authentication)
```

### **2. Core Patient Flow**
```
patient_extended_profiles (Patient)
    ↓ (has appointments)
appointment_metadata (Healthie appointments)
    ↓ (may have recording)
appointment_recordings (Audio sessions)
    ↓ (contains segments)
recording_segments (Pause/resume audio)
```

### **3. AI Processing Flow**  
```
appointment_metadata + appointment_recordings
    ↓ (AI analysis)
appointment_ai_analysis (Clinical insights)
    ↓ (generates)
actionable_insights (Patient recommendations)
```

### **4. Family Access Flow**
```
patient_extended_profiles (Patient)
    ↓ (grants access to)
family_dashboard_access (Family member permissions)
    ↓ (can view)
appointment_metadata + appointment_ai_analysis + actionable_insights
```

## Database Design Principles

### **📞 Phone Onboarding Architecture**
- **Premium onboarding**: Care coordinators create accounts via phone intake calls
- **Extended profiles**: Healthie handles auth, our table handles app-specific functionality  
- **Consent management**: Detailed consent discussions documented during phone calls
- **Follow-up tracking**: Automated monitoring of patient adoption and engagement

### **🔗 External System Integration**
- **`healthie_patient_id`**: Links to Healthie EHR as single source of truth
- **`healthie_appointment_id`**: All appointments managed in Healthie first
- **External providers**: Stored locally when appointment provider_id is null in Healthie

### **🎙️ Recording Architecture**
- **Flexible recording**: Supports both Zoom (automatic) and mobile (pause/resume)
- **Segment-based**: External appointments can be paused/resumed with full audit trail
- **Quality tracking**: Audio quality metrics for processing optimization

### **🤖 AI Analysis Structure**
- **JSONB fields**: Flexible storage for structured medical data
- **Confidence scoring**: AI analysis includes confidence levels
- **Emergency detection**: Automated flagging of urgent findings
- **Care coordination**: Cross-provider communication triggers

### **👥 Family Dashboard Security**
- **Permission-based**: Granular control over what family can see
- **View-only MVP**: Family members cannot edit, only view
- **Token-based invites**: Secure invitation system
- **Relationship tracking**: Different permissions by relationship type

## Technical Implementation Notes

### **Performance Optimizations**
- Index on `healthie_patient_id` for fast patient lookups
- Index on `appointment_status` + `analysis_status` for processing queues
- Index on `patient_user_id` + `created_at` for timeline queries
- Index on `urgency_level` + `created_at` for emergency processing

### **Data Integrity**
- Foreign key constraints ensure referential integrity
- Enum types prevent invalid status values  
- NOT NULL constraints on critical fields
- Unique constraints prevent duplicate invitations

### **HIPAA Compliance**
- All PII encrypted at rest and in transit
- Audit trails with created_at/updated_at timestamps
- Granular access controls through family_dashboard_access
- Secure token-based family invitations
