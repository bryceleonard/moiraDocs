# September 2025 PRD / Execution Gameplan

**Owner**: Bryce (Product)  
**Tech Lead**: TBD  
**Version**: 1.0 (2025-09-09)  
**Timeline**: September 1–30, 2025

---

## 🎯 1) Objectives (September)

### **Primary Goal**
Deliver the core foundation to onboard patients via phone intake, authenticate against Healthie, and run the end-to-end recording → AI summary flow for both virtual (Zoom) and external (mobile) appointments at MVP quality.

### **Secondary Goal** 
Establish the design system, CI gates, and QA processes so velocity increases in October without churn.

### **Success KPIs (Exit Criteria)**
- ✅ **20 patients** fully onboarded via phone intake in staging environment
- ✅ **10 successful virtual visit recordings** processed end-to-end (Zoom → AI → notes)
- ✅ **10 successful external recordings** processed end-to-end (mobile upload → AI → summary)
- ✅ **>90% of Storybook components** pass visual regression and a11y checks
- ✅ **P0 prod readiness gaps** tracked with owners and closure dates

---

## 📋 2) Scope Definition

### **✅ In-Scope (September Must-Haves)**
- **Authentication**: Healthie OAuth integration + extended profiles
- **Phone Onboarding**: Admin portal for care coordinator workflow
- **Credential Management**: Email/SMS delivery + first-time login flow
- **Virtual Recording Pipeline**: Zoom webhook ingestion + processing
- **External Recording Pipeline**: Mobile segment upload + merge + transcription
- **AI Analysis Core**: Summary, key findings, action items with safety guardrails
- **Patient Surfaces**: Basic appointment list + AI summary views
- **Design System Foundation**: Tokens, primitives, core components in Storybook
- **CI/CD**: Lint/typecheck/tests + visual regression + a11y gates
- **Monitoring**: Pipeline observability (logs, alerts, dashboards)

### **❌ Non-Goals (Push to October+)**
- **Device Integrations**: Withings/wearables (planning only)
- **Advanced Analytics**: Provider dashboard analytics, predictive models
- **Full Family Dashboard**: Complete feature set (invitation stub only)
- **Advanced Care Coordination**: Complex provider workflow automation

---

## 📅 3) Weekly Milestones & Deliverables

### **Week 1: Foundation & Authentication (Sep 1–7)**
**Focus**: Core infrastructure and authentication

**Deliverables**:
- ✅ Healthie OAuth verification service + `patient_extended_profiles` table
- ✅ Admin Onboarding Portal scaffold (create patient, capture consent, notes)
- ✅ Credential delivery service (email + SMS templates, queued delivery)
- ✅ Design system tokens (colors, typography, spacing, shadows, motion)
- ✅ Base primitives (Text, Box, Stack, ButtonBase) in Storybook
- ✅ CI pipeline: lint, typecheck, unit tests, VRT, a11y gates

**Acceptance Criteria**:
- Healthie login on staging successfully creates/loads extended profile
- Storybook shows design tokens and ButtonBase stories pass VRT + a11y
- Admin portal can create patient record and stage credential delivery

### **Week 2: Phone Onboarding + Zoom Pipeline (Sep 8–14)**
**Focus**: Complete onboarding flow and virtual recording processing

**Deliverables**:
- ✅ Complete phone onboarding: intake → create Healthie patient → link profiles → deliver credentials
- ✅ First-time login flow: password reset + consent confirmation
- ✅ Zoom webhook endpoint + audio/transcript download + data lake storage
- ✅ AI analysis pipeline for Zoom recordings + appointment notes update
- ✅ Pipeline monitoring dashboards (errors, throughput, latency)

**Acceptance Criteria**:
- End-to-end patient onboarding: admin portal → credential delivery → first login
- Zoom appointment recorded → AI summary generated within 30 minutes in staging
- All CI gates passing + pipeline health visible in monitoring

### **Week 3: Mobile App Core + External Recording (Sep 15–21)**
**Focus**: Patient-facing mobile application and external appointment workflow

**Deliverables**:
- ✅ **Patient Homepage**: Dashboard with upcoming appointments, recent AI summaries, quick actions
- ✅ **Appointment Management**: List view, add external appointment flow, appointment details screens
- ✅ **External Recording Interface**: Start/pause/resume recording with visual feedback and upload progress
- ✅ **AI Summary Viewing**: Patient-friendly summaries with action items and key findings
- ✅ **Mobile Recording Pipeline**: Segment upload + merge service + transcription processing
- ✅ **Basic Family Invitations**: Send invitation tokens (acceptance flow stub for October)

**Acceptance Criteria**:
- Patient can navigate homepage → add external appointment → record conversation → view AI summary
- External recording: segments upload → merge → transcript → AI analysis → patient summary
- Mobile app works on iOS/Android with proper audio permissions and background upload
- Core appointment workflows validated end-to-end in staging

### **Week 4: Hardening & Launch Prep (Sep 22–30)**
**Focus**: Production readiness and security hardening

**Deliverables**:
- ✅ Error handling, retries, idempotency across all pipelines
- ✅ Security review: secrets management, PHI storage, retention policies
- ✅ Accessibility compliance on core flows + cross-browser testing
- ✅ Incident response runbook + on-call procedures
- ✅ Launch checklist + scope cut decisions documented

**Acceptance Criteria**:
- Chaos testing shows graceful pipeline recovery + proper alerting
- Security checklist signed off + PHI handling validated
- All KPIs met or clear mitigation path defined for October

---

## 🤖 4) Multi-Agent Workflow Architecture

### **Agent Specialization Strategy**
Each agent owns a specific domain with clear boundaries. All agents consume shared design tokens and API contracts to maintain consistency.

### **Agent Roster & Responsibilities**

#### **🎨 Design System Agent**
- **Owns**: Design tokens, primitive components, Storybook stories, VRT baselines
- **Outputs**: Component library, accessibility compliance, visual regression tests

#### **🏥 EHR/Integrations Agent** 
- **Owns**: Healthie authentication, GraphQL queries, Zoom webhooks, external APIs
- **Outputs**: Integration services, API client libraries, webhook processors

#### **🎙️ Recording Pipeline Agent**
- **Owns**: Mobile recording ingest, audio segment merging, transcription services
- **Outputs**: Recording processing pipeline, audio quality enhancement

#### **🧠 AI Analysis Agent**
- **Owns**: Medical conversation analysis, safety guardrails, structured output generation
- **Outputs**: AI analysis pipeline, medical summary generation, safety filters

#### **📊 Data/ETL Agent**
- **Owns**: Data lake architecture, BigQuery schemas, ETL pipelines
- **Outputs**: Data processing jobs, analytics foundations, data quality monitoring

#### **⚙️ Backend/API Agent**
- **Owns**: Application services, admin onboarding APIs, credential delivery
- **Outputs**: REST/GraphQL APIs, service orchestration, business logic

#### **📱 Mobile App Agent**
- **Owns**: Patient mobile app (Expo React Native), core user experience flows
- **Key Screens**: Homepage dashboard, appointment management, external appointment creation, recording interface, AI summary viewing, settings
- **Outputs**: iOS/Android mobile app, patient user flows, audio recording implementation

#### **💻 Web Admin Portal Agent**
- **Owns**: Care coordinator admin portal, phone onboarding interface
- **Outputs**: Web dashboard for care coordinators, patient onboarding workflow

#### **🔧 DevOps/SRE Agent**
- **Owns**: CI/CD pipelines, infrastructure, monitoring, security
- **Outputs**: Deployment automation, observability, incident response

#### **✅ QA Agent**
- **Owns**: Test planning, VRT/a11y baselines, release validation
- **Outputs**: Test suites, quality gates, release sign-off

### **Coordination Mechanisms**

#### **Agent Router (Task Triage)**
- Incoming issues automatically triaged and assigned to primary agent
- Cross-agent dependencies tracked as epic checklist items
- Conflict resolution and task reassignment

#### **Shared Contracts**
- API contracts stored in `/contracts` folder (OpenAPI/GraphQL schemas)
- Design tokens as single source of truth for all agents
- Database schemas and data models shared across agents

#### **Daily Cadence**
- **15-min async standup**: Yesterday/Today/Blockers + PR links
- **Router triage**: Resolve blockers, reassign tasks, escalate issues
- **End-of-day status**: Burndown progress, failing CI checks, unblocked work

#### **Weekly Rhythm**
- **Monday Sprint Planning**: Commit to week scope, freeze by EOD
- **Wednesday Integration Demo**: Cross-agent features demo in staging
- **Friday Release Candidate**: Tag build, smoke test, milestone decisions

#### **Quality Gates**
- **All PRs must pass**: Lint, typecheck, unit tests, VRT, a11y
- **Contract changes**: Require approval from all affected agents
- **Security checkpoints**: Week 2 (auth/data), Week 4 (full review)

---

## 📝 5) Work Breakdown Structure

### **EPIC A: Authentication & Extended Profiles**
- **A1**: Healthie OAuth verification service implementation
- **A2**: `patient_extended_profiles` schema + database migrations
- **A3**: PatientDataService for merged Healthie + extended data
- **A4**: First-time login flow + consent confirmation screens

### **EPIC B: Admin Phone Onboarding Portal**
- **B1**: Care coordinator intake form interface
- **B2**: Create Healthie patient + extended profile linking
- **B3**: Credential delivery system (email/SMS automation)
- **B4**: Initial appointment scheduling integration

### **EPIC C: Virtual Recording (Zoom) Pipeline**
- **C1**: Zoom webhook endpoint + signature verification
- **C2**: Recording download service (audio + transcripts)
- **C3**: AI analysis processing + Healthie notes integration
- **C4**: Pipeline monitoring, retries, and error handling

### **EPIC D: External Recording (Mobile) Pipeline**
- **D1**: Mobile segment upload API + cloud storage
- **D2**: Audio merge service + quality enhancement
- **D3**: Transcription processor integration
- **D4**: AI analysis + summary persistence

### **EPIC E: Mobile Patient Application**
- **E1**: Patient homepage (dashboard with upcoming appointments, recent summaries)
- **E2**: Appointment management (list, add external appointment, appointment details)
- **E3**: External appointment creation flow (provider details, date/time, preparation checklist)
- **E4**: Recording interface (start/pause/resume/stop with visual feedback)
- **E5**: AI summary viewing (appointment summaries, action items, key findings)
- **E6**: First-time login and consent confirmation screens
- **E7**: Basic settings and family invitation flow (MVP)

### **EPIC F: Design System & Quality Assurance**
- **F1**: Design tokens + primitive components
- **F2**: Core component library (Button, Input, Select, Toggle)
- **F3**: Storybook VRT + accessibility baselines
- **F4**: Cross-browser/device testing suite

### **EPIC G: DevOps & Security Infrastructure**
- **G1**: CI/CD pipeline setup + deployment automation
- **G2**: Secrets management + environment configurations
- **G3**: Monitoring, alerting, and incident runbooks
- **G4**: Security audit + HIPAA compliance checklist

---

## 🔗 6) External Dependencies & Access Requirements

### **Third-Party Service Access**
- **Healthie EHR**: API credentials + sandbox environment access
- **Zoom Healthcare**: HIPAA-compliant account + recording/webhook permissions
- **Cloud Platform**: GCP project (Storage, Functions, Pub/Sub, BigQuery)
- **Communications**: SendGrid/Twilio credentials for email/SMS delivery
- **Design Assets**: Figma workspace access + token export permissions

### **Internal Dependencies**
- **Product Requirements**: Final design system handoff + component specifications
- **Security Review**: HIPAA compliance validation + PHI handling procedures
- **Legal Approval**: Terms of service + privacy policy for patient onboarding

---

## ⚠️ 7) Risk Assessment & Mitigation Strategies

### **High-Risk Areas**

#### **🔴 Third-Party API Constraints**
- **Risk**: Healthie/Zoom API limitations or unexpected behavior
- **Mitigation**: Early spike testing + fallback manual upload workflows
- **Owner**: EHR/Integrations Agent

#### **🔴 Transcription Accuracy**
- **Risk**: Poor medical terminology transcription affecting AI analysis
- **Mitigation**: Medical-grade ASR selection + human review pathway + re-run capability
- **Owner**: Recording Pipeline Agent + AI Analysis Agent

#### **🔴 Design System Churn** 
- **Risk**: Endless pixel-perfect revision cycles slowing development
- **Mitigation**: Enforce design contract + automated VRT gates + batched changes
- **Owner**: Design System Agent

#### **🔴 PHI Data Handling Errors**
- **Risk**: HIPAA violations from improper data storage/access
- **Mitigation**: Data minimization + scoped access controls + retention policies + security audit
- **Owner**: DevOps/SRE Agent + QA Agent

#### **🔴 Timeline Compression**
- **Risk**: September timeline too aggressive for scope
- **Mitigation**: Weekly scope guards + prepared cut list + epic prioritization
- **Owner**: Product (Bryce) + Tech Lead

### **Medium-Risk Areas**
- **Performance bottlenecks** in AI analysis pipeline
- **Mobile recording quality** issues in noisy environments  
- **User adoption** challenges with phone onboarding flow
- **Integration complexity** between multiple external services

---

## ✅ 8) Exit Criteria & Success Metrics

### **Must-Have (Go/No-Go Criteria)**
- ✅ **Authentication**: Healthie login creates extended profile + token refresh works
- ✅ **Phone Onboarding**: Care coordinator can onboard patient end-to-end with credential delivery
- ✅ **Virtual Pipeline**: Zoom recording → AI analysis → notes update in <30 minutes
- ✅ **External Pipeline**: Mobile segments → merged audio → transcript → AI summary in app
- ✅ **Design System**: Design tokens + 4 core components with VRT/a11y compliance
- ✅ **DevOps**: CI/CD green + monitoring dashboards + incident runbooks

### **Performance Targets**
- **Processing Time**: <30 minutes for complete recording → summary pipeline
- **Uptime**: >99% for critical path services (auth, recording upload)
- **Quality**: >90% transcription accuracy for clear audio recordings
- **Usability**: <5 minutes for care coordinator to complete patient onboarding

---

## 🚦 9) Go/No-Go Decision Framework

### **Go Criteria**
- ≥80% of exit criteria successfully demonstrated in staging
- All P0 security risks mitigated with documented controls
- Performance targets met within acceptable tolerance
- Critical path user workflows validated end-to-end

### **Prepared Cut List (Defer to October)**
- Family invitation acceptance UI polish
- Advanced appointment filtering and search
- Sophisticated error state handling and recovery
- Rich analytics dashboard seeds beyond basic metrics

---

## 📊 10) Progress Reporting & Communication

### **Daily Updates**
- Async standup thread: Progress + blockers + PR links
- Failing CI check alerts with ownership assignment
- Cross-agent dependency status updates

### **Weekly Deliverables**
- **Wednesday**: Integration demo recording from staging environment
- **Friday**: KPI dashboard update (metrics snapshot + screenshots)
- **Friday**: Weekly retrospective + following week planning

### **Milestone Reviews**
- End-of-week milestone assessment against acceptance criteria
- Risk register updates with new issues and mitigation progress
- Stakeholder communication with demo links and metric dashboards

---

## 🎯 Next Steps for Execution

This PRD provides the framework for immediate execution once development green light is given. The multi-agent approach ensures specialized expertise while maintaining coordination through shared contracts and daily integration checkpoints.

**Ready for**:
- Agent-specific epic breakdown and issue template generation
- API contract skeleton creation in `/contracts` folder
- Initial repository setup with CI/CD pipeline templates
- Design system foundation scaffolding with Storybook integration

The plan balances ambitious September delivery with realistic scope management and quality gates to ensure sustainable development velocity beyond the initial MVP launch.
