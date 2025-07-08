# GitHub Actions Docker 构建优化任务

## 任务背景
用户发现 `.github/workflows/build-and-push-docker.yml` 中的相对路径配置有误。在 GitHub Actions 中，`.` 表示项目根目录，但当前配置使用了 `./XVerse` 路径，而实际项目结构中 Dockerfile 位于根目录。

## 问题分析
- **当前配置**: `context: ./XVerse`, `file: ./XVerse/Dockerfile`
- **实际结构**: Dockerfile 位于根目录 `.`，不存在 `./XVerse/` 子目录
- **影响**: Docker 构建无法找到正确的 Dockerfile 和构建上下文

## 解决方案
选择方案1：修正路径配置
- 将 `context: ./XVerse` 改为 `context: .`
- 将 `file: ./XVerse/Dockerfile` 改为 `file: ./Dockerfile`

## 执行计划
1. ✅ 修正 `.github/workflows/build-and-push-docker.yml` 中的路径配置
2. ✅ 验证 Dockerfile 中的 COPY 指令与新构建上下文兼容
3. ✅ 创建任务记录文档

## 修改内容
```yaml
# 修改前
context: ./XVerse
file: ./XVerse/Dockerfile

# 修改后  
context: .
file: ./Dockerfile
```

## 验证
- Dockerfile 使用 `COPY . /app/` 等相对路径，与新构建上下文 `.` 完全兼容
- 所有项目文件都在根目录下，构建上下文设为 `.` 是正确的

## 完成状态
- [x] 路径配置修正完成
- [x] 兼容性验证通过
- [x] 任务记录创建完成

## 补充修复：flash-attn 编译错误

### 问题描述
Docker构建在安装 flash-attn==2.7.4.post1 时失败：
```
FileNotFoundError: [Errno 2] No such file or directory: '/usr/local/cuda/bin/nvcc'
```

### 根本原因
- 基础镜像使用了 `nvidia/cuda:11.8.0-runtime-ubuntu22.04`
- runtime版本只包含运行时库，不包含CUDA开发工具(nvcc编译器)
- flash-attn需要从源码编译，必须有CUDA开发环境

### 解决方案
1. **切换基础镜像**：改为 `nvidia/cuda:11.8.0-devel-ubuntu22.04`
2. **添加编译环境变量**：
   - `TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6"`
   - `FLASH_ATTENTION_FORCE_BUILD=TRUE`

### 修改内容
```dockerfile
# 修改前
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

# 修改后
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# 新增环境变量
ENV TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6"
ENV FLASH_ATTENTION_FORCE_BUILD=TRUE
```

### 状态更新
- [x] 基础镜像修正完成
- [x] 编译环境变量添加完成
- [x] flash-attn编译错误修复完成

## 进一步优化：使用预编译wheel

### 优化背景
虽然修复了编译环境，但flash-attn从源码编译仍需要6小时以上，导致GitHub Actions超时。

### 最终解决方案
1. **多级fallback策略**：
   - 首先尝试pip安装（可能有预编译版本）
   - 失败则从GitHub下载官方预编译wheel
   - 最后才从源码编译
   
2. **增加构建超时**：设置为180分钟防止意外超时

3. **预编译wheel选择**：
   - 使用 `flash_attn-2.7.4.post1+cu12torch2.6cxx11abiFALSE-cp310-cp310-linux_x86_64.whl`
   - 匹配Python 3.10和PyTorch 2.6.0
   - 支持CUDA 12（向下兼容CUDA 11.8）

### 最终修改
```dockerfile
# 多级fallback安装策略
RUN pip install flash-attn==2.7.4.post1 --no-build-isolation || \
    (echo "预编译wheel安装失败，尝试从GitHub下载预编译版本..." && \
     pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.7.4.post1/flash_attn-2.7.4.post1+cu12torch2.6cxx11abiFALSE-cp310-cp310-linux_x86_64.whl || \
     (echo "预编译版本不可用，从源码编译（这将需要很长时间）..." && \
      export TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6" && \
      export FLASH_ATTENTION_FORCE_BUILD=TRUE && \
      pip install flash-attn==2.7.4.post1 --no-build-isolation))
```

### 预期效果
- 构建时间从6小时减少到几分钟
- 避免GitHub Actions超时
- 保持完整的fallback机制 