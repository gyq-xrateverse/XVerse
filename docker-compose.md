# XVerse Docker Compose 使用指南

## 快速启动

### 1. 准备工作

确保您的系统已安装：
- Docker
- Docker Compose
- NVIDIA Docker Runtime (用于GPU支持)

### 2. 准备模型文件

在项目根目录创建 `checkpoints` 文件夹并放入模型文件：

```bash
mkdir -p checkpoints outputs
```

模型文件结构：
```
checkpoints/
├── Florence-2-large/          # Florence-2 模型
├── sam2.1_hiera_large.pt     # SAM 2.1 模型  
├── model_ir_se50.pth         # Face ID 模型
├── clip-vit-large-patch14/   # CLIP 模型
├── FLUX.1-dev/               # FLUX 模型
├── mplug_visual-question-answering_coco_large_en/  # DPG VQA 模型
├── dino-vits16/              # DINO 模型
└── XVerse/                   # XVerse 主模型
```

### 3. 启动服务

```bash
# 启动服务（后台运行）
docker-compose up -d

# 查看启动日志
docker-compose logs -f xverse

# 停止服务
docker-compose down
```

### 4. 访问应用

启动成功后，在浏览器中访问：
- **Gradio 界面**: http://localhost:7860

## 配置说明

### 端口映射
- `7860:7860` - Gradio Web 界面端口

### 文件夹映射
- `./checkpoints:/app/checkpoints` - 模型文件夹
- `./outputs:/app/outputs` - 输出文件夹（可选）

### 环境变量
- `START_MODE=gradio` - 启动模式
  - `gradio`: 启动 Gradio 演示界面（默认）
  - `bash`: 启动 bash shell 用于调试

### GPU 配置
自动检测并使用所有可用的 NVIDIA GPU。

## 常用命令

```bash
# 启动服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看实时日志
docker-compose logs -f xverse

# 进入容器调试
docker-compose exec xverse bash

# 重启服务
docker-compose restart xverse

# 停止并删除容器
docker-compose down

# 停止并删除容器和数据卷
docker-compose down -v

# 拉取最新镜像
docker-compose pull

# 重新构建并启动
docker-compose up -d --build
```

## 故障排除

### 1. GPU 不可用
```bash
# 检查 NVIDIA Docker 运行时
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu22.04 nvidia-smi

# 如果失败，安装 NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/$(. /etc/os-release;echo $ID$VERSION_ID) /" | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### 2. 端口被占用
修改 docker-compose.yml 中的端口映射：
```yaml
ports:
  - "8860:7860"  # 修改为其他端口
```

### 3. 模型文件缺失
```bash
# 检查模型文件
ls -la checkpoints/

# 使用容器内的下载脚本
docker-compose exec xverse /app/download_models.sh
```

### 4. 内存不足
```yaml
# 在 docker-compose.yml 中添加内存限制
services:
  xverse:
    deploy:
      resources:
        limits:
          memory: 16G
        reservations:
          memory: 8G
```

## 开发模式

如果需要进行开发或调试：

```bash
# 启动 bash 模式
START_MODE=bash docker-compose up -d

# 进入容器
docker-compose exec xverse bash

# 手动启动应用
python run_gradio.py
```

## 数据持久化

输出文件会保存在本地 `outputs` 文件夹中，容器重启后数据不会丢失。

## 更新镜像

```bash
# 拉取最新镜像
docker-compose pull

# 重启服务使用新镜像
docker-compose up -d
``` 