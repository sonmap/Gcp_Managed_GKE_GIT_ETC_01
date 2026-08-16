from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator

from airflow.providers.google.cloud.operators.kubernetes_engine import (
    GKEStartPodOperator,
)


PROJECT_ID = "dev-com-334508"
REGION = "asia-northeast3"
CLUSTER_NAME = "gke-ai-dev"


def validate_request(**context):
    print("Validate batch request:", context["run_id"])


with DAG(
    dag_id="sample_l2_pipeline",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["managed-platform", "l2"],
) as dag:

    start = EmptyOperator(
        task_id="start"
    )

    validate = PythonOperator(
        task_id="validate_request",
        python_callable=validate_request,
    )

    execute_l2_model = GKEStartPodOperator(
        task_id="execute_l2_model",
        name="l2-model-batch",
        project_id=PROJECT_ID,
        location=REGION,
        cluster_name=CLUSTER_NAME,
        namespace="default",

        image="python:3.12-slim",

        cmds=["python", "-c"],

        arguments=[
            """
values = [10, 20, 30]
score = sum(values) / len(values)

print("===== L2 MODEL RESULT =====")
print("values =", values)
print("score  =", score)
print("===========================")
"""
        ],

        get_logs=True,
        on_finish_action="delete_pod",
    )

    end = EmptyOperator(
        task_id="end"
    )

    start >> validate >> execute_l2_model >> end
