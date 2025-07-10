# 任务：添加Resnet50_Final.pth模型下载

## 上下文
用户需要在Dockerfile中下载 `Resnet50_Final.pth` 文件并放置到指定位置 `/root/.cache/torch/hub/checkpoints/Resnet50_Final.pth`

## 执行计划
1. 修改Dockerfile添加下载逻辑
2. 添加环境变量RESNET50_MODEL_PATH
3. 更新下载脚本添加检查逻辑
4. 记录任务完成情况

## 实现细节

### 1. Dockerfile修改
- 在创建checkpoints目录时同时下载Resnet50_Final.pth
- 使用curl命令从GitHub releases下载文件
- 添加下载进度和完成提示

### 2. 环境变量
- 新增 `ENV RESNET50_MODEL_PATH="/root/.cache/torch/hub/checkpoints/Resnet50_Final.pth"`

### 3. 下载脚本更新
- 在模型检查中添加Resnet50模型的检查逻辑
- 提供下载地址和目标位置信息

## 执行状态
- [x] 修改Dockerfile添加下载逻辑
- [x] 添加环境变量
- [x] 更新下载脚本
- [x] 创建任务记录

## 测试建议
构建Docker镜像时观察下载过程，确保文件正确下载到指定位置。 