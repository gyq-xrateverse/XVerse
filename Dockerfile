# XVerse Dockerfile - Multi-Subject Image Synthesis - Multi-stage Build
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 AS builder

# 构建参数
ARG VERSION="latest"
ARG BUILD_DATE
ARG VCS_REF

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# 显示初始磁盘空间
RUN echo "=== 初始磁盘空间 ===" && df -h

# 安装系统依赖和Python环境
RUN apt-get update && apt-get install -y \
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
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && ln -s /usr/bin/python3.10 /usr/bin/python \
    && python -m pip install --upgrade pip \
    && echo "=== 系统依赖安装后磁盘空间 ===" && df -h

# 单独安装PyTorch - 最大的依赖项
RUN echo "=== 开始安装PyTorch ===" && df -h \
    && pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 \
       --index-url https://download.pytorch.org/whl/cu118 \
       --no-cache-dir \
    && pip cache purge \
    && rm -rf /tmp/* /var/tmp/* \
    && find /usr/local -name "*.pyc" -delete \
    && find /usr/local -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && echo "=== PyTorch安装后磁盘空间 ===" && df -h

# 复制requirements.txt并安装其他Python依赖
COPY requirements.txt /tmp/requirements.txt
RUN echo "=== 开始安装其他依赖 ===" && df -h \
    && pip install -r /tmp/requirements.txt --no-cache-dir \
    && pip install httpx==0.23.3 huggingface_hub[cli] --no-cache-dir \
    && pip cache purge \
    && rm -rf /tmp/* /var/tmp/* /root/.cache \
    && find /usr/local -name "*.pyc" -delete \
    && find /usr/local -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && echo "跳过flash-attn安装，使用torch原生attention。用户可后续手动安装flash-attn。" \
    && echo "# flash-attn已跳过安装，如需要请运行: pip install flash-attn" > /usr/local/lib/python3.10/dist-packages/flash_attn_install_note.txt \
    && echo "=== 所有依赖安装后磁盘空间 ===" && df -h

# 运行时阶段 - 精简镜像
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04 AS runtime

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

# 安装运行时必需的系统依赖
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3.10-distutils \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgcc-s1 \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && ln -s /usr/bin/python3.10 /usr/bin/python

# 从builder阶段复制Python环境
COPY --from=builder /usr/local/lib/python3.10 /usr/local/lib/python3.10
COPY --from=builder /usr/local/bin /usr/local/bin

# 设置工作目录
WORKDIR /app

# 复制项目代码
COPY . /app/

# 创建checkpoints目录
RUN mkdir -p /app/checkpoints

# 设置模型路径环境变量
ENV FLORENCE2_MODEL_PATH="/app/checkpoints/Florence-2-large"
ENV SAM2_MODEL_PATH="/app/checkpoints/sam2.1_hiera_large.pt"
ENV FACE_ID_MODEL_PATH="/app/checkpoints/model_ir_se50.pth"
ENV CLIP_MODEL_PATH="/app/checkpoints/clip-vit-large-patch14"
ENV FLUX_MODEL_PATH="/app/checkpoints/FLUX.1-dev"
ENV DPG_VQA_MODEL_PATH="/app/checkpoints/mplug_visual-question-answering_coco_large_en"
ENV DINO_MODEL_PATH="/app/checkpoints/dino-vits16"

# 复制启动脚本
COPY file/entrypoint.sh /app/entrypoint.sh
COPY file/download_models.sh /app/download_models.sh
RUN chmod +x /app/entrypoint.sh /app/download_models.sh

# 最终清理和磁盘空间检查
RUN rm -rf /tmp/* /var/tmp/* /root/.cache \
    && find /usr/local -name "*.pyc" -delete \
    && find /usr/local -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && echo "=== 最终镜像磁盘空间 ===" && df -h

# 暴露端口
EXPOSE 7860

# 设置启动命令
ENTRYPOINT ["/app/entrypoint.sh"]