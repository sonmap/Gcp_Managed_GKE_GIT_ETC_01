from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator


def validate_request(**context):
    print('Validate batch request:', context['run_id'])


def trigger_l2_model(**context):
    # PoC placeholder. Replace with Workflows/GKE/BigQuery operator or API call.
    print('Trigger L2 model execution:', context['run_id'])


with DAG(
    dag_id='sample_l2_pipeline',
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=['managed-platform', 'l2'],
) as dag:
    start = EmptyOperator(task_id='start')
    validate = PythonOperator(task_id='validate_request', python_callable=validate_request)
    execute = PythonOperator(task_id='trigger_l2_model', python_callable=trigger_l2_model)
    end = EmptyOperator(task_id='end')

    start >> validate >> execute >> end
