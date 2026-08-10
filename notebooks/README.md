# Notebook source management

분석전문가는 JupyterHub에서 이 저장소를 clone/pull하여 Notebook 소스를 사용할 수 있습니다.

권장 정책:

- 공용 템플릿: `notebooks/samples/`
- 사용자 작업파일: 사용자 PVC/Filestore
- 대용량 데이터/결과: Cloud Storage
- 대규모 SQL 분석: BigQuery
- 비밀정보: Secret Manager, Git에 저장 금지

`cloudbuild/notebook.yaml`은 승인된 Notebook 템플릿을 GCS에 동기화하는 선택적 파이프라인입니다.
