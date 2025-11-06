# Network Volume 模型存储配置指南

本指南说明如何使用 RunPod Network Volume 存储模型，从而大幅缩短 Docker 镜像构建时间。

## 📊 优化效果对比

| 方案 | 构建时间 | 镜像大小 | 灵活性 |
|------|---------|---------|--------|
| **原方案（模型内置）** | 1.5-5 小时 | ~92 GB | 低（需重新构建镜像才能更新模型） |
| **Network Volume** | 10-30 分钟 | ~5-10 GB | 高（可随时更新模型，无需重建镜像） |

## 🎯 为什么使用 Network Volume？

1. **大幅缩短构建时间**：从数小时缩短到 10-30 分钟
2. **镜像体积更小**：从 92GB 减少到 5-10GB，推送更快
3. **灵活更新模型**：无需重建镜像即可添加/更新模型
4. **节省成本**：更快的构建和部署，减少等待时间
5. **共享模型**：多个 Endpoint 可以共享同一个 Network Volume

## 📋 前置条件

- RunPod 账户
- 已创建 Network Volume（或准备创建）
- 了解如何访问 RunPod 控制台

## 🚀 快速开始

### 步骤 1: 创建 Network Volume

1. 登录 [RunPod 控制台](https://www.runpod.io/console)
2. 导航到 **Storage > Network Volumes**
3. 点击 **Create Network Volume**
4. 配置参数：
   - **Name**: `comfyui-models`（或您喜欢的名称）
   - **Size**: 建议至少 200GB（根据模型数量调整）
   - **Region**: 选择与您的 Endpoint 相同的区域
5. 点击 **Create**

> 💡 **提示**：Network Volume 按存储容量计费，建议根据实际需求选择大小。

### 步骤 2: 准备模型目录结构

Network Volume 挂载到容器内的 `/runpod-volume`，ComfyUI 会自动从以下路径加载模型：

```
/runpod-volume/
└── models/
    ├── checkpoints/          # 主模型（.safetensors, .ckpt）
    │   ├── SDXL/
    │   └── Wan2.2/
    ├── loras/                # LoRA 模型
    │   ├── SDXL/
    │   └── Wan2.2/
    ├── clip_vision/          # CLIP Vision 模型
    │   └── wan/
    ├── pulid/                # PuLID 模型
    ├── insightface/          # InsightFace 模型
    │   └── models/
    │       └── antelopev2/
    ├── reswapper/            # ReActor 模型
    ├── hyperswap/            # HyperSwap 模型
    ├── facerestore_models/   # 面部修复模型
    ├── upscale_models/       # 超分辨率模型
    ├── vae/                  # VAE 模型
    ├── controlnet/           # ControlNet 模型
    └── blip/                 # BLIP 模型（用于图像描述）
```

### 步骤 3: 上传模型到 Network Volume

有两种方法上传模型：

#### 方法 A: 使用临时 Pod（推荐）

1. **创建临时 Pod**：
   - 在 RunPod 控制台，导航到 **Pods**
   - 点击 **Deploy Pod**
   - 选择任意 GPU 类型（最便宜的即可，如 RTX 3060）
   - 在 **Network Volume** 中选择您创建的 Volume
   - 点击 **Deploy**

2. **连接到 Pod**：
   - Pod 启动后，点击 **Connect** → **HTTP Service** 或使用 **Jupyter Lab**
   - 打开终端

3. **下载模型**：
   ```bash
   # Network Volume 挂载在 /workspace
   cd /workspace
   
   # 创建目录结构
   mkdir -p models/{checkpoints/SDXL,checkpoints/Wan2.2,loras/SDXL,loras/Wan2.2,clip_vision/wan,pulid,insightface/models,reswapper,hyperswap,facerestore_models,upscale_models}
   
   # 下载 Checkpoint 模型（示例）
   cd models/checkpoints/SDXL
   wget -O ultraRealisticByStable_v20FP16.safetensors \
     "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/ultraRealisticByStable_v20FP16.safetensors"
   
   # 下载 WAN2.2 Checkpoint（示例）
   cd ../Wan2.2
   wget -O wan2.2-i2v-rapid-aio-v10-nsfw.safetensors \
     "https://huggingface.co/Phr00t/WAN2.2-14B-Rapid-AllInOne/resolve/main/v10/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors"
   
   # 下载 LoRA 模型（示例）
   cd ../../loras/SDXL
   wget -O subtle-analsex-xl3.safetensors \
     "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/subtle-analsex-xl3.safetensors"
   
   # 下载 InsightFace 模型
   cd ../../insightface/models
   wget -O /tmp/antelopev2.zip \
     "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip"
   unzip /tmp/antelopev2.zip -d .
   rm /tmp/antelopev2.zip
   
   # 继续下载其他模型...
   ```

4. **验证上传**：
   ```bash
   # 检查文件
   ls -lh /workspace/models/checkpoints/SDXL/
   ls -lh /workspace/models/loras/SDXL/
   ```

5. **删除临时 Pod**（节省成本）

#### 方法 B: 使用自动化脚本批量下载（推荐）

我们提供了一个自动化脚本，可以一键下载所有模型：

1. **在临时 Pod 中克隆仓库**（或上传脚本）：
   ```bash
   # 如果 Network Volume 挂载在 /workspace
   cd /workspace
   
   # 克隆仓库（或直接上传脚本文件）
   git clone https://github.com/ultimatech-cn/runpod-comfyui-cuda128-pure.git
   cd runpod-comfyui-cuda128-pure
   ```

2. **运行下载脚本**：
   ```bash
   # 如果 Network Volume 挂载在 /workspace（默认）
   bash scripts/download-models-to-volume.sh
   
   # 或者指定挂载路径（如果挂载在其他位置，如 /runpod-volume）
   bash scripts/download-models-to-volume.sh /runpod-volume
   ```

   脚本会自动：
   - ✅ 创建所有必要的目录结构
   - ✅ 下载所有 Checkpoint 模型
   - ✅ 下载所有 LoRA 模型（SDXL 和 Wan2.2）
   - ✅ 下载 CLIP Vision、PuLID、ReActor、HyperSwap 等模型
   - ✅ 下载 InsightFace AntelopeV2 模型并解压
   - ✅ 下载 BLIP 模型（如果 Python 可用）
   - ✅ 显示下载进度和文件统计
   - ✅ 跳过已存在的文件（支持断点续传）

3. **等待下载完成**：
   - 脚本会显示每个文件的下载进度
   - 完成后会显示文件统计信息
   - 预计下载时间：根据网络速度，可能需要 30 分钟到 2 小时

> 💡 **提示**：脚本支持断点续传，如果下载中断，重新运行脚本会跳过已下载的文件。

### 步骤 4: 构建优化版镜像

使用 `Dockerfile.optimized` 构建镜像：

```powershell
# 构建优化版镜像（不包含模型）
docker build --platform linux/amd64 -f Dockerfile.optimized -t runpod-comfyui-cuda128:optimized .
```

构建时间预计：**10-30 分钟**（相比原来的 1.5-5 小时）

### 步骤 5: 配置 Endpoint 使用 Network Volume

1. **部署 Endpoint**：
   - 在 RunPod 控制台，导航到 **Serverless > Endpoints**
   - 创建新 Endpoint 或编辑现有 Endpoint
   - 选择您构建的优化版镜像

2. **附加 Network Volume**：
   - 在 Endpoint 配置中，找到 **Advanced** 或 **Network Volume** 选项
   - 选择您创建的 Network Volume（如 `comfyui-models`）
   - 保存配置

3. **验证配置**：
   - 部署 Endpoint 后，发送测试请求
   - 检查日志确认模型加载成功

## 🔍 验证模型加载

### 方法 1: 检查日志

在 Endpoint 日志中查找模型加载信息：

```
worker-comfyui - Loading model: /runpod-volume/models/checkpoints/SDXL/ultraRealisticByStable_v20FP16.safetensors
```

### 方法 2: 使用 ComfyUI API

如果启用了 `SERVE_API_LOCALLY=true`，可以访问 ComfyUI 的 API：

```bash
# 获取可用模型列表
curl http://localhost:8188/object_info | jq '.CheckpointLoaderSimple.input.required.ckpt_name[0]'
```

## 📝 模型列表参考

以下是原 Dockerfile 中下载的模型，您可以根据需要选择性下载：

### Checkpoint 模型
- `models/checkpoints/SDXL/ultraRealisticByStable_v20FP16.safetensors`
- `models/checkpoints/Wan2.2/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors`

### LoRA 模型（SDXL）
- `models/loras/SDXL/subtle-analsex-xl3.safetensors`
- `models/loras/SDXL/LCMV2-PONYplus-PAseer.safetensors`

### LoRA 模型（Wan2.2）
- `models/loras/Wan2.2/DR34MJOB_I2V_14b_HighNoise.safetensors`
- `models/loras/Wan2.2/DR34MJOB_I2V_14b_LowNoise.safetensors`
- ...（其他 Wan2.2 LoRA）

### 其他模型
- `models/clip_vision/wan/clip_vision_h.safetensors`
- `models/pulid/ip-adapter_pulid_sdxl_fp16.safetensors`
- `models/insightface/models/antelopev2/`（解压后的目录）
- `models/reswapper/reswapper_128.onnx`
- `models/hyperswap/hyperswap_1a_256.onnx`
- `models/hyperswap/hyperswap_1b_256.onnx`
- `models/hyperswap/hyperswap_1c_256.onnx`
- `models/upscale_models/RealESRGAN_x2.pth`
- `models/facerestore_models/GFPGANv1.4.pth`
- `models/facerestore_models/GPEN-BFR-512.onnx`

## ⚠️ 注意事项

1. **区域一致性**：确保 Network Volume 和 Endpoint 在同一区域，否则会有延迟
2. **模型路径**：模型必须放在正确的子目录中，ComfyUI 才能识别
3. **首次加载**：首次使用模型时，ComfyUI 可能需要一些时间加载到 GPU 内存
4. **成本考虑**：Network Volume 按存储容量计费，删除不需要的模型可以节省成本
5. **备份**：重要模型建议备份，Network Volume 虽然持久，但最好有备份策略

## 🔄 更新模型

更新模型非常简单：

1. 创建临时 Pod 并附加 Network Volume
2. 连接到 Pod
3. 删除旧模型或添加新模型
4. 删除临时 Pod
5. 无需重新构建或部署 Endpoint

## 📚 相关文档

- [RunPod Network Volumes 官方文档](https://docs.runpod.io/pods/storage/create-network-volumes)
- [RunPod Serverless 概述](https://docs.runpod.io/serverless/overview)
- [自定义配置指南](customization.md)
- [部署指南](deployment.md)
- [extra_model_paths.yaml 常见问题](extra_model_paths-faq.md) - 了解模型路径配置的详细说明

## ❓ 常见问题

### Q: Network Volume 和镜像中的模型可以同时使用吗？

A: 可以。ComfyUI 会同时从两个位置加载模型：
- 镜像中的模型：`/comfyui/models/...`
- Network Volume 中的模型：`/runpod-volume/models/...`

### Q: 如何知道模型是否加载成功？

A: 检查 ComfyUI 日志或使用 `/object_info` API 端点查看可用模型列表。

### Q: 可以多个 Endpoint 共享同一个 Network Volume 吗？

A: 可以，但需要注意并发访问可能影响性能。建议为高负载场景使用独立的 Network Volume。

### Q: Network Volume 的成本是多少？

A: 根据 RunPod 定价，Network Volume 按存储容量和区域计费。请查看 [RunPod 定价页面](https://www.runpod.io/pricing) 获取最新价格。

### Q: extra_model_paths.yaml 中没写的路径会自动加载吗？

A: **不会**。只有 `extra_model_paths.yaml` 中明确配置的路径才会被 ComfyUI 搜索和加载。未配置的目录即使存在文件也不会被自动发现。详见 [extra_model_paths.yaml 常见问题](extra_model_paths-faq.md)。

