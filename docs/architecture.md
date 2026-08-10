# GCP 관리형 전환 아키텍처

## 1. 배치 수행 플랫폼

기존 VM Airflow를 **Managed Airflow(Cloud Composer Gen 3)** 로 전환합니다.

```text
외부/자동화 서버
      |
      v
Cloud Run (DAG 생성/배치 제어 API) <-> Cloud SQL
      |
      v
Managed Airflow (Composer)
  |       |        |
  |       |        +-> Workflows -> GKE Autopilot / BigQuery
  |       +-> Cloud Storage (입력/중간/결과)
  +-> Cloud Run Jobs (선택)
```

DAG, `requirements.txt`, plugins는 Git에서 관리하고 Cloud Build가 검증/배포합니다. **Cloud Build는 배포 엔진이며 Airflow 실행 엔진이 아닙니다.**

## 2. L2 모델 수행 환경

- Python/Container 모델: GKE Autopilot
- SQL 대량 처리: BigQuery
- 이미지: Artifact Registry
- 입력/결과 파일: Cloud Storage
- 향후 확장: Vertex AI

## 3. 배포 / CI-CD / 인프라 관리

Git 변경이 시작점이고 Cloud Build가 실행 엔진입니다.

```text
GitHub -> Cloud Build
          |-- Cloud Run pipeline -> Artifact Registry -> Cloud Run
          |-- GKE Model pipeline -> Artifact Registry -> GKE Autopilot
          |-- Composer pipeline -> Composer DAG GCS / Environment Update
          |-- Notebook pipeline -> GCS/PVC sync (선택)
          `-- Terraform pipeline -> GCP Infra / GCS State
```

Terraform은 인프라 관리자/DevOps 전용이며 초기 구축, 추가 증설, 인프라 변경 시 사용합니다.

## 4. 분석과제 수행 환경

분석전문가는 Terraform/CI-CD를 직접 사용하지 않습니다.

```text
포털/분석전문가
      |
      v
Cloud Run (분석환경 Backend)
      |
      v
GKE Autopilot / JupyterHub
      |-- User Notebook Pod
      |-- PVC/Filestore
      |-- Cloud Storage
      `-- BigQuery
```

Notebook 소스는 GitHub에서 clone/pull하며, 필요하면 Cloud Build가 승인된 표준 Notebook을 GCS로 동기화합니다.

## 공통

IAM, Service Account, Secret Manager, Cloud Logging/Monitoring, VPC/Private IP, Serverless VPC Access, Cloud NAT/Firewall을 공통 적용합니다.
