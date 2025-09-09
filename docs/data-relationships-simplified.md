# Moira Healthcare - Database Relationships Simplified

## 🔗 Core Data Relationships (Plain English)

### **1. The Patient Journey - Phone Onboarding Flow**

```
Patient calls for info → Phone intake with care coordinator → Account created by staff → Patient gets credentials → Downloads app → Books appointments → Records conversations → Gets AI insights → Family can view
```

**Key Relationships:**
- **ONE patient** has **ONE phone intake session** (initial onboarding call)
- **ONE patient** has **ONE patient_extended_profile** (links to Healthie + app preferences)
- **ONE patient** can have **MANY appointments** (virtual with your practice + external specialists)
- **ONE appointment** can have **ONE recording session** (optional)
- **ONE recording session** can have **MANY segments** (pause/resume functionality)
- **ONE appointment** gets **ONE AI analysis** (after recording is processed)
- **ONE AI analysis** can create **MANY actionable insights** for the patient

### **2. Family Access - Who Can See What**

```
Patient → Invites family member → Family member accepts → Gets view-only dashboard access
```

**Key Relationships:**
- **ONE patient** can grant access to **MANY family members**
- **ONE family member** can monitor **MANY patients** (if multiple family members invite them)
- **Family access permissions** are granular - patient controls exactly what each family member can see

---

## 🗄️ PostgreSQL Operational Database - The Real-Time System

### **Core Tables and Their Purpose**

#### **👤 patient_extended_profiles** (The Patient)
- **What it is**: Every patient who uses your app (extended beyond Healthie)
- **Links to**: Healthie EHR (single patient record for auth and medical data)
- **Contains**: Consent preferences, HealthKit authorization, phone onboarding details
- **Relationship**: This is the "parent" table - everything else connects back to the patient
- **Phone Onboarding**: Created by care coordinators during intake calls

#### **📅 appointment_metadata** (Every Healthcare Visit)
- **What it is**: ALL appointments (your virtual practice + external specialists)
- **Links to**: Healthie EHR (single source of truth for appointments)
- **Contains**: Provider info, appointment type, recording status
- **Key insight**: External appointments have `provider_id = null` in Healthie

#### **🎙️ appointment_recordings** (Audio Sessions)
- **What it is**: Recording session for each appointment (if patient consents)
- **Links to**: ONE specific appointment
- **Contains**: Audio files, quality scores, timing info
- **Two types**: 
  - Zoom recordings (automatic for virtual appointments)
  - Mobile recordings (manual for external appointments)

#### **📊 appointment_ai_analysis** (AI Medical Insights)
- **What it is**: AI analysis results for each recorded appointment
- **Links to**: ONE appointment + ONE patient
- **Contains**: Clinical summary, diagnoses, medications, emergency flags
- **Creates**: Action items and care coordination needs

#### **💡 actionable_insights** (Patient Recommendations)
- **What it is**: Specific recommendations generated from AI analysis
- **Links to**: ONE patient + ONE source appointment
- **Contains**: What the patient should do, priority level, completion tracking
- **Examples**: "Schedule cardiology follow-up", "Check blood pressure daily"

#### **👨‍👩‍👧‍👦 family_dashboard_access** (Family Permissions)
- **What it is**: Family member access permissions set by patient
- **Links to**: ONE patient (who grants access)
- **Contains**: Family member info, what they can see, invitation status
- **Security**: View-only access with granular permissions

#### **📞 phone_intake_sessions** (Onboarding Calls)
- **What it is**: Record of phone intake calls with care coordinators
- **Links to**: ONE patient (who was onboarded via phone)
- **Contains**: Call notes, duration, follow-up status, coordinator info
- **Purpose**: Premium onboarding experience with human touch

---

## 📈 BigQuery Analytics Warehouse - The Intelligence System

### **What BigQuery Does Differently**
- **PostgreSQL**: Handles real-time app operations ("What's happening now?")
- **BigQuery**: Analyzes historical patterns ("What trends do we see?")

### **Analytics Tables and Their Purpose**

#### **📊 patient_health_trends** (Health Over Time)
- **What it analyzes**: Patient's health trajectory across multiple appointments
- **Key insights**: 
  - Is health improving, stable, or declining?
  - How often do they have emergencies?
  - How well are different providers coordinating care?
  - How engaged is their family?

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

## 🔄 Data Flow - How Information Moves Through the System

### **Step 1: Appointment Happens**
```
Patient books appointment in Healthie → Appointment metadata synced to PostgreSQL
```

### **Step 2: Recording (If Consented)**
```
Virtual appointment → Zoom automatically records
External appointment → Patient uses mobile app to record (with pause/resume)
```

### **Step 3: AI Processing**
```
Audio file → AI transcription → Medical analysis → Clinical insights stored in PostgreSQL
```

### **Step 4: Analytics Generation**
```
PostgreSQL data → ETL pipeline (every 15 minutes) → BigQuery raw data → Analytics processing → Insights
```

### **Step 5: Patient & Family Notifications**
```
AI detects something important → Creates actionable insight → Patient sees in app
If urgent → Family members get notified (based on their preferences)
```

---

## 🔑 Key Relationship Rules

### **One-to-One Relationships**
- Patient ↔ User Profile (every patient has exactly one profile)
- Appointment ↔ Recording Session (each appointment can have one recording)
- Appointment ↔ AI Analysis (each recorded appointment gets one analysis)

### **One-to-Many Relationships**
- Patient → Appointments (patients have multiple appointments over time)
- Recording Session → Recording Segments (mobile recordings can be paused/resumed)
- AI Analysis → Actionable Insights (one analysis creates multiple recommendations)
- Patient → Family Access (patients can invite multiple family members)

### **Many-to-Many Relationships**
- Family Member ↔ Patients (one family member can monitor multiple patients)

---

## 🎯 Why This Architecture Works

### **For Patients**
- Single app manages all healthcare (your practice + external specialists)
- AI never misses important details from any appointment
- Family stays informed without being overwhelmed

### **For Providers (Your Practice)**
- Complete picture of patient's care across all providers
- AI flags important findings from external appointments
- Automated care coordination reduces manual work

### **For Family Members**
- View-only access respects patient privacy
- Smart notifications reduce caregiver burden
- Urgent alerts ensure quick response when needed

### **For the Business**
- Scalable architecture supports growth
- HIPAA-compliant by design
- Analytics provide insights for improving care quality

---

## 🚀 Implementation Priority

### **Phase 1: Core Relationships**
1. Patient profiles and consent management
2. Appointment metadata sync with Healthie
3. Basic recording functionality

### **Phase 2: AI Processing**
1. Recording → AI analysis pipeline
2. Actionable insights generation
3. Emergency detection and alerts

### **Phase 3: Family & Analytics**
1. Family access and permissions
2. BigQuery analytics setup
3. Advanced family engagement optimization

This simplified view shows how each piece connects without getting lost in the technical details!
