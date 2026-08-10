import os
from flask import Flask, jsonify, request

app = Flask(__name__)

@app.get('/healthz')
def healthz():
    return {'status': 'ok'}

@app.post('/analysis/environment')
def request_environment():
    body = request.get_json(silent=True) or {}
    return jsonify({
        'accepted': True,
        'user': body.get('user', 'unknown'),
        'profile': body.get('profile', 'standard'),
        'target': 'jupyterhub',
        'message': 'PoC backend. Connect to JupyterHub/Kubernetes API with least-privilege Service Account.'
    }), 202

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', '8080')))
