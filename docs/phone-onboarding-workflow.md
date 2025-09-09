# Moira Healthcare - Phone-Based Onboarding Workflow

## 📞 Phone Onboarding vs. Self-Service Registration

Your client wants **phone-based onboarding**, which is actually common in healthcare, especially for:
- Senior patients (less tech-savvy)
- Premium concierge services  
- Complex medical situations requiring human assistance
- HIPAA-sensitive onboarding conversations

## 🔄 Phone Onboarding User Creation Flow

### **Current Challenge**
```
❌ IDEAL FLOW (Self-Service):
Patient downloads app → Self-registers → Healthie creates account → App syncs

✅ ACTUAL FLOW (Phone Onboarding):
Phone call → Staff creates accounts → Patient gets credentials → App login
```

### **Recommended Phone Onboarding Architecture**

## 📋 Step-by-Step Phone Onboarding Process

### **Step 1: Phone Consultation & Data Gathering**
```
📞 PHONE CALL (Care Coordinator + Prospective Patient)
├── Collect basic patient information
│   ├── Full name, DOB, address, phone, email
│   ├── Primary care concerns and goals
│   ├── Current medications and conditions
│   ├── Emergency contact information
│   └── Insurance information (if applicable)
├── Explain Moira platform and services
├── Obtain verbal consent for recording & AI analysis
├── Schedule first virtual appointment if ready
└── Collect family member information for dashboard access
```

### **Step 2: Staff Creates Accounts (Admin Portal)**

```typescript
// Admin portal workflow for care coordinators
class PatientOnboardingService {
  async createPatientFromPhoneIntake(intakeData: PhoneIntakeData): Promise<OnboardingResult> {
    
    // 1. Create patient in Healthie EHR first
    const healthiePatient = await this.healthieAPI.createPatient({
      first_name: intakeData.firstName,
      last_name: intakeData.lastName,
      email: intakeData.email,
      phone: intakeData.phone,
      date_of_birth: intakeData.dateOfBirth,
      address: intakeData.address,
      // Set initial password (patient will change on first login)
      password: this.generateSecureTemporaryPassword(),
      // Mark as phone onboarded
      custom_fields: {
        onboarding_method: 'phone',
        onboarding_date: new Date().toISOString(),
        care_coordinator: intakeData.coordinatorId
      }
    });

    // 2. Create extended profile in your database
    const extendedProfile = await this.createExtendedProfile({
      healthie_patient_id: healthiePatient.id,
      // Set consents based on phone conversation
      audio_recording_consent: intakeData.recordingConsent,
      ai_analysis_consent: intakeData.aiAnalysisConsent,
      family_sharing_consent: intakeData.familySharingConsent,
      // Phone onboarding specific fields
      onboarding_method: 'phone',
      onboarding_coordinator: intakeData.coordinatorId,
      phone_intake_notes: intakeData.intakeNotes,
      // Mark as requiring first-time login setup
      requires_password_reset: true,
      app_onboarding_completed: false
    });

    // 3. Create initial appointment if scheduled during call
    if (intakeData.initialAppointment) {
      await this.healthieAPI.createAppointment({
        patient_id: healthiePatient.id,
        provider_id: intakeData.assignedProviderId,
        appointment_type_id: intakeData.appointmentTypeId,
        date: intakeData.appointmentDate,
        contact_type: 'video_chat',
        notes: 'Initial consultation - phone onboarded patient'
      });
    }

    // 4. Set up family access if discussed
    if (intakeData.familyMembers?.length > 0) {
      await this.createFamilyAccessInvitations({
        patientId: extendedProfile.user_id,
        familyMembers: intakeData.familyMembers
      });
    }

    return {
      healthiePatient,
      extendedProfile,
      temporaryCredentials: {
        email: intakeData.email,
        temporaryPassword: healthiePatient.temporaryPassword
      },
      nextSteps: this.generateOnboardingNextSteps(intakeData)
    };
  }
}
```

### **Step 3: Patient Credential Delivery**

```
📧 EMAIL + 📱 SMS (Automated after account creation)
├── Welcome email with:
│   ├── Account credentials (email + temporary password)
│   ├── Mobile app download links (iOS/Android)
│   ├── First appointment details (if scheduled)
│   ├── Care coordinator contact information
│   └── Next steps checklist
├── SMS with:
│   ├── Welcome message
│   ├── App download link
│   └── Support phone number
└── Follow-up call scheduled (24-48 hours later)
```

### **Step 4: Patient First-Time App Login**

```typescript
// Enhanced first-time login flow
class FirstTimeLoginService {
  async handleFirstTimeLogin(credentials: LoginCredentials): Promise<FirstTimeLoginResult> {
    
    // 1. Authenticate with Healthie
    const authResult = await this.healthieAuth.login(credentials);
    
    // 2. Check if this is first-time login
    const extendedProfile = await this.getExtendedProfile(authResult.patient_id);
    
    if (extendedProfile.requires_password_reset) {
      // 3. Force password change
      return {
        requiresPasswordReset: true,
        temporaryToken: authResult.token,
        onboardingData: {
          phoneIntakeNotes: extendedProfile.phone_intake_notes,
          assignedCoordinator: extendedProfile.onboarding_coordinator,
          presetConsents: {
            recording: extendedProfile.audio_recording_consent,
            aiAnalysis: extendedProfile.ai_analysis_consent,
            familySharing: extendedProfile.family_sharing_consent
          }
        }
      };
    }
    
    // 4. Standard login flow
    return this.standardLoginFlow(authResult);
  }

  async completeFirstTimeSetup(setupData: FirstTimeSetupData): Promise<SetupResult> {
    // 1. Update password in Healthie
    await this.healthieAPI.updatePassword({
      patient_id: setupData.patientId,
      new_password: setupData.newPassword
    });
    
    // 2. Complete app onboarding
    await this.updateExtendedProfile(setupData.patientId, {
      requires_password_reset: false,
      app_onboarding_completed: true,
      first_login_date: new Date(),
      // Update any consent preferences if changed
      ...setupData.consentUpdates
    });
    
    // 3. Set up HealthKit if authorized
    if (setupData.healthkitAuthorized) {
      await this.setupHealthKitIntegration(setupData.patientId);
    }
    
    return { success: true, redirectToMain: true };
  }
}
```

## 🏗️ Required Infrastructure Changes

### **1. Admin Portal for Care Coordinators**

```typescript
// Admin dashboard for phone onboarding
interface AdminOnboardingPortal {
  // Patient creation form
  createPatientForm: {
    basicInfo: PatientBasicInfo;
    medicalInfo: MedicalIntakeInfo;
    consentPreferences: ConsentSettings;
    familyMembers: FamilyMemberInfo[];
    appointmentScheduling: InitialAppointmentInfo;
  };
  
  // Batch operations
  batchPatientCreation: (patients: PhoneIntakeData[]) => Promise<BatchResult>;
  
  // Follow-up management
  onboardingStatusTracking: {
    pendingFirstLogin: Patient[];
    completedSetup: Patient[];
    needsFollowUp: Patient[];
  };
}
```

### **2. Enhanced Database Schema**

```sql
-- Add phone onboarding fields to patient_extended_profiles
ALTER TABLE patient_extended_profiles ADD COLUMN onboarding_method 'phone' | 'self_service' DEFAULT 'self_service';
ALTER TABLE patient_extended_profiles ADD COLUMN onboarding_coordinator VARCHAR(255);
ALTER TABLE patient_extended_profiles ADD COLUMN phone_intake_notes TEXT;
ALTER TABLE patient_extended_profiles ADD COLUMN requires_password_reset BOOLEAN DEFAULT false;
ALTER TABLE patient_extended_profiles ADD COLUMN first_login_date TIMESTAMP;
ALTER TABLE patient_extended_profiles ADD COLUMN onboarding_completed_date TIMESTAMP;

-- Phone intake tracking table
CREATE TABLE phone_intake_sessions (
    intake_id UUID PRIMARY KEY,
    patient_id UUID REFERENCES patient_extended_profiles(user_id),
    coordinator_id VARCHAR(255),
    intake_date TIMESTAMP,
    call_duration_minutes INTEGER,
    intake_notes TEXT,
    follow_up_scheduled TIMESTAMP,
    follow_up_completed TIMESTAMP,
    onboarding_status 'scheduled' | 'completed' | 'requires_follow_up' | 'cancelled',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### **3. Automated Follow-Up System**

```typescript
// Automated follow-up for phone onboarded patients
class OnboardingFollowUpService {
  async scheduleFollowUps(patientId: string): Promise<void> {
    // 24 hours: Check if they've downloaded the app
    await this.scheduleTask({
      patientId,
      taskType: 'check_app_download',
      scheduledFor: addHours(new Date(), 24)
    });
    
    // 48 hours: Check if they've completed first login
    await this.scheduleTask({
      patientId, 
      taskType: 'check_first_login',
      scheduledFor: addHours(new Date(), 48)
    });
    
    // 7 days: Check if they've used recording features
    await this.scheduleTask({
      patientId,
      taskType: 'check_feature_adoption', 
      scheduledFor: addDays(new Date(), 7)
    });
  }
  
  async handleFollowUpTasks(task: FollowUpTask): Promise<void> {
    const patient = await this.getPatientStatus(task.patientId);
    
    switch (task.taskType) {
      case 'check_app_download':
        if (!patient.hasLoggedIn) {
          await this.sendAppDownloadReminder(patient);
        }
        break;
        
      case 'check_first_login':
        if (!patient.appOnboardingCompleted) {
          await this.scheduleCoordinatorCall(patient);
        }
        break;
        
      case 'check_feature_adoption':
        await this.generateAdoptionReport(patient);
        break;
    }
  }
}
```

## 📞 Phone Onboarding Best Practices

### **1. Intake Call Script**
```
PHONE ONBOARDING SCRIPT (Care Coordinator)
├── Introduction & rapport building (5 min)
├── Explain Moira platform and benefits (10 min)
├── Collect patient information (15 min)
│   ├── Demographics and contact info
│   ├── Current health concerns and goals
│   ├── Technology comfort level assessment
│   └── Family involvement preferences
├── Consent discussion (10 min)
│   ├── Audio recording consent (detailed explanation)
│   ├── AI analysis benefits and consent
│   ├── Family dashboard sharing preferences
│   └── HIPAA privacy explanations
├── Schedule initial appointment (5 min)
├── Next steps explanation (5 min)
│   ├── Credential delivery timeline
│   ├── App download and setup
│   ├── Follow-up call scheduling
└── Q&A and wrap-up (5 min)

Total call time: ~50 minutes
```

### **2. Quality Assurance**
```sql
-- Track onboarding success metrics
CREATE VIEW onboarding_success_metrics AS
SELECT 
    onboarding_method,
    COUNT(*) as total_patients,
    AVG(EXTRACT(DAYS FROM first_login_date - created_at)) as avg_days_to_first_login,
    COUNT(CASE WHEN app_onboarding_completed THEN 1 END) * 100.0 / COUNT(*) as completion_rate,
    AVG(EXTRACT(DAYS FROM onboarding_completed_date - created_at)) as avg_onboarding_duration
FROM patient_extended_profiles 
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY onboarding_method;
```

## 🎯 Benefits of Phone Onboarding

### **For Patients**
- ✅ **Human touch** for complex medical situations
- ✅ **Senior-friendly** approach (less intimidating than self-service)
- ✅ **Immediate questions answered** during intake process
- ✅ **Pre-configured preferences** based on conversation
- ✅ **Personal care coordinator relationship** established

### **For Your Business**
- ✅ **Higher conversion rates** (human assistance reduces drop-off)
- ✅ **Better data quality** (staff can ask clarifying questions)
- ✅ **Premium service perception** (white-glove onboarding)
- ✅ **Immediate relationship building** with care team
- ✅ **Complex case management** from day one

### **For Care Coordinators**
- ✅ **Complete patient context** before first appointment
- ✅ **Identified technology barriers** early
- ✅ **Family dynamics understanding** for better care
- ✅ **Consent preferences** clearly documented

## 🚀 Implementation Priority for September

### **Week 1: Admin Portal Basics**
- Care coordinator dashboard for patient creation
- Phone intake form with all required fields  
- Basic Healthie + extended profile creation flow

### **Week 2: Patient Credential System**
- Temporary password generation and delivery
- First-time login flow with forced password reset
- Email/SMS templates for credential delivery

### **Week 3: Follow-Up Automation**
- Automated follow-up task scheduling
- Phone intake session tracking
- Basic onboarding completion metrics

### **Week 4: Quality Assurance**
- Onboarding success tracking
- Care coordinator training materials
- Patient feedback collection system

This phone onboarding approach actually gives you a **competitive advantage** - most healthcare apps force self-service registration, but you're providing premium, human-assisted onboarding that's perfect for your senior patient demographic!
