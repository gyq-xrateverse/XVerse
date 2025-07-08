# 修复 Docker 推送问题

## 问题背景

Docker 镜像构建成功，但推送到腾讯 Coding 容器镜像仓库时出现 `400 Bad Request` 错误：

```
ERROR: failed to push ***/xverse:main: unexpected status from HEAD request to https://***/v2/xverse/blobs/sha256:1acd3243d6a28b87ca02a2dc581448980ebe83be258c89e34a3575228e2d3c12: 400 Bad Request
```

## 原因分析

1. **镜像仓库地址格式错误**：原配置使用了变量引用，实际格式应为 `g-chqo4329-docker.pkg.coding.net/beilv-ai/tools/xverse`
2. **标签生成复杂**：使用 `docker/metadata-action` 生成了过多标签，可能包含不符合规范的格式
3. **缺少错误处理**：没有重试机制和详细的错误诊断

## 解决方案

### 修改内容

1. **更新环境变量配置**
   ```yaml
   env:
     CODING_DOCKER_REGISTRY: g-chqo4329-docker.pkg.coding.net
     CODING_PROJECT: beilv-ai
     CODING_PACKAGE: tools
     DOCKER_IMAGE_NAME: xverse
   ```

2. **简化标签生成**
   - 移除复杂的 `docker/metadata-action`
   - 直接指定两个标签：`latest` 和版本标签

3. **添加验证和重试机制**
   - 推送前验证仓库连通性
   - 失败后自动重试推送
   - 改进错误日志输出

4. **优化推送流程**
   ```yaml
   tags: |
     ${{ env.CODING_DOCKER_REGISTRY }}/${{ env.CODING_PROJECT }}/${{ env.CODING_PACKAGE }}/${{ env.DOCKER_IMAGE_NAME }}:latest
     ${{ env.CODING_DOCKER_REGISTRY }}/${{ env.CODING_PROJECT }}/${{ env.CODING_PACKAGE }}/${{ env.DOCKER_IMAGE_NAME }}:${{ env.VERSION }}
   ```

### 新增功能

1. **仓库连通性验证**：推送前测试仓库访问权限
2. **自动重试机制**：首次失败后等待30秒重试
3. **详细状态报告**：显示完整镜像名称和使用方法

## 预期结果

- 成功推送到 `g-chqo4329-docker.pkg.coding.net/beilv-ai/tools/xverse:latest`
- 成功推送到 `g-chqo4329-docker.pkg.coding.net/beilv-ai/tools/xverse:{VERSION}`
- 提供清晰的使用说明和错误诊断

## 使用方法

修复后的镜像使用方法：
```bash
# 拉取镜像
docker pull g-chqo4329-docker.pkg.coding.net/beilv-ai/tools/xverse:latest

# 运行容器
docker run --gpus all -p 7860:7860 g-chqo4329-docker.pkg.coding.net/beilv-ai/tools/xverse:latest
```

## 修改文件

- `.github/workflows/build-and-push-docker.yml`：主要修改文件

## 磁盘空间问题修复

### 新增问题
在修复推送问题后，遇到了 GitHub Actions Runner 磁盘空间不足的问题：
```
System.IO.IOException: No space left on device
```

### 解决方案
1. **工作流优化**
   - 添加磁盘空间监控步骤
   - 增加系统清理步骤（APT缓存、Docker缓存、临时文件）
   - 调整Docker缓存策略（mode=min）
   - 构建后立即清理缓存

2. **Dockerfile优化**
   - 合并多个RUN指令减少镜像层数
   - 在同一层中安装依赖并立即清理缓存
   - 使用`--no-cache-dir`标志避免pip缓存积累
   - 及时删除临时文件和编译缓存

### 主要修改
- 工作流添加磁盘监控和清理步骤
- Dockerfile合并RUN指令，减少临时空间占用
- 调整缓存策略为最小模式

## 测试验证

下次触发工作流时验证：
1. 标签格式是否正确
2. 推送是否成功
3. 磁盘空间是否充足
4. 镜像是否可正常拉取和运行 