# MoiraMVP Data PRD v2.1 - BigQuery Corrected
## Comprehensive Healthcare Data Architecture with Healthie + BigQuery Integration

**Document Version**: 2.1  
**Last Updated**: September 2, 2025  
**Owner**: Technical Architecture Team  
**Correction**: Fixed BitQuery → BigQuery (Google Cloud Data Warehouse)

---

## 1. Executive Summary

### **MVP User Stories**
1. **Authentication & HealthKit**: Healthie auth + Apple HealthKit integration
2. **External Care Management**: Create external appointments with pause/resume audio recording
3. **AI Analysis & Actions**: Comprehensive analysis with actionable patient insights
4. **Family Coordination**: View-only family dashboard with intelligent monitoring
5. **Virtual Practice**: Book and participate in telehealth with Concierge Clinicians
6. **Cross-Appointment Intelligence**: Platform-wide analysis after each new appointment

### **Corrected Data Architecture Principles**
- **Healthie as Single Source of Truth**: All appointments and clinical data in Healthie EHR
- **PostgreSQL for Operational Data**: Real-time application data and processing
- **BigQuery for Analytics**: Google Cloud data warehouse for complex healthcare analytics
- **Unified Recording Pipeline**: Single audio file per appointment (pause/resume for external, Zoom for internal)

---

## 2. Data Architecture: PostgreSQL + BigQuery

### **2.1 PostgreSQL (Operational Database)**
```sql
-- Core application tables in PostgreSQL for real-time operations
-- [Previous schemas remain the same - these are operational tables]

-- Application user profiles (operational)
CREATE TABLE app_user_profiles (
    user_id UUID PRIMARY KEY,
    healthie_patient_id VARCHAR(255) UNIQUE NOT NULL,
    -- [same as before - operational data]
);

-- Appointment metadata (operational)  
CREATE TABLE appointment_metadata (
    healthie_appointment_id VARCHAR(255) PRIMARY KEY,
    is_internal_appointment BOOLEAN,
    -- [same as before - operational data]
);

-- Recording sessions (operational)
CREATE TABLE appointment_recordings (
    recording_id UUID PRIMARY KEY,
    healthie_appointment_id VARCHAR(255) UNIQUE,
    recording_status 'not_started' | 'recording' | 'paused' | 'completed' | 'failed',
    -- [same pause/resume schema as before]
);

-- AI analysis results (operational)
CREATE TABLE appointment_ai_analysis (
    analysis_id UUID PRIMARY KEY,
    healthie_appointment_id VARCHAR(255),
    clinical_summary TEXT,
    diagnoses JSONB,
    medications JSONB,
    -- [same as before - operational data]
);
```

### **2.2 BigQuery (Analytics Data Warehouse)**
```sql
-- BigQuery tables for complex healthcare analytics

-- Patient analytics dataset in BigQuery
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
    
    -- Care coordination metrics
    coordination_effectiveness_score FLOAT64,
    active_care_coordination_items INT64,
    provider_network_diversity INT64,
    
    -- Medication analysis
    medication_changes_count INT64,
    potential_drug_interactions INT64,
    
    -- Family engagement metrics
    family_members_active INT64,
    family_notification_engagement_rate FLOAT64,
    
    -- Data sources
    healthkit_data_completeness FLOAT64,
    appointment_recording_quality_avg FLOAT64,
    
    -- Metadata
    analysis_timestamp TIMESTAMP,
    data_freshness_hours FLOAT64
) 
PARTITION BY analysis_date
CLUSTER BY patient_id;

-- Care coordination analytics in BigQuery
CREATE OR REPLACE TABLE `moira-healthcare.analytics.care_coordination_patterns` (
    patient_id STRING,
    analysis_period_start DATE,
    analysis_period_end DATE,
    
    -- Provider network analysis
    internal_providers_count INT64,
    external_providers_count INT64,
    provider_specialties ARRAY<STRING>,
    
    -- Coordination effectiveness
    coordination_events_total INT64,
    coordination_events_resolved INT64,
    avg_resolution_time_hours FLOAT64,
    
    -- Communication patterns
    provider_to_provider_communication_gaps INT64,
    patient_information_sharing_effectiveness FLOAT64,
    
    -- Care quality indicators
    treatment_plan_coherence_score FLOAT64,
    medication_management_effectiveness FLOAT64,
    
    -- Risk factors
    care_fragmentation_risk_score FLOAT64,
    emergency_coordination_preparedness FLOAT64,
    
    -- Metadata
    analysis_timestamp TIMESTAMP
)
PARTITION BY analysis_period_start
CLUSTER BY patient_id;

-- Family dashboard analytics in BigQuery
CREATE OR REPLACE TABLE `moira-healthcare.analytics.family_engagement_metrics` (
    patient_id STRING,
    family_member_access_id STRING,
    relationship STRING,
    analysis_date DATE,
    
    -- Engagement metrics
    dashboard_views_count INT64,
    notification_interactions_count INT64,
    urgent_alert_response_rate FLOAT64,
    
    -- Family effectiveness metrics
    caregiver_burden_score FLOAT64,
    family_coordination_effectiveness FLOAT64,
    
    -- Predictive insights
    optimal_notification_frequency STRING,
    predicted_caregiver_availability FLOAT64,
    
    -- Metadata
    analysis_timestamp TIMESTAMP
)
PARTITION BY analysis_date
CLUSTER BY patient_id;
```

---

## 3. Data Processing Pipeline with BigQuery Integration

### **3.1 PostgreSQL → BigQuery ETL Pipeline**

```yaml
# Data pipeline: PostgreSQL (operational) → BigQuery (analytics)
postgresql_to_bigquery_pipeline:
  
  # Real-time data sync
  real_time_sync:
    frequency: "every_15_minutes"
    
    tables_to_sync:
      - table: "appointment_ai_analysis"
        bigquery_destination: "moira-healthcare.raw_data.appointment_analyses"
        sync_strategy: "incremental_by_analysis_completed_at"
        
      - table: "appointment_metadata" 
        bigquery_destination: "moira-healthcare.raw_data.appointments"
        sync_strategy: "incremental_by_updated_at"
        
      - table: "actionable_insights"
        bigquery_destination: "moira-healthcare.raw_data.patient_insights" 
        sync_strategy: "incremental_by_created_at"
        
      - table: "healthkit_metrics"
        bigquery_destination: "moira-healthcare.raw_data.healthkit_data"
        sync_strategy: "incremental_by_synced_at"
  
  # Analytics processing in BigQuery
  bigquery_analytics_processing:
    
    # Daily analytics refresh
    daily_analytics:
      schedule: "0 2 * * *"  # 2 AM daily
      
      transforms:
        patient_health_trends:
          source_tables: ["raw_data.appointment_analyses", "raw_data.healthkit_data"]
          output_table: "analytics.patient_health_trends"
          processing: "complex_trend_analysis_sql"
          
        care_coordination_patterns:
          source_tables: ["raw_data.appointments", "raw_data.appointment_analyses", "raw_data.patient_insights"]
          output_table: "analytics.care_coordination_patterns"
          processing: "provider_network_analysis_sql"
          
        family_engagement_metrics:
          source_tables: ["raw_data.family_access", "raw_data.family_notifications"]
          output_table: "analytics.family_engagement_metrics"
          processing: "family_intelligence_analysis_sql"
    
    # Real-time analytics (for processing pipeline)
    real_time_analytics:
      trigger: "new_appointment_analysis_completion"
      
      queries:
        patient_trend_analysis:
          sql: "SELECT * FROM `analytics.patient_health_trends` WHERE patient_id = @patient_id ORDER BY analysis_date DESC LIMIT 1"
          use_case: "enhance_cross_appointment_analysis"
          
        care_coordination_status:
          sql: "SELECT * FROM `analytics.care_coordination_patterns` WHERE patient_id = @patient_id ORDER BY analysis_period_end DESC LIMIT 1"
          use_case: "inform_care_coordination_recommendations"
          
        family_dashboard_context:
          sql: "SELECT * FROM `analytics.family_engagement_metrics` WHERE patient_id = @patient_id ORDER BY analysis_date DESC LIMIT 7"
          use_case: "optimize_family_notifications"
```

### **3.2 Revised Processing Pipeline with BigQuery**

```python
# Corrected pipeline with BigQuery analytics integration
class BigQueryEnhancedProcessor:
    
    def __init__(self):
        self.bigquery_client = bigquery.Client()
        self.postgresql_db = PostgreSQLClient()
        self.healthie_client = HealthieClient()
        
    async def process_appointment_with_bigquery_analytics(self, appointment_id: str):
        """Process appointment with BigQuery analytics enhancement"""
        
        # 1. Complete recording and AI analysis (PostgreSQL)
        ai_analysis = await self.complete_ai_analysis(appointment_id)
        
        # 2. Sync new data to BigQuery
        await self.sync_to_bigquery([
            {'table': 'appointment_ai_analysis', 'record_id': ai_analysis.analysis_id},
            {'table': 'appointment_metadata', 'record_id': appointment_id}
        ])
        
        # 3. Run BigQuery analytics queries for patient context
        bigquery_insights = await self.get_bigquery_patient_analytics(ai_analysis.patient_id)
        
        # 4. Enhanced cross-appointment analysis with BigQuery context
        comprehensive_analysis = await self.run_enhanced_cross_analysis({
            'ai_analysis': ai_analysis,
            'bigquery_trends': bigquery_insights.health_trends,
            'bigquery_coordination': bigquery_insights.care_coordination,
            'bigquery_family_metrics': bigquery_insights.family_engagement
        })
        
        # 5. Update family dashboard with BigQuery-informed insights
        await self.update_family_dashboard_with_bigquery_insights(
            ai_analysis.patient_id, comprehensive_analysis, bigquery_insights
        )
        
        return comprehensive_analysis
        
    async def get_bigquery_patient_analytics(self, patient_id: str) -> BigQueryInsights:
        """Get patient analytics from BigQuery data warehouse"""
        
        # Execute BigQuery analytics queries in parallel
        queries = {
            'health_trends': f"""
                SELECT 
                    health_trend_direction,
                    severity_score_avg,
                    emergency_episodes_count,
                    coordination_effectiveness_score
                FROM `moira-healthcare.analytics.patient_health_trends`
                WHERE patient_id = '{patient_id}'
                ORDER BY analysis_date DESC
                LIMIT 1
            """,
            
            'care_coordination': f"""
                SELECT 
                    coordination_events_resolved,
                    coordination_events_total,
                    provider_network_diversity,
                    care_fragmentation_risk_score
                FROM `moira-healthcare.analytics.care_coordination_patterns`
                WHERE patient_id = '{patient_id}'
                ORDER BY analysis_period_end DESC
                LIMIT 1
            """,
            
            'family_engagement': f"""
                SELECT 
                    AVG(dashboard_views_count) as avg_engagement,
                    AVG(urgent_alert_response_rate) as urgent_response_rate,
                    AVG(caregiver_burden_score) as caregiver_burden,
                    COUNT(DISTINCT family_member_access_id) as active_family_members
                FROM `moira-healthcare.analytics.family_engagement_metrics`
                WHERE patient_id = '{patient_id}'
                AND analysis_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                GROUP BY patient_id
            """
        }
        
        # Execute queries in parallel
        results = await asyncio.gather(*[
            self.bigquery_client.query(query).result() 
            for query in queries.values()
        ])
        
        return BigQueryInsights(
            health_trends=self.parse_bigquery_result(results[0]),
            care_coordination=self.parse_bigquery_result(results[1]),
            family_engagement=self.parse_bigquery_result(results[2])
        )
```

### **3.3 BigQuery Analytics SQL for Healthcare**

```sql
-- BigQuery analytics queries for real-time processing enhancement

-- Patient health trend analysis in BigQuery
CREATE OR REPLACE TABLE FUNCTION `moira-healthcare.analytics.analyze_patient_health_trends`(patient_id STRING)
AS (
  WITH appointment_timeline AS (
    SELECT 
      aa.analysis_completed_at,
      aa.emergency_flags,
      aa.overall_confidence_score,
      aa.medications,
      
      -- Calculate severity score
      CASE 
        WHEN REGEXP_CONTAINS(CAST(aa.emergency_flags AS STRING), r'urgent|critical') THEN 0.9
        WHEN REGEXP_CONTAINS(CAST(aa.emergency_flags AS STRING), r'high|severe') THEN 0.7
        WHEN REGEXP_CONTAINS(CAST(aa.emergency_flags AS STRING), r'medium|moderate') THEN 0.5
        ELSE 0.3
      END as severity_score,
      
      -- Previous appointment comparison using LAG
      LAG(CASE 
        WHEN REGEXP_CONTAINS(CAST(aa.emergency_flags AS STRING), r'urgent|critical') THEN 0.9
        WHEN REGEXP_CONTAINS(CAST(aa.emergency_flags AS STRING), r'high|severe') THEN 0.7
        WHEN REGEXP_CONTAINS(CAST(aa.emergency_flags AS STRING), r'medium|moderate') THEN 0.5
        ELSE 0.3
      END) OVER (ORDER BY aa.analysis_completed_at) as prev_severity_score
      
    FROM `moira-healthcare.raw_data.appointment_analyses` aa
    WHERE aa.patient_id = patient_id
    AND aa.analysis_completed_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
    ORDER BY aa.analysis_completed_at DESC
    LIMIT 20
  ),
  trend_calculation AS (
    SELECT 
      CASE 
        WHEN AVG(severity_score - IFNULL(prev_severity_score, severity_score)) > 0.1 THEN 'declining'
        WHEN AVG(severity_score - IFNULL(prev_severity_score, severity_score)) < -0.1 THEN 'improving'
        ELSE 'stable'
      END as trend_direction,
      
      ABS(AVG(severity_score - IFNULL(prev_severity_score, severity_score))) as trend_confidence,
      
      STRUCT(
        AVG(severity_score) as current_avg_severity,
        STDDEV(severity_score) as severity_variance,
        COUNTIF(severity_score > 0.8) / COUNT(*) as emergency_frequency,
        DATE_DIFF(MAX(DATE(analysis_completed_at)), MIN(DATE(analysis_completed_at)), DAY) / COUNT(*) as avg_days_between_appointments
      ) as trajectory_metrics,
      
      CASE 
        WHEN AVG(severity_score) > 0.8 THEN 'urgent'
        WHEN AVG(severity_score - IFNULL(prev_severity_score, severity_score)) > 0.2 THEN 'attention'
        WHEN COUNTIF(severity_score > 0.8) > 0 THEN 'important'
        ELSE 'normal'
      END as family_alert_level
      
    FROM appointment_timeline
    WHERE prev_severity_score IS NOT NULL OR COUNTIF(TRUE) = 1
  )
  SELECT 
    patient_id,
    trend_direction,
    trend_confidence,
    trajectory_metrics,
    family_alert_level,
    CURRENT_TIMESTAMP() as analysis_timestamp
  FROM trend_calculation
);

-- Care coordination effectiveness analysis in BigQuery
CREATE OR REPLACE TABLE FUNCTION `moira-healthcare.analytics.analyze_care_coordination`(patient_id STRING)
AS (
  WITH coordination_metrics AS (
    SELECT 
      -- Provider diversity
      COUNT(DISTINCT CASE WHEN am.is_internal_appointment = false THEN am.external_provider_name END) as external_providers,
      COUNT(DISTINCT CASE WHEN am.is_internal_appointment = true THEN am.healthie_appointment_id END) as internal_appointments,
      
      -- Coordination effectiveness
      COUNT(ai.insight_id) as total_coordination_insights,
      COUNTIF(ai.status = 'completed') as resolved_coordination_insights,
      COUNTIF(ai.status IN ('new', 'in_progress')) as active_coordination_insights,
      
      -- Time patterns
      AVG(DATETIME_DIFF(ai.completed_at, ai.created_at, MINUTE)) as avg_resolution_minutes,
      
      -- Urgency patterns
      COUNTIF(ai.action_urgency = 'urgent' AND ai.insight_category = 'care_coordination') as urgent_coordination_needs
      
    FROM `moira-healthcare.raw_data.patient_insights` ai
    JOIN `moira-healthcare.raw_data.appointments` am ON ai.healthie_appointment_id = am.healthie_appointment_id
    WHERE ai.patient_id = patient_id
    AND ai.created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
    AND ai.insight_category = 'care_coordination'
  )
  SELECT 
    patient_id,
    
    -- Coordination effectiveness score
    CASE WHEN total_coordination_insights = 0 THEN 1.0
         ELSE resolved_coordination_insights / total_coordination_insights 
    END as coordination_effectiveness_score,
    
    active_coordination_insights,
    
    STRUCT(
      external_providers,
      internal_appointments,
      CASE WHEN (external_providers + internal_appointments) = 0 THEN 0
           ELSE internal_appointments / (external_providers + internal_appointments)
      END as internal_care_ratio,
      avg_resolution_minutes,
      CASE WHEN total_coordination_insights = 0 THEN 0
           ELSE urgent_coordination_needs / total_coordination_insights
      END as urgent_coordination_ratio
    ) as network_effectiveness,
    
    STRUCT(
      internal_appointments < external_providers as needs_more_internal_care,
      active_coordination_insights > 3 as needs_prioritized_coordination,
      urgent_coordination_needs > 0 as needs_immediate_attention
    ) as recommended_actions,
    
    CURRENT_TIMESTAMP() as analysis_timestamp
    
  FROM coordination_metrics
);

-- Family intelligence analysis in BigQuery
CREATE OR REPLACE TABLE FUNCTION `moira-healthcare.analytics.analyze_family_intelligence`(patient_id STRING)
AS (
  WITH family_metrics AS (
    SELECT 
      COUNT(DISTINCT fem.family_member_access_id) as active_family_members,
      AVG(fem.dashboard_views_count) as avg_dashboard_engagement,
      AVG(fem.notification_interactions_count) as avg_notification_engagement,
      AVG(fem.urgent_alert_response_rate) as avg_urgent_response_rate,
      AVG(fem.caregiver_burden_score) as avg_caregiver_burden,
      
      -- Engagement distribution by relationship
      COUNTIF(fem.relationship = 'spouse') as spouse_count,
      COUNTIF(fem.relationship = 'parent') as parent_count,
      COUNTIF(fem.relationship = 'child') as child_count,
      COUNTIF(fem.relationship = 'caregiver') as caregiver_count
      
    FROM `moira-healthcare.analytics.family_engagement_metrics` fem
    WHERE fem.patient_id = patient_id
    AND fem.analysis_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  )
  SELECT 
    patient_id,
    
    -- Overall family engagement score
    LEAST(1.0, 
      (avg_notification_engagement / 10 * 0.4) + 
      (avg_urgent_response_rate * 0.4) + 
      (CASE WHEN avg_dashboard_engagement > 5 THEN 0.2 ELSE avg_dashboard_engagement * 0.04 END)
    ) as family_engagement_score,
    
    STRUCT(
      CASE WHEN avg_notification_engagement > 8 THEN 'immediate'
           WHEN avg_notification_engagement > 3 THEN 'daily_digest'
           ELSE 'weekly_summary'
      END as optimal_frequency,
      CASE WHEN avg_urgent_response_rate > 0.9 THEN 'medium'
           ELSE 'high'
      END as urgency_threshold
    ) as notification_optimization,
    
    STRUCT(
      active_family_members,
      avg_caregiver_burden,
      CASE WHEN active_family_members > 3 THEN 'high'
           WHEN active_family_members > 1 THEN 'moderate'
           ELSE 'low'
      END as coordination_complexity,
      STRUCT(spouse_count, parent_count, child_count, caregiver_count) as relationship_distribution
    ) as caregiver_assessment,
    
    CURRENT_TIMESTAMP() as analysis_timestamp
    
  FROM family_metrics
);
```

### **3.4 Revised Processing Pipeline Integration**

```python
# Corrected pipeline with BigQuery data warehouse
class BigQueryHealthcareAnalytics:
    
    def __init__(self):
        self.bigquery = bigquery.Client(project='moira-healthcare')
        self.postgresql = PostgreSQLClient()
        
    async def process_appointment_with_bigquery_context(self, appointment_id: str):
        """Process appointment with BigQuery analytics context"""
        
        # 1. Complete PostgreSQL processing (operational data)
        ai_analysis = await self.complete_postgresql_processing(appointment_id)
        
        # 2. Sync new data to BigQuery
        await self.sync_appointment_data_to_bigquery(appointment_id, ai_analysis)
        
        # 3. Get BigQuery analytics context
        bigquery_context = await self.get_bigquery_analytics_context(ai_analysis.patient_id)
        
        # 4. Enhanced cross-appointment analysis with BigQuery insights
        comprehensive_analysis = await self.run_enhanced_analysis_with_bigquery({
            'postgresql_analysis': ai_analysis,
            'bigquery_trends': bigquery_context.health_trends,
            'bigquery_coordination': bigquery_context.care_coordination,
            'bigquery_family': bigquery_context.family_intelligence
        })
        
        # 5. Update PostgreSQL with enhanced results
        await self.store_enhanced_analysis_results(appointment_id, comprehensive_analysis)
        
        # 6. Update family dashboard with BigQuery-optimized insights
        await self.update_family_dashboard_with_bigquery_optimization(
            ai_analysis.patient_id, comprehensive_analysis, bigquery_context
        )
        
        return comprehensive_analysis
        
    async def get_bigquery_analytics_context(self, patient_id: str) -> BigQueryContext:
        """Get patient analytics context from BigQuery data warehouse"""
        
        # Run BigQuery analytics functions
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
        
        # Execute BigQuery queries
        results = {}
        for name, query in queries.items():
            query_job = self.bigquery.query(query)
            results[name] = [dict(row) for row in query_job.result()]
            
        return BigQueryContext(
            health_trends=results['health_trends'][0] if results['health_trends'] else None,
            care_coordination=results['care_coordination'][0] if results['care_coordination'] else None,
            family_intelligence=results['family_intelligence'][0] if results['family_intelligence'] else None
        )
```

---

## 4. Corrected Architecture Summary

### **What Changed:**
- ❌ **BitQuery** (blockchain analytics) → ✅ **BigQuery** (Google Cloud data warehouse)
- ✅ **PostgreSQL**: Operational database for real-time app operations
- ✅ **BigQuery**: Analytics data warehouse for complex healthcare analytics
- ✅ **ETL Pipeline**: PostgreSQL → BigQuery for analytics processing
- ✅ **Real-time Integration**: BigQuery analytics inform PostgreSQL processing

### **Benefits of BigQuery for Healthcare:**
- **Scalable Analytics**: Handle large healthcare datasets efficiently
- **Complex Queries**: Advanced SQL for patient journey analysis
- **Machine Learning**: Built-in ML capabilities for predictive analytics
- **HIPAA Compliance**: Google Cloud healthcare compliance features
- **Cost Effective**: Pay-per-query model scales with usage

### **Implementation Priority:**
1. **Phase 1**: Build PostgreSQL operational database and basic processing
2. **Phase 2**: Set up BigQuery data warehouse and ETL pipeline
3. **Phase 3**: Integrate BigQuery analytics into processing pipeline
4. **Phase 4**: Advanced BigQuery ML for predictive healthcare insights

This corrected architecture properly uses **BigQuery** as a powerful healthcare analytics data warehouse while maintaining PostgreSQL for operational efficiency.
