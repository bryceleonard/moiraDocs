# Moira Healthcare - Visual Summary of Key Relationships

## 🎯 The Big Picture (Simple View)

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

---

## 📊 Core Relationships - Text Diagrams

### **1. Patient → Appointments → Recording → AI Analysis**

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

### **2. Patient → Family Access Permissions**

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

### **3. Recording Session → Segments (For External Appointments)**

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

### **4. AI Analysis → Patient Insights**

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

## 🔄 Data Movement (Step by Step)

### **External Appointment Flow**
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

### **Virtual Appointment Flow**
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

## 🏗️ Database Architecture (Simple View)

### **PostgreSQL - Real-Time Operations**
```
📱 MOBILE APP
    ↓ (reads/writes)
🗄️ POSTGRESQL DATABASE
    ├── Patient profiles
    ├── Appointments (all types)
    ├── Recording sessions  
    ├── AI analysis results
    ├── Patient insights
    └── Family permissions
```

### **BigQuery - Analytics Intelligence**
```
🗄️ POSTGRESQL (every 15 minutes)
    ↓ (ETL sync)
📊 BIGQUERY WAREHOUSE
    ├── Patient health trends over time
    ├── Care coordination effectiveness
    ├── Family engagement patterns
    └── Predictive health insights
    ↓ (powers)
👥 FAMILY DASHBOARD + 🤖 AI RECOMMENDATIONS
```

---

## 🔐 Security & Privacy (Simple Rules)

### **Patient Controls Everything**
```
👤 PATIENT decides:
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

## ✅ **Benefits of This Simple Structure**

### **For Development**
- Clear data relationships make coding easier
- Each table has a single, clear purpose
- Foreign keys ensure data integrity
- Permissions are explicit and auditable

### **For Patients**
- Full control over their data and privacy
- All healthcare information in one place
- AI helps them never miss important details
- Family stays informed without overwhelming them

### **For Providers**
- Complete patient health picture across all care
- AI flags important findings they might miss
- Reduced administrative burden through automation
- Better care coordination with other providers

This simplified view shows exactly how your data connects without getting overwhelmed by technical implementation details!
