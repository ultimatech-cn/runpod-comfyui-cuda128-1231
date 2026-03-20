# 本地测试和发布到 Docker Hub 完整指南

本指南将帮助您：
1. ✅ 在本地环境测试 Docker 镜像
2. ✅ 构建镜像并发布到 Docker Hub

---

## 第一部分：本地测试

### 前置要求

1. **Docker Desktop** 已安装并运行
2. **NVIDIA GPU** 和驱动程序（Windows 需要 WSL2 + NVIDIA Container Toolkit）
3. **至少 150 GB 可用磁盘空间**

### 步骤 1: 构建本地镜像

在项目根目录执行：

```bash
# Windows PowerShell
cd "E:\Program Files\runpod-comfyui-cuda128-1231"

# 构建镜像（替换 your-username 为您的 Docker Hub 用户名）
docker build --platform linux/amd64 -t runpod-comfyui-cuda128:local .
```

**构建时间预计：1.5-5 小时**（首次构建，取决于网络速度）

> 💡 **提示**: 构建过程可能需要很长时间，特别是下载模型阶段。可以在后台运行或使用 tmux/screen。

### 步骤 2: 使用 Docker Compose 启动本地环境

1. **更新 docker-compose.yml**（如果需要）：

确保 `docker-compose.yml` 使用您刚构建的镜像：

```yaml
services:
  comfyui-worker:
    image: runpod-comfyui-cuda128:local  # 使用本地构建的镜像
    pull_policy: never
    # ... 其他配置保持不变
```

2. **创建数据目录**（如果不存在）：

```bash
# Windows PowerShell
New-Item -ItemType Directory -Force -Path ".\data\comfyui\output"
New-Item -ItemType Directory -Force -Path ".\data\runpod-volume"
```

3. **启动服务**：

```bash
docker-compose up --build
```

这将启动：
- **ComfyUI 服务**：http://localhost:8188
- **Worker API 服务**：http://localhost:8000

### 步骤 3: 测试 API

#### 方法 1: 使用 Swagger UI（推荐）

1. 打开浏览器访问：http://localhost:8000/docs
2. 在 Swagger UI 中可以直接测试 API
3. 使用 `/runsync` 端点进行同步测试

#### 方法 2: 使用 curl

```powershell
# Windows PowerShell
$jsonContent = Get-Content "test_resources\moshimosh_sdxl_runpod.json" -Raw -Encoding UTF8
$response = Invoke-RestMethod -Uri "http://localhost:8000/runsync" -Method Post -Body $jsonContent -ContentType "application/json"
$response | ConvertTo-Json -Depth 10
```

如需测试视频阶段，请将文件路径切换为 `test_resources\moshimosh_videogen_runpod.json`。

#### 方法 3: 使用 Python 脚本

创建测试脚本 `test_local.py`：

```python
import requests
import json

# 读取测试输入
with open('test_resources/moshimosh_sdxl_runpod.json', 'r', encoding='utf-8') as f:
    test_input = json.load(f)

# 发送请求
response = requests.post(
    'http://localhost:8000/runsync',
    json=test_input
)

print(f"Status Code: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
```

运行：

```bash
python test_local.py
```

### 步骤 4: 验证功能

测试以下功能：

1. **✅ URL 图片输入**：
   - 测试输入中包含 `"image": "https://..."` 的情况
   - 确认图片被成功下载并转换为 base64

2. **✅ Base64 图片输入**：
   - 测试输入中包含 base64 编码图片的情况
   - 确认图片被正常处理

3. **✅ 路径标准化**：
   - 验证工作流中的路径（如 `ckpt_name`）是否正确处理
   - 确认反斜杠被转换为正斜杠

4. **✅ 工作流执行**：
   - 确认 ComfyUI 能正常执行工作流
   - 检查输出图片是否生成

### 步骤 5: 停止本地环境

```bash
# 按 Ctrl+C 停止
# 或运行
docker-compose down
```

---

## 第二部分：发布到 Docker Hub

### 步骤 1: 准备 Docker Hub 账户

1. **注册 Docker Hub 账户**（如果还没有）：
   - 访问：https://hub.docker.com/signup
   - 创建账户并验证邮箱

2. **创建访问令牌**（推荐，更安全）：
   - 访问：https://hub.docker.com/settings/security
   - 点击 "New Access Token"
   - 创建令牌并保存（只显示一次）

### 步骤 2: 构建生产镜像

使用带版本号的标签（推荐）：

```bash
# 替换 your-username 为您的 Docker Hub 用户名
# 替换 v1.0.0 为您的版本号
docker build --platform linux/amd64 -t your-username/runpod-comfyui-cuda128:v1.0.0 .

# 同时标记为 latest
docker tag your-username/runpod-comfyui-cuda128:v1.0.0 your-username/runpod-comfyui-cuda128:latest
```

### 步骤 3: 验证镜像

```bash
# 查看镜像列表
docker images | Select-String "runpod-comfyui-cuda128"

# 检查镜像大小
docker images your-username/runpod-comfyui-cuda128:latest
```

预期大小：**约 70-90 GB**（包含所有模型）

### 步骤 4: 登录 Docker Hub

```bash
docker login
```

输入：
- **Username**: 您的 Docker Hub 用户名
- **Password**: 密码或访问令牌

### 步骤 5: 推送镜像到 Docker Hub

```bash
# 推送带版本号的镜像
docker push your-username/runpod-comfyui-cuda128:v1.0.0

# 推送 latest 标签
docker push your-username/runpod-comfyui-cuda128:latest
```

**推送时间预计：30 分钟 - 2 小时**（取决于镜像大小和上传速度）

> ⚠️ **注意**: 推送大镜像时可能需要较长时间，确保网络连接稳定。

### 步骤 6: 验证推送成功

1. 访问您的 Docker Hub 仓库：
   ```
   https://hub.docker.com/r/your-username/runpod-comfyui-cuda128
   ```

2. 应该能看到您的镜像和标签

### 步骤 7: 在 RunPod 中使用镜像

1. **登录 RunPod 控制台**：
   - https://www.runpod.io/console

2. **创建 Serverless Endpoint**：
   - Serverless → Endpoints → New Endpoint

3. **配置镜像**：
   - **Container Image**: `your-username/runpod-comfyui-cuda128:latest`
   - **Container Disk**: 80 GB（根据您的 hub.json 配置）
   - **GPU**: 选择支持的 GPU（如 RTX 4090）

4. **部署并测试**

---

## 完整命令清单

### 本地测试

```powershell
# 1. 构建镜像
docker build --platform linux/amd64 -t runpod-comfyui-cuda128:local .

# 2. 创建数据目录
New-Item -ItemType Directory -Force -Path ".\data\comfyui\output"
New-Item -ItemType Directory -Force -Path ".\data\runpod-volume"

# 3. 启动服务
docker-compose up

# 4. 测试 API (新终端)
curl -X POST http://localhost:8000/runsync -H "Content-Type: application/json" --data-binary "@test_resources/moshimosh_sdxl_runpod.json"

# 5. 停止服务
docker-compose down
```

### 发布到 Docker Hub

```powershell
# 1. 构建生产镜像
docker build --platform linux/amd64 -t your-username/runpod-comfyui-cuda128:v1.0.0 .
docker tag your-username/runpod-comfyui-cuda128:v1.0.0 your-username/runpod-comfyui-cuda128:latest

# 2. 登录 Docker Hub
docker login

# 3. 推送镜像
docker push your-username/runpod-comfyui-cuda128:v1.0.0
docker push your-username/runpod-comfyui-cuda128:latest

# 4. 验证
# 访问 https://hub.docker.com/r/your-username/runpod-comfyui-cuda128
```

---

## 常见问题

### Q: 构建过程中出现网络超时怎么办？

**A**: Docker 会缓存已完成的步骤，只需重新运行构建命令即可继续：

```bash
docker build --platform linux/amd64 -t runpod-comfyui-cuda128:local .
```

### Q: 磁盘空间不足怎么办？

**A**: 

1. **清理 Docker 缓存**：
   ```bash
   docker system prune -a
   ```

2. **扩展 Docker Desktop 磁盘大小**（Windows）：
   - Docker Desktop → Settings → Resources → Advanced
   - 增加 Disk image size（建议至少 200GB）

### Q: 推送镜像时出现 502 错误？

**A**: 
- 镜像太大导致超时
- 尝试在更稳定的网络环境下推送
- 或者分批推送（如果可能）

### Q: 如何加速构建过程？

**A**:
- 使用更快的网络
- 使用 Docker BuildKit（默认已启用）
- 考虑使用 GitHub Actions 自动构建

### Q: 可以在本地测试时不下载所有模型吗？

**A**: 可以修改 Dockerfile，只下载测试需要的模型，或者使用网络卷（Network Volume）存储模型。

---

## 下一步

测试和发布完成后：

1. ✅ **在 RunPod 上创建端点**并测试
2. ✅ **参考 [部署指南](deployment.md)** 进行详细配置
3. ✅ **参考 [发布到 RunPod Hub 指南](publish-to-hub.md)** 发布到 Hub（如果适用）

