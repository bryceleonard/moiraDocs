#!/bin/bash

# Multi-Agent Development Environment Setup for MoiraMVP
echo "🚀 Setting up Multi-Agent Development Environment for MoiraMVP"

# Create main project directories for each agent
echo "📁 Creating agent-specific directories..."

# Agent 1: Frontend & UI/UX
mkdir -p frontend/{src/{components,screens,hooks,services,utils,types},tests,assets}
mkdir -p frontend/src/components/{Recording,Calendar,Health,Common}
mkdir -p frontend/src/screens/{Dashboard,Care,Profile,Auth}

# Agent 2: Backend & API Integration
mkdir -p backend/{src/{controllers,services,models,middleware,utils},tests,database}
mkdir -p backend/src/services/{healthie,recording,external,ai}
mkdir -p backend/database/{migrations,seeds}

# Agent 3: AI & Medical Context
mkdir -p ai-services/{src/{processors,safety,analysis,compliance},tests,models}
mkdir -p ai-services/src/{medical,safety,analysis,compliance}

# Agent 4: DevOps & Infrastructure
mkdir -p infrastructure/{docker,kubernetes,terraform,scripts,monitoring}
mkdir -p infrastructure/scripts/{deployment,backup,monitoring}

# Shared resources
mkdir -p shared/{types,constants,utils,docs}
mkdir -p docs/{api,architecture,compliance,workflows}

# Create initial configuration files
echo "⚙️ Creating configuration templates..."

# Package.json templates for each service
cat > frontend/package.json << 'EOF'
{
  "name": "moira-frontend",
  "version": "1.0.0",
  "main": "expo/AppEntry.js",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web"
  },
  "dependencies": {
    "expo": "~51.0.0",
    "react": "18.2.0",
    "react-native": "0.74.0",
    "@apollo/client": "^3.8.0",
    "react-native-audio-recorder-player": "^3.6.0"
  }
}
EOF

cat > backend/package.json << 'EOF'
{
  "name": "moira-backend",
  "version": "1.0.0",
  "scripts": {
    "dev": "nodemon src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "apollo-server-express": "^3.12.0",
    "graphql": "^16.8.0",
    "@prisma/client": "^5.6.0",
    "openai": "^4.20.0"
  }
}
EOF

cat > ai-services/package.json << 'EOF'
{
  "name": "moira-ai-services",
  "version": "1.0.0",
  "scripts": {
    "dev": "nodemon src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "openai": "^4.20.0",
    "anthropic": "^0.25.0",
    "@deepgram/sdk": "^3.4.0",
    "natural": "^6.5.0"
  }
}
EOF

# Git configuration for multi-agent workflow
echo "🔧 Setting up Git workflow..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Build outputs
dist/
build/
*.tsbuildinfo

# IDE files
.vscode/
.idea/

# OS files
.DS_Store
Thumbs.db

# Logs
logs/
*.log

# Database
*.db
*.sqlite

# AI models (too large for git)
ai-services/models/*.bin
ai-services/models/*.pkl
EOF

# Create branch strategy template
cat > docs/git-workflow.md << 'EOF'
# Multi-Agent Git Workflow

## Branch Strategy
- `main`: Production-ready code
- `develop`: Integration branch for all agents
- `agent-1/frontend`: Frontend development 
- `agent-2/backend`: Backend development
- `agent-3/ai-services`: AI services development
- `agent-4/infrastructure`: DevOps and infrastructure

## Workflow Process
1. Each agent works on their designated branch
2. Regular merges to `develop` branch for integration
3. Code reviews before merging to `main`
4. Use feature branches for major features: `agent-X/feature-name`
EOF

# Create shared interfaces
echo "🔗 Creating shared interfaces..."
cat > shared/types/index.ts << 'EOF'
// Shared TypeScript interfaces for MoiraMVP

export interface Patient {
  id: string;
  name: string;
  email: string;
  phone: string;
  healthieId?: string;
}

export interface Appointment {
  id: string;
  patientId: string;
  type: 'practice' | 'external';
  providerId: string;
  providerName: string;
  date: string;
  duration: number;
  status: 'scheduled' | 'completed' | 'cancelled';
  recordingId?: string;
}

export interface Recording {
  id: string;
  appointmentId: string;
  audioFileUrl: string;
  transcript?: string;
  aiAnalysis?: AIAnalysis;
  duration: number;
  createdAt: string;
}

export interface AIAnalysis {
  chiefComplaint?: string;
  symptoms: string[];
  medications: Medication[];
  vitals: VitalSigns;
  actionItems: ActionItem[];
  emergencyFlags: EmergencyFlag[];
  patientSummary: string;
}

export interface Medication {
  name: string;
  dosage: string;
  frequency: string;
  status: 'current' | 'new' | 'changed' | 'discontinued';
}

export interface VitalSigns {
  bloodPressure?: { systolic: number; diastolic: number };
  heartRate?: number;
  temperature?: number;
  weight?: number;
  oxygenSaturation?: number;
}

export interface ActionItem {
  task: string;
  timeframe: string;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  assignedTo?: string;
}

export interface EmergencyFlag {
  type: 'cardiovascular' | 'neurological' | 'respiratory' | 'general';
  severity: 'warning' | 'critical' | 'emergency';
  description: string;
  recommendedAction: string;
}
EOF

# Create API contracts
cat > shared/constants/api-endpoints.ts << 'EOF'
// API endpoint constants for service communication

export const API_ENDPOINTS = {
  // Healthie Integration
  HEALTHIE_GRAPHQL: 'https://staging-api.gethealthie.com/graphql',
  
  // Internal Services
  BACKEND_API: process.env.BACKEND_URL || 'http://localhost:4000',
  AI_SERVICES: process.env.AI_SERVICES_URL || 'http://localhost:5000',
  
  // External Services
  DEEPGRAM_API: 'https://api.deepgram.com/v1',
  OPENAI_API: 'https://api.openai.com/v1',
} as const;

export const API_ROUTES = {
  // Appointments
  APPOINTMENTS: '/api/appointments',
  EXTERNAL_APPOINTMENTS: '/api/external-appointments',
  
  // Recordings
  RECORDINGS: '/api/recordings',
  UPLOAD_AUDIO: '/api/recordings/upload',
  
  // AI Analysis
  ANALYZE_RECORDING: '/api/ai/analyze-recording',
  EMERGENCY_CHECK: '/api/ai/emergency-check',
  
  // Healthie Integration
  HEALTHIE_SYNC: '/api/healthie/sync',
} as const;
EOF

echo "✅ Multi-agent environment setup complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Open 4 separate Warp tabs/windows"
echo "2. Navigate each to their respective agent directory:"
echo "   - Tab 1 (Frontend): cd /Users/bryce/MoiraMVP/frontend"
echo "   - Tab 2 (Backend): cd /Users/bryce/MoiraMVP/backend" 
echo "   - Tab 3 (AI Services): cd /Users/bryce/MoiraMVP/ai-services"
echo "   - Tab 4 (Infrastructure): cd /Users/bryce/MoiraMVP/infrastructure"
echo "3. Initialize each agent's development environment"
echo "4. Start parallel development using the coordination framework"
