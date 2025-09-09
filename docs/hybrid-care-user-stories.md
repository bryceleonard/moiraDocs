# MoiraMVP Hybrid Care User Stories
## Virtual Practice + In-Person External Care Model

---

## Executive Summary

MoiraMVP operates a **hybrid care coordination model**:
- **Your Practice**: Virtual appointments via telehealth
- **External Care**: In-person specialist visits with ambient AI assistance
- **AI Coordination**: Unified health insights across both care modalities

This document defines user stories that drive our data pipeline requirements, audio processing architecture, and care coordination workflows.

---

## Core User Stories by Care Type

### **Category A: Virtual Practice Appointments (Your Practice)**

#### **Story A1: Virtual Consultation with AI Analysis**
**As a patient**, I want to have a virtual appointment with my primary care provider where our conversation is automatically analyzed for medical insights.

**Acceptance Criteria:**
- Patient joins virtual appointment via secure video platform
- Audio from virtual meeting is captured and processed in real-time
- AI provides live insights to provider during consultation
- Clinical notes are automatically generated post-visit
- Patient receives simplified summary via mobile app

**Data Pipeline Requirements:**
- Real-time audio stream capture from virtual meeting platform
- Live transcription with medical terminology recognition
- Real-time AI analysis for provider support
- Integration with Healthie EHR for clinical documentation
- Patient notification system for post-visit summaries

#### **Story A2: Virtual Provider Dashboard with Complete Context**
**As a virtual care provider**, I want to see a patient's complete health context before and during our virtual appointment, including insights from their recent specialist visits.

**Acceptance Criteria:**
- Provider dashboard shows unified timeline of virtual + in-person care
- AI-generated insights from external appointments are highlighted
- Real-time alerts during virtual consultation if specialist findings are relevant
- Ability to reference external specialist recommendations during virtual visit
- Integrated care coordination suggestions

**Data Pipeline Requirements:**
- Pre-appointment data aggregation from multiple sources
- Real-time data correlation during virtual visits
- Cross-appointment insight generation
- Provider notification and alert system
- Healthie EHR integration for comprehensive record keeping

#### **Story A3: Virtual Follow-up Triggered by External Care**
**As a patient**, when my in-person specialist makes medication changes or identifies concerns, I want my virtual primary care team to automatically reach out for coordination.

**Acceptance Criteria:**
- AI detects significant findings from in-person specialist visit
- System automatically suggests virtual follow-up with primary care
- Virtual appointment can be scheduled directly from mobile app
- Provider is pre-briefed with specialist findings before virtual visit
- Care plan is updated across all providers

**Data Pipeline Requirements:**
- Real-time processing of in-person visit recordings
- Automated care coordination trigger system
- Virtual appointment scheduling integration
- Cross-provider communication workflow
- Unified care plan management

---

### **Category B: In-Person External Appointments (Specialists)**

#### **Story B1: Discreet In-Person Recording and Analysis**
**As a patient**, I want to discretely record my in-person specialist appointment and receive AI insights afterward, without disrupting the doctor-patient relationship.

**Acceptance Criteria:**
- Simple one-tap recording start/stop on mobile device
- Audio processing handles background noise and multiple speakers
- AI analysis identifies key medical information post-visit
- Patient-friendly summary available within 30 minutes
- Option to share insights with virtual primary care team

**Data Pipeline Requirements:**
- Mobile device audio capture and upload
- Background noise filtering and speaker separation
- Post-processing AI analysis pipeline
- Patient summary generation system
- Secure data transmission and storage

#### **Story B2: In-Person Specialist Visit with Care Coordination**
**As a patient**, when I visit a specialist in-person, I want the AI to analyze our conversation and coordinate any findings with my virtual primary care team.

**Acceptance Criteria:**
- Recording captures full specialist conversation
- AI identifies medication changes, new diagnoses, follow-up requirements
- System flags potential conflicts with existing care plan
- Virtual primary care team is notified of significant findings
- Patient receives coordinated care recommendations

**Data Pipeline Requirements:**
- In-person audio processing with medical terminology extraction
- Medication conflict detection across care teams
- Automated provider notification system
- Care plan integration and conflict resolution
- Cross-provider communication workflow

#### **Story B3: Emergency Detection During In-Person Visit**
**As a patient**, if my in-person specialist appointment reveals urgent findings, I want immediate coordination with my virtual primary care team.

**Acceptance Criteria:**
- AI detects emergency keywords or critical findings during recording
- Immediate alert sent to virtual primary care provider
- Virtual urgent consultation can be scheduled same-day
- Patient is notified of urgency and next steps
- All providers have immediate access to critical findings

**Data Pipeline Requirements:**
- Real-time emergency detection during audio processing
- Immediate alert and notification system
- Urgent virtual appointment scheduling integration
- Critical findings distribution to care team
- Emergency protocol automation

---

### **Category C: Unified Care Coordination**

#### **Story C1: Complete Health Timeline Across Care Types**
**As a patient**, I want to see all my healthcare encounters (virtual with my practice, in-person with specialists) in one unified timeline with AI insights.

**Acceptance Criteria:**
- Single dashboard shows virtual + in-person appointments chronologically
- AI analysis results displayed for each encounter
- Care coordination activities tracked and visible
- Medication changes and health trends visualized
- Ability to share complete timeline with any provider

**Data Pipeline Requirements:**
- Unified data model for virtual and in-person appointments
- Cross-appointment data correlation and timeline generation
- Comprehensive health trend analysis
- Multi-source data visualization pipeline
- Provider sharing and export capabilities

#### **Story C2: AI-Powered Care Coordination Between Virtual and In-Person Teams**
**As a virtual care provider**, I want AI to automatically coordinate care with the patient's in-person specialists, identifying conflicts and opportunities.

**Acceptance Criteria:**
- AI analyzes all patient encounters (virtual + in-person) for care coordination opportunities
- System identifies medication conflicts between virtual and in-person providers
- Automated recommendations for care plan adjustments
- Direct communication facilitation with external specialists when appropriate
- Comprehensive care coordination documentation

**Data Pipeline Requirements:**
- Cross-modal appointment data analysis
- Medication and treatment conflict detection
- Care coordination recommendation engine
- Inter-provider communication facilitation
- Comprehensive care documentation system

#### **Story C3: Predictive Health Insights Across Care Modalities**
**As a patient**, I want AI to identify health patterns and risks by analyzing my complete care history (virtual + in-person) and proactively recommend preventive actions.

**Acceptance Criteria:**
- AI analyzes patterns across virtual and in-person care encounters
- Predictive risk assessment for chronic disease progression
- Proactive recommendations for preventive care
- Integration with wearable/health tracking data
- Personalized health optimization suggestions

**Data Pipeline Requirements:**
- Historical health data analysis across all care types
- Predictive modeling and risk assessment algorithms
- Preventive care recommendation system
- Wearable/IoT data integration
- Personalized health insight generation

---

## Technical Implications by Care Type

### **Virtual Appointments (Your Practice)**
**Audio Capture Method**: Screen recording, virtual meeting platform integration
**Processing Requirements**: 
- Real-time transcription during live consultation
- Live AI insights for provider support
- Immediate integration with Healthie EHR
- Low-latency processing for real-time feedback

**Data Characteristics**:
- High audio quality (digital transmission)
- Clear speaker separation (patient vs. provider)
- Structured conversation flow
- Predictable duration and format

### **In-Person External Appointments (Specialists)**
**Audio Capture Method**: Mobile device recording in clinical setting
**Processing Requirements**:
- Post-visit batch processing (privacy considerations)
- Background noise filtering and enhancement
- Speaker identification and separation
- Medical terminology extraction from natural conversation

**Data Characteristics**:
- Variable audio quality (room acoustics, device placement)
- Multiple speakers (patient, provider, possibly others)
- Unstructured conversation flow
- Variable duration and interruptions

---

## Data Pipeline Architecture Implications

### **Dual Processing Pipelines Required:**

#### **Pipeline 1: Virtual Care (Real-Time)**
```mermaid
Virtual Meeting → Real-time Capture → Live Transcription → 
AI Analysis → Provider Insights → Healthie EHR → Patient Summary
```

#### **Pipeline 2: In-Person Care (Batch Processing)**
```mermaid
Mobile Recording → Upload → Audio Enhancement → Transcription → 
AI Analysis → Care Coordination → Provider Alerts → Patient Summary
```

### **Integration Points:**
- **Unified Patient Timeline**: Merge virtual + in-person encounter data
- **Cross-Care Insights**: AI correlation between virtual and in-person findings
- **Care Coordination**: Automated communication between virtual practice and external specialists
- **Emergency Detection**: Different urgency protocols for virtual vs. in-person findings

---

## Key Questions for Data Pipeline PRD

Based on these refined user stories, we need to define:

1. **Audio Processing Architecture**: How do we handle both real-time virtual meeting capture and mobile device recording?

2. **Data Lake Structure**: How do we organize virtual vs. in-person appointment data for optimal analysis?

3. **BigQuery Integration**: What specific healthcare data queries and analytics do we need?

4. **Real-time vs. Batch Processing**: Which workflows need immediate processing vs. can be handled asynchronously?

5. **Care Coordination Triggers**: What events automatically trigger cross-care communication?

6. **Compliance Framework**: How do we ensure HIPAA compliance across both virtual and in-person data capture?

These user stories provide the concrete foundation needed for designing the data pipeline architecture. Would you like me to use these to create the detailed data pipeline PRD with BigQuery integration and data lake design?
