# XVerse Dockerfile - Multi-Subject Image Synthesis - Optimized Single Stage
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# 构建参数
ARG VERSION="latest"
ARG BUILD_DATE
ARG VCS_REF

# 设置标签
LABEL org.opencontainers.image.title="XVerse" \
      org.opencontainers.image.description="Multi-Subject Image Synthesis via DiT Modulation" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/bytedance/XVerse" \
      org.opencontainers.image.url="https://bytedance.github.io/XVerse/" \
      org.opencontainers.image.vendor="ByteDance" \
      org.opencontainers.image.licenses="Apache-2.0"

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
ENV XVERSE_VERSION="${VERSION}"

# 显示初始磁盘空间
RUN echo "=== 初始磁盘空间 ===" && df -h

# 第一阶段：安装系统依赖和Python环境
RUN echo "=== 安装系统依赖和Python环境 ===" \
    && apt-get update && apt-get install -y \
        python3.10 \
        python3.10-dev \
        python3.10-distutils \
        python3-pip \
        git \
        wget \
        curl \
        build-essential \
        gcc \
        g++ \
        make \
        ninja-build \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        libgcc-s1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && ln -s /usr/bin/python3.10 /usr/bin/python \
    && python -m pip install --upgrade pip \
    && echo "=== 系统依赖安装后磁盘空间 ===" && df -h

# 复制requirements.txt并安装Python依赖
COPY requirements.txt /tmp/requirements.txt

# 第二阶段：安装Python依赖（包括PyTorch）
RUN echo "=== 开始安装Python依赖（包括PyTorch） ===" && df -h \
    && pip install -r /tmp/requirements.txt \
       --index-url https://download.pytorch.org/whl/cu118 \
       --no-cache-dir \
    && pip install httpx==0.23.3 huggingface_hub[cli] --no-cache-dir \
    && echo "=== 验证PyTorch安装 ===" \
    && python -c "import torch; print(f'PyTorch版本: {torch.__version__}')" \
    && python -c "import torch; print(f'CUDA可用: {torch.cuda.is_available()}')" \
    && pip cache purge \
    && rm -rf /tmp/* /var/tmp/* /root/.cache \
    && find /usr/local -name "*.pyc" -delete \
    && find /usr/local -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && echo "跳过flash-attn安装，使用torch原生attention。用户可后续手动安装flash-attn。" \
    && echo "# flash-attn已跳过安装，如需要请运行: pip install flash-attn" > /usr/local/lib/python3.10/dist-packages/flash_attn_install_note.txt \
    && echo "=== Python依赖安装后磁盘空间 ===" && df -h

# 第四阶段：清理开发工具（保留运行时必需）
RUN echo "=== 清理开发工具以减少镜像大小 ===" \
    && apt-get remove -y \
        python3.10-dev \
        build-essential \
        gcc \
        g++ \
        make \
        ninja-build \
        wget \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "=== 开发工具清理后磁盘空间 ===" && df -h

# 设置工作目录
WORKDIR /app

# 复制项目代码
COPY . /app/

# 创建checkpoints目录并下载Resnet50_Final.pth
RUN mkdir -p /app/checkpoints \
    && mkdir -p /root/.cache/torch/hub/checkpoints \
    && echo "=== 下载Resnet50_Final.pth模型 ===" \
    && curl -L -o /root/.cache/torch/hub/checkpoints/Resnet50_Final.pth \
        "https://github.com/elliottzheng/face-detection/releases/download/0.0.1/Resnet50_Final.pth" \
    && echo "=== Resnet50_Final.pth下载完成 ===" \
    && ls -la /root/.cache/torch/hub/checkpoints/

# 设置模型路径环境变量
ENV FLORENCE2_MODEL_PATH="/app/checkpoints/Florence-2-large"
ENV SAM2_MODEL_PATH="/app/checkpoints/sam2.1_hiera_large.pt"
ENV FACE_ID_MODEL_PATH="/app/checkpoints/model_ir_se50.pth"
ENV CLIP_MODEL_PATH="/app/checkpoints/clip-vit-large-patch14"
ENV FLUX_MODEL_PATH="/app/checkpoints/FLUX.1-dev"
ENV DPG_VQA_MODEL_PATH="/app/checkpoints/mplug_visual-question-answering_coco_large_en"
ENV DINO_MODEL_PATH="/app/checkpoints/dino-vits16"
ENV RESNET50_MODEL_PATH="/root/.cache/torch/hub/checkpoints/Resnet50_Final.pth"

# 复制启动脚本并设置权限
COPY file/entrypoint.sh /app/entrypoint.sh
COPY file/download_models.sh /app/download_models.sh
RUN chmod +x /app/entrypoint.sh /app/download_models.sh

# 最终清理和验证
RUN echo "=== 最终清理和验证 ===" \
    && rm -rf /tmp/* /var/tmp/* /root/.cache \
    && find /usr/local -name "*.pyc" -delete \
    && find /usr/local -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && echo "=== 验证Python环境 ===" \
    && python --version \
    && echo "=== 最终镜像磁盘空间 ===" && df -h

# 暴露端口
EXPOSE 7860

# 设置启动命令
ENTRYPOINT ["/app/entrypoint.sh"]