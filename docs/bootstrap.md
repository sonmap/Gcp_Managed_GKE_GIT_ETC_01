# Bootstrap / Cloud Build 연결 절차

## 1. 사전 준비

- GCP Project와 Billing 연결
- GitHub Repository 관리자 권한
- Cloud Build API 활성화
- GitHub App 기반 Repository 연결
- Terraform State용 Cloud Storage bucket 생성

## 2. Terraform State bucket

State는 Artifact Registry에 저장하지 않습니다. 전용 GCS bucket을 사용합니다.

```bash
export PROJECT_ID="YOUR_PROJECT_ID"
export REGION="asia-northeast3"
export TF_STATE_BUCKET="${PROJECT_ID}-tfstate"

gcloud config set project "${PROJECT_ID}"
gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com container.googleapis.com composer.googleapis.com

gcloud storage buckets create "gs://${TF_STATE_BUCKET}" \
  --location="${REGION}" \
  --uniform-bucket-level-access

gcloud storage buckets update "gs://${TF_STATE_BUCKET}" --versioning
```

## 3. GitHub -> Cloud Build

Google Cloud Console에서 Cloud Build > Repositories/Triggers에서 GitHub App을 연결합니다. 이후 `scripts/create-triggers.sh`의 변수를 수정하여 5개 파이프라인 Trigger를 생성할 수 있습니다.

## 4. 권장 Trigger 정책

| Trigger | Branch/Event | Build Config | 비고 |
|---|---|---|---|
| Cloud Run batch-api | main push | `cloudbuild/cloudrun.yaml` | `_SERVICE=batch-api` |
| Cloud Run analysis-backend | main push | `cloudbuild/cloudrun.yaml` | `_SERVICE=analysis-backend` |
| GKE model | main push | `cloudbuild/gke-model.yaml` | 모델 이미지/배포 |
| Composer | main push | `cloudbuild/composer.yaml` | DAG/requirements/plugins |
| Notebook | main push | `cloudbuild/notebook.yaml` | 선택적 표준 Notebook sync |
| Terraform plan | PR | `cloudbuild/terraform.yaml` | `_APPLY=false` |
| Terraform apply | main push + 승인 | `cloudbuild/terraform.yaml` | `_APPLY=true` |

## 5. IAM

PoC에서는 단일 Cloud Build Service Account로 시작할 수 있지만, 운영에서는 다음처럼 분리하는 것을 권장합니다.

- Cloud Run deployer SA
- GKE deployer SA
- Composer deployer SA
- Terraform infra SA

각 SA에는 필요한 최소 역할만 부여합니다. Terraform SA는 VPC/IAM/Composer/GKE/Storage 등 인프라 변경 권한을 가지므로 일반 개발자/분석전문가와 분리하십시오.

## 6. 사용자 역할

- 인프라 관리자/DevOps: Terraform, Cloud Build, IAM, Network
- 개발자: Cloud Run/Model/Composer source
- 분석전문가: Portal, Cloud Run 분석 Backend, JupyterHub/Notebook, BigQuery/GCS

분석전문가는 Terraform을 직접 실행하지 않습니다.
