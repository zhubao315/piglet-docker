"""
Claude API 代理 - 将 Claude 格式转换为 OpenAI 格式
"""
import os
import json
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

VLLM_BASE_URL = os.getenv('VLLM_BASE_URL', 'http://192.168.1.3:808/v1/chat/completions')
DEFAULT_MODEL = os.getenv('DEFAULT_MODEL', 'qwen3.6-35b-a3b')
API_KEY = os.getenv('API_KEY', 'dummy-key-for-local')

def claude_to_openai(claude_messages):
    """将 Claude 消息格式转换为 OpenAI 格式"""
    messages = []
    for msg in claude_messages:
        role = msg.get('role', 'user')
        if role == 'user':
            role = 'user'
        elif role == 'assistant':
            role = 'assistant'
        else:
            role = 'user'
        
        content = msg.get('content', '')
        if isinstance(content, list):
            text_parts = [c.get('text', '') for c in content if c.get('type') == 'text']
            content = '\n'.join(text_parts)
        
        messages.append({'role': role, 'content': content})
    return messages

@app.route('/v1/messages', methods=['POST'])
def claude_messages():
    """Claude Messages API 端点"""
    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Missing or invalid Authorization header'}), 401
    
    data = request.get_json() or {}
    messages = data.get('messages', [])
    model = data.get('model', DEFAULT_MODEL)
    max_tokens = data.get('max_tokens', 4096)
    temperature = data.get('temperature', 1.0)
    
    # 转换为 OpenAI 格式
    openai_messages = claude_to_openai(messages)
    
    # 调用 vLLM
    openai_payload = {
        'model': model,
        'messages': openai_messages,
        'max_tokens': max_tokens,
        'temperature': temperature
    }
    
    try:
        response = requests.post(
            f'{VLLM_BASE_URL}',
            headers={
                'Authorization': f'Bearer {API_KEY}',
                'Content-Type': 'application/json'
            },
            json=openai_payload,
            timeout=120
        )
        result = response.json()
        
        # 转换回 Claude 格式
        choice = result.get('choices', [{}])[0]
        assistant_message = choice.get('message', {})
        
        return jsonify({
            'id': f'msg_{os.urandom(12).hex()}',
            'type': 'message',
            'role': 'assistant',
            'content': [{
                'type': 'text',
                'text': assistant_message.get('content', '')
            }],
            'model': model,
            'stop_reason': choice.get('finish_reason', 'end_turn'),
            'stop_sequence': None,
            'usage': result.get('usage', {
                'input_tokens': 0,
                'output_tokens': 0
            })
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/v1/chat/completions', methods=['POST'])
def chat_completions():
    """OpenAI 兼容的 Chat Completions 端点"""
    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Missing or invalid Authorization header'}), 401
    
    data = request.get_json() or {}
    messages = data.get('messages', [])
    model = data.get('model', DEFAULT_MODEL)
    max_tokens = data.get('max_tokens', 4096)
    temperature = data.get('temperature', 1.0)
    
    try:
        response = requests.post(
            f'{VLLM_BASE_URL}',
            headers={
                'Authorization': f'Bearer {API_KEY}',
                'Content-Type': 'application/json'
            },
            json={
                'model': model,
                'messages': messages,
                'max_tokens': max_tokens,
                'temperature': temperature
            },
            timeout=120
        )
        return jsonify(response.json())
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    """健康检查"""
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    port = int(os.getenv('API_PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
