1. EHR as Single Source of Truth
> Context: Your architecture uses Healthie as the master database for ALL appointments (virtual AND external)

Questions:
•  "Can we create appointments in Healthie for external specialist visits (where provider_id is null) to maintain a unified patient timeline?"
•  "What's the best practice for storing external provider information in Healthie when the provider isn't in your system?"
•  "How do you recommend handling appointment metadata that's specific to our app but needs to link to Healthie appointments?"

2. Zoom Integration & Recording Access
> Context: Your virtual practice relies on Healthie's Zoom integration for automatic recording

Critical Questions:
•  "What's the exact workflow for accessing Zoom cloud recordings through Healthie's API? Is it polling-based or webhook-driven?"
•  "Are the zoom_cloud_recording_files available immediately after a meeting ends, or is there a delay?"
•  "What's the retention policy for Zoom recordings accessed through Healthie? Can we control this?"
•  "Do you provide webhooks when recordings become available, or do we need to poll the GraphQL API?"

3. Authentication & Patient Data Integration
> Context: Your app authenticates through Healthie and extends patient profiles

Questions:
•  "What's the recommended pattern for linking Healthie patient IDs to external app user profiles?"
•  "Can we store additional patient metadata (like family member access, recording consents) that references Healthie patients?"
•  "How do you handle patient authentication for a mobile app that needs to access Healthie data?"

4. Real-Time Data Synchronization
> Context: Your AI processing needs to update Healthie with analysis results

Questions:
•  "What's the best practice for writing AI analysis results back to Healthie appointments?"
•  "Can we use the GraphQL API for real-time updates, or are there rate limits we should consider?"
•  "How do you recommend storing structured AI analysis data (JSON) in Healthie's clinical notes or custom fields?"

5. External Provider Workflow
> Context: Your patients see external specialists, and you need care coordination

Questions:
•  "How do other Healthie customers handle referrals to external specialists that aren't in the Healthie system?"
•  "Can we create appointment records for external visits to maintain care continuity?"
•  "What's the recommended approach for storing external provider communications and coordination notes?"

6. API Performance & Scalability
> Context: Your pipeline processes appointments in real-time with BigQuery analytics

Questions:
•  "What are the GraphQL API rate limits for production usage?"
•  "How do you recommend batching operations when we need to sync data to external analytics systems?"
•  "Are there webhook options for appointment status changes that could trigger our processing pipeline?"

7. HIPAA & Compliance Considerations
> Context: Your app handles patient recordings and family member access

Questions:
•  "What HIPAA compliance features does Healthie provide for patient data access by family members?"
•  "How do you recommend implementing patient consent management for AI processing of appointment recordings?"
•  "Are there built-in audit trails for patient data access that we can leverage?"

8. Integration Architecture Best Practices
> Context: Your system needs to work seamlessly with Healthie without creating conflicts

Questions:
•  "What's the recommended architecture pattern for applications that extend Healthie functionality?"
•  "Should we primarily use GraphQL subscriptions, polling, or webhooks for real-time data synchronization?"
•  "How do you handle data consistency when external systems are updating Healthie records?"

MVP-Specific Use Case Questions

Scenario-Based Questions:
1. "We have a patient who sees your virtual care provider AND external specialists. How would you architect the data flow to maintain a unified care timeline in Healthie?"
2. "When our AI analyzes an external specialist recording and detects urgent findings, what's the fastest way to alert the Healthie provider and trigger a virtual follow-up?"
3. "For family member dashboards, how do you recommend implementing view-only access to patient data with appropriate privacy controls?"

Technical Deep-Dive:
•  "Can you walk us through the actual API calls needed to retrieve Zoom recordings from a completed Healthie appointment?"
•  "What's the most efficient way to keep external analytics systems (like BigQuery) synchronized with Healthie data changes?"