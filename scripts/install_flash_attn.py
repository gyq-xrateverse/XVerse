#!/usr/bin/env python3
"""
Flash-Attention Python安装脚本
支持多种安装方法，智能环境检测
"""

import subprocess
import sys
import os
import shutil
from pathlib import Path

def run_command(cmd, check=True, capture_output=False):
    """执行命令并处理结果"""
    try:
        if capture_output:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
        else:
            result = subprocess.run(cmd, shell=True, check=check)
            return True, "", ""
    except subprocess.CalledProcessError as e:
        return False, "", str(e)

def log(message, level="INFO"):
    """日志输出"""
    colors = {
        "INFO": "\033[0;34m",
        "SUCCESS": "\033[0;32m", 
        "WARNING": "\033[1;33m",
        "ERROR": "\033[0;31m"
    }
    color = colors.get(level, "")
    reset = "\033[0m"
    print(f"{color}[{level}]{reset} {message}")

def check_environment():
    """检查系统环境"""
    log("检查系统环境...")
    
    # Python版本
    python_version = f"{sys.version_info.major}.{sys.version_info.minor}"
    log(f"Python版本: {python_version}")
    
    # PyTorch版本
    try:
        import torch
        torch_version = torch.__version__
        cuda_version = torch.version.cuda
        log(f"PyTorch版本: {torch_version}")
        log(f"Torch CUDA版本: {cuda_version}")
        
        if torch.cuda.is_available():
            gpu_name = torch.cuda.get_device_name(0)
            log(f"GPU: {gpu_name}")
        else:
            log("未检测到CUDA GPU", "WARNING")
    except ImportError:
        log("PyTorch未安装", "ERROR")
        return False
    
    # CUDA编译器
    nvcc_available, nvcc_version, _ = run_command("nvcc --version", capture_output=True, check=False)
    if nvcc_available:
        log(f"NVCC: {nvcc_version.split('release')[1].split(',')[0].strip()}")
    else:
        log("NVCC编译器未找到", "WARNING")
    
    # 磁盘空间
    disk_usage = shutil.disk_usage("/")
    free_gb = disk_usage.free / (1024**3)
    log(f"可用磁盘空间: {free_gb:.1f}GB")
    
    if free_gb < 5:
        log("磁盘空间不足5GB，可能影响编译安装", "WARNING")
    
    return True

def test_flash_attn():
    """测试Flash-Attention安装"""
    log("测试Flash-Attention安装...")
    
    try:
        import flash_attn
        log(f"✅ flash-attn导入成功，版本: {flash_attn.__version__}", "SUCCESS")
        
        from flash_attn import flash_attn_func
        log("✅ flash_attn_func可用", "SUCCESS")
        
        from flash_attn.bert_padding import index_first_axis, pad_input, unpad_input
        log("✅ bert_padding模块可用", "SUCCESS")
        
        log("🎉 Flash-Attention功能完整!", "SUCCESS")
        return True
        
    except ImportError as e:
        log(f"❌ Flash-Attention导入失败: {e}", "ERROR")
        return False
    except Exception as e:
        log(f"⚠️ Flash-Attention部分功能异常: {e}", "WARNING")
        return False

def cleanup_cache():
    """清理缓存"""
    log("清理pip缓存...")
    
    # pip缓存
    subprocess.run(["pip", "cache", "purge"], check=False)
    
    # 临时文件
    temp_dirs = ["/tmp", "/var/tmp", os.path.expanduser("~/.cache")]
    for temp_dir in temp_dirs:
        if os.path.exists(temp_dir):
            try:
                shutil.rmtree(temp_dir, ignore_errors=True)
                os.makedirs(temp_dir, exist_ok=True)
            except:
                pass
    
    log("缓存清理完成", "SUCCESS")

def install_precompiled():
    """安装预编译版本"""
    log("开始预编译版本安装...")
    
    # 安装方案列表（按推荐程度排序）
    install_options = [
        {
            "name": "vllm-flash-attn (VLLM优化版)",
            "command": "pip install --no-cache-dir vllm-flash-attn==2.6.2"
        },
        {
            "name": "官方预编译版本",
            "command": "pip install --no-cache-dir flash-attn==2.6.3 --find-links https://download.pytorch.org/whl/torch_stable.html"
        },
        {
            "name": "CUDA 11.8专用版本",
            "command": "pip install --no-cache-dir https://github.com/jllllll/flash-attention/releases/download/v2.7.4.post1/flash_attn-2.7.4.post1%2Bcu118torch2.6cxx11abiFALSE-cp310-cp310-linux_x86_64.whl"
        },
        {
            "name": "最新稳定版本",
            "command": "pip install --no-cache-dir flash-attn==2.7.4.post1"
        }
    ]
    
    for option in install_options:
        log(f"尝试安装: {option['name']}")
        success, _, error = run_command(option['command'], check=False)
        
        if success:
            log(f"✅ {option['name']} 安装成功", "SUCCESS")
            return True
        else:
            log(f"❌ {option['name']} 安装失败: {error}", "ERROR")
    
    return False

def install_from_source():
    """从源码编译安装"""
    log("开始源码编译安装...")
    log("此过程可能需要1-3小时，请耐心等待...", "WARNING")
    
    # 设置环境变量
    env = os.environ.copy()
    env.update({
        "TORCH_CUDA_ARCH_LIST": "7.0;7.5;8.0;8.6;8.9;9.0",
        "FLASH_ATTENTION_FORCE_BUILD": "TRUE",
        "MAX_JOBS": "4"
    })
    
    log("设置编译环境变量...")
    for key, value in env.items():
        if key.startswith(("TORCH_", "FLASH_", "MAX_")):
            log(f"{key}={value}")
    
    # 编译安装
    cmd = "pip install --no-cache-dir --no-build-isolation flash-attn==2.7.4.post1"
    process = subprocess.Popen(cmd, shell=True, env=env)
    
    try:
        return_code = process.wait()
        if return_code == 0:
            log("✅ 源码编译安装成功", "SUCCESS")
            return True
        else:
            log("❌ 源码编译安装失败", "ERROR")
            return False
    except KeyboardInterrupt:
        log("用户中断编译过程", "WARNING")
        process.terminate()
        return False

def main():
    """主安装流程"""
    print("🚀 Flash-Attention Python安装脚本")
    print("=" * 40)
    
    # 检查环境
    if not check_environment():
        log("环境检查失败，退出安装", "ERROR")
        return 1
    
    # 检查是否已安装
    if test_flash_attn():
        log("Flash-Attention已安装且功能正常", "SUCCESS")
        return 0
    
    # 清理缓存
    cleanup_cache()
    
    # 尝试预编译安装
    log("开始尝试预编译安装...")
    if install_precompiled():
        if test_flash_attn():
            log("🎉 预编译安装成功!", "SUCCESS")
            return 0
        else:
            log("预编译安装完成但测试失败", "WARNING")
    
    # 清理失败的安装
    subprocess.run(["pip", "uninstall", "-y", "flash-attn", "vllm-flash-attn"], 
                  check=False, capture_output=True)
    cleanup_cache()
    
    # 询问是否进行源码编译
    print("\n预编译安装失败，是否尝试源码编译？")
    print("警告：源码编译可能需要1-3小时")
    choice = input("继续编译安装? (y/N): ").lower().strip()
    
    if choice in ['y', 'yes']:
        log("开始源码编译...")
        if install_from_source():
            if test_flash_attn():
                log("🎉 源码编译安装成功!", "SUCCESS")
                return 0
    
    # 所有方法都失败
    log("❌ 所有安装方法都失败了", "ERROR")
    print("\n建议:")
    print("1. 检查CUDA环境是否正确安装")
    print("2. 确保有足够的磁盘空间和内存")  
    print("3. 项目可以在没有flash-attn的情况下运行（使用PyTorch原生attention）")
    
    return 1

if __name__ == "__main__":
    sys.exit(main()) 