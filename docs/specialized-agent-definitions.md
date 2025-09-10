# Specialized Agent Definitions for Moira Platform

**Date**: September 9, 2025  
**Purpose**: Define specialized AI agents with specific domain expertise for complex workflows  
**Status**: Ready for implementation

---

## 🎯 Agent Specialization Philosophy

### **Why Specialized Agents?**
The Moira platform has several complex, multi-step workflows that require:
- **Domain expertise** in healthcare, audio processing, and user experience
- **Context retention** across multiple interactions within a workflow
- **Specialized knowledge** of medical terminology, HIPAA compliance, and clinical workflows
- **Workflow orchestration** between different systems (Healthie, Zoom, mobile apps)

### **Agent Coordination Model**
- **Specialized agents** handle complex domain-specific workflows
- **General agents** handle standard development tasks
- **Router agent** triages tasks and delegates to appropriate specialists
- **Shared contracts** ensure consistent data flow between agents

---

## 👨‍⚕️ 1. Clinical Recording Workflow Agent

### **Primary Responsibilities**
- **Virtual recording pipeline** (Zoom webhook → AI analysis → Healthie integration)
- **External recording pipeline** (mobile upload → segment merging → transcription)
- **Medical conversation analysis** with safety guardrails
- **Clinical data integration** with Healthie EHR
- **Healthcare compliance** (HIPAA, medical data handling)

### **Specialized Knowledge Domains**
- Healthcare data flow patterns and medical terminology
- Audio processing and enhancement techniques for clinical settings
- HIPAA-compliant data handling and retention policies
- Medical conversation analysis and safety guardrails
- Integration patterns with EHR systems (specifically Healthie)

### **Key Tasks & Workflows**

#### **Virtual Recording Processing**
```typescript
interface VirtualRecordingWorkflow {
  // Input: Zoom webhook notification
  validateZoomWebhook(webhook: ZoomWebhook): boolean;
  downloadRecordingFiles(meetingId: string): Promise<RecordingFiles>;
  storeInDataLake(files: RecordingFiles): Promise<StoragePaths>;
  extractMedicalContext(appointmentId: string): Promise<MedicalContext>;
  analyzeConversation(audio: AudioFile, context: MedicalContext): Promise<ClinicalAnalysis>;
  updateHealthieRecord(appointmentId: string, analysis: ClinicalAnalysis): Promise<void>;
  generatePatientSummary(analysis: ClinicalAnalysis): Promise<PatientSummary>;
  triggerNotifications(analysis: ClinicalAnalysis): Promise<void>;
}
```

#### **External Recording Processing**
```typescript
interface ExternalRecordingWorkflow {
  // Input: Mobile app recording upload
  validateRecordingUpload(upload: RecordingUpload): Promise<boolean>;
  mergeRecordingSegments(segments: AudioSegment[]): Promise<MergedAudio>;
  enhanceAudioQuality(audio: MergedAudio): Promise<EnhancedAudio>;
  generateMedicalTranscript(audio: EnhancedAudio): Promise<MedicalTranscript>;
  analyzeMedicalConversation(transcript: MedicalTranscript, context: AppointmentContext): Promise<ClinicalAnalysis>;
  validateClinicalFindings(analysis: ClinicalAnalysis): Promise<ValidatedAnalysis>;
  createActionableInsights(analysis: ValidatedAnalysis): Promise<ActionItem[]>;
  updatePatientRecord(analysis: ValidatedAnalysis): Promise<void>;
}
```

### **Success Metrics**
- **Processing accuracy**: >95% successful recording → analysis pipeline completion
- **Medical safety**: 100% compliance with safety guardrails (no medical advice)
- **Processing speed**: <30 minutes from recording completion to patient summary
- **Data integrity**: 100% HIPAA-compliant data handling and retention

### **Agent Interfaces**
- **Input contracts**: Zoom webhooks, mobile recording uploads, appointment contexts
- **Output contracts**: Clinical analyses, patient summaries, action items, EHR updates
- **Dependencies**: Audio Processing Agent, Data Pipeline Agent, Notification Agent

---

## 📱 2. Patient Experience Orchestration Agent

### **Primary Responsibilities**
- **External appointment workflow** (creation → preparation → recording → follow-up)
- **Patient onboarding journey** (phone intake → credential delivery → first login)
- **Mobile app user experience** flows and state management
- **Patient notifications and reminders** across the entire healthcare journey
- **Family member experience** and access management

### **Specialized Knowledge Domains**
- Healthcare patient journey design and psychology
- Mobile app UX patterns for healthcare applications  
- Patient communication and engagement strategies
- Accessibility and inclusive design for diverse patient populations
- Healthcare literacy and patient education approaches

### **Key Tasks & Workflows**

#### **External Appointment Journey**
```typescript
interface ExternalAppointmentJourney {
  // Patient creates external appointment
  validateAppointmentDetails(details: ExternalAppointmentInput): Promise<ValidationResult>;
  createAppointmentRecord(details: ValidatedAppointment): Promise<AppointmentRecord>;
  generatePreparationChecklist(appointment: AppointmentRecord): Promise<PreparationChecklist>;
  scheduleSmartReminders(appointment: AppointmentRecord): Promise<ReminderSchedule>;
  
  // Pre-appointment preparation
  trackPreparationProgress(appointmentId: string, checklist: PreparationChecklist): Promise<ProgressStatus>;
  generateContextualTips(appointment: AppointmentRecord): Promise<PreparationTips>;
  prepareRecordingInterface(appointmentId: string): Promise<RecordingConfig>;
  
  // Post-appointment follow-up
  processRecordingCompletion(appointmentId: string): Promise<void>;
  generateFollowUpActions(analysis: ClinicalAnalysis): Promise<FollowUpPlan>;
  scheduleFollowUpReminders(followUpPlan: FollowUpPlan): Promise<void>;
  updatePatientJourney(appointmentId: string, outcomes: AppointmentOutcome): Promise<void>;
}
```

#### **Phone Onboarding Journey**
```typescript
interface PhoneOnboardingJourney {
  // Coordination with care coordinator
  prepareIntakeSession(patientInfo: PatientBasicInfo): Promise<IntakePreparation>;
  validateConsentCollection(consents: ConsentCollection): Promise<ConsentValidation>;
  createExtendedProfile(intakeData: PhoneIntakeData): Promise<ExtendedProfile>;
  
  // Credential delivery and setup
  generateSecureCredentials(patientId: string): Promise<PatientCredentials>;
  deliverCredentialsMultiChannel(credentials: PatientCredentials, preferences: ContactPreferences): Promise<DeliveryConfirmation>;
  trackCredentialUsage(patientId: string): Promise<UsageTracking>;
  
  // First-time app experience
  personalizeFirstLogin(patientId: string, intakeData: PhoneIntakeData): Promise<PersonalizedExperience>;
  validateConsentConfirmation(patientId: string, appConsents: AppConsent[]): Promise<ConsentStatus>;
  completeOnboardingJourney(patientId: string): Promise<OnboardingCompletion>;
}
```

#### **Family Access Management**
```typescript
interface FamilyAccessWorkflow {
  // Family invitation process
  validateFamilyInvitation(invitation: FamilyInvitationRequest): Promise<ValidationResult>;
  createFamilyAccessRecord(invitation: ValidatedInvitation): Promise<FamilyAccessRecord>;
  generateInvitationDelivery(accessRecord: FamilyAccessRecord): Promise<InvitationDelivery>;
  
  // Family member onboarding
  processInvitationAcceptance(invitationId: string, familyMemberInfo: FamilyMemberInfo): Promise<FamilyMemberAccount>;
  configureFamilyPermissions(familyMemberId: string, permissions: FamilyPermissions): Promise<PermissionConfig>;
  generateFamilyDashboard(familyMemberId: string): Promise<FamilyDashboardConfig>;
  
  // Ongoing family engagement
  determineFamilyNotifications(patientEvent: PatientEvent, familyMembers: FamilyMember[]): Promise<NotificationPlan>;
  trackFamilyEngagement(familyMemberId: string): Promise<EngagementMetrics>;
  optimizeFamilyExperience(familyMemberId: string, engagement: EngagementMetrics): Promise<ExperienceOptimization>;
}
```

### **Success Metrics**
- **Journey completion**: >85% completion rate for phone onboarding → first recording
- **User satisfaction**: >4.5/5 rating for patient experience flows
- **Engagement**: >70% of patients complete external appointment preparation checklist
- **Family adoption**: >60% of invited family members accept and actively use dashboard

### **Agent Interfaces**
- **Input contracts**: Patient actions, appointment events, family interactions
- **Output contracts**: Journey states, personalized experiences, notification triggers
- **Dependencies**: Notification Agent, Clinical Recording Agent, Care Coordination Agent

---

## 👨‍👩‍👧‍👦 3. Care Coordination Intelligence Agent

### **Primary Responsibilities**
- **Cross-appointment analysis** (virtual + external appointment correlation)
- **Care gap identification** and proactive intervention recommendations  
- **Provider communication** facilitation and care team coordination
- **Family engagement optimization** and caregiver burden management
- **Emergency detection** and escalation protocols

### **Specialized Knowledge Domains**
- Healthcare care coordination best practices and clinical pathways
- Medical decision-making support and care gap analysis
- Family dynamics in healthcare and caregiver psychology
- Provider workflow integration and communication patterns
- Emergency protocols and clinical escalation procedures

### **Key Tasks & Workflows**

#### **Cross-Appointment Intelligence**
```typescript
interface CrossAppointmentAnalysis {
  // Correlation analysis
  identifyAppointmentRelationships(patientId: string, timeframe: DateRange): Promise<AppointmentCorrelations>;
  detectCareGaps(appointments: AppointmentCorrelations, clinicalHistory: ClinicalHistory): Promise<CareGap[]>;
  analyzeTreatmentConsistency(analyses: ClinicalAnalysis[]): Promise<ConsistencyAnalysis>;
  identifyMedicationConflicts(medications: MedicationHistory[]): Promise<MedicationConflict[]>;
  
  // Proactive care recommendations
  generateCareCoordinationPlan(patient: PatientProfile, careGaps: CareGap[]): Promise<CareCoordinationPlan>;
  prioritizeCareActions(careActions: CareAction[]): Promise<PrioritizedCareActions>;
  scheduleFollowUpCoordination(careActions: PrioritizedCareActions): Promise<CoordinationSchedule>;
  
  // Provider communication facilitation
  prepareProviderCommunications(coordinationPlan: CareCoordinationPlan): Promise<ProviderCommunications>;
  trackCoordinationOutcomes(communicationId: string): Promise<CoordinationOutcome>;
}
```

#### **Family Engagement Optimization**
```typescript
interface FamilyEngagementIntelligence {
  // Family dynamic analysis
  assessFamilyEngagementPatterns(familyId: string): Promise<FamilyEngagementProfile>;
  identifyCaregiver Burden(familyMembers: FamilyMember[], patientNeeds: PatientNeed[]): Promise<CaregiverBurdenAssessment>;
  optimizeNotificationFrequency(familyMember: FamilyMember, engagement: EngagementHistory): Promise<NotificationOptimization>;
  
  // Family communication coordination
  generateFamilyUpdates(patientEvents: PatientEvent[], familyPreferences: FamilyPreferences): Promise<FamilyUpdate[]>;
  facilitateFamilyDecisionMaking(decision: MedicalDecision, familyMembers: FamilyMember[]): Promise<DecisionSupport>;
  coordinateEmergencyResponse(emergency: EmergencyEvent, familyMembers: FamilyMember[]): Promise<EmergencyCoordination>;
  
  // Long-term family support
  trackFamilyCaregivingHealth(familyMembers: FamilyMember[]): Promise<CaregiverWellnessMetrics>;
  recommendFamilySupportResources(burden: CaregiverBurdenAssessment): Promise<SupportRecommendations>;
}
```

#### **Emergency Detection & Escalation**
```typescript
interface EmergencyIntelligence {
  // Real-time emergency detection
  analyzeForEmergencyIndicators(analysis: ClinicalAnalysis): Promise<EmergencyAssessment>;
  validateEmergencyCredibility(emergency: EmergencyAssessment, patientHistory: ClinicalHistory): Promise<EmergencyValidation>;
  determineEscalationProtocol(emergency: ValidatedEmergency): Promise<EscalationProtocol>;
  
  // Emergency response coordination
  notifyPrimaryProvider(emergency: ValidatedEmergency, provider: ProviderInfo): Promise<ProviderNotification>;
  alertFamilyMembers(emergency: ValidatedEmergency, familyMembers: FamilyMember[]): Promise<FamilyAlert[]>;
  documentEmergencyResponse(emergency: ValidatedEmergency, responses: EmergencyResponse[]): Promise<EmergencyRecord>;
  
  // Follow-up coordination
  trackEmergencyOutcome(emergencyId: string): Promise<EmergencyOutcome>;
  generateEmergencyLessonsLearned(outcome: EmergencyOutcome): Promise<ProcessImprovement>;
}
```

### **Success Metrics**
- **Care gap detection**: >90% accuracy in identifying clinically relevant care gaps
- **Emergency response**: <5 minutes from detection to family/provider notification
- **Coordination effectiveness**: >80% of care coordination recommendations acted upon
- **Family satisfaction**: >85% family satisfaction with communication and engagement

### **Agent Interfaces**
- **Input contracts**: Clinical analyses, appointment data, family interaction data
- **Output contracts**: Care coordination plans, family engagement strategies, emergency protocols
- **Dependencies**: Clinical Recording Agent, Patient Experience Agent, Notification Agent

---

## 🔔 4. Intelligent Notification Agent

### **Primary Responsibilities**
- **Smart notification orchestration** across SMS, email, push, and in-app channels
- **Personalized messaging** based on patient preferences, health literacy, and engagement patterns
- **Multi-stakeholder communication** (patient, family, providers, care coordinators)
- **Notification fatigue prevention** and engagement optimization
- **HIPAA-compliant messaging** with appropriate privacy controls

### **Specialized Knowledge Domains**
- Healthcare communication best practices and patient engagement psychology
- Multi-channel messaging optimization and personalization algorithms
- Health literacy assessment and accessible communication design
- HIPAA-compliant messaging and privacy-preserving communication
- Behavioral psychology and notification timing optimization

### **Key Tasks & Workflows**

#### **Intelligent Message Orchestration**
```typescript
interface IntelligentNotificationSystem {
  // Message planning and personalization
  analyzePatientCommunicationProfile(patientId: string): Promise<CommunicationProfile>;
  determineOptimalMessaging(event: NotificationTrigger, profile: CommunicationProfile): Promise<MessagePlan>;
  personalizeMessageContent(message: BaseMessage, patientProfile: PatientProfile): Promise<PersonalizedMessage>;
  
  // Multi-channel delivery optimization
  selectOptimalChannels(message: PersonalizedMessage, preferences: CommunicationPreferences): Promise<ChannelSelection>;
  scheduleDeliveryTiming(message: PersonalizedMessage, patientBehavior: BehaviorProfile): Promise<DeliverySchedule>;
  coordinateMultiStakeholderMessaging(event: CareEvent, stakeholders: Stakeholder[]): Promise<MessageCoordination>;
  
  // Engagement optimization
  trackMessageEngagement(messageId: string): Promise<EngagementMetrics>;
  optimizeNotificationFrequency(patientId: string, engagementHistory: EngagementHistory): Promise<FrequencyOptimization>;
  preventNotificationFatigue(patientId: string, notificationHistory: NotificationHistory): Promise<FatiguePreventionStrategy>;
}
```

#### **Healthcare-Specific Messaging**
```typescript
interface HealthcareMessagingIntelligence {
  // Medical communication adaptation
  assessHealthLiteracy(patientId: string, communicationHistory: CommunicationHistory): Promise<HealthLiteracyProfile>;
  adaptMedicalContent(medicalInfo: MedicalContent, literacyProfile: HealthLiteracyProfile): Promise<AdaptedContent>;
  generatePatientFriendlyExplanations(clinicalFindings: ClinicalAnalysis): Promise<PatientExplanation>;
  
  // Emergency and urgent messaging
  classifyMessageUrgency(event: CareEvent, clinicalContext: ClinicalContext): Promise<UrgencyClassification>;
  generateEmergencyNotifications(emergency: EmergencyEvent, recipients: Recipient[]): Promise<EmergencyNotification[]>;
  coordinateUrgentFamilyAlerts(urgent: UrgentEvent, familyMembers: FamilyMember[]): Promise<FamilyAlertCoordination>;
  
  // Privacy-preserving family communications
  determineFamilyMessagePrivacy(content: MessageContent, familyPermissions: FamilyPermissions): Promise<PrivacyFilteredMessage>;
  generateFamilyAppropriateSummaries(patientUpdate: PatientUpdate, familyMember: FamilyMember): Promise<FamilySummary>;
}
```

### **Success Metrics**
- **Message engagement**: >70% read rate for important health notifications
- **Response optimization**: >60% improvement in response time vs. generic messaging
- **Fatigue prevention**: <5% unsubscribe rate from health communications
- **Family satisfaction**: >80% family satisfaction with communication frequency and content

### **Agent Interfaces**
- **Input contracts**: Care events, patient actions, emergency alerts, family interactions
- **Output contracts**: Personalized messages, delivery schedules, engagement analytics
- **Dependencies**: Patient Experience Agent, Care Coordination Agent, Clinical Recording Agent

---

## 🤖 Agent Coordination Framework

### **Router Agent Responsibilities**
- **Task triage**: Route complex workflows to specialized agents
- **Workflow orchestration**: Coordinate multi-agent workflows
- **Contract enforcement**: Ensure proper data flow between agents
- **Conflict resolution**: Handle agent boundary disputes and dependencies

### **Inter-Agent Communication Patterns**
```typescript
// Example: External appointment recording workflow
Router receives: "Patient uploaded external recording"
   ↓
Route to: Clinical Recording Workflow Agent
   ↓ (processing complete)
Notify: Patient Experience Orchestration Agent (for follow-up journey)
   ↓ (parallel)
Notify: Care Coordination Intelligence Agent (for cross-appointment analysis)
   ↓ (if insights found)
Notify: Intelligent Notification Agent (for patient/family updates)
```

### **Shared Contracts & Data Models**
- **Patient Profile**: Unified patient data structure used by all agents
- **Clinical Analysis**: Standard output format from all recording analyses
- **Care Event**: Common event structure for triggering agent workflows
- **Notification Trigger**: Standard input for all messaging decisions

---

## 📋 Implementation Roadmap

### **Phase 1: Core Specialized Agents (Week 1-2)**
- Clinical Recording Workflow Agent
- Patient Experience Orchestration Agent  
- Basic Router Agent for task delegation

### **Phase 2: Intelligence & Coordination (Week 3-4)**
- Care Coordination Intelligence Agent
- Intelligent Notification Agent
- Advanced router orchestration patterns

### **Phase 3: Optimization & Learning (October+)**
- Agent performance optimization
- Cross-agent learning and improvement
- Advanced workflow automation

This specialized agent architecture ensures that complex healthcare workflows are handled by agents with deep domain expertise while maintaining coordination through clear contracts and orchestration patterns.
