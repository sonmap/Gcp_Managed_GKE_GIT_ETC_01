import os
from flask import Flask, jsonify, request

app = Flask(__name__)

@app.get('/healthz')
def healthz():
    return {'status': 'ok'}

@app.post('/batch/request')
def create_batch_request():
    payload = request.get_json(silent=True) or {}
    return jsonify({
        'accepted': True,
        'dag_id': payload.get('dag_id', 'sample_l2_pipeline'),
        'run_id': payload.get('run_id'),
        'message': 'PoC endpoint. Connect this service to Composer/Airflow API or your metadata DB.'
    }), 202

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', '8080')))
