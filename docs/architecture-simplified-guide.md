# Moira Healthcare - Architecture Simplified Guide

## 🎯 Complete System Overview (Plain English)

This guide explains how all the pieces of Moira's healthcare platform work together, from phone onboarding to family dashboards, without getting lost in technical complexity.

---

## 📞 1. The Patient Journey - Phone Onboarding Flow

### **The Complete Patient Experience**
```
Patient learns about Moira → Phone intake call with care coordinator → Care coordinator creates accounts → Patient receives credentials → Downloads app → Books appointments → Records conversations → Gets AI insights → Family can view and help
```

### **Key Relationships (One-to-One, One-to-Many)**
- **ONE patient** has **ONE phone intake session** (initial onboarding call with care coordinator)
- **ONE patient** has **ONE patient_extended_profile** (links to Healthie EHR + app-specific preferences)
- **ONE patient** can have **MANY appointments** (virtual with your practice + external specialists)
- **ONE appointment** can have **ONE recording session** (optional, with patient consent)
- **ONE recording session** can have **MANY segments** (pause/resume functionality for privacy)
- **ONE appointment** gets **ONE AI analysis** (after recording is processed)
- **ONE AI analysis** can create **MANY actionable insights** for the patient

### **Family Access - Who Can See What**
```
Patient → Invites family member during onboarding → Family member accepts invitation → Gets view-only dashboard access with granular permissions
```

**Family Relationship Rules:**
- **ONE patient** can grant access to **MANY family members**
- **ONE family member** can monitor **MANY patients** (if multiple family members invite them)
- **Family access permissions** are granular - patient controls exactly what each family member can see

---

## 🗄️ 2. Database Tables and Their Purpose (Real-Time System)

### **👤 patient_extended_profiles** (The Patient)
- **What it is**: Every patient who uses your app (extends beyond Healthie EHR)
- **Links to**: Healthie EHR (for authentication and core medical data)
- **Contains**: Consent preferences, HealthKit authorization, phone onboarding details
- **Phone Onboarding**: Created by care coordinators during intake calls with pre-set preferences
- **Relationship**: This is the "parent" table - everything else connects back to the patient

### **📞 phone_intake_sessions** (Onboarding Calls)
- **What it is**: Record of phone intake calls with care coordinators
- **Links to**: ONE patient (who was onboarded via phone)
- **Contains**: Call notes, duration, follow-up status, coordinator information
- **Purpose**: Premium onboarding experience with human touch and consent documentation

### **📅 appointment_metadata** (Every Healthcare Visit)
- **What it is**: ALL appointments (your virtual practice + external specialists)
- **Links to**: Healthie EHR (single source of truth for appointments)
- **Contains**: Provider info, appointment type, recording status
- **Key insight**: External appointments have `provider_id = null` in Healthie

### **🎙️ appointment_recordings** (Audio Sessions)
- **What it is**: Recording session for each appointment (if patient consents)
- **Links to**: ONE specific appointment
- **Contains**: Audio files, quality scores, timing information
- **Two types**: 
  - Zoom recordings (automatic for virtual appointments with your practice)
  - Mobile recordings (manual for external specialist appointments with pause/resume)

### **📊 appointment_ai_analysis** (AI Medical Insights)
- **What it is**: AI analysis results for each recorded appointment
- **Links to**: ONE appointment + ONE patient
- **Contains**: Clinical summary, diagnoses, medications, emergency flags
- **Creates**: Action items and care coordination needs for providers and patients

### **💡 actionable_insights** (Patient Recommendations)
- **What it is**: Specific recommendations generated from AI analysis
- **Links to**: ONE patient + ONE source appointment
- **Contains**: What the patient should do, priority level, completion tracking
- **Examples**: "Schedule cardiology follow-up", "Check blood pressure daily", "Call provider if dizziness occurs"

### **👨‍👩‍👧‍👦 family_dashboard_access** (Family Permissions)
- **What it is**: Family member access permissions set by patient during onboarding
- **Links to**: ONE patient (who grants access)
- **Contains**: Family member info, what they can see, invitation status
- **Security**: View-only access with granular permissions for different family roles

---

## 📈 3. Analytics System - Understanding Health Patterns Over Time

### **What's Different About BigQuery Analytics?**
- **PostgreSQL**: Handles real-time app operations ("What's happening now?")
- **BigQuery**: Analyzes historical patterns ("What trends do we see over time?")

### **Analytics Tables and What They Tell Us**

#### **📊 patient_health_trends** (Health Over Time)
- **What it analyzes**: Patient's health trajectory across multiple appointments
- **Key insights**: 
  - Is health improving, stable, or declining?
  - How often do they have emergencies?
  - How well are different providers coordinating care?
  - How engaged is their family in their care?

#### **🤝 care_coordination_patterns** (Provider Teamwork)
- **What it analyzes**: How well different doctors work together for each patient
- **Key insights**:
  - Are providers communicating effectively?
  - Are there conflicts in treatment plans?
  - Are there gaps in care coordination?
  - Is the patient seeing too many specialists (fragmented care)?

#### **👥 family_engagement_metrics** (Family Involvement)
- **What it analyzes**: How family members engage with patient's care
- **Key insights**:
  - How quickly do family members respond to urgent alerts?
  - Are family members getting overwhelmed (caregiver burden)?
  - What's the optimal notification frequency for each family member?
  - Does family engagement improve patient outcomes?

---

## 🌊 4. Data Lake - The Processing Factory (Plain English)

### **What is a Data Lake?**
A **data lake** is like a central storage and processing hub between your **data sources** (patient recordings, Healthie, wearables) and your **databases** (PostgreSQL and BigQuery).

```
[ Data Sources ] → [ Data Lake ] → [ Clean, Organized Databases ]
```

### **Data Lake vs. HIPAA-Compliant Cloud**

#### **HIPAA-Compliant Cloud = The Secure Building**
Think of the HIPAA-compliant cloud as your **secure building** with:
- Security guards (access controls)
- Vault doors (encryption)
- Security cameras (audit logging)
- Compliance certifications

#### **Data Lake = The Equipment Inside the Building**
The data lake is all the **equipment and processes** inside that building:
- Storage containers (Google Cloud Storage)
- Processing machinery (Cloud Functions, Cloud Run)
- Conveyor belts (ETL pipelines)
- Communication systems (Pub/Sub)

### **What the Data Lake Actually Does**

#### **Raw Data Storage**
```
CLOUD STORAGE BUCKETS (Raw Data)
├── 🎙️ raw-audio-recordings/
│   ├── appointment-123-zoom.mp4
│   ├── appointment-456-mobile-segment1.m4a
│   └── appointment-456-mobile-segment2.m4a
├── 📝 raw-transcripts/
│   ├── appointment-123-transcript.txt
│   └── appointment-456-transcript.txt
├── ⌚ wearable-data/
│   ├── patient-789-heartrate-20250901.json
│   └── patient-789-sleep-20250901.json
└── 🏥 healthie-exports/
    ├── patient-profiles-20250901.json
    └── appointments-20250901.json
```

#### **Data Processing Functions**
```
CLOUD FUNCTIONS (Audio Processing)
├── audio-enhancement.js → "Removes background noise, enhances voices"
├── segment-merger.js → "Combines paused/resumed segments"
└── transcription-processor.js → "Converts audio to text with Deepgram"

CLOUD RUN (AI Analysis)
├── medical-conversation-analyzer → "Extracts clinical info from transcripts"
├── emergency-detector → "Flags urgent medical situations"
└── insight-generator → "Creates actionable patient recommendations"
```

#### **Real-Time Communication**
```
PUB/SUB TOPICS (Event Streaming)
├── appointment-completed → "Triggered when appointment ends"
├── recording-ready-for-processing → "Triggered when recording uploaded"
├── analysis-completed → "Triggered when AI analysis done"
└── emergency-detected → "Urgent notification needed"
```

### **Data Lake Processing Examples**

#### **Example 1: Processing an External Appointment Recording**
```
1. Patient uploads recording from mobile app
   ↓
2. Recording stored in Cloud Storage bucket
   ↓
3. Pub/Sub message: "New recording available"
   ↓
4. Cloud Function: Audio enhancement
   ↓
5. Cloud Function: Transcription with Deepgram
   ↓
6. Cloud Run: Medical conversation analysis
   ↓
7. Results stored in PostgreSQL
   ↓
8. Dataflow ETL: Sync to BigQuery for analytics
```

#### **Example 2: Emergency Detection**
```
1. AI analysis detects "chest pain" in transcript
   ↓
2. Emergency flag set in analysis results
   ↓
3. Pub/Sub message: "Emergency detected"
   ↓
4. Cloud Function: Emergency handler
   ↓
5. Notification sent to patient's care team
   ↓
6. Family alert sent if permission granted
   ↓
7. Emergency data stored for analytics
```

---

## 📊 5. Visual Summary - How Data Flows Through the System

### **The Big Picture (Simple View)**

```
PATIENT (Phone Onboarded)
   ├── Phone Intake Session (care coordinator call)
   ├── Extended Profile (consent & preferences)
   ├── Healthie Account (authentication & EHR)
   ├── Appointments
   │   ├── Virtual (with your practice) → Zoom recording
   │   └── External (specialists) → Mobile recording
   │       
   ├── AI Analysis (from each recording)
   │   ├── Clinical insights
   │   ├── Emergency detection
   │   └── Action items for patient
   │
   └── Family Access
       ├── Spouse (can see everything)
       ├── Adult child (can see emergencies only)
       └── Caregiver (can see appointments & insights)
```

### **Patient → Appointments → Recording → AI Analysis**

```
👤 PATIENT
    |
    ├── 📅 Appointment #1 (Cardiologist)
    │    └── 🎙️ Mobile Recording → 🤖 AI Analysis → 💡 "Schedule follow-up"
    │
    ├── 📅 Appointment #2 (Your Virtual Visit) 
    │    └── 🎙️ Zoom Recording → 🤖 AI Analysis → 💡 "Blood pressure improving"
    │
    └── 📅 Appointment #3 (Dermatologist)
         └── 🎙️ Mobile Recording → 🤖 AI Analysis → 💡 "New medication prescribed"
```

### **Patient → Family Access Permissions**

```
👤 PATIENT (Sarah)
    |
    ├── 👨 Husband (John)
    │    ├── ✅ Can see all appointments
    │    ├── ✅ Can see AI summaries  
    │    ├── ✅ Gets urgent alerts
    │    └── ✅ Can see action items
    │
    ├── 👩 Daughter (Lisa)
    │    ├── ❌ Cannot see routine appointments
    │    ├── ❌ Cannot see AI summaries
    │    ├── ✅ Gets urgent alerts only
    │    └── ❌ Cannot see action items
    │
    └── 👩 Caregiver (Maria)
         ├── ✅ Can see appointments
         ├── ✅ Can see AI summaries
         ├── ✅ Gets urgent alerts
         └── ✅ Can see action items
```

### **Recording Session → Segments (For External Appointments)**

```
🎙️ EXTERNAL APPOINTMENT RECORDING
    |
    ├── 🔴 Segment 1 (0:00-15:30) → "Initial conversation"
    ├── ⏸️ PAUSE (15:30-16:00) → "Private discussion"
    ├── 🔴 Segment 2 (16:00-25:45) → "Treatment discussion" 
    ├── ⏸️ PAUSE (25:45-26:15) → "Payment/scheduling"
    └── 🔴 Segment 3 (26:15-30:00) → "Final instructions"
         |
         └── 🎵 MERGED AUDIO → AI Analysis
```

### **AI Analysis → Patient Insights**

```
🤖 AI ANALYSIS
    ├── Clinical Summary: "Discussed blood pressure medication adjustment"
    ├── Medications: "Increased lisinopril to 10mg daily"  
    ├── Emergency Flags: "None detected"
    └── Urgency Level: "Routine"
         |
         ├── 💡 Insight #1: "Schedule follow-up in 4 weeks"
         ├── 💡 Insight #2: "Monitor blood pressure daily"
         └── 💡 Insight #3: "Report any dizziness to provider"
```

---

## 🔄 6. Complete Data Flow - Step by Step

### **External Specialist Appointment Flow**
```
Step 1: Patient → "I have cardiologist appointment tomorrow"
Step 2: App → Creates appointment record in Healthie (provider_id = null)
Step 3: Patient → Taps "Start Recording" during appointment
Step 4: Patient → Pauses when needed, resumes when appropriate  
Step 5: Patient → Taps "Stop Recording" when appointment ends
Step 6: App → Merges segments, uploads to cloud storage
Step 7: AI → Analyzes merged audio, creates medical insights
Step 8: App → Shows insights to patient, notifies family if urgent
Step 9: Data → Syncs to BigQuery for long-term analytics
```

### **Virtual Practice Appointment Flow**
```
Step 1: Patient → Books virtual appointment through Healthie
Step 2: Healthie → Creates Zoom meeting automatically  
Step 3: Patient + Provider → Join Zoom call
Step 4: Zoom → Automatically records to cloud (if consented)
Step 5: AI → Downloads recording, analyzes conversation
Step 6: App → Shows insights to patient, updates Healthie EHR
Step 7: Family → Gets notifications based on their permissions
Step 8: Data → Syncs to BigQuery for analytics
```

---

## 🔐 7. Security & Privacy (Simple Rules)

### **Patient Controls Everything**
```
👤 PATIENT decides during phone onboarding:
    ├── ✅ "Yes, record my appointments" or ❌ "No recording"
    ├── ✅ "Yes, AI can analyze" or ❌ "No AI analysis"  
    ├── ✅ "Yes, family can see" or ❌ "No family access"
    └── 👨‍👩‍👧‍👦 For each family member: what they can/cannot see
```

### **Family Member Permissions (Granular)**
```
👨 FAMILY MEMBER can be granted:
    ├── 👀 View appointments (yes/no)
    ├── 📋 View AI summaries (yes/no)
    ├── 💡 View action items (yes/no)  
    ├── 🚨 Receive urgent alerts (yes/no)
    └── 📞 Emergency contact priority (1st, 2nd, 3rd...)
```

---

## 🎯 8. Why This Architecture Works

### **For Patients**
- Single app manages all healthcare (your practice + external specialists)
- AI never misses important details from any appointment
- Family stays informed without being overwhelmed
- Premium phone onboarding provides human support

### **For Providers (Your Practice)**
- Complete picture of patient's care across all providers
- AI flags important findings from external appointments
- Automated care coordination reduces manual work
- Phone onboarding ensures better patient adoption

### **For Family Members**
- View-only access respects patient privacy
- Smart notifications reduce caregiver burden
- Urgent alerts ensure quick response when needed
- Granular permissions match family relationship roles

### **For the Business**
- Phone onboarding provides premium service differentiation
- Scalable architecture supports growth
- HIPAA-compliant by design
- Analytics provide insights for improving care quality

---

## 🚀 9. Implementation Priority

### **September 2025 - Foundation Month**
1. **Phone onboarding system** (care coordinator dashboard, patient credential delivery)
2. **Patient profiles and consent management** (extended profiles with Healthie integration)
3. **Appointment metadata sync** with Healthie EHR
4. **Basic recording functionality** (both Zoom and mobile)

### **October 2025 - AI & Analytics**
1. **Recording → AI analysis pipeline** (data lake processing)
2. **Actionable insights generation** (patient recommendations)
3. **Emergency detection and alerts** (family notifications)
4. **BigQuery analytics setup** (health trends analysis)

### **November 2025 - Family & Advanced Features**
1. **Family access and permissions** (dashboard and notifications)
2. **Advanced family engagement optimization** (caregiver burden analysis)
3. **Care coordination automation** (provider alerts and communication)
4. **Performance optimization** and scaling

---

## 🔑 Common Questions & Answers

### **Q: How is this different from other health apps?**
**A**: Most health apps force patients to self-register and figure things out alone. Moira provides phone onboarding with care coordinators, records ALL appointments (not just virtual ones), and gives families smart access to help without overwhelming them.

### **Q: What makes the AI analysis trustworthy?**
**A**: The AI includes confidence scores, safety guardrails prevent medical advice, emergency detection has human oversight, and all insights encourage patients to discuss findings with their providers.

### **Q: How does family access respect patient privacy?**
**A**: Patients control exactly what each family member can see during the phone onboarding process. Family members get view-only access with granular permissions based on their relationship and the patient's preferences.

### **Q: Why use both PostgreSQL and BigQuery?**
**A**: PostgreSQL handles real-time app operations (fast reads/writes), while BigQuery analyzes historical patterns for health trends and family engagement optimization. Each database is optimized for its specific purpose.

This simplified architecture guide shows how all the pieces work together to create a comprehensive healthcare coordination platform that puts patients and families in control while providing providers with unprecedented visibility across all care settings.
