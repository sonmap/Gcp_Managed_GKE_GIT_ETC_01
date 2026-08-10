# Gcp_Managed_GKE_GIT_ETC_01

GCP 관리형 전환 PoC/표준구성 예제입니다. **현재 Source of Truth는 GitHub**이며, 향후 **Secure Source Manager(Git SSM)** 로 저장소만 교체할 수 있도록 Cloud Build 중심으로 구성합니다.

## 목표 아키텍처

```text
GitHub (현재) / Git SSM (향후)
          |
          v
      Cloud Build
   +------+------+-------+-------+
   |      |      |       |       |
   v      v      v       v       v
Cloud   GKE   Composer Notebook Terraform
Run    Model    DAG      Sync    Infra
 |       |
 v       v
Artifact Registry

Terraform State -> Cloud Storage(GCS)
Composer DAG     -> Composer DAG GCS
Notebook Source  -> GitHub/Git SSM, 필요 시 GCS/PVC 동기화
```

## 5개 Cloud Build 파이프라인

| No | 파이프라인 | Git 저장소 | Cloud Build | Artifact Registry | 최종 대상 |
|---|---|---|---|---|---|
| 1 | Cloud Run 빌드/배포 | `cloud-run-src/` | Build/Test/Push/Deploy | Docker Image | Cloud Run |
| 2 | GKE 모델 이미지 빌드/배포 | `model-src/` | Build/Test/Push/Deploy | Docker Image | GKE Autopilot |
| 3 | Cloud Composer DAG 배포 | `composer/` | DAG 검증/Sync/환경 Update | 선택: 내부 Python Package | Managed Airflow(Gen 3) |
| 4 | Notebook 동기화 | `notebooks/` | 검증/선택적 Sync | 선택: Jupyter Runtime Image | JupyterHub/GKE |
| 5 | Terraform 인프라 배포 | `terraform/` | fmt/validate/plan/apply | 사용 안 함 | GCP Infra + GCS State |

> Jenkins/Argo CD는 1차 구축에서 사용하지 않습니다. CI/CD는 Cloud Build를 기본으로 하고, 향후 환경 승격이 필요하면 Cloud Deploy, GKE GitOps/Drift 관리가 필요하면 Config Sync를 검토합니다.

## 디렉터리

```text
cloudbuild/                 # 5개 Cloud Build 파이프라인
cloud-run-src/              # Batch API / 분석 Backend
model-src/                  # L2 모델 컨테이너 + GKE Manifest
composer/                   # DAG / requirements / plugins
notebooks/                  # Notebook 소스/템플릿
jupyterhub/                 # JupyterHub Helm values
terraform/                  # GCP 인프라 IaC
docs/                       # 설계/운영 문서
```

## 시작 순서

1. GCP Project/Billing 준비
2. Terraform State용 GCS Bucket을 1회 Bootstrap
3. GitHub Repository를 Cloud Build에 연결
4. `terraform/` 파이프라인으로 공통 인프라 구축
5. Cloud Run → GKE Model → Composer → Notebook 순으로 Trigger 생성
6. 운영 전환 시 GitHub 연결을 Git SSM으로 교체

자세한 내용은 `docs/architecture.md`, `docs/pipeline-matrix.md`, `docs/github-to-ssm.md`를 참고하세요.
