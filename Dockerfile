# Piglet Docker 镜像
# AI Web Coding 运行时沙箱
# 整合 PostgreSQL + VS Code + JupyterLab + Claude Code

FROM ubuntu:22.04

# ============================================================
# 基础配置
# ============================================================
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/vibe
ENV PIGSTY_HOME=/opt/piglet

# vLLM 后端配置
ENV VLLM_BASE_URL=http://192.168.1.3:808/v1/chat/completions
ENV DEFAULT_MODEL=qwen3.6-35b-a3b
ENV ADDITIONAL_MODELS=gemma-4-31b-it
ENV API_PORT=8080
ENV API_KEY=dummy-key-for-local

# Code-Server 配置
ENV CODE_PORT=8443
ENV CODE_PASSWORD=Vibe.Coding

# JupyterLab 配置
ENV JUPYTER_PORT=8888
ENV JUPYTER_PASSWORD=Vibe.Coding

# Claude Code 配置
ENV ANTHROPIC_API_KEY=dummy-key-for-local
ENV ANTHROPIC_BASE_URL=http://localhost:8080/v1/messages

# PostgreSQL 配置
ENV PG_PORT=5432
ENV POSTGRES_PASSWORD=Vibe.Coding

# ============================================================
# 安装系统依赖
# ============================================================
RUN apt-get update && apt-get install -y \
    # 基础工具
    curl \
    wget \
    git \
    sudo \
    gnupg2 \
    ca-certificates \
    lsb-release \
    apt-transport-https \
    # Python 环境
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    # Node.js 环境
    ca-certificates \
    gnupg \
    # Nginx
    nginx \
    # PostgreSQL
    postgresql \
    postgresql-client \
    postgresql-contrib \
    # 其他工具
    jq \
    tree \
    htop \
    vim \
    sudo \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/bin/python

# ============================================================
# 安装 Node.js (使用 nvm 方式 - 为 vibe 用户安装)
# ============================================================
RUN apt-get update \
    && apt-get install -y curl \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && cp -r ~/.nvm ${HOME}/.nvm \
    && chown -R vibe:vibe ${HOME}/.nvm

# ============================================================
# 安装 Code-Server (官方脚本)
# ============================================================
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ============================================================
# 预装 Claude Code CLI (使用 nvm)
# ============================================================
RUN bash -c "source ${HOME}/.nvm/nvm.sh && nvm install 18 && nvm alias default 18 && nvm use default" \
    && bash -c "source ${HOME}/.nvm/nvm.sh && npm config set registry https://registry.npmmirror.com && npm install -g @anthropic-ai/claude-code@latest"

# ============================================================
# 安装 JupyterLab
# ============================================================
RUN python3 -m venv /opt/jupytervenv \
    && /opt/jupytervenv/bin/pip install --upgrade pip \
    && /opt/jupytervenv/bin/pip install \
        jupyterlab \
        notebook \
        ipywidgets \
        ipykernel

# ============================================================
# 安装 Python API 代理依赖
# ============================================================
RUN pip3 install --no-cache-dir \
    flask \
    gunicorn

# ============================================================
# 配置 Nginx
# ============================================================
RUN mkdir -p /run/nginx \
    && mkdir -p /etc/nginx/ssl

# ============================================================
# 创建应用目录
# ============================================================
RUN mkdir -p ${HOME} \
    && mkdir -p ${PIGSTY_HOME} \
    && mkdir -p ${HOME}/.config \
    && mkdir -p ${HOME}/.local/share \
    && mkdir -p /data/code \
    && mkdir -p /data/jupyter \
    && mkdir -p /data/workspace \
    && mkdir -p /var/lib/postgresql/data

# ============================================================
# 复制配置文件
# ============================================================
COPY proxy.py ${PIGSTY_HOME}/proxy.py
COPY nginx.conf /etc/nginx/nginx.conf
COPY code-server-config.yaml ${PIGSTY_HOME}/code-server-config.yaml
COPY jupyter_lab_config.py ${PIGSTY_HOME}/jupyter_lab_config.py
COPY CLAUDE.md ${PIGSTY_HOME}/CLAUDE.md
COPY start.sh ${PIGSTY_HOME}/start.sh
COPY index.html ${PIGSTY_HOME}/index.html
COPY postgres-init.sh ${PIGSTY_HOME}/postgres-init.sh

# ============================================================
# 创建 vibe 用户组
# ============================================================
RUN groupadd -g 1000 vibe \
    && useradd -r -u 1000 -g vibe -s /bin/bash -d ${HOME} vibe \
    && usermod -aG sudo vibe \
    && usermod -aG postgres vibe

# ============================================================
# 初始化 PostgreSQL (构建时完成)
# ============================================================
RUN mkdir -p /var/lib/postgresql/data \
    && chown postgres:postgres /var/lib/postgresql/data \
    && chmod 700 /var/lib/postgresql/data \
    && su - postgres -c "/usr/lib/postgresql/*/bin/initdb -D /var/lib/postgresql/data" \
    && su - postgres -c "sed -i \"s/#listen_addresses = 'localhost'/listen_addresses = '*'/\" /var/lib/postgresql/data/postgresql.conf" \
    && su - postgres -c "echo \"host all all 0.0.0.0/0 md5\" >> /var/lib/postgresql/data/pg_hba.conf" \
    && su - postgres -c "echo \"host all all ::0/0 md5\" >> /var/lib/postgresql/data/pg_hba.conf"

# ============================================================
# 设置权限
# ============================================================
RUN chmod +x ${PIGSTY_HOME}/start.sh \
    && chmod +x ${PIGSTY_HOME}/proxy.py \
    && chmod +x ${PIGSTY_HOME}/postgres-init.sh \
    && chown -R vibe:vibe ${HOME} \
    && chown -R vibe:vibe ${PIGSTY_HOME} \
    && chown -R vibe:vibe /data

USER vibe
WORKDIR ${HOME}

# ============================================================
# 初始化 Jupyter 内核
# ============================================================
RUN ${PIGSTY_HOME}/../jupytervenv/bin/python -m ipykernel install --user --name=python3 --display-name="Python 3"

# ============================================================
# 暴露端口
# ============================================================
EXPOSE ${API_PORT} ${CODE_PORT} ${JUPYTER_PORT} ${PG_PORT}

# ============================================================
# 健康检查
# ============================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${API_PORT}/health 2>/dev/null || exit 1

# ============================================================
# 启动脚本
# ============================================================
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/opt/piglet/start.sh"]
