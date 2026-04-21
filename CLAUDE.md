# Claude Code 使用指南

## 环境变量

```bash
# Claude API 配置
export ANTHROPIC_API_KEY=your-api-key
export ANTHROPIC_BASE_URL=http://localhost:8080/v1/messages

# vLLM 后端 (用于 API 代理)
export VLLM_BASE_URL=http://192.168.1.3:808/v1/chat/completions

# 模型配置
export DEFAULT_MODEL=qwen3.6-35b-a3b
```

## 使用本地 API

```bash
# 设置环境变量
export ANTHROPIC_BASE_URL=http://localhost:8080/v1/messages
export ANTHROPIC_API_KEY=dummy-key-for-local

# 启动 Claude Code
claude

# 或者指定项目目录
claude /data/workspace
```

## API 调用示例

```python
import anthropic

client = anthropic.Anthropic(
    base_url="http://localhost:8080/v1",
    api_key="dummy-key-for-local"
)

response = client.messages.create(
    model="qwen3.6-35b-a3b",
    max_tokens=4096,
    messages=[
        {"role": "user", "content": "Hello!"}
    ]
)

print(response.content)
```

## 端口说明

| 端口 | 服务 |
|------|------|
| 8080 | Claude API 代理 |
| 8443 | Code-Server |
| 8888 | JupyterLab |
| 5432 | PostgreSQL |
