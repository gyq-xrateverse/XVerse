# XVerse Dockerfile - Multi-Subject Image Synthesis  
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

# 设置工作目录
WORKDIR /app

# 安装系统依赖
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
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

# 创建软链接
RUN ln -s /usr/bin/python3.10 /usr/bin/python

# 升级pip
RUN python -m pip install --upgrade pip

# 安装PyTorch (CUDA 11.8版本 - 稳定兼容版本)
RUN pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu118

# 复制requirements.txt并安装Python依赖
COPY requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt

# 安装flash-attn (需要单独安装)
# 设置编译环境变量确保CUDA工具链可用
ENV TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6"
ENV FLASH_ATTENTION_FORCE_BUILD=TRUE
RUN pip install flash-attn==2.7.4.post1 --no-build-isolation

# 更新httpx版本
RUN pip install httpx==0.23.3

# 安装HuggingFace CLI
RUN pip install huggingface_hub[cli]

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

# 暴露端口
EXPOSE 7860

# 设置启动命令
ENTRYPOINT ["/app/entrypoint.sh"]