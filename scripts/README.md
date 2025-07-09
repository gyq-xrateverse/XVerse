# Flash-Attention 安装指南

## 🚀 快速安装 (推荐)

### Docker容器内安装

```bash
# 1. 构建并启动容器
docker build -t xverse:optimized .
docker run -it --gpus all xverse:optimized bash

# 2. 快速安装Flash-Attention
bash scripts/quick_install_flash_attn.sh
```

### 本地环境安装

```bash
# Linux/WSL/Windows环境
bash scripts/quick_install_flash_attn.sh
```

## 📋 安装脚本

**`quick_install_flash_attn.sh`** - 简单高效的Flash-Attention安装脚本

## 🔧 手动安装方法

如果脚本安装失败，可以手动尝试以下方法：

### 方法1: VLLM优化版 (最推荐)
```bash
pip install --no-cache-dir vllm-flash-attn==2.6.2
```

### 方法2: 官方预编译版
```bash
pip install --no-cache-dir flash-attn==2.6.3 --find-links https://download.pytorch.org/whl/torch_stable.html
```

### 方法3: 最新稳定版
```bash
pip install --no-cache-dir flash-attn==2.7.4.post1
```

## ✅ 验证安装

```python
# 测试导入
import flash_attn
print(f"Flash-Attention版本: {flash_attn.__version__}")

# 测试功能
from flash_attn import flash_attn_func
print("✅ Flash-Attention功能正常")
```

## ❓ 常见问题

### Q: 没有Flash-Attention项目能运行吗？
**A: 可以正常运行**。项目已实现优雅降级，会自动回退到PyTorch原生attention。

### Q: 性能差异有多大？
**A: Flash-Attention提供2-4倍速度提升和30-50%内存优化**。

### Q: 安装失败怎么办？
**A: 按顺序尝试**：
1. 清理缓存：`pip cache purge`
2. 检查CUDA版本：`nvcc --version`
3. 手动尝试上述安装方法
4. 项目可以在没有Flash-Attention的情况下正常运行

---
**适用环境**: XVerse Docker镜像 | **PyTorch版本**: 2.6.0+cu118 