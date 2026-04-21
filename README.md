# Piglet Docker

AI Coding Sandbox - 基于 Pigsty 的轻量级运行时环境

## 包含组件

| 组件 | 端口 | 说明 |
|:---|:---|:---|
| Claude API 代理 | 8080 | Claude → OpenAI 格式转换 |
| Code-Server | 8443 | 浏览器版 VS Code |
| JupyterLab | 8888 | Python 交互环境 |
| PostgreSQL | 5432 | 数据库 + 向量搜索 |
| Nginx | 80 | 统一入口 |

## 快速开始

### Docker Hub

```bash
# 拉取镜像
docker pull zhubao315/piglet:latest

# 运行
docker run -d \
  --name piglet \
  -p 8080:8080 -p 8443:8443 -p 8888:8888 -p 5432:5432 \
  -e VLLM_BASE_URL=http://your-vllm-server:808/v1/chat/completions \
  -e DEFAULT_MODEL=qwen3.6-35b-a3b \
  -e POSTGRES_PASSWORD=YourPassword \
  zhubao315/piglet:latest
```

### 本地构建

```bash
# 构建
docker build -t piglet .

# 运行
docker run -d \
  --name piglet \
  -p 8080:8080 -p 8443:8443 -p 8888:8888 -p 5432:5432 \
  -v piglet-data:/data \
  zhubao315/piglet:latest
```

## 访问地址

| 服务 | 地址 |
|------|------|
| 首页 | http://localhost/code/ |
| VS Code | http://localhost/code/ |
| JupyterLab | http://localhost/jupyter/ |
| API | http://localhost/v1/messages |
| PostgreSQL | localhost:5432 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| VLLM_BASE_URL | http://192.168.1.3:808/v1/chat/completions | vLLM 服务器 |
| DEFAULT_MODEL | qwen3.6-35b-a3b | 默认模型 |
| API_PORT | 8080 | API 代理端口 |
| CODE_PORT | 8443 | Code-Server 端口 |
| JUPYTER_PORT | 8888 | JupyterLab 端口 |
| PG_PORT | 5432 | PostgreSQL 端口 |
| CODE_PASSWORD | Vibe.Coding | Code-Server 密码 |
| JUPYTER_PASSWORD | Vibe.Coding | JupyterLab 密码 |
| POSTGRES_PASSWORD | Vibe.Coding | PostgreSQL 密码 |

## 使用 Claude Code

```bash
# 进入容器
docker exec -it piglet bash

# 设置环境变量
export ANTHROPIC_BASE_URL=http://localhost:8080/v1/messages
export ANTHROPIC_API_KEY=dummy-key-for-local

# 启动 Claude Code
claude
```

## API 示例

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
```
