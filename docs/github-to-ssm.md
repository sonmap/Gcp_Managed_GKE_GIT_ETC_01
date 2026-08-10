# GitHub -> Secure Source Manager 전환 계획

현재 PoC는 GitHub를 Source of Truth로 사용합니다. Cloud Build 이하를 저장소에 종속시키지 않아 향후 Git SSM으로 쉽게 교체합니다.

## 현재

```text
GitHub -> Cloud Build -> GCP Managed Services
```

## 향후

```text
Secure Source Manager -> Cloud Build -> GCP Managed Services
```

## 유지되는 것

- `cloudbuild/*.yaml`
- Artifact Registry
- Cloud Run/GKE/Composer/JupyterHub
- Terraform 코드와 GCS State
- Service Account/IAM

## 변경되는 것

- Repository URL/Connection
- Cloud Build Trigger source connection
- 필요 시 Git clone credential/Workload Identity 설정

GitHub Actions에 CI/CD 로직을 집중하지 않고 Cloud Build YAML을 기준으로 유지하는 것이 핵심입니다.
