#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-REPLACE_PROJECT_ID}"
REGION="${REGION:-asia-northeast3}"
REPO_OWNER="${REPO_OWNER:-sonmap}"
REPO_NAME="${REPO_NAME:-Gcp_Managed_GKE_GIT_ETC_01}"
TF_STATE_BUCKET="${TF_STATE_BUCKET:-REPLACE_TF_STATE_BUCKET}"
COMPOSER_ENV="${COMPOSER_ENV:-managed-airflow-dev}"
COMPOSER_BUCKET="${COMPOSER_BUCKET:-REPLACE_COMPOSER_BUCKET}"
NOTEBOOK_BUCKET="${NOTEBOOK_BUCKET:-REPLACE_NOTEBOOK_BUCKET}"
GKE_CLUSTER="${GKE_CLUSTER:-gke-ai-dev}"

if [[ "${PROJECT_ID}" == REPLACE_* ]]; then
  echo "Set PROJECT_ID before running."
  exit 1
fi

gcloud config set project "${PROJECT_ID}"

create_push_trigger() {
  local name="$1" config="$2" files="$3" substitutions="$4"
  gcloud builds triggers create github \
    --name="${name}" \
    --region="${REGION}" \
    --repo-owner="${REPO_OWNER}" \
    --repo-name="${REPO_NAME}" \
    --branch-pattern='^main$' \
    --build-config="${config}" \
    --included-files="${files}" \
    --substitutions="${substitutions}" \
    --include-logs-with-status
}

create_push_trigger \
  "cloudrun-batch-api" \
  "cloudbuild/cloudrun.yaml" \
  "cloud-run-src/batch-api/**" \
  "_REGION=${REGION},_SERVICE=batch-api,_APP_DIR=cloud-run-src/batch-api,_AR_REPO=app-images"

create_push_trigger \
  "cloudrun-analysis-backend" \
  "cloudbuild/cloudrun.yaml" \
  "cloud-run-src/analysis-backend/**" \
  "_REGION=${REGION},_SERVICE=analysis-backend,_APP_DIR=cloud-run-src/analysis-backend,_AR_REPO=app-images"

create_push_trigger \
  "gke-l2-model" \
  "cloudbuild/gke-model.yaml" \
  "model-src/**" \
  "_REGION=${REGION},_CLUSTER=${GKE_CLUSTER},_AR_REPO=model-images,_IMAGE=l2-model,_NAMESPACE=model"

create_push_trigger \
  "composer-dag-deploy" \
  "cloudbuild/composer.yaml" \
  "composer/**" \
  "_REGION=${REGION},_COMPOSER_ENV=${COMPOSER_ENV},_COMPOSER_BUCKET=${COMPOSER_BUCKET}"

create_push_trigger \
  "notebook-sync" \
  "cloudbuild/notebook.yaml" \
  "notebooks/**" \
  "_NOTEBOOK_BUCKET=${NOTEBOOK_BUCKET}"

# Terraform main/apply trigger. Keep approval enabled for infrastructure changes.
gcloud builds triggers create github \
  --name="terraform-apply" \
  --region="${REGION}" \
  --repo-owner="${REPO_OWNER}" \
  --repo-name="${REPO_NAME}" \
  --branch-pattern='^main$' \
  --build-config="cloudbuild/terraform.yaml" \
  --included-files='terraform/**' \
  --substitutions="_TF_STATE_BUCKET=${TF_STATE_BUCKET},_TF_STATE_PREFIX=managed-platform/dev,_TFVARS=envs/dev/terraform.tfvars,_APPLY=true" \
  --require-approval \
  --include-logs-with-status

echo "Triggers created. Create a separate PR plan trigger in Cloud Build Console if PR validation is required."
