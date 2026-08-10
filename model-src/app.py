import os
from flask import Flask, jsonify, request

app = Flask(__name__)

@app.get('/healthz')
def healthz():
    return {'status': 'ok', 'model_version': os.getenv('MODEL_VERSION', 'dev')}

@app.post('/predict')
def predict():
    payload = request.get_json(silent=True) or {}
    values = payload.get('values', [])
    score = float(sum(values)) / len(values) if values else 0.0
    return jsonify({'score': score, 'count': len(values)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
