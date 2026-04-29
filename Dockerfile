# 1. 选择适合的基础镜像（这里以 Python 3.12 slim 为例，兼容性好且体积小）
FROM python:3.12-slim

# 2. 从官方的 uv alpine 镜像中直接复制 uv 和 uvx 二进制文件到当前环境中
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# 3. 设置工作目录
WORKDIR /app

# 4. 配置 uv 的环境变量以优化 Docker 构建
# UV_COMPILE_BYTECODE: 自动将 .py 文件编译为 .pyc 以加快启动速度
# UV_LINK_MODE=copy: 强制使用复制而非硬链接，避免在 Docker 跨层/跨卷时出现权限或文件系统报错
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PATH="/app/.venv/bin:$PATH"

# 5. 利用 Docker 缓存：先复制依赖配置文件
# 如果你使用的是 requirements.txt，请将下面替换为 COPY requirements.txt .
COPY pyproject.toml uv.lock ./

# 6. 安装依赖 (但不包含项目源代码)
# --frozen 确保锁文件不会被修改，--no-dev 排除开发环境依赖
RUN uv sync --frozen --no-dev --no-install-project

# 7. 复制项目剩余的源代码
COPY src/ ./src/
COPY static/ ./static/

# 8. 安装项目自身（以及之前没包含的内容）
RUN uv sync --frozen --no-dev

# 9. 暴露容器端口 (根据你的应用实际端口修改)
EXPOSE 8000

# 10. 定义启动命令
# 使用 uv run 确保在正确的虚拟环境中运行
CMD ["uv", "run", "uvicorn", "src.app:app", "--host", "0.0.0.0", "--port", "8000"]