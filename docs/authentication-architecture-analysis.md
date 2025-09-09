# Moira Healthcare - Authentication Architecture Analysis

## 🔐 Do We Need Our Own Users Table with Healthie Auth?

**Short Answer: YES** - You need both Healthie authentication AND your own user profile table.

## 🏗️ Hybrid Authentication Architecture (Recommended)

### **Healthie Handles:**
- ✅ **Patient Authentication** (login/logout, password management)  
- ✅ **Patient Identity** (official patient records, medical data)
- ✅ **Appointments** (scheduling, provider assignments)
- ✅ **Clinical Data** (EHR, provider notes, medical history)

### **Your App Handles:**
- 🎙️ **Recording Consent Management** (audio recording permissions)
- 🤖 **AI Analysis Consent** (consent for AI processing)
- 👥 **Family Access Control** (family member permissions)
- 📱 **Mobile App Preferences** (notification settings, app behavior)
- ⌚ **Wearable Integration** (HealthKit authorization, device connections)
- 🎵 **Recording Session Management** (pause/resume, audio quality)

## 📊 Updated Database Design

### **Keep This Table (But Rename It)**

```sql
-- Rename from app_user_profiles to patient_extended_profiles
CREATE TABLE patient_extended_profiles (
    user_id UUID PRIMARY KEY,
    healthie_patient_id VARCHAR(255) UNIQUE NOT NULL,  -- Links to Healthie
    
    -- Consent management (Healthie doesn't handle this granularly)
    audio_recording_consent BOOLEAN DEFAULT false,
    ai_analysis_consent BOOLEAN DEFAULT false,
    family_sharing_consent BOOLEAN DEFAULT false,
    
    -- Mobile app specific preferences
    push_notifications_enabled BOOLEAN DEFAULT true,
    emergency_contact_preferences JSONB,
    app_onboarding_completed BOOLEAN DEFAULT false,
    preferred_notification_times TEXT[],
    
    -- Wearable & health data integration (not in Healthie)
    healthkit_authorized BOOLEAN DEFAULT false,
    authorized_data_types TEXT[],
    wearable_devices JSONB,
    
    -- Recording preferences (unique to your app)
    auto_start_recording BOOLEAN DEFAULT false,
    recording_quality_preference 'high' | 'medium' | 'low' DEFAULT 'high',
    
    -- Family dashboard settings (not in Healthie)
    family_notifications_enabled BOOLEAN DEFAULT true,
    emergency_alert_threshold 'low' | 'medium' | 'high' DEFAULT 'medium',
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

## 🔄 Authentication Flow

### **1. Patient Login Process**
```
1. Patient opens mobile app
   ↓
2. App redirects to Healthie OAuth/login
   ↓  
3. Patient authenticates with Healthie
   ↓
4. Healthie returns patient_id + auth token
   ↓
5. App checks if patient_extended_profile exists
   ↓
6. If not exists → Create extended profile with healthie_patient_id
   ↓
7. App loads patient data (Healthie + extended preferences)
```

### **2. Data Access Pattern**
```
Mobile App Request
   ↓
Check Auth Token (Healthie)
   ↓
Get healthie_patient_id from token
   ↓
Query patient_extended_profiles WHERE healthie_patient_id = ?
   ↓
Fetch additional data as needed:
   ├── Healthie GraphQL API (appointments, clinical data)
   ├── PostgreSQL (recording sessions, AI analysis, family access)
   └── BigQuery (analytics, trends)
```

## 🎯 Key Benefits of This Approach

### **✅ Single Source of Truth (Healthie)**
- Patient identity and clinical data managed by Healthie
- No duplication of medical records
- Healthie handles HIPAA compliance for medical data

### **✅ Extended Functionality (Your Tables)**
- Recording consent and preferences
- Family access permissions  
- Mobile app specific features
- AI processing consent
- Wearable integration settings

### **✅ Clean Architecture**
- Clear separation of concerns
- Healthie focuses on medical data
- Your app focuses on enhanced user experience
- Easy to maintain and scale

## 🔧 Implementation for September

### **Week 1: Authentication Setup**
```typescript
// Healthie authentication service
class HealthieAuthService {
  async authenticateUser(authToken: string): Promise<AuthResult> {
    // Verify token with Healthie
    const healthiePatient = await this.healthieAPI.getCurrentUser(authToken);
    
    // Get or create extended profile
    let extendedProfile = await this.getExtendedProfile(healthiePatient.id);
    if (!extendedProfile) {
      extendedProfile = await this.createExtendedProfile({
        healthie_patient_id: healthiePatient.id,
        // Set defaults for new users
        audio_recording_consent: false,
        ai_analysis_consent: false,
        family_sharing_consent: false
      });
    }
    
    return {
      healthiePatient,
      extendedProfile,
      isAuthenticated: true
    };
  }
}
```

### **Week 2: Data Fetching Pattern**
```typescript
// Unified patient data service
class PatientDataService {
  async getPatientData(healthiePatientId: string): Promise<PatientData> {
    // Fetch from multiple sources in parallel
    const [
      healthieData,
      extendedProfile, 
      appointments,
      recentAnalysis
    ] = await Promise.all([
      this.healthieAPI.getPatient(healthiePatientId),
      this.getExtendedProfile(healthiePatientId),
      this.getAppointments(healthiePatientId),
      this.getRecentAIAnalysis(healthiePatientId)
    ]);
    
    return {
      // Merge data from all sources
      ...healthieData,
      ...extendedProfile,
      appointments,
      recentAnalysis
    };
  }
}
```

## 🚨 Critical Questions for Healthie

Based on your questions in `healthie-questions.md`, you need to confirm:

### **Authentication & Authorization**
1. **"How do you handle patient authentication for a mobile app that needs to access Healthie data?"**
   - OAuth flow? API keys? JWT tokens?
   - Token refresh mechanism?
   - Session management?

2. **"What's the recommended pattern for linking Healthie patient IDs to external app user profiles?"**
   - Use healthie_patient_id as foreign key
   - Any constraints or best practices?

3. **"Can we store additional patient metadata that references Healthie patients?"**
   - Confirm this hybrid approach is supported
   - Any data synchronization requirements?

## 📋 Updated Architecture Summary

### **Authentication Layer**
```
HEALTHIE (Primary Auth)
├── Patient login/logout
├── Password management
├── Session management
└── Patient identity verification

YOUR APP (Extended Profile)
├── Additional consent management
├── App-specific preferences  
├── Family access permissions
├── Recording session data
└── Analytics & insights
```

### **Data Layer Relationships**
```
healthie_patient_id (from Healthie auth)
   ↓
patient_extended_profiles.healthie_patient_id (your database)
   ↓
All other tables link to patient_extended_profiles.user_id
```

## 🎯 Bottom Line

**Keep your user table but rename it to `patient_extended_profiles`**. This gives you:

- ✅ **Healthie handles authentication** (login, security, medical identity)
- ✅ **Your app handles extended functionality** (recording, family, AI consent)
- ✅ **Clean separation of concerns** (medical data vs app features)
- ✅ **Compliance** (Healthie handles medical HIPAA, you handle app privacy)
- ✅ **Scalability** (can add new app features without touching Healthie)

This hybrid approach is the best of both worlds - leveraging Healthie's medical expertise while giving you the flexibility to build innovative features on top!
