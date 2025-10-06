# CI/CD Deployment Pipeline

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GitHub as GitHub Repo
    participant Jenkins as Jenkins CI/CD
    participant Raigad as Ansible (WSL)
    participant QA as QA Server
    participant PROD as Prod Server

    Dev->>GitHub: Push code (main / release branch)
    GitHub->>Jenkins: Webhook trigger
    Jenkins->>Jenkins: Build & publish artifacts
    Jenkins->>Raigad: Invoke Ansible playbook
    Raigad->>QA: Deploy QA build
    Raigad->>PROD: Deploy Production build (manual approval)
    Jenkins->>QA: Run smoke tests
    Jenkins->>B2: Upload build logs & artifacts
