# Git / Cloud Build / Artifact Registry 역할 비교

| 구분 | GitHub (향후 Git SSM) | Cloud Build | Artifact Registry | 별도 저장소 | Runtime |
|---|---|---|---|---|---|
| Cloud Run | 소스/Dockerfile/설정 | 검증, 이미지 빌드, 테스트, push, deploy | Docker Image | - | Cloud Run |
| GKE Model | 모델 소스/Dockerfile/K8s YAML | 검증, 이미지 빌드, 테스트, push, deploy | Docker Image | Model/Data는 GCS 가능 | GKE Autopilot |
| Composer | DAG/requirements/plugins | DAG test, GCS sync, PyPI update, plugin sync | 선택: 사내 PyPI package | Composer DAG GCS | Composer |
| Notebook | ipynb/py/sql/template | 검증, 선택적 GCS sync | 선택: custom Jupyter image | Git/PVC/GCS | JupyterHub |
| Terraform | tf/tfvars/module | fmt, validate, plan, apply | **사용 안 함** | **State=GCS** | GCP Infra |

## Artifact Registry 사용 원칙

- 필수: Cloud Run/GKE Docker/OCI 이미지
- 선택: 내부 Python(PyPI) 패키지, Jupyter Runtime 이미지
- 사용하지 않음: Terraform state/source, 일반 DAG `.py`, Notebook `.ipynb`

## Trigger 권장

- PR: 검증/테스트/terraform plan
- `main` merge: DEV 자동 배포
- PROD: 승인 Trigger 또는 별도 Release Trigger
