# MoiraMVP Data PRD v2.0
## Comprehensive Healthcare Data Architecture with Healthie Integration

**Document Version**: 2.0  
**Last Updated**: September 2, 2025  
**Owner**: Technical Architecture Team

---

## 1. Executive Summary

### **MVP User Stories**
1. **Authentication & HealthKit**: Healthie auth + Apple HealthKit integration
2. **External Care Management**: Create external appointments with pause/resume audio recording
3. **AI Analysis & Actions**: Comprehensive analysis with actionable patient insights
4. **Family Coordination**: View-only family dashboard with intelligent monitoring
5. **Virtual Practice**: Book and participate in telehealth with Concierge Clinicians
6. **Cross-Appointment Intelligence**: Platform-wide analysis after each new appointment

### **Core Data Architecture Principles**
- **Healthie as Single Source of Truth**: All appointments and clinical data in Healthie EHR
- **Smart Appointment Categorization**: Internal vs external determined by provider_id presence
- **Unified Recording Pipeline**: Single audio file per appointment (pause/resume for external, Zoom for internal)
- **Cross-Appointment Intelligence**: Comprehensive patient analysis triggered by any new appointment completion

---

## 2. Complete Data Schema Architecture

### **2.1 User Authentication & Profile Management**

```sql
-- Application user profiles (extends Healthie patient data)
CREATE TABLE app_user_profiles (
    user_id UUID PRIMARY KEY,
    healthie_patient_id VARCHAR(255) UNIQUE NOT NULL, -- Primary identifier
    
    -- Authentication tracking
    healthie_access_token_hash VARCHAR(255),
    last_login_at TIMESTAMP,
    login_count INTEGER DEFAULT 0,
    
    -- Onboarding and consent
    onboarding_completed_at TIMESTAMP,
    onboarding_version VARCHAR(20),
    
    -- Consent management
    audio_recording_consent BOOLEAN DEFAULT false,
    ai_analysis_consent BOOLEAN DEFAULT false,
    family_sharing_consent BOOLEAN DEFAULT false,
    data_retention_consent BOOLEAN DEFAULT false,
    consent_last_updated TIMESTAMP,
    
    -- App preferences
    notification_preferences JSONB,
    privacy_settings JSONB,
    accessibility_settings JSONB,
    
    -- Account status
    account_status 'active' | 'suspended' | 'deactivated',
    subscription_tier 'basic' | 'premium' | 'family',
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- HealthKit integration tracking
CREATE TABLE healthkit_integration (
    integration_id UUID PRIMARY KEY,
    user_id UUID REFERENCES app_user_profiles(user_id),
    
    -- Authorization status
    healthkit_authorized BOOLEAN DEFAULT false,
    authorized_data_types TEXT[],        -- ['heart_rate', 'blood_pressure', 'steps', etc.]
    authorization_date TIMESTAMP,
    last_successful_sync TIMESTAMP,
    
    -- Sync configuration
    sync_frequency 'realtime' | 'hourly' | 'daily',
    auto_sync_enabled BOOLEAN DEFAULT true,
    sync_failures_count INTEGER DEFAULT 0,
    
    -- Data volume tracking
    total_data_points_synced BIGINT DEFAULT 0,
    last_30_days_data_points INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- HealthKit metrics storage
CREATE TABLE healthkit_metrics (
    metric_id UUID PRIMARY KEY,
    user_id UUID REFERENCES app_user_profiles(user_id),
    
    -- Metric details
    metric_type VARCHAR(50),             -- 'heart_rate', 'blood_pressure_systolic', etc.
    metric_value DECIMAL(10,3),
    metric_unit VARCHAR(20),
    
    -- Timestamp and source
    recorded_at TIMESTAMP,               -- When metric was captured by device
    synced_at TIMESTAMP DEFAULT NOW(),   -- When synced to our system
    source_app VARCHAR(100),
    device_type VARCHAR(100),
    
    -- Data quality
    confidence_level DECIMAL(3,2),       -- HealthKit confidence score
    data_quality_flags TEXT[],           -- Any quality issues detected
    
    -- Clinical relevance (AI-determined)
    clinical_relevance_score DECIMAL(3,2),
    anomaly_score DECIMAL(3,2),          -- Deviation from patient baseline
    
    created_at TIMESTAMP DEFAULT NOW()
);
```

### **2.2 Unified Appointment Schema (Healthie + Extended Metadata)**

```sql
-- Extended metadata for ALL Healthie appointments
CREATE TABLE appointment_metadata (
    healthie_appointment_id VARCHAR(255) PRIMARY KEY,
    
    -- Appointment classification (auto-determined)
    is_internal_appointment BOOLEAN,     -- true if provider_id exists in Healthie
    appointment_category VARCHAR(50),    -- 'virtual_internal', 'in_person_internal', 'external_specialist'
    
    -- External provider information (when is_internal_appointment = false)
    external_provider_name VARCHAR(255),
    external_provider_specialty VARCHAR(100),
    external_facility_name VARCHAR(255),
    external_facility_address TEXT,
    external_facility_phone VARCHAR(20),
    
    -- Recording configuration
    recording_method 'zoom_automatic' | 'mobile_pause_resume',
    recording_enabled BOOLEAN DEFAULT true,
    patient_recording_consent BOOLEAN DEFAULT false,
    
    -- Appointment preparation and context
    preparation_completed BOOLEAN DEFAULT false,
    pre_visit_notes TEXT,
    patient_questions TEXT[],
    current_symptoms TEXT[],
    
    -- Visit logistics
    estimated_duration_minutes INTEGER,
    actual_duration_minutes INTEGER,
    appointment_location TEXT,           -- Address for external, 'Virtual' for internal
    
    -- Status tracking
    appointment_status 'scheduled' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled' | 'no_show',
    recording_status 'not_applicable' | 'not_started' | 'in_progress' | 'completed' | 'failed',
    analysis_status 'pending' | 'processing' | 'completed' | 'failed',
    
    -- Integration tracking
    healthie_last_synced TIMESTAMP,
    data_completeness_score DECIMAL(3,2), -- How complete is the appointment data
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### **2.5 Family Dashboard & Access Management**

```sql
-- Family member access control
CREATE TABLE family_dashboard_access (
    access_id UUID PRIMARY KEY,
    patient_user_id UUID REFERENCES app_user_profiles(user_id), -- Data owner
    
    -- Family member details
    family_member_email VARCHAR(255),
    family_member_name VARCHAR(255),
    relationship 'spouse' | 'parent' | 'child' | 'sibling' | 'caregiver' | 'guardian' | 'other',
    
    -- Access configuration
    access_level 'view_only',           -- MVP: Only view-only access
    access_status 'invited' | 'pending' | 'active' | 'suspended' | 'revoked',
    
    -- Data visibility permissions
    can_view_appointments BOOLEAN DEFAULT true,
    can_view_ai_summaries BOOLEAN DEFAULT true,
    can_view_actionable_insights BOOLEAN DEFAULT true,
    can_view_healthkit_trends BOOLEAN DEFAULT false,
    can_receive_urgent_notifications BOOLEAN DEFAULT true,
    
    -- Invitation management
    invitation_token VARCHAR(255) UNIQUE,
    invitation_sent_at TIMESTAMP,
    invitation_expires_at TIMESTAMP,
    invitation_accepted_at TIMESTAMP,
    
    -- Access tracking
    last_dashboard_access TIMESTAMP,
    total_dashboard_views INTEGER DEFAULT 0,
    access_granted_at TIMESTAMP,
    access_revoked_at TIMESTAMP,
    revocation_reason TEXT,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Family dashboard intelligent insights
CREATE TABLE family_dashboard_insights (
    insight_id UUID PRIMARY KEY,
    patient_user_id UUID REFERENCES app_user_profiles(user_id),
    
    -- Insight generation
    insight_type 'health_trend' | 'appointment_adherence' | 'medication_compliance' | 
                'care_coordination_status' | 'emergency_alert' | 'positive_progress',
    
    -- Family-specific content
    family_title VARCHAR(255),
    family_summary TEXT,
    family_recommended_actions TEXT[],
    urgency_level 'info' | 'attention' | 'important' | 'urgent',
    
    -- Supporting data
    supporting_appointments TEXT[],      -- Which appointments contributed to this insight
    supporting_health_data JSONB,       -- Relevant HealthKit data
    trend_analysis JSONB,               -- Health trends over time
    
    -- Visibility and notifications
    visible_to_family_members UUID[],   -- Specific family member access IDs
    notification_sent BOOLEAN DEFAULT false,
    notification_sent_at TIMESTAMP,
    
    -- Insight lifecycle
    insight_status 'active' | 'resolved' | 'acknowledged' | 'expired',
    resolution_notes TEXT,
    resolved_at TIMESTAMP,
    expires_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### **2.6 Cross-Appointment Analysis Schema**

```sql
-- Comprehensive patient analysis across all appointments
CREATE TABLE cross_appointment_analysis (
    analysis_id UUID PRIMARY KEY,
    patient_user_id UUID REFERENCES app_user_profiles(user_id),
    trigger_appointment_id VARCHAR(255), -- Healthie appointment that triggered analysis
    
    -- Analysis scope and parameters
    analysis_time_window_days INTEGER,  -- How many days back analyzed
    appointments_analyzed INTEGER,
    internal_appointments_count INTEGER,
    external_appointments_count INTEGER,
    
    -- Health journey insights
    health_trajectory_analysis JSONB,   -- Overall health trends
    medication_timeline_analysis JSONB, -- Medication changes across appointments
    care_coordination_effectiveness JSONB, -- How well care is coordinated
    
    -- Cross-provider insights
    provider_consistency_analysis JSONB, -- Alignment between providers
    treatment_plan_coherence JSONB,     -- Whether treatments work together
    communication_gaps JSONB,           -- Information not shared between providers
    
    -- Predictive insights
    health_risk_assessment JSONB,       -- Risk factors identified across appointments
    care_gap_identification JSONB,      -- Missing care or follow-ups
    preventive_opportunities JSONB,     -- Prevention opportunities across care types
    
    -- Patient journey analysis
    patient_engagement_score DECIMAL(3,2), -- How engaged patient is with care
    care_burden_assessment JSONB,       -- Complexity of patient's care requirements
    quality_of_life_indicators JSONB,   -- Indicators from appointment conversations
    
    -- BitQuery-enhanced insights
    bitquery_trend_analysis JSONB,      -- BitQuery-powered trend insights
    bitquery_network_analysis JSONB,    -- Provider network effectiveness from BitQuery
    bitquery_family_insights JSONB,     -- Family-relevant insights from BitQuery
    
    -- Actionable recommendations
    recommended_care_coordination JSONB,
    suggested_provider_communications JSONB,
    patient_education_opportunities JSONB,
    family_involvement_recommendations JSONB,
    
    -- Analysis metadata
    ai_models_used JSONB,               -- Which AI models/versions used
    bitquery_functions_used TEXT[],     -- Which BitQuery functions contributed
    analysis_confidence_score DECIMAL(3,2),
    processing_time_seconds INTEGER,
    data_sources_analyzed JSONB,        -- Which data contributed to analysis
    
    -- Lifecycle tracking
    analysis_triggered_at TIMESTAMP,
    analysis_completed_at TIMESTAMP,
    next_analysis_recommended_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 3. Data Processing Pipelines with BitQuery Integration

### **3.1 Unified Recording Processing Pipeline**

```yaml
# Complete pipeline with BitQuery as processing component
unified_recording_pipeline_v2:
  
  # Stage 1: Recording Acquisition
  recording_acquisition:
    internal_virtual:
      source: "healthie_zoom_integration"
      method: "polling_zoom_cloud_recordings"
      frequency: "every_5_minutes"
      files: ["M4A", "TRANSCRIPT", "MP4"]
      
    external_mobile:
      source: "mobile_app_pause_resume_recording"
      method: "recording_completion_webhook"
      processing: "segment_merging_into_single_file"
      format: "M4A"
  
  # Stage 2: Audio Processing
  audio_processing:
    both:
      enhancement: "noise_reduction_and_normalization"
      quality_assessment: "technical_quality_scoring"
      
    external_specific:
      segment_merge_validation: "verify_seamless_transitions"
      mobile_optimization: "compensate_for_device_limitations"
      
  # Stage 3: Transcription
  transcription:
    internal:
      primary: "zoom_auto_transcript"
      fallback: "deepgram_medical_model"
      
    external:
      service: "deepgram_medical_conversation_model"
      features: ["speaker_diarization", "medical_terminology", "confidence_scoring"]
      
  # Stage 4: Individual AI Analysis
  ai_analysis:
    both:
      service: "claude_3_5_sonnet"
      system_prompt: "medical_analysis_specialist"
      input: ["audio", "transcript", "appointment_context", "patient_healthie_history"]
      output: "clinical_analysis_with_structured_data"
      
  # Stage 5: BigQuery Real-Time Analytics (NEW INTEGRATION)
  bigquery_real_time_processing:
    trigger: "ai_analysis_completion"
    processing_type: "parallel_analytics_execution"
    
    bigquery_functions:
      health_trends:
        function: "bigquery_analyze_health_trends(patient_id)"
        output: "trend_direction, confidence, family_alert_level"
        performance_target: "<10_seconds"
        
      care_coordination:
        function: "bigquery_care_coordination_analysis(patient_id)"
        output: "coordination_effectiveness, active_needs, gaps"
        performance_target: "<15_seconds"
        
      medication_safety:
        view: "bigquery_medication_safety"
        filter: "patient_id = $patient_id"
        output: "interaction_warnings, safety_alerts"
        performance_target: "<5_seconds"
        
      family_intelligence:
        function: "bigquery_family_dashboard_metrics(patient_id)"
        output: "family_insights, notification_priorities, engagement_scores"
        performance_target: "<10_seconds"
        
    total_bigquery_processing_target: "<30_seconds"
    
  # Stage 6: Enhanced Cross-Appointment Analysis
  enhanced_cross_analysis:
    input: [
      "individual_ai_analysis",
      "bitquery_health_trends", 
      "bitquery_care_patterns",
      "bitquery_provider_network"
    ]
    
    processing: "ai_analysis_with_bitquery_context"
    
    ai_enhancement:
      trend_aware_recommendations: "use_bitquery_trends_for_personalized_advice"
      network_informed_coordination: "leverage_provider_effectiveness_data"
      pattern_based_risk_assessment: "apply_care_pattern_insights"
      
    output: "comprehensive_patient_insights_with_bitquery_intelligence"
    
  # Stage 7: Family Dashboard Updates
  family_dashboard_integration:
    input: [
      "enhanced_cross_analysis",
      "bitquery_family_insights",
      "bitquery_notification_priorities"
    ]
    
    processing: "family_dashboard_intelligence_generation"
    
    family_specific_processing:
      insight_personalization: "customize_insights_by_family_relationship"
      notification_optimization: "use_bitquery_engagement_patterns"
      urgency_assessment: "bitquery_powered_priority_scoring"
      
  # Stage 8: Healthie EHR Integration
  healthie_integration:
    both:
      appointment_update: "clinical_summary_and_structured_data"
      metadata_storage: "full_analysis_including_bitquery_insights"
      provider_notifications: "urgent_findings_and_coordination_needs"
```

### **3.2 BitQuery Processing Functions (Integrated into Pipeline)**

```sql
-- BitQuery functions that execute during processing pipeline

-- Real-time health trend analysis (called during Stage 5)
CREATE OR REPLACE FUNCTION bitquery_analyze_health_trends(input_patient_id VARCHAR(255))
RETURNS TABLE(
    trend_direction VARCHAR(20),
    trend_confidence DECIMAL(3,2),
    severity_trajectory JSONB,
    family_alert_level VARCHAR(20),
    key_health_indicators JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH patient_timeline AS (
        SELECT 
            aaa.analysis_completed_at,
            (aaa.clinical_summary)::text as summary,
            (aaa.emergency_flags)::jsonb as emergency_flags,
            (aaa.overall_confidence_score)::decimal as confidence,
            
            -- Calculate severity score from AI analysis
            CASE 
                WHEN aaa.emergency_flags::text LIKE '%urgent%' THEN 0.9
                WHEN aaa.emergency_flags::text LIKE '%high%' THEN 0.7
                WHEN aaa.emergency_flags::text LIKE '%medium%' THEN 0.5
                ELSE 0.3
            END as severity_score,
            
            -- Previous appointment comparison
            LAG(CASE 
                WHEN aaa.emergency_flags::text LIKE '%urgent%' THEN 0.9
                WHEN aaa.emergency_flags::text LIKE '%high%' THEN 0.7
                WHEN aaa.emergency_flags::text LIKE '%medium%' THEN 0.5
                ELSE 0.3
            END) OVER (ORDER BY aaa.analysis_completed_at) as prev_severity
            
        FROM appointment_ai_analysis aaa
        JOIN appointment_metadata am ON aaa.healthie_appointment_id = am.healthie_appointment_id
        JOIN app_user_profiles up ON am.patient_user_id = up.user_id
        WHERE up.healthie_patient_id = input_patient_id
        AND aaa.analysis_completed_at >= NOW() - INTERVAL '6 months'
        ORDER BY aaa.analysis_completed_at DESC
        LIMIT 20
    ),
    trend_analysis AS (
        SELECT 
            CASE 
                WHEN AVG(severity_score - COALESCE(prev_severity, severity_score)) > 0.1 THEN 'declining'
                WHEN AVG(severity_score - COALESCE(prev_severity, severity_score)) < -0.1 THEN 'improving'
                ELSE 'stable'
            END as calc_trend_direction,
            
            ABS(AVG(severity_score - COALESCE(prev_severity, severity_score))) as calc_confidence,
            
            jsonb_build_object(
                'current_severity', AVG(severity_score),
                'severity_variance', VAR_POP(severity_score),
                'emergency_frequency', COUNT(CASE WHEN severity_score > 0.8 THEN 1 END)::decimal / COUNT(*),
                'appointment_frequency_days', EXTRACT(EPOCH FROM (MAX(analysis_completed_at) - MIN(analysis_completed_at)))/86400 / COUNT(*)
            ) as trajectory_data,
            
            CASE 
                WHEN AVG(severity_score) > 0.8 THEN 'urgent'
                WHEN AVG(severity_score - COALESCE(prev_severity, severity_score)) > 0.2 THEN 'attention'
                WHEN COUNT(CASE WHEN severity_score > 0.8 THEN 1 END) > 0 THEN 'important'
                ELSE 'normal'
            END as calc_family_alert_level,
            
            jsonb_build_object(
                'total_appointments', COUNT(*),
                'avg_confidence', AVG(confidence),
                'trend_stability', 1.0 - VAR_POP(severity_score),
                'emergency_episodes', COUNT(CASE WHEN severity_score > 0.8 THEN 1 END)
            ) as indicators
            
        FROM patient_timeline
        WHERE prev_severity IS NOT NULL OR COUNT(*) = 1
    )
    SELECT 
        calc_trend_direction,
        calc_confidence,
        trajectory_data,
        calc_family_alert_level,
        indicators
    FROM trend_analysis;
END;
$$ LANGUAGE plpgsql;

-- BitQuery care coordination effectiveness (called during Stage 5)
CREATE OR REPLACE FUNCTION bitquery_care_coordination_effectiveness(input_patient_id VARCHAR(255))
RETURNS TABLE(
    coordination_score DECIMAL(3,2),
    active_coordination_items INTEGER,
    provider_network_effectiveness JSONB,
    recommended_actions JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH coordination_analysis AS (
        SELECT 
            -- Coordination effectiveness metrics
            COUNT(ai.insight_id) as total_coordination_insights,
            COUNT(CASE WHEN ai.status = 'completed' THEN 1 END) as resolved_insights,
            COUNT(CASE WHEN ai.status IN ('new', 'in_progress') THEN 1 END) as active_insights,
            
            -- Provider network analysis
            COUNT(DISTINCT am.external_provider_name) FILTER (WHERE NOT am.is_internal_appointment) as external_providers,
            COUNT(DISTINCT am.healthie_appointment_id) FILTER (WHERE am.is_internal_appointment) as internal_appointments,
            
            -- Time-based coordination metrics
            AVG(EXTRACT(EPOCH FROM ai.completed_at - ai.created_at)/3600) FILTER (WHERE ai.completed_at IS NOT NULL) as avg_resolution_hours,
            
            -- Network effectiveness indicators
            COUNT(CASE WHEN ai.insight_category = 'care_coordination' AND ai.action_urgency = 'urgent' THEN 1 END) as urgent_coordination_needs
            
        FROM actionable_insights ai
        JOIN appointment_metadata am ON ai.healthie_appointment_id = am.healthie_appointment_id
        WHERE ai.user_id = (SELECT user_id FROM app_user_profiles WHERE healthie_patient_id = input_patient_id)
        AND ai.created_at >= NOW() - INTERVAL '6 months'
    )
    SELECT 
        CASE WHEN total_coordination_insights = 0 THEN 1.0
             ELSE resolved_insights::decimal / total_coordination_insights 
        END as coordination_score,
        
        active_insights as active_coordination_items,
        
        jsonb_build_object(
            'external_provider_count', external_providers,
            'internal_appointment_ratio', 
                CASE WHEN (external_providers + internal_appointments) = 0 THEN 0
                     ELSE internal_appointments::decimal / (external_providers + internal_appointments)
                END,
            'avg_resolution_time_hours', avg_resolution_hours,
            'urgent_items_ratio', 
                CASE WHEN total_coordination_insights = 0 THEN 0
                     ELSE urgent_coordination_needs::decimal / total_coordination_insights
                END
        ) as provider_network_effectiveness,
        
        jsonb_build_object(
            'increase_internal_appointments', internal_appointments < external_providers,
            'prioritize_coordination', active_insights > 3,
            'provider_communication_needed', urgent_coordination_needs > 0,
            'family_involvement_recommended', active_insights > 2 AND urgent_coordination_needs > 0
        ) as recommended_actions
        
    FROM coordination_analysis;
END;
$$ LANGUAGE plpgsql;

-- BitQuery family dashboard metrics (called during Stage 5)
CREATE OR REPLACE FUNCTION bitquery_family_dashboard_metrics(input_patient_id VARCHAR(255))
RETURNS TABLE(
    family_engagement_score DECIMAL(3,2),
    notification_optimization JSONB,
    caregiver_burden_assessment JSONB,
    family_actionable_priorities JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH family_activity AS (
        SELECT 
            fda.access_id,
            fda.relationship,
            fda.last_dashboard_access,
            fda.total_dashboard_views,
            
            -- Family notification engagement
            COUNT(fn.notification_id) as notifications_received,
            COUNT(CASE WHEN fn.delivery_status IN ('read', 'acknowledged') THEN 1 END) as notifications_engaged,
            
            -- Family response patterns
            COUNT(CASE WHEN fn.urgency_level = 'urgent' AND fn.acknowledged_at IS NOT NULL THEN 1 END) as urgent_responses,
            AVG(EXTRACT(EPOCH FROM fn.acknowledged_at - fn.sent_at)/60) FILTER (WHERE fn.acknowledged_at IS NOT NULL) as avg_response_time_minutes
            
        FROM family_dashboard_access fda
        LEFT JOIN family_notifications fn ON fda.access_id = fn.family_access_id
        WHERE fda.patient_user_id = (SELECT user_id FROM app_user_profiles WHERE healthie_patient_id = input_patient_id)
        AND fda.access_status = 'active'
        GROUP BY fda.access_id, fda.relationship, fda.last_dashboard_access, fda.total_dashboard_views
    ),
    family_insights AS (
        SELECT 
            COUNT(*) as active_family_members,
            AVG(total_dashboard_views) as avg_engagement,
            
            -- Engagement scoring
            AVG(CASE WHEN notifications_received = 0 THEN 0
                     ELSE notifications_engaged::decimal / notifications_received 
                END) as notification_engagement_rate,
                
            -- Response effectiveness
            AVG(CASE WHEN urgent_responses > 0 THEN 1 ELSE 0 END) as urgent_response_rate,
            AVG(avg_response_time_minutes) as avg_family_response_time,
            
            -- Caregiver distribution
            jsonb_object_agg(relationship, COUNT(*)) as relationship_distribution
            
        FROM family_activity
    )
    SELECT 
        LEAST(1.0, 
            (notification_engagement_rate * 0.4) + 
            (urgent_response_rate * 0.4) + 
            (CASE WHEN avg_engagement > 5 THEN 0.2 ELSE avg_engagement * 0.04 END)
        ) as family_engagement_score,
        
        jsonb_build_object(
            'optimal_notification_frequency', 
                CASE WHEN notification_engagement_rate > 0.8 THEN 'immediate'
                     WHEN notification_engagement_rate > 0.5 THEN 'daily_digest'
                     ELSE 'weekly_summary'
                END,
            'preferred_urgency_threshold', 
                CASE WHEN urgent_response_rate > 0.9 THEN 'medium'
                     ELSE 'high'
                END,
            'engagement_trend', 
                CASE WHEN avg_engagement > 10 THEN 'highly_engaged'
                     WHEN avg_engagement > 3 THEN 'moderately_engaged'
                     ELSE 'low_engagement'
                END
        ) as notification_optimization,
        
        jsonb_build_object(
            'caregiver_distribution', relationship_distribution,
            'response_burden_hours_per_week', avg_family_response_time * active_family_members / 60,
            'coordination_load_assessment', 
                CASE WHEN active_family_members > 3 THEN 'high'
                     WHEN active_family_members > 1 THEN 'moderate' 
                     ELSE 'low'
                END
        ) as caregiver_burden_assessment,
        
        jsonb_build_object(
            'high_priority_items', urgent_response_rate * 10, -- Estimated weekly urgent items
            'family_education_opportunities', 
                CASE WHEN notification_engagement_rate < 0.5 THEN true ELSE false END,
            'communication_optimization_needed',
                CASE WHEN avg_family_response_time > 120 THEN true ELSE false END
        ) as family_actionable_priorities
        
    FROM family_insights;
END;
$$ LANGUAGE plpgsql;
```

### **3.3 Cross-Appointment Analysis with BitQuery Enhancement**

```python
# Enhanced cross-appointment analysis leveraging BitQuery processing
class BitQueryEnhancedCrossAnalysis:
    
    async def run_comprehensive_analysis_with_bitquery(self, 
                                                      patient_user_id: str, 
                                                      trigger_appointment_id: str):
        """Run cross-appointment analysis enhanced with BitQuery real-time analytics"""
        
        # Get Healthie patient ID
        healthie_patient_id = await self.get_healthie_patient_id(patient_user_id)
        
        # 1. Run BitQuery analytics in parallel with data gathering
        bitquery_results, patient_data = await asyncio.gather(
            self.run_bitquery_real_time_analytics(healthie_patient_id),
            self.gather_patient_appointment_data(patient_user_id)
        )
        
        # 2. Enhanced AI analysis with BitQuery context
        comprehensive_analysis = await self.medical_ai.analyze_patient_journey_enhanced({
            'patient_id': patient_user_id,
            'appointment_data': patient_data,
            'bitquery_context': {
                'health_trends': bitquery_results.health_trends,
                'care_coordination_effectiveness': bitquery_results.care_coordination,
                'medication_safety_analysis': bitquery_results.medication_safety,
                'family_intelligence': bitquery_results.family_metrics
            },
            'trigger_appointment': trigger_appointment_id
        })
        
        # 3. Generate BitQuery-informed actionable insights
        actionable_insights = await self.generate_bitquery_informed_insights(
            patient_user_id, comprehensive_analysis, bitquery_results
        )
        
        # 4. Update family dashboard with BitQuery family intelligence
        await self.update_family_dashboard_with_bitquery(
            patient_user_id, comprehensive_analysis, bitquery_results.family_metrics
        )
        
        # 5. Store comprehensive analysis with BitQuery metadata
        analysis_record = await self.store_cross_analysis_with_bitquery({
            'patient_user_id': patient_user_id,
            'trigger_appointment_id': trigger_appointment_id,
            'comprehensive_analysis': comprehensive_analysis,
            'bitquery_insights': bitquery_results,
            'actionable_insights_generated': len(actionable_insights)
        })
        
        return analysis_record
        
    async def run_bitquery_real_time_analytics(self, healthie_patient_id: str) -> BitQueryResults:
        """Execute BitQuery functions during processing pipeline"""
        
        # Execute BitQuery functions in parallel for performance
        results = await asyncio.gather(
            self.bitquery.execute_function('bitquery_analyze_health_trends', [healthie_patient_id]),
            self.bitquery.execute_function('bitquery_care_coordination_effectiveness', [healthie_patient_id]),
            self.bitquery.execute_view('bitquery_medication_safety', {'patient_id': healthie_patient_id}),
            self.bitquery.execute_function('bitquery_family_dashboard_metrics', [healthie_patient_id])
        )
        
        return BitQueryResults(
            health_trends=results[0],
            care_coordination=results[1], 
            medication_safety=results[2],
            family_metrics=results[3],
            processing_time=self.calculate_bitquery_processing_time()
        )
```

### **3.4 Family Dashboard Processing with BitQuery**

```python
# Family dashboard updates enhanced with BitQuery analytics
class FamilyDashboardBitQueryProcessor:
    
    async def update_family_dashboard_with_bitquery(self, 
                                                   patient_user_id: str,
                                                   comprehensive_analysis: CrossAppointmentAnalysis,
                                                   bitquery_family_metrics: BitQueryFamilyMetrics):
        """Update family dashboard using BitQuery-enhanced insights"""
        
        # Get active family members
        family_members = await self.get_active_family_members(patient_user_id)
        
        if not family_members:
            return
            
        # Generate BitQuery-enhanced family insights
        family_insights = await self.generate_bitquery_family_insights({
            'patient_id': patient_user_id,
            'comprehensive_analysis': comprehensive_analysis,
            'bitquery_trends': bitquery_family_metrics.family_engagement_score,
            'bitquery_optimization': bitquery_family_metrics.notification_optimization,
            'bitquery_burden': bitquery_family_metrics.caregiver_burden_assessment,
            'family_members': family_members
        })
        
        # Create optimized family notifications using BitQuery insights
        await self.create_optimized_family_notifications({
            'family_insights': family_insights,
            'notification_optimization': bitquery_family_metrics.notification_optimization,
            'urgency_thresholds': bitquery_family_metrics.family_actionable_priorities
        })
        
        # Update family dashboard intelligence with BitQuery-powered recommendations
        await self.update_family_intelligence_with_bitquery({
            'patient_user_id': patient_user_id,
            'family_insights': family_insights,
            'bitquery_recommendations': bitquery_family_metrics.family_actionable_priorities
        })
        
    async def generate_bitquery_family_insights(self, context: FamilyInsightContext) -> List[FamilyInsight]:
        """Generate family insights enhanced with BitQuery analytics"""
        
        insights = []
        
        # Health trend insights (BitQuery-enhanced)
        if context.bitquery_trends.trend_direction in ['improving', 'stable']:
            insights.append(FamilyInsight(
                type='positive_progress',
                title=f"Health Trends Looking {context.bitquery_trends.trend_direction.title()}",
                summary=f"Recent appointments show {context.bitquery_trends.trend_direction} health trajectory",
                urgency=context.bitquery_trends.family_alert_level,
                bitquery_data=context.bitquery_trends.key_health_indicators
            ))
            
        # Care coordination insights (BitQuery-enhanced)
        if context.bitquery_optimization.coordination_score < 0.7:
            insights.append(FamilyInsight(
                type='care_coordination_attention',
                title="Care Coordination Needs Attention",
                summary=f"Care team communication could be improved (Score: {context.bitquery_optimization.coordination_score:.1f}/1.0)",
                urgency='attention',
                bitquery_data=context.bitquery_optimization.provider_network_effectiveness
            ))
            
        # Family engagement optimization (BitQuery-powered)
        if context.bitquery_burden.coordination_load_assessment == 'high':
            insights.append(FamilyInsight(
                type='family_support_optimization',
                title="Family Care Coordination Tips",
                summary="Based on care patterns, here are ways to optimize family involvement",
                urgency='info',
                bitquery_data=context.bitquery_burden.caregiver_distribution
            ))
            
        return insights
```

---

## 4. Healthie Integration Patterns

### **4.1 Unified Appointment Management with BitQuery Context**

```typescript
// Healthie integration enhanced with BitQuery insights
class HealthieBitQueryIntegration {
  
  async createAppointmentWithIntelligence(appointmentData: AppointmentRequest): Promise<EnhancedAppointment> {
    // 1. Create appointment in Healthie (same for internal/external)
    const healthieAppointment = await this.healthie.createAppointment({
      patient_id: appointmentData.healthie_patient_id,
      appointment_type_id: appointmentData.appointment_type_id,
      date: appointmentData.date,
      
      // Provider assignment
      provider_id: appointmentData.is_internal ? appointmentData.provider_id : null,
      
      // Contact type and Zoom setup
      contact_type: appointmentData.is_internal ? appointmentData.contact_type : 'in_person',
      use_zoom: appointmentData.is_internal && appointmentData.contact_type === 'video_chat',
      
      // Notes with external provider info
      notes: appointmentData.is_internal 
        ? appointmentData.notes
        : this.formatExternalProviderNotes(appointmentData.external_provider)
    });
    
    // 2. Add extended metadata
    await this.addAppointmentMetadata(healthieAppointment.id, appointmentData);
    
    // 3. Run BitQuery pre-appointment analysis for context
    const preAppointmentContext = await this.getBitQueryPreAppointmentContext(
      appointmentData.healthie_patient_id
    );
    
    // 4. Initialize recording session based on appointment type
    const recordingSession = appointmentData.is_internal
      ? await this.initializeZoomRecording(healthieAppointment)
      : await this.initializeMobileRecording(healthieAppointment.id);
      
    return {
      healthie_appointment: healthieAppointment,
      recording_session: recordingSession,
      pre_appointment_insights: preAppointmentContext,
      appointment_preparation_recommendations: this.generatePreparationRecommendations(preAppointmentContext)
    };
  }
  
  async updateAppointmentWithBitQueryAnalysis(appointment_id: string, 
                                             ai_analysis: AIAnalysis,
                                             bitquery_insights: BitQueryResults): Promise<void> {
    // Enhanced Healthie update with BitQuery context
    await this.healthie.updateAppointment({
      id: appointment_id,
      
      // Clinical notes enhanced with BitQuery insights
      notes: this.combineNotesWithBitQueryInsights(
        ai_analysis.clinical_summary,
        bitquery_insights
      ),
      
      // Comprehensive metadata including BitQuery results
      metadata: JSON.stringify({
        ai_analysis: ai_analysis,
        bitquery_insights: {
          health_trends: bitquery_insights.health_trends,
          care_coordination: bitquery_insights.care_coordination,
          family_intelligence: bitquery_insights.family_metrics
        },
        processing_timestamp: new Date().toISOString(),
        analysis_confidence: ai_analysis.overall_confidence_score,
        bitquery_processing_time: bitquery_insights.processing_time
      }),
      
      // Follow-up actions informed by BitQuery
      follow_up_actions: this.generateBitQueryInformedFollowUp(
        ai_analysis, bitquery_insights
      )
    });
  }
}
```

### **4.2 Recording Processing with BitQuery Integration**

```typescript
// Unified recording processor with BitQuery analytics
class UnifiedRecordingProcessorWithBitQuery {
  
  async processRecordingWithBitQueryEnhancement(healthie_appointment_id: string): Promise<ProcessingResult> {
    // 1. Determine appointment type and get recording
    const appointment = await this.getAppointmentWithMetadata(healthie_appointment_id);
    
    const recording = appointment.is_internal_appointment
      ? await this.processZoomRecording(appointment)      // Zoom automatic recording
      : await this.processPauseResumeRecording(appointment); // Mobile pause/resume recording
      
    // 2. Initial AI analysis
    const aiAnalysis = await this.runAIAnalysis(recording, appointment);
    
    // 3. BitQuery real-time analytics (integrated into pipeline)
    const bitqueryInsights = await this.runBitQueryRealTimeAnalytics(
      appointment.patient_user_id
    );
    
    // 4. Enhanced cross-appointment analysis with BitQuery context
    const comprehensiveAnalysis = await this.runBitQueryEnhancedCrossAnalysis({
      appointment_id: healthie_appointment_id,
      ai_analysis: aiAnalysis,
      bitquery_insights: bitqueryInsights
    });
    
    // 5. Update Healthie with BitQuery-enhanced analysis
    await this.updateHealthieWithBitQueryAnalysis(
      healthie_appointment_id, aiAnalysis, bitqueryInsights
    );
    
    // 6. Generate BitQuery-informed actionable insights
    await this.generateBitQueryActionableInsights(
      appointment.patient_user_id, comprehensiveAnalysis, bitqueryInsights
    );
    
    // 7. Update family dashboard with BitQuery intelligence
    await this.updateFamilyDashboardWithBitQuery(
      appointment.patient_user_id, comprehensiveAnalysis, bitqueryInsights
    );
    
    return {
      appointment_id: healthie_appointment_id,
      ai_analysis_completed: true,
      bitquery_analytics_completed: true,
      cross_analysis_completed: true,
      family_dashboard_updated: true,
      total_processing_time: this.calculateTotalProcessingTime()
    };
  }
  
  private async processPauseResumeRecording(appointment: AppointmentWithMetadata): Promise<ProcessedRecording> {
    // Get mobile recording with pause/resume segments
    const mobileRecording = await this.getMobileRecordingSession(appointment.healthie_appointment_id);
    
    // Verify recording is completed and merged
    if (mobileRecording.recording_status !== 'completed') {
      throw new Error('Recording not completed - cannot process');
    }
    
    // Get final merged audio file
    const finalAudioFile = await this.downloadAudioFile(mobileRecording.final_audio_file_url);
    
    // Enhanced audio processing for mobile recordings
    const enhancedAudio = await this.audioProcessor.enhance({
      audioFile: finalAudioFile,
      processingType: 'mobile_medical_conversation',
      noiseReduction: 'aggressive',
      speechEnhancement: true,
      volumeNormalization: true,
      pauseGapRemoval: true  // Remove pause periods from pause/resume
    });
    
    // Generate medical transcript
    const transcript = await this.transcriptionService.transcribe({
      audioFile: enhancedAudio,
      model: 'medical_conversation',
      speakerDiarization: true,
      medicalTerminology: true,
      confidenceScoring: true
    });
    
    return {
      source: 'mobile_pause_resume',
      audio_file: enhancedAudio,
      transcript: transcript,
      quality_metrics: {
        overall_quality: mobileRecording.overall_audio_quality_score,
        pause_count: mobileRecording.pause_events_count,
        net_duration: mobileRecording.net_recording_duration_seconds,
        background_noise: mobileRecording.background_noise_score
      },
      processing_notes: `Mobile recording with ${mobileRecording.pause_events_count} pause events, merged seamlessly`
    };
  }
}
```

---

## 5. Cross-Appointment Analysis Architecture

### **5.1 Unified Analysis Trigger System**

```sql
-- Automated triggers for cross-appointment analysis
CREATE OR REPLACE FUNCTION trigger_cross_appointment_analysis()
RETURNS TRIGGER AS $$
BEGIN
    -- Queue comprehensive analysis when any appointment analysis completes
    INSERT INTO cross_analysis_queue (
        patient_user_id,
        trigger_appointment_id,
        analysis_type,
        priority,
        scheduled_processing_time
    ) VALUES (
        (SELECT am.patient_user_id 
         FROM appointment_metadata am 
         WHERE am.healthie_appointment_id = NEW.healthie_appointment_id),
        NEW.healthie_appointment_id,
        'triggered_by_new_appointment',
        CASE 
            WHEN NEW.emergency_flags::text LIKE '%urgent%' THEN 'urgent'
            WHEN NEW.emergency_flags::text LIKE '%high%' THEN 'high'
            ELSE 'medium'
        END,
        NOW() + INTERVAL '5 minutes'  -- Slight delay for data consistency
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on completion of any appointment AI analysis
CREATE TRIGGER cross_analysis_trigger
    AFTER INSERT ON appointment_ai_analysis
    FOR EACH ROW EXECUTE FUNCTION trigger_cross_appointment_analysis();

-- Queue management for cross-appointment analysis
CREATE TABLE cross_analysis_queue (
    queue_id UUID PRIMARY KEY,
    patient_user_id UUID REFERENCES app_user_profiles(user_id),
    trigger_appointment_id VARCHAR(255),
    
    -- Queue management
    queue_status 'pending' | 'processing' | 'completed' | 'failed',
    priority 'low' | 'medium' | 'high' | 'urgent',
    
    -- Processing configuration
    analysis_type 'routine' | 'triggered_by_new_appointment' | 'emergency_triggered' | 'scheduled_comprehensive',
    scheduled_processing_time TIMESTAMP,
    
    -- Processing tracking
    processing_started_at TIMESTAMP,
    processing_completed_at TIMESTAMP,
    processing_duration_seconds INTEGER,
    
    -- Error handling
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    last_error_message TEXT,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### **5.2 Comprehensive Analysis Engine**

```python
# Main cross-appointment analysis engine
class CrossAppointmentAnalysisEngine:
    
    def __init__(self):
        self.healthie_client = HealthieClient()
        self.medical_ai = MedicalAIService()
        self.family_dashboard = FamilyDashboardService()
        
    async def process_queued_analysis(self, queue_item: CrossAnalysisQueueItem):
        """Process a queued cross-appointment analysis"""
        
        try:
            # Mark as processing
            await self.update_queue_status(queue_item.queue_id, 'processing')
            
            # 1. Gather complete patient data context
            patient_context = await self.gather_complete_patient_context(
                queue_item.patient_user_id
            )
            
            # 2. Run comprehensive AI analysis across all appointments
            comprehensive_analysis = await self.run_unified_analysis({
                'patient_context': patient_context,
                'trigger_appointment_id': queue_item.trigger_appointment_id
            })
            
            # 3. Generate actionable insights
            actionable_insights = await self.generate_comprehensive_actionable_insights(
                queue_item.patient_user_id,
                comprehensive_analysis
            )
            
            # 4. Update family dashboard
            await self.family_dashboard.update_with_comprehensive_analysis(
                queue_item.patient_user_id,
                comprehensive_analysis
            )
            
            # 5. Store comprehensive analysis results
            analysis_record = await self.store_comprehensive_analysis({
                'queue_item': queue_item,
                'comprehensive_analysis': comprehensive_analysis,
                'actionable_insights': actionable_insights
            })
            
            # 6. Send notifications for urgent findings
            if self.has_urgent_findings(comprehensive_analysis):
                await self.send_urgent_notifications(
                    queue_item.patient_user_id,
                    comprehensive_analysis
                )
                
            # Mark as completed
            await self.update_queue_status(queue_item.queue_id, 'completed')
            
            return analysis_record
            
        except Exception as e:
            await self.handle_analysis_error(queue_item.queue_id, str(e))
            raise
            
    async def gather_complete_patient_context(self, patient_user_id: str) -> PatientContext:
        """Gather all available patient data for comprehensive analysis"""
        
        # Get user profile and Healthie patient ID
        user_profile = await self.get_user_profile(patient_user_id)
        healthie_patient_id = user_profile.healthie_patient_id
        
        # Gather all data in parallel for performance
        [healthie_appointments, appointment_analyses, healthkit_data] = await asyncio.gather(
            # All Healthie appointments (12 months)
            self.healthie_client.get_patient_appointments(
                patient_id=healthie_patient_id,
                time_range='last_12_months',
                include_completed=True
            ),
            
            # All AI analyses for patient's appointments
            self.get_all_appointment_analyses(patient_user_id),
            
            # HealthKit trends and patterns
            self.get_healthkit_trends(
                user_id=patient_user_id,
                time_range='last_6_months'
            )
        )
        
        return PatientContext(
            user_profile=user_profile,
            healthie_patient_id=healthie_patient_id,
            healthie_appointments=healthie_appointments,
            appointment_analyses=appointment_analyses,
            healthkit_data=healthkit_data,
            data_completeness_score=self.calculate_data_completeness(healthie_appointments, appointment_analyses)
        )
        
    async def run_unified_analysis(self, context: AnalysisContext) -> ComprehensiveAnalysis:
        """Run comprehensive analysis across ALL appointments (internal + external)"""
        
        # Categorize appointments
        internal_appointments = [apt for apt in context.patient_context.healthie_appointments 
                               if self.is_internal_appointment(apt)]
        external_appointments = [apt for apt in context.patient_context.healthie_appointments 
                               if not self.is_internal_appointment(apt)]
        
        # AI analysis across all appointments
        analysis_result = await self.medical_ai.analyze_unified_patient_journey({
            'patient_id': context.patient_context.user_profile.user_id,
            'internal_appointments': internal_appointments,
            'external_appointments': external_appointments,
            'all_appointment_analyses': context.patient_context.appointment_analyses,
            'healthkit_data': context.patient_context.healthkit_data,
            'trigger_appointment_context': context.trigger_appointment_id,
            
            'analysis_objectives': [
                'identify_overall_health_trajectory',
                'assess_care_coordination_across_all_providers',
                'detect_medication_interactions_and_changes',
                'evaluate_treatment_plan_coherence',
                'identify_care_gaps_and_opportunities',
                'generate_family_actionable_insights',
                'recommend_care_optimization_strategies'
            ]
        })
        
        return ComprehensiveAnalysis(
            health_trajectory=analysis_result.health_trajectory,
            care_coordination_assessment=analysis_result.care_coordination,
            medication_timeline=analysis_result.medication_analysis,
            treatment_coherence=analysis_result.treatment_alignment,
            care_gaps=analysis_result.identified_gaps,
            family_insights=analysis_result.family_recommendations,
            optimization_recommendations=analysis_result.care_optimization,
            confidence_score=analysis_result.overall_confidence,
            processing_metadata=analysis_result.processing_stats
        )
    
    def is_internal_appointment(self, appointment) -> bool:
        """Determine if appointment is with your practice"""
        return appointment.provider_id is not None and \
               appointment.provider_id in self.internal_provider_ids
```

---

## 6. Family Dashboard Data Requirements

### **6.1 Family Dashboard Comprehensive Views**

```sql
-- Primary family dashboard view with unified appointment intelligence
CREATE OR REPLACE VIEW family_dashboard_unified AS
SELECT 
    fda.access_id,
    fda.patient_user_id,
    fda.family_member_name,
    fda.relationship,
    
    -- Patient overview
    up.healthie_patient_id,
    up.account_status,
    
    -- Current health status (from latest cross-appointment analysis)
    caa.health_trajectory_analysis->>'current_status' as current_health_status,
    caa.health_trajectory_analysis->>'trend_direction' as health_trend,
    caa.care_coordination_assessment->>'overall_score' as care_coordination_score,
    
    -- Unified appointment activity (last 30 days)
    appointment_activity.total_appointments,
    appointment_activity.internal_appointments,
    appointment_activity.external_appointments,
    appointment_activity.missed_appointments,
    appointment_activity.last_appointment_date,
    appointment_activity.next_appointment_date,
    
    -- Active family-visible insights
    family_insights.total_family_insights,
    family_insights.urgent_family_insights,
    family_insights.action_required_insights,
    family_insights.most_recent_insight,
    
    -- HealthKit integration status and trends
    healthkit_status.integration_active,
    healthkit_status.key_metrics_tracked,
    healthkit_status.recent_anomalies,
    healthkit_status.last_sync_time,
    
    -- Care coordination status across all appointments
    coordination_status.active_coordination_items,
    coordination_status.cross_provider_coordination_score,
    coordination_status.last_coordination_update,
    
    -- Family engagement and burden assessment
    engagement_metrics.notification_engagement_rate,
    engagement_metrics.dashboard_usage_frequency,
    engagement_metrics.urgent_response_effectiveness,
    
    -- Dashboard metadata
    fda.last_dashboard_access,
    fda.total_dashboard_views,
    CASE WHEN fda.last_dashboard_access > NOW() - INTERVAL '7 days' THEN 'active'
         WHEN fda.last_dashboard_access > NOW() - INTERVAL '30 days' THEN 'periodic'
         ELSE 'inactive'
    END as family_engagement_level
    
FROM family_dashboard_access fda
JOIN app_user_profiles up ON fda.patient_user_id = up.user_id

-- Latest cross-appointment analysis
LEFT JOIN (
    SELECT DISTINCT ON (patient_user_id) 
        patient_user_id,
        health_trajectory_analysis,
        care_coordination_assessment,
        analysis_completed_at
    FROM cross_appointment_analysis
    ORDER BY patient_user_id, analysis_completed_at DESC
) caa ON fda.patient_user_id = caa.patient_user_id

-- Unified appointment activity (internal + external)
LEFT JOIN (
    SELECT 
        am.patient_user_id,
        COUNT(*) as total_appointments,
        COUNT(CASE WHEN am.is_internal_appointment THEN 1 END) as internal_appointments,
        COUNT(CASE WHEN NOT am.is_internal_appointment THEN 1 END) as external_appointments,
        COUNT(CASE WHEN am.appointment_status IN ('cancelled', 'no_show') THEN 1 END) as missed_appointments,
        MAX(am.created_at) as last_appointment_date,
        MIN(am.created_at) FILTER (WHERE am.created_at > NOW()) as next_appointment_date
    FROM appointment_metadata am
    WHERE am.created_at >= NOW() - INTERVAL '30 days' OR am.created_at > NOW()
    GROUP BY am.patient_user_id
) appointment_activity ON fda.patient_user_id = appointment_activity.patient_user_id

-- Family-visible actionable insights
LEFT JOIN (
    SELECT 
        ai.user_id,
        COUNT(*) as total_family_insights,
        COUNT(CASE WHEN ai.family_notification_level = 'urgent' THEN 1 END) as urgent_family_insights,
        COUNT(CASE WHEN ai.family_action_required THEN 1 END) as action_required_insights,
        MAX(ai.created_at) as most_recent_insight
    FROM actionable_insights ai
    WHERE ai.family_dashboard_visible = true
    AND ai.status NOT IN ('completed', 'dismissed')
    GROUP BY ai.user_id
) family_insights ON fda.patient_user_id = family_insights.user_id

-- HealthKit integration and trends
LEFT JOIN (
    SELECT 
        hi.user_id,
        hi.healthkit_authorized as integration_active,
        hi.authorized_data_types as key_metrics_tracked,
        hi.last_successful_sync as last_sync_time,
        COUNT(CASE WHEN hm.anomaly_score > 0.8 THEN 1 END) as recent_anomalies
    FROM healthkit_integration hi
    LEFT JOIN healthkit_metrics hm ON hi.user_id = hm.user_id 
        AND hm.recorded_at >= NOW() - INTERVAL '7 days'
    GROUP BY hi.user_id, hi.healthkit_authorized, hi.authorized_data_types, hi.last_successful_sync
) healthkit_status ON fda.patient_user_id = healthkit_status.user_id

-- Care coordination across all appointment types
LEFT JOIN (
    SELECT 
        ai.user_id,
        COUNT(CASE WHEN ai.insight_category = 'care_coordination' AND ai.status IN ('new', 'in_progress') THEN 1 END) as active_coordination_items,
        AVG(CASE WHEN ai.insight_category = 'care_coordination' THEN 
               CASE ai.status WHEN 'completed' THEN 1.0 ELSE 0.5 END 
            END) as cross_provider_coordination_score,
        MAX(ai.created_at) FILTER (WHERE ai.insight_category = 'care_coordination') as last_coordination_update
    FROM actionable_insights ai
    WHERE ai.created_at >= NOW() - INTERVAL '90 days'
    GROUP BY ai.user_id
) coordination_status ON fda.patient_user_id = coordination_status.user_id

-- Family engagement metrics
LEFT JOIN (
    SELECT 
        fn.patient_user_id,
        COUNT(CASE WHEN fn.delivery_status IN ('read', 'acknowledged') THEN 1 END)::decimal / 
            NULLIF(COUNT(*), 0) as notification_engagement_rate,
        CASE WHEN COUNT(*) > 0 THEN 'regular' ELSE 'none' END as dashboard_usage_frequency,
        COUNT(CASE WHEN fn.urgency_level = 'urgent' AND fn.acknowledged_at IS NOT NULL THEN 1 END)::decimal / 
            NULLIF(COUNT(CASE WHEN fn.urgency_level = 'urgent' THEN 1 END), 0) as urgent_response_effectiveness
    FROM family_notifications fn
    WHERE fn.created_at >= NOW() - INTERVAL '30 days'
    GROUP BY fn.patient_user_id
) engagement_metrics ON fda.patient_user_id = engagement_metrics.patient_user_id

WHERE fda.access_status = 'active';
```

### **6.2 Family Dashboard Intelligence Processing**

```python
# Unified family dashboard processing for all appointment types
class UnifiedFamilyDashboardProcessor:
    
    async def update_family_dashboard_with_unified_analysis(self, 
                                                          patient_user_id: str,
                                                          comprehensive_analysis: CrossAppointmentAnalysis):
        """Update family dashboard with insights from all appointment types"""
        
        # Get active family members
        family_members = await self.get_active_family_members(patient_user_id)
        
        if not family_members:
            return
            
        # Generate unified family insights (internal + external appointments)
        family_insights = await self.generate_unified_family_insights({
            'patient_id': patient_user_id,
            'comprehensive_analysis': comprehensive_analysis,
            'family_members': family_members
        })
        
        # Create family notifications based on unified analysis
        await self.create_family_notifications_from_unified_insights(
            family_members, family_insights
        )
        
        # Update family dashboard intelligence
        await self.update_family_intelligence({
            'patient_user_id': patient_user_id,
            'family_insights': family_insights,
            'comprehensive_analysis': comprehensive_analysis
        })
        
    async def generate_unified_family_insights(self, context: UnifiedFamilyContext) -> List[FamilyInsight]:
        """Generate family insights from analysis of ALL appointment types"""
        
        insights = []
        analysis = context.comprehensive_analysis
        
        # Unified health trend insights (across internal + external care)
        if analysis.health_trajectory.trend_direction in ['improving', 'stable']:
            insights.append(FamilyInsight(
                type='unified_health_progress',
                title=f"Overall Health Trends: {analysis.health_trajectory.trend_direction.title()}",
                summary=f"Analysis across all doctors shows {analysis.health_trajectory.trend_direction} health trajectory",
                urgency='info',
                supporting_data={
                    'internal_appointments_contributing': analysis.internal_appointment_count,
                    'external_appointments_contributing': analysis.external_appointment_count,
                    'key_health_indicators': analysis.health_trajectory.key_indicators
                }
            ))
            
        # Cross-provider care coordination insights
        if analysis.care_coordination_assessment.coordination_opportunities:
            insights.append(FamilyInsight(
                type='cross_provider_coordination',
                title="Care Team Coordination Update",
                summary=f"Your practice is coordinating with {analysis.care_coordination_assessment.external_providers_count} specialists",
                urgency='attention',
                supporting_data={
                    'coordination_score': analysis.care_coordination_assessment.effectiveness_score,
                    'active_coordination_items': analysis.care_coordination_assessment.active_items,
                    'provider_network': analysis.care_coordination_assessment.provider_summary
                }
            ))
            
        # Medication management across all providers
        if analysis.medication_timeline.cross_provider_changes:
            insights.append(FamilyInsight(
                type='unified_medication_management',
                title="Medication Updates Across All Doctors",
                summary=f"Recent medication changes from {analysis.medication_timeline.prescribing_providers_count} providers",
                urgency='important',
                supporting_data={
                    'medication_changes': analysis.medication_timeline.recent_changes,
                    'interaction_warnings': analysis.medication_timeline.interaction_alerts,
                    'prescribing_providers': analysis.medication_timeline.provider_list
                }
            ))
            
        # Emergency or urgent findings (from any appointment type)
        if analysis.emergency_assessment.urgent_findings:
            insights.append(FamilyInsight(
                type='urgent_health_update',
                title="Important Health Update Requires Attention",
                summary="Recent appointment identified something that needs immediate follow-up",
                urgency='urgent',
                supporting_data={
                    'finding_source': analysis.emergency_assessment.source_appointment_type,
                    'urgency_level': analysis.emergency_assessment.urgency_score,
                    'recommended_actions': analysis.emergency_assessment.immediate_actions
                }
            ))
            
        return insights
```

---

## 7. Implementation Roadmap

### **7.1 Phase 1: Foundation (Weeks 1-6)**
- [ ] Set up Healthie authentication and patient management integration
- [ ] Build unified appointment creation system (internal + external in Healthie)
- [ ] Implement pause/resume mobile recording with segment merging
- [ ] Create basic AI analysis pipeline for both recording types
- [ ] Set up PostgreSQL operational database with all schemas
- [ ] Implement HealthKit integration and data sync

### **7.2 Phase 2: Intelligence & Coordination (Weeks 7-12)**
- [ ] Build cross-appointment analysis trigger system
- [ ] Implement comprehensive patient analysis engine
- [ ] Create actionable insights generation and management
- [ ] Build family dashboard access and invitation system
- [ ] Implement family notification optimization
- [ ] Set up Healthie EHR integration for all analysis results

### **7.3 Phase 3: Advanced Analytics (Weeks 13-18)**
- [ ] Set up BigQuery data warehouse and ETL pipeline
- [ ] Implement BigQuery analytics integration into processing pipeline
- [ ] Build advanced family dashboard intelligence
- [ ] Create predictive health insights and trend analysis
- [ ] Implement comprehensive care coordination automation
- [ ] Deploy performance monitoring and optimization

### **7.4 Phase 4: Production & Scaling (Weeks 19-24)**
- [ ] Optimize processing pipeline performance
- [ ] Implement advanced BigQuery ML for predictive healthcare insights
- [ ] Build comprehensive compliance and audit reporting
- [ ] Scale infrastructure for production healthcare workloads
- [ ] Deploy advanced family engagement optimization
- [ ] Create provider analytics and insights dashboard

---

## 8. Success Metrics & KPIs

### **8.1 Core Pipeline Performance**

```yaml
performance_targets:
  
  # Recording processing (with pause/resume)
  recording_pipeline:
    mobile_segment_merging: "<2_minutes_for_60min_appointment"
    audio_enhancement: "<3_minutes_per_hour_of_audio"
    transcription: "<5_minutes_per_hour_of_audio"
    zoom_recording_download: "<1_minute_via_healthie_urls"
    
  # AI analysis across appointment types
  ai_analysis_pipeline:
    individual_appointment_analysis: "<10_minutes"
    cross_appointment_comprehensive_analysis: "<15_minutes"
    actionable_insights_generation: "<5_minutes"
    total_pipeline_time: "<25_minutes_from_recording_completion"
    
  # Family dashboard updates
  family_dashboard_pipeline:
    family_insight_generation: "<5_minutes"
    dashboard_update_propagation: "<30_seconds"
    notification_delivery: "<2_minutes_for_urgent_items"
    
  # Healthie integration performance
  healthie_integration:
    appointment_creation: "<30_seconds"
    ehr_updates_with_analysis: "<2_minutes"
    provider_dashboard_refresh: "<30_seconds"
```

### **8.2 User Experience Metrics**

```yaml
user_experience_targets:
  
  # Authentication and onboarding
  authentication:
    healthie_auth_success_rate: ">99%"
    onboarding_completion_rate: ">85%"
    healthkit_connection_success: ">90%"
    
  # Recording experience
  recording_quality:
    pause_resume_user_satisfaction: ">4.5/5.0"
    recording_completion_rate: ">95%_for_scheduled_appointments"
    audio_quality_satisfaction: ">4.0/5.0"
    
  # Analysis and insights
  ai_analysis_quality:
    clinical_accuracy_rating: ">4.5/5.0_from_providers"
    actionable_insight_usefulness: ">4.0/5.0_from_patients"
    care_coordination_effectiveness: ">85%_successful_coordination"
    
  # Family dashboard engagement
  family_dashboard:
    family_member_activation_rate: ">70%_of_invitations"
    weekly_dashboard_usage: ">60%_active_family_members"
    urgent_notification_response_rate: ">90%_within_4_hours"
    family_satisfaction_with_insights: ">4.0/5.0"
```

### **8.3 Clinical Quality Metrics**

```yaml
clinical_quality_targets:
  
  # Cross-appointment intelligence
  cross_appointment_analysis:
    care_coordination_opportunity_detection: ">90%_accuracy"
    medication_interaction_flagging: ">99%_for_documented_medications"
    emergency_flag_precision: ">95%_minimize_false_positives"
    treatment_plan_coherence_assessment: ">85%_accuracy"
    
  # Provider satisfaction
  provider_experience:
    ai_summary_usefulness: ">4.5/5.0_provider_rating"
    care_coordination_effectiveness: ">4.0/5.0_provider_rating"
    time_savings_per_patient: ">15_minutes_per_appointment"
    clinical_decision_support_value: ">4.0/5.0_provider_rating"
    
  # Patient outcomes
  patient_outcomes:
    appointment_adherence_improvement: ">20%_vs_baseline"
    medication_adherence_improvement: ">15%_vs_baseline"
    care_coordination_satisfaction: ">4.5/5.0_patient_rating"
    family_engagement_in_care: ">80%_active_family_participation"
```

This completes the comprehensive MVP Data PRD with:
- ✅ **Unified appointment analysis architecture** treating internal and external appointments equally in Healthie
- ✅ **Pause/resume recording system** with seamless audio merging
- ✅ **Cross-appointment intelligence** triggered by any new appointment
- ✅ **Family dashboard** with intelligent monitoring and actionable insights
- ✅ **Complete implementation roadmap** with phases and success metrics

The architecture now properly supports all your MVP user stories with Healthie as the central EHR and smart categorization of appointment types for unified processing.

### **2.3 Refined Recording Schema (Pause/Resume)**

```sql
-- Single recording per appointment with pause/resume tracking
CREATE TABLE appointment_recordings (
    recording_id UUID PRIMARY KEY,
    healthie_appointment_id VARCHAR(255) UNIQUE,
    user_id UUID REFERENCES app_user_profiles(user_id),
    
    -- Recording session state
    recording_status 'not_started' | 'recording' | 'paused' | 'completed' | 'failed',
    
    -- Pause/resume session tracking
    session_data JSONB,                  -- {segments: [{start, end, file_url}], pauses: [{pause_time, resume_time}]}
    current_segment_number INTEGER DEFAULT 0,
    total_segments INTEGER DEFAULT 0,
    
    -- Consolidated recording metrics
    total_recording_duration_seconds INTEGER DEFAULT 0,
    total_pause_duration_seconds INTEGER DEFAULT 0,
    net_recording_duration_seconds INTEGER DEFAULT 0, -- Total - pauses
    pause_events_count INTEGER DEFAULT 0,
    
    -- Final audio file (merged from all segments)
    final_audio_file_url VARCHAR(500),
    final_audio_file_size_bytes BIGINT,
    final_audio_format VARCHAR(10) DEFAULT 'M4A',
    
    -- Audio quality assessment
    overall_audio_quality_score DECIMAL(3,2),
    average_volume_level DECIMAL(3,2),
    background_noise_score DECIMAL(3,2),
    speech_clarity_score DECIMAL(3,2),
    
    -- Recording environment
    recording_location VARCHAR(100),     -- 'waiting_room', 'exam_room', 'consultation_room'
    ambient_noise_description VARCHAR(100),
    estimated_speaker_count INTEGER,
    
    -- Session timestamps
    recording_started_at TIMESTAMP,
    recording_completed_at TIMESTAMP,
    last_pause_at TIMESTAMP,
    last_resume_at TIMESTAMP,
    
    -- Processing pipeline status
    audio_processing_status 'pending' | 'enhancing' | 'completed' | 'failed',
    transcription_status 'pending' | 'processing' | 'completed' | 'failed',
    ai_analysis_status 'pending' | 'processing' | 'completed' | 'failed',
    
    -- Integration status
    synced_to_healthie BOOLEAN DEFAULT false,
    healthie_sync_timestamp TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Detailed segment tracking for technical debugging and quality control
CREATE TABLE recording_segments (
    segment_id UUID PRIMARY KEY,
    recording_id UUID REFERENCES appointment_recordings(recording_id),
    
    -- Segment details
    segment_number INTEGER,
    segment_start_time TIMESTAMP,
    segment_end_time TIMESTAMP,
    segment_duration_seconds INTEGER,
    
    -- Segment file information
    segment_file_url VARCHAR(500),
    segment_file_size_bytes INTEGER,
    segment_audio_quality DECIMAL(3,2),
    
    -- Technical metadata
    device_battery_at_start INTEGER,
    device_storage_available_mb INTEGER,
    network_quality_at_start VARCHAR(20),
    
    -- Processing status
    uploaded_successfully BOOLEAN DEFAULT false,
    included_in_final_merge BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP DEFAULT NOW()
);
```

### **2.4 AI Analysis & Intelligence Schema**

```sql
-- Comprehensive AI analysis for any appointment type
CREATE TABLE appointment_ai_analysis (
    analysis_id UUID PRIMARY KEY,
    healthie_appointment_id VARCHAR(255),
    recording_id UUID REFERENCES appointment_recordings(recording_id),
    analysis_type 'external_mobile' | 'internal_zoom',
    
    -- Core clinical analysis
    clinical_summary TEXT,
    chief_complaint TEXT,
    history_of_present_illness TEXT,
    assessment_and_plan TEXT,
    
    -- Structured clinical data extraction
    diagnoses JSONB,                     -- [{"code": "I10", "description": "Essential hypertension", "confidence": 0.95}]
    medications JSONB,                   -- [{"name": "Lisinopril", "dosage": "10mg", "frequency": "daily", "action": "prescribed"}]
    procedures JSONB,                    -- [{"name": "Blood pressure check", "result": "140/90"}]
    lab_orders JSONB,                    -- [{"test": "Lipid panel", "urgency": "routine", "due_date": "2024-09-15"}]
    
    -- Care coordination insights
    care_coordination_flags JSONB,      -- Opportunities for coordination with other providers
    referral_recommendations JSONB,     -- Suggested specialist referrals
    follow_up_requirements JSONB,       -- Required follow-up actions and timing
    
    -- Patient communication analysis
    patient_understanding_assessment TEXT,
    key_patient_questions TEXT[],
    provider_education_provided TEXT[],
    communication_effectiveness_score DECIMAL(3,2),
    
    -- Risk and priority assessment
    emergency_flags JSONB,              -- Urgent findings requiring immediate attention
    risk_factors JSONB,                  -- Identified health risks
    preventive_opportunities JSONB,     -- Preventive care recommendations
    
    -- Quality and confidence metrics
    ai_model_version VARCHAR(50),
    overall_confidence_score DECIMAL(3,2),
    clinical_accuracy_estimate DECIMAL(3,2),
    analysis_processing_time_seconds INTEGER,
    
    -- Timeline tracking
    analysis_started_at TIMESTAMP,
    analysis_completed_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- Patient-facing actionable insights
CREATE TABLE actionable_insights (
    insight_id UUID PRIMARY KEY,
    analysis_id UUID REFERENCES appointment_ai_analysis(analysis_id),
    user_id UUID REFERENCES app_user_profiles(user_id),
    healthie_appointment_id VARCHAR(255),
    
    -- Insight classification
    insight_category 'medication_management' | 'follow_up_care' | 'lifestyle_modification' | 
                    'symptom_monitoring' | 'care_coordination' | 'preventive_care' | 'emergency',
    
    insight_type 'reminder' | 'action_required' | 'information' | 'warning' | 'celebration',
    
    -- Insight content
    title VARCHAR(255),
    description TEXT,
    detailed_explanation TEXT,
    
    -- Action specifications
    recommended_action TEXT,
    action_urgency 'low' | 'medium' | 'high' | 'urgent',
    action_deadline TIMESTAMP,
    
    -- Interactive elements
    action_buttons JSONB,               -- [{"label": "Schedule Follow-up", "action": "book_appointment"}]
    requires_user_input BOOLEAN DEFAULT false,
    input_fields JSONB,                 -- If user input needed
    
    -- User interaction tracking
    status 'new' | 'viewed' | 'acknowledged' | 'in_progress' | 'completed' | 'dismissed' | 'snoozed',
    user_interaction_count INTEGER DEFAULT 0,
    first_viewed_at TIMESTAMP,
    last_interaction_at TIMESTAMP,
    
    -- Family dashboard configuration
    family_dashboard_visible BOOLEAN DEFAULT false,
    family_notification_level 'none' | 'info' | 'important' | 'urgent',
    family_action_required BOOLEAN DEFAULT false,
    
    -- Completion tracking
    completion_method 'user_action' | 'automatic' | 'external_verification',
    completion_notes TEXT,
    completed_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

<function_calls>
<invoke name="mark_todo_as_done">
<parameter name="todo_ids">["acedf124-279d-4a7d-8eaf-0a2b5d60ba09"]
