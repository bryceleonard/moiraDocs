# MoiraMVP - Hybrid Healthcare Platform

## 🎯 Project Overview

MoiraMVP is a revolutionary hybrid healthcare coordination platform that unifies virtual practice appointments with external specialist care through AI-powered analysis and family coordination.

### Core Capabilities
- **Premium Phone Onboarding**: Human-assisted enrollment with care coordinator intake calls
- **Virtual Practice Integration**: Full Healthie EHR integration with Zoom recording
- **External Care Coordination**: Mobile recording and AI analysis of specialist visits  
- **Family Dashboard**: View-only family access with intelligent notifications
- **AI Health Intelligence**: Medical conversation analysis and predictive insights
- **Cross-Provider Care Coordination**: Unified health timeline across all providers

## 📊 Data Architecture & ERDs

Our comprehensive data architecture supports real-time healthcare operations while providing powerful analytics for patient insights and family coordination.

### 📖 **Start Here: Simplified Explanations**
- 🔗 [**Data Relationships Simplified**](docs/data-relationships-simplified.md) - **Plain English explanation of core relationships**
- 📊 [**Visual Summary of Key Relationships**](docs/relationships-visual-summary.md) - **Text diagrams and examples**
- 🌊 [**Data Lake Simplified**](docs/data-lake-simplified.md) - **What the data lake does (plain English)**
- 📞 [**Phone Onboarding Workflow**](docs/phone-onboarding-workflow.md) - **Premium human-assisted patient enrollment**
- 🎯 [**Phone Onboarding Flow Guide**](docs/phone-onboarding-flow-simple.md) - **Step-by-step visual guide**

### 🗄️ **Technical ERD Documentation**
- 🗄️ [PostgreSQL Operational Database ERD](docs/moira-postgresql-erd.md) - Real-time application operations and patient data management
- 📈 [BigQuery Analytics Warehouse ERD](docs/moira-bigquery-erd.md) - Healthcare intelligence and predictive analytics
- 🏗️ [Complete System Architecture ERD](docs/moira-complete-data-architecture-erd.md) - End-to-end data flow across all systems

## 📋 Documentation Organization

### **Primary Architecture Documents**
- 📄 [**DOCUMENT_ORGANIZATION.md**](DOCUMENT_ORGANIZATION.md) - Complete documentation overview and BitQuery→BigQuery migration summary
- 📄 [**Complete Data Architecture ERD**](docs/moira-complete-data-architecture-erd.md) - **Master technical reference**

### **User & Technical Requirements**
- 📄 [Hybrid Care User Stories](docs/hybrid-care-user-stories.md) - User stories driving system requirements
- 📄 [Medical AI Context Requirements](docs/medical-ai-context-requirements.md) - AI safety frameworks and medical context
- 📄 [Hybrid Healthcare App Architecture](docs/hybrid-healthcare-app-architecture.md) - Mobile app and practice integration architecture
- 🔐 [Authentication Architecture Analysis](docs/authentication-architecture-analysis.md) - Healthie auth + extended profiles
- 📄 [Multi-Agent Coordination Framework](docs/multi-agent-coordination-framework.md) - AI agent coordination patterns
- 📄 [Healthie + Zoom Integration Research](docs/healthie-zoom-integration-research.md) - Technical integration specifications

### **Implementation Planning**
- 📄 [Healthie Questions](healthie-questions.md) - Key technical questions for Healthie integration
- 📁 [Archive](archive/) - Historical architecture documents and migration references

## 🔧 Technical Stack

### **Infrastructure**
- **Cloud Platform**: Google Cloud Platform (HIPAA-compliant)
- **Operational Database**: PostgreSQL with real-time operations
- **Analytics Warehouse**: BigQuery with healthcare intelligence functions
- **Data Processing**: Cloud Functions, Cloud Run, Dataflow ETL pipelines

### **External Integrations**  
- **EHR System**: Healthie (single source of truth)
- **Virtual Meetings**: Zoom Healthcare API with automatic recording
- **Mobile Recording**: iOS/Android apps with pause/resume functionality
- **Wearable Data**: HealthKit, Oura, Fitbit, Withings integrations
- **Communications**: Twilio SMS/voice for patient and family notifications

### **AI & Analytics**
- **Medical AI Analysis**: Claude/OpenAI for conversation analysis
- **Speech Processing**: Deepgram/AssemblyAI for medical transcription
- **Predictive Analytics**: BigQuery ML for health trend analysis
- **Family Intelligence**: Caregiver burden analysis and notification optimization

## 🚀 September 2025 Implementation Status

### ✅ **Architecture Complete**
- [x] Complete database schemas (PostgreSQL + BigQuery)
- [x] Data processing pipelines with BigQuery analytics integration
- [x] API specifications for Healthie, Zoom, mobile recording
- [x] Family dashboard architecture with caregiver analytics
- [x] HIPAA compliance framework
- [x] Implementation roadmap and timeline

### 🏗️ **Ready for Development**
- [x] **Phone Onboarding System**: Care coordinator dashboard and patient credential delivery
- [x] **Foundation & Core Build**: PostgreSQL setup, Healthie integration, mobile recording
- [x] **AI Processing Pipeline**: Medical conversation analysis with safety guardrails  
- [x] **Analytics Intelligence**: BigQuery functions for health trends and family insights
- [x] **Family Dashboard**: View-only family access with intelligent notifications

## 🔐 Security & Compliance

### **HIPAA Compliance**
- **Data Encryption**: AES-256 at rest, TLS 1.3 in transit
- **Access Controls**: Role-based permissions with audit trails
- **BAA Coverage**: Business Associate Agreements with all vendors
- **Data Minimization**: Granular family access controls
- **Audit Logging**: Complete data access and modification tracking

### **Privacy by Design**
- **Patient Consent Management**: Explicit opt-in for all data processing
- **Family Permission Controls**: Patients control exactly what family can see
- **Emergency Protocol**: Automated urgent notifications with privacy safeguards
- **Right to Erasure**: Complete data deletion capabilities

## 📞 Contact & Development

This comprehensive architecture provides the foundation for revolutionizing healthcare coordination through AI-powered insights and family engagement while maintaining the highest standards of security and compliance.

For technical questions about the architecture or implementation, refer to the detailed ERD documentation in the `docs/` directory.
