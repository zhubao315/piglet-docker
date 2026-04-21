# JupyterLab Configuration
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True
c.ServerApp.password = 'Vibe.Coding'
c.ServerApp.allow_origin = '*'
c.ServerApp.root_dir = '/data/jupyter'
c.IdentityProvider.token = 'Vibe.Coding'

# 启用 WebSocket
c.ServerApp.allow_ws_kerberos = True

# 禁用自动启动浏览器
c.ServerApp.browser = None

# 增加超时
c.ServerApp.shutdown_no_activity_timeout = 3600
c.ServerApp.http_timeout = 3600

# 启用漫游
c.ServerApp.allow_remote_access = True

# 存储
c.ServerApp.notebook_dir = '/data/jupyter'
