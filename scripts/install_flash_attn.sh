#!/bin/bash

# Flash-Attention 安装脚本
# 支持多种安装方法，自动选择最适合的方案
# 创建时间: $(date)
# 适用环境: XVerse Docker容器

set -e  # 遇到错误立即退出

echo "🚀 Flash-Attention 安装脚本启动"
echo "================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查环境函数
check_environment() {
    log_info "检查系统环境..."
    
    # 检查Python版本
    PYTHON_VERSION=$(python -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
    log_info "Python版本: $PYTHON_VERSION"
    
    # 检查PyTorch版本
    TORCH_VERSION=$(python -c "import torch; print(torch.__version__)" 2>/dev/null || echo "未安装")
    log_info "PyTorch版本: $TORCH_VERSION"
    
    # 检查CUDA版本
    if command -v nvcc &> /dev/null; then
        CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9.]*\).*/\1/')
        log_info "CUDA版本: $CUDA_VERSION"
    else
        CUDA_VERSION="未找到"
        log_warning "未找到CUDA编译器"
    fi
    
    # 检查torch CUDA版本
    TORCH_CUDA=$(python -c "import torch; print(torch.version.cuda)" 2>/dev/null || echo "未知")
    log_info "Torch CUDA版本: $TORCH_CUDA"
    
    # 检查GPU架构
    if command -v nvidia-smi &> /dev/null; then
        GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1)
        log_info "GPU: $GPU_NAME"
    else
        log_warning "未找到nvidia-smi"
    fi
    
    # 检查磁盘空间
    DISK_FREE=$(df -h / | awk 'NR==2 {print $4}')
    log_info "可用磁盘空间: $DISK_FREE"
    
    echo ""
}

# 清理函数
cleanup_cache() {
    log_info "清理缓存以释放空间..."
    
    # 清理pip缓存
    pip cache purge 2>/dev/null || true
    
    # 清理系统缓存
    if [ "$EUID" -eq 0 ]; then
        apt-get clean 2>/dev/null || true
        rm -rf /var/lib/apt/lists/* 2>/dev/null || true
    fi
    
    # 清理临时文件
    rm -rf /tmp/* /var/tmp/* ~/.cache 2>/dev/null || true
    
    # 清理Python缓存
    find /usr/local -name "*.pyc" -delete 2>/dev/null || true
    find /usr/local -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    
    log_success "缓存清理完成"
    df -h / | head -2
    echo ""
}

# 测试Flash-Attention安装
test_flash_attn() {
    log_info "测试Flash-Attention安装..."
    
    python -c "
import sys
try:
    import flash_attn
    print('✅ flash-attn导入成功')
    print(f'版本: {flash_attn.__version__}')
    
    from flash_attn import flash_attn_func
    print('✅ flash_attn_func可用')
    
    from flash_attn.bert_padding import index_first_axis, pad_input, unpad_input
    print('✅ bert_padding模块可用')
    
    print('🎉 Flash-Attention安装成功并功能完整!')
    sys.exit(0)
    
except ImportError as e:
    print(f'❌ Flash-Attention导入失败: {e}')
    sys.exit(1)
except Exception as e:
    print(f'⚠️ Flash-Attention部分功能异常: {e}')
    sys.exit(2)
"
    
    return $?
}

# 方法1: 预编译wheel安装（推荐）
install_precompiled() {
    log_info "方法1: 使用预编译wheel安装Flash-Attention..."
    
    # 方案1: VLLM优化版本（最稳定）
    log_info "尝试安装vllm-flash-attn..."
    if pip install --no-cache-dir vllm-flash-attn==2.6.2; then
        log_success "vllm-flash-attn安装成功"
        return 0
    fi
    
    # 方案2: 官方预编译版本
    log_info "尝试安装官方预编译版本..."
    if pip install --no-cache-dir flash-attn==2.6.3 --find-links https://download.pytorch.org/whl/torch_stable.html; then
        log_success "官方预编译版本安装成功"
        return 0
    fi
    
    # 方案3: 专用CUDA 11.8版本
    log_info "尝试安装CUDA 11.8专用版本..."
    WHEEL_URL="https://github.com/jllllll/flash-attention/releases/download/v2.7.4.post1/flash_attn-2.7.4.post1%2Bcu118torch2.6cxx11abiFALSE-cp310-cp310-linux_x86_64.whl"
    if pip install --no-cache-dir "$WHEEL_URL"; then
        log_success "CUDA 11.8专用版本安装成功"
        return 0
    fi
    
    # 方案4: 最新稳定版本
    log_info "尝试安装最新稳定版本..."
    if pip install --no-cache-dir flash-attn==2.7.4.post1; then
        log_success "最新稳定版本安装成功"
        return 0
    fi
    
    log_error "所有预编译版本安装失败"
    return 1
}

# 方法2: 源码编译安装
install_from_source() {
    log_info "方法2: 从源码编译安装Flash-Attention..."
    log_warning "此过程可能需要1-3小时，请耐心等待..."
    
    # 设置编译环境变量
    export TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0"
    export FLASH_ATTENTION_FORCE_BUILD=TRUE
    export MAX_JOBS=4  # 限制并发数避免内存不足
    
    log_info "编译环境变量已设置"
    log_info "TORCH_CUDA_ARCH_LIST=$TORCH_CUDA_ARCH_LIST"
    
    # 从源码安装
    if pip install --no-cache-dir --no-build-isolation flash-attn==2.7.4.post1; then
        log_success "源码编译安装成功"
        return 0
    else
        log_error "源码编译安装失败"
        return 1
    fi
}

# 方法3: Conda安装
install_with_conda() {
    log_info "方法3: 使用Conda安装Flash-Attention..."
    
    # 检查conda是否可用
    if ! command -v conda &> /dev/null; then
        log_warning "Conda未安装，跳过此方法"
        return 1
    fi
    
    # 使用conda安装
    if conda install -y flash-attn -c conda-forge; then
        log_success "Conda安装成功"
        return 0
    else
        log_error "Conda安装失败"
        return 1
    fi
}

# 主安装流程
main() {
    echo "🎯 开始Flash-Attention安装流程"
    echo ""
    
    # 检查环境
    check_environment
    
    # 检查是否已安装
    if test_flash_attn; then
        log_success "Flash-Attention已安装且功能正常"
        echo ""
        echo "🎉 安装检查完成!"
        exit 0
    fi
    
    # 清理缓存
    cleanup_cache
    
    # 尝试方法1: 预编译安装
    log_info "开始尝试预编译安装..."
    if install_precompiled; then
        if test_flash_attn; then
            log_success "🎉 预编译安装成功!"
            exit 0
        else
            log_warning "预编译安装完成但测试失败，尝试其他方法"
        fi
    fi
    
    # 清理失败的安装
    pip uninstall -y flash-attn vllm-flash-attn 2>/dev/null || true
    cleanup_cache
    
    # 尝试方法2: 源码编译
    log_info "开始尝试源码编译..."
    if install_from_source; then
        if test_flash_attn; then
            log_success "🎉 源码编译安装成功!"
            exit 0
        else
            log_warning "源码编译完成但测试失败，尝试其他方法"
        fi
    fi
    
    # 清理失败的安装
    pip uninstall -y flash-attn 2>/dev/null || true
    cleanup_cache
    
    # 尝试方法3: Conda安装
    log_info "开始尝试Conda安装..."
    if install_with_conda; then
        if test_flash_attn; then
            log_success "🎉 Conda安装成功!"
            exit 0
        else
            log_warning "Conda安装完成但测试失败"
        fi
    fi
    
    # 所有方法都失败
    log_error "❌ 所有安装方法都失败了"
    log_info "建议:"
    log_info "1. 检查CUDA环境是否正确安装"
    log_info "2. 确保有足够的磁盘空间和内存"
    log_info "3. 尝试使用较低版本的flash-attn"
    log_info "4. 项目可以在没有flash-attn的情况下运行（使用PyTorch原生attention）"
    
    exit 1
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 