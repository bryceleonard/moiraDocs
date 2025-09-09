# Warp Terminal Multi-Agent Workflows for MoiraMVP

## Terminal Session Management in Warp

### **Opening & Organizing Agent Sessions**

```bash
# Option 1: Manual Setup (4 separate Warp windows/tabs)
# Window 1: Frontend Agent
cd /Users/bryce/MoiraMVP/frontend
export AGENT_ROLE="frontend"
echo "🎨 Frontend Agent Active - React Native Development"

# Window 2: Backend Agent  
cd /Users/bryce/MoiraMVP/backend
export AGENT_ROLE="backend"
echo "⚙️ Backend Agent Active - API & Integration"

# Window 3: AI Services Agent
cd /Users/bryce/MoiraMVP/ai-services  
export AGENT_ROLE="ai-services"
echo "🧠 AI Agent Active - Medical Analysis & NLP"

# Window 4: Infrastructure Agent
cd /Users/bryce/MoiraMVP/infrastructure
export AGENT_ROLE="infrastructure" 
echo "🚀 Infrastructure Agent Active - DevOps & Cloud"
```

```bash
# Option 2: Automated Setup (using Warp workflows)
# Save as Warp workflow: "MoiraMVP Multi-Agent Setup"
function setup_moira_agents() {
  # Create 4 Warp tabs with pre-configured environments
  warp-cli create-tab --title "Frontend Agent" --directory "/Users/bryce/MoiraMVP/frontend"
  warp-cli create-tab --title "Backend Agent" --directory "/Users/bryce/MoiraMVP/backend" 
  warp-cli create-tab --title "AI Services Agent" --directory "/Users/bryce/MoiraMVP/ai-services"
  warp-cli create-tab --title "Infrastructure Agent" --directory "/Users/bryce/MoiraMVP/infrastructure"
}
```

---

## Agent-Specific Daily Workflows

### **Agent 1: Frontend Development Workflow** 🎨

#### **Morning Startup (Terminal 1)**
```bash
cd /Users/bryce/MoiraMVP/frontend
export AGENT_ROLE="frontend"

# Daily sync and status check
echo "🌅 Frontend Agent - Daily Startup"
git status
git pull origin develop

# Check for shared interface updates
echo "📋 Checking for shared type updates..."
git log --oneline ../shared/types/ --since="1 day ago"

# Start development environment
echo "🚀 Starting React Native development..."
npm install  # in case of new dependencies
npm start    # Start Expo development server

# Optional: Check backend API status
curl -s http://localhost:4000/health && echo "✅ Backend is running" || echo "❌ Backend is down"
```

#### **Feature Development Commands**
```bash
# Creating new UI components
echo "🎨 Creating new component: PatientDashboard"
mkdir -p src/components/Dashboard
touch src/components/Dashboard/PatientDashboard.tsx
touch src/components/Dashboard/index.ts

# Testing UI components
npm run test src/components/Dashboard/
npm run test:e2e -- --spec="patient-dashboard"

# Building for different platforms
npm run ios      # iOS simulator
npm run android  # Android emulator  
npm run web      # Web browser
```

#### **Integration with Other Agents**
```bash
# Getting latest API schema from Backend Agent
curl http://localhost:4000/api/schema.json > src/types/api-schema.json

# Testing AI integration with mock data
echo '{"transcript": "Patient reports chest pain"}' | \
  curl -X POST -H "Content-Type: application/json" \
  -d @- http://localhost:5000/api/analyze

# Checking infrastructure readiness
curl -s http://localhost:4000/health | jq '.services'
```

---

### **Agent 2: Backend Development Workflow** ⚙️

#### **Morning Startup (Terminal 2)**
```bash
cd /Users/bryce/MoiraMVP/backend
export AGENT_ROLE="backend"

# Daily sync and status check
echo "🌅 Backend Agent - Daily Startup"
git status
git pull origin develop

# Database and services health check
echo "🔍 Checking services health..."
npm run db:check
npm run healthie:test-connection
npm run ai-services:ping

# Start development server
echo "🚀 Starting backend services..."
npm run dev  # Starts Express server with hot reload
```

#### **API Development Commands**
```bash
# Database operations
npx prisma generate    # Generate Prisma client
npx prisma db push     # Push schema changes
npx prisma studio      # Open database GUI

# GraphQL schema development
npm run codegen        # Generate GraphQL types
npm run graphql:validate  # Validate schema

# Testing API endpoints
curl -X POST http://localhost:4000/api/appointments \
  -H "Content-Type: application/json" \
  -d '{"patientId": "123", "providerId": "456", "date": "2024-01-20T10:00:00Z"}'

# Healthie integration testing
npm run test:healthie
npm run healthie:sync-test-patient
```

#### **Service Coordination**
```bash
# Coordinating with AI Services Agent
echo "🤝 Testing AI service integration..."
curl -X POST http://localhost:5000/api/analyze-recording \
  -H "Content-Type: application/json" \
  -d @tests/fixtures/sample-appointment.json

# Frontend API contract validation
npm run test:api-contracts
npm run generate:api-docs   # Update API documentation

# Infrastructure coordination
docker-compose up -d        # Start local services
kubectl port-forward svc/postgres 5432:5432  # Connect to staging DB
```

---

### **Agent 3: AI Services Development Workflow** 🧠

#### **Morning Startup (Terminal 3)**
```bash
cd /Users/bryce/MoiraMVP/ai-services
export AGENT_ROLE="ai-services"

# Daily sync and status check  
echo "🌅 AI Services Agent - Daily Startup"
git status
git pull origin develop

# AI services health check
echo "🧠 Checking AI services..."
python -c "import openai; print('✅ OpenAI available')" || echo "❌ OpenAI setup needed"
curl -s https://api.deepgram.com/v1/listen --header "Authorization: Token $DEEPGRAM_API_KEY" \
  && echo "✅ Deepgram available" || echo "❌ Deepgram setup needed"

# Start AI processing services
echo "🚀 Starting AI services..."
npm run dev  # Start AI analysis microservice
```

#### **AI Development Commands**
```bash
# Medical terminology processing
echo "🏥 Testing medical terminology processor..."
echo "Patient reports SOB and DOE" | npm run test:terminology

# Emergency detection testing
echo "🚨 Testing emergency detection..."
echo "Patient is having severe chest pain" | npm run test:emergency-detection

# Audio analysis pipeline
echo "🎙️ Processing sample audio..."
npm run analyze:sample-audio tests/fixtures/sample-recording.wav

# Medical knowledge validation
npm run test:drug-interactions
npm run test:clinical-guidelines
npm run validate:safety-protocols
```

#### **Integration with Medical Context**
```bash
# Updating medical terminology database
npm run update:medical-terms
npm run validate:terminology-accuracy

# Testing clinical safety protocols
npm run test:safety-guardrails
npm run validate:emergency-detection

# HIPAA compliance checking
npm run audit:hipaa-compliance
npm run test:data-encryption
```

---

### **Agent 4: Infrastructure Development Workflow** 🚀

#### **Morning Startup (Terminal 4)**
```bash
cd /Users/bryce/MoiraMVP/infrastructure
export AGENT_ROLE="infrastructure"

# Daily sync and status check
echo "🌅 Infrastructure Agent - Daily Startup"  
git status
git pull origin develop

# Infrastructure health monitoring
echo "📊 Checking infrastructure status..."
aws sts get-caller-identity  # Verify AWS access
kubectl get pods            # Check Kubernetes status
docker ps                   # Check local containers

# Start infrastructure monitoring
echo "🚀 Starting infrastructure services..."
docker-compose up -d monitoring  # Start monitoring stack
```

#### **Infrastructure Commands**
```bash
# Cloud infrastructure management
terraform plan              # Review infrastructure changes
terraform apply             # Apply infrastructure updates
aws s3 ls moira-audio-storage  # Check S3 bucket

# Container management  
docker build -t moira-backend ../backend/
docker build -t moira-ai-services ../ai-services/
docker push moira-backend:latest

# Kubernetes deployments
kubectl apply -f kubernetes/
kubectl rollout status deployment/moira-backend
kubectl logs -f deployment/moira-ai-services

# Database administration
kubectl exec -it postgres-pod -- psql -U moira -d moira_db
pg_dump -h staging-db.aws.com moira_db > backups/$(date +%Y%m%d).sql
```

#### **Security & Compliance**
```bash
# HIPAA compliance checks
./scripts/hipaa-audit.sh
./scripts/encryption-validation.sh

# Security scanning
docker scan moira-backend:latest
npm audit                    # Check for vulnerable dependencies
./scripts/penetration-test.sh

# Monitoring and alerting
./scripts/setup-monitoring.sh
kubectl apply -f monitoring/prometheus/
```

---

## Cross-Agent Coordination Commands

### **Integration Testing Workflow**
Run these commands when agents need to test integration:

```bash
# Terminal 1 (Frontend): Mock backend integration
npm run test:integration -- --mock-backend
npm run e2e:staging

# Terminal 2 (Backend): API integration testing
npm run test:integration:full
npm run load-test

# Terminal 3 (AI): End-to-end AI pipeline testing
npm run test:pipeline:full
npm run benchmark:performance  

# Terminal 4 (Infrastructure): System integration testing
./scripts/integration-test.sh
kubectl run test-pod --image=moira-test --rm -it
```

### **Deployment Coordination** 
```bash
# Agent 4 coordinates deployment across all services

# Step 1: Build all services
cd /Users/bryce/MoiraMVP
./scripts/build-all-services.sh

# Step 2: Run integration tests
./scripts/run-integration-tests.sh

# Step 3: Deploy to staging
cd infrastructure/
terraform apply -var="environment=staging"
kubectl apply -f kubernetes/staging/

# Step 4: Validate deployment
./scripts/validate-staging-deployment.sh
```

### **Emergency Response Workflow**
```bash
# Production incident response - all agents coordinate

# Agent 4 (Infrastructure): Immediate response
kubectl get pods --all-namespaces | grep -v Running
./scripts/emergency-diagnostics.sh

# Agent 2 (Backend): Service diagnosis  
tail -f logs/application.log | grep ERROR
npm run health-check:detailed

# Agent 3 (AI): AI service status
./scripts/ai-service-health.sh
curl -s http://ai-services/health | jq '.status'

# Agent 1 (Frontend): User impact assessment
npm run analytics:error-rates
./scripts/frontend-health-check.sh
```

---

## Advanced Multi-Agent Patterns

### **Parallel Feature Development**
When building a complex feature that spans all agents:

```bash
# Example: Implementing Real-time Care Alerts

# Agent 1 (Frontend): Real-time UI updates
git checkout -b agent-1/real-time-alerts
# Implement WebSocket client, alert components

# Agent 2 (Backend): WebSocket server & alert logic
git checkout -b agent-2/real-time-alerts  
# Implement WebSocket server, alert routing

# Agent 3 (AI): Alert generation from analysis
git checkout -b agent-3/real-time-alerts
# Implement real-time analysis, alert triggers

# Agent 4 (Infrastructure): WebSocket scaling & monitoring
git checkout -b agent-4/real-time-alerts
# Configure WebSocket load balancing, monitoring
```

### **Testing Integration Points**
```bash
# Contract testing between agents

# Agent 1 tests Backend contracts
npm run test:api-contracts -- backend

# Agent 2 tests AI service contracts  
npm run test:ai-service-contracts

# Agent 3 tests data format contracts
npm run test:data-contracts -- backend

# Agent 4 tests deployment contracts
./scripts/test-deployment-contracts.sh
```

### **Performance Optimization Coordination**
```bash
# When performance issues span multiple services

# Agent 1: Frontend optimization
npm run analyze:bundle-size
npm run lighthouse:performance

# Agent 2: Backend optimization  
npm run profile:api-performance
npm run analyze:db-queries

# Agent 3: AI optimization
npm run benchmark:ai-processing
npm run profile:memory-usage

# Agent 4: Infrastructure optimization
kubectl top pods
./scripts/analyze-resource-usage.sh
```

---

## Success Indicators & Milestones

### **Week 1 Success Metrics**
```bash
# Agent 1: Frontend foundation
- [ ] React Native app builds successfully
- [ ] Basic navigation implemented  
- [ ] Core UI components created
- [ ] Audio recording interface mockup

# Agent 2: Backend foundation
- [ ] Express server running on port 4000
- [ ] Database connected and seeded
- [ ] Basic CRUD APIs implemented
- [ ] Healthie API connection established

# Agent 3: AI foundation  
- [ ] Audio transcription working
- [ ] Basic medical terminology processing
- [ ] OpenAI integration functional
- [ ] Safety protocols framework created

# Agent 4: Infrastructure foundation
- [ ] Docker containers for all services
- [ ] Local development environment working
- [ ] Basic AWS/GCP infrastructure provisioned
- [ ] CI/CD pipeline skeleton created
```

### **Integration Checkpoint Commands**
```bash
# Run every 2-3 days to validate integration

# Full system health check
cd /Users/bryce/MoiraMVP
./scripts/full-system-health-check.sh

# API integration validation
cd backend/ && npm run test:integration:all

# End-to-end flow testing
cd frontend/ && npm run test:e2e:critical-paths

# Performance baseline
cd infrastructure/ && ./scripts/performance-baseline.sh
```

This workflow enables efficient parallel development while maintaining coordination and integration quality. Each agent can work autonomously in their Warp terminal while contributing to the unified MoiraMVP healthcare application.
