# Docker Compose Bash模式无限重启修复

## 问题描述
使用docker-compose启动容器时，设置START_MODE=bash后容器无限重启。

## 根因分析
1. bash模式下，entrypoint.sh执行`exec /bin/bash`
2. 由于容器中bash没有交互式输入，bash立即退出
3. 容器退出后被restart策略重新启动，形成无限循环

## 解决方案
1. **修改entrypoint.sh**：将`exec /bin/bash`改为`tail -f /dev/null`保持容器运行
2. **增加操作说明**：提示用户使用`docker exec`进入容器
3. **优化docker-compose**：添加`tty: true`和`stdin_open: true`支持交互

## 修改内容
- file/entrypoint.sh: bash和setup模式使用tail保持运行
- docker-compose.yml: 增加tty和stdin_open配置

## 使用方法
启动后通过以下命令进入容器：
```bash
docker exec -it xverse-app /bin/bash
```

## 预期结果
容器稳定运行，不再无限重启，用户可正常操作。 