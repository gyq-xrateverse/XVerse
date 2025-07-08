# Flash-Attention 安装脚本使用指南

## 脚本概述

本目录包含三个Flash-Attention安装脚本，适用于不同场景：

### 1. 🚀 quick_install_flash_attn.sh (推荐)
**简单快速的安装脚本**
- 只尝试最稳定的预编译版本
- 安装速度快，成功率高
- 适合大多数用户

### 2. 🔧 install_flash_attn.sh (完整版)
**功能最全的Bash安装脚本**  
- 支持多种安装方法（预编译、源码编译、Conda）
- 详细的环境检测和错误处理
- 包含磁盘空间监控
- 适合高级用户或预编译版本失败时使用

### 3. 🐍 install_flash_attn.py (Python版)
**Python版本的安装脚本**
- 更好的跨平台兼容性
- 智能环境检测
- 交互式选择编译安装
- 适合Python开发者

## 使用方法

### Docker容器内安装

1. **启动Docker容器**
```bash
# 首先构建Docker镜像
docker build -t xverse:optimized .

# 启动容器
docker run -it --gpus all xverse:optimized bash
```

2. **选择安装脚本**

**方法1: 快速安装 (推荐)**
```bash
bash scripts/quick_install_flash_attn.sh
```

**方法2: 完整安装**
```bash
bash scripts/install_flash_attn.sh
```

**方法3: Python安装**
```bash
python scripts/install_flash_attn.py
```

### 本地环境安装

如果你在本地环境（非Docker）中使用：

**Linux/WSL环境:**
```bash
# 给脚本添加执行权限
chmod +x scripts/*.sh

# 执行安装
bash scripts/quick_install_flash_attn.sh
```

**Windows PowerShell环境:**
```powershell
# 直接执行Python脚本
python scripts/install_flash_attn.py

# 或者通过bash执行
bash scripts/quick_install_flash_attn.sh
```

## 安装方法说明

### 预编译版本 (推荐)

脚本会按以下顺序尝试安装：

1. **vllm-flash-attn** (最推荐)
   - VLLM团队优化的版本
   - 体积更小，兼容性更好
   ```bash
   pip install --no-cache-dir vllm-flash-attn==2.6.2
   ```

2. **官方预编译版本**
   - PyTorch官方发布的预编译包
   ```bash
   pip install --no-cache-dir flash-attn==2.6.3 --find-links https://download.pytorch.org/whl/torch_stable.html
   ```

3. **CUDA 11.8专用版本**
   - 针对CUDA 11.8 + PyTorch 2.6优化
   ```bash
   pip install --no-cache-dir https://github.com/jllllll/flash-attention/releases/download/v2.7.4.post1/flash_attn-2.7.4.post1%2Bcu118torch2.6cxx11abiFALSE-cp310-cp310-linux_x86_64.whl
   ```

4. **最新稳定版本**
   - 官方最新发布版本
   ```bash
   pip install --no-cache-dir flash-attn==2.7.4.post1
   ```

### 源码编译 (备选)

如果预编译版本都失败，可以尝试源码编译：

**环境要求:**
- CUDA 11.8+
- 至少5GB可用磁盘空间
- 8GB+ RAM
- 编译时间: 1-3小时

**编译命令:**
```bash
export TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0"
export FLASH_ATTENTION_FORCE_BUILD=TRUE
export MAX_JOBS=4
pip install --no-cache-dir --no-build-isolation flash-attn==2.7.4.post1
```

## 验证安装

安装完成后，可以使用以下命令验证：

```python
# 测试导入
import flash_attn
print(f"Flash-Attention版本: {flash_attn.__version__}")

# 测试功能
from flash_attn import flash_attn_func
from flash_attn.bert_padding import index_first_axis, pad_input, unpad_input
print("✅ Flash-Attention功能正常")
```

## 常见问题

### Q: 安装失败怎么办？

A: 按以下顺序排查：
1. 检查CUDA版本是否匹配 (`nvcc --version`)
2. 检查磁盘空间是否充足 (`df -h`)
3. 清理pip缓存 (`pip cache purge`)
4. 尝试不同的预编译版本
5. 最后考虑源码编译

### Q: 没有Flash-Attention项目能运行吗？

A: **可以正常运行**。项目已经实现了优雅降级：
- 自动检测Flash-Attention可用性
- 如果不可用，回退到PyTorch原生SDPA
- 功能完整，只是性能稍差

### Q: 性能差异有多大？

A: Flash-Attention vs PyTorch原生:
- **速度提升**: 2-4倍
- **内存优化**: 减少30-50%显存使用
- **序列长度**: 支持更长的输入序列

### Q: 磁盘空间不足怎么办？

A: 执行清理操作：
```bash
# 清理pip缓存
pip cache purge

# 清理系统缓存
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 清理Python缓存
find /usr/local -name "*.pyc" -delete
find /usr/local -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
```

## 技术支持

如果遇到问题：
1. 查看脚本输出的详细错误信息
2. 检查系统环境是否满足要求
3. 参考项目的Flash-Attention相关文档
4. 记住：即使不安装Flash-Attention，项目依然可以正常运行

---

**创建时间**: 2024年12月
**适用环境**: XVerse Docker镜像
**PyTorch版本**: 2.6.0+cu118
**Python版本**: 3.10 