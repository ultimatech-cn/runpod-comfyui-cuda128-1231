# worker-comfyui

> Package [ComfyUI](https://github.com/comfyanonymous/ComfyUI) as a serviceable API that can be tested locally and deployed in RunPod/container environments.

<p align="center">
  <img src="assets/worker_sitting_in_comfy_chair.jpg" title="Worker sitting in comfy chair" />
</p>

[![Runpod](https://api.runpod.io/badge/ultimatech-cn/runpod-comfyui-cuda128)](https://console.runpod.io/hub/ultimatech-cn/runpod-comfyui-cuda128)

---

This project is based on the official `runpod/worker-comfyui` and includes commonly used custom nodes and models. It adds the following capabilities:

- **Image Input Support**: HTTP(S) URLs and Base64 (URLs are automatically downloaded and converted to Base64)
- **Path Normalization**: Automatically standardizes Windows-style paths in workflows (`\\` → `/`)
- **Docker Local Testing**: One-click local startup with Swagger test interface
- **Deployment Documentation**: Guides and scripts for publishing to Docker Hub and RunPod Hub

## Table of Contents

- [Quickstart](#quickstart)
- [What's Included](#whats-included)
- [Local Development & Testing](#local-development--testing)
- [API Specification](#api-specification)
- [Usage](#usage)
- [Getting the Workflow JSON](#getting-the-workflow-json)
- [Build Optimization](#build-optimization)
- [Publish to Docker Hub](#publish-to-docker-hub)
- [Further Documentation](#further-documentation)

---

## Quickstart

For the fastest start, refer to the quick guide:

- [QUICK_START.md](./QUICK_START.md)

Core steps (Windows example):

1. **Build the image** (first build takes 1.5-5 hours, mainly downloading models)
   ```powershell
   cd "E:\Program Files\runpod-comfyui-cuda128"
   docker build --platform linux/amd64 -t runpod-comfyui-cuda128:local .
   ```
   
   > 💡 **Optimization Tip**: If build time is too long, use the `Dockerfile.optimized` + Network Volume approach to reduce build time to 10-30 minutes. See [Network Volume Setup Guide](docs/network-volume-setup.md)

2. **Start local environment**
   ```powershell
   docker-compose up
   ```
   - Worker API: http://localhost:8000 (Swagger: http://localhost:8000/docs)
   - ComfyUI: http://localhost:8188

3. **Send a test request** (using `test_input copy 4.json`)
   ```powershell
   python test_local.py
   ```

## What's Included

This custom ComfyUI worker includes:

### Pre-installed Models:

- **SDXL Checkpoint**: `ultraRealisticByStable_v20FP16.safetensors`
- **Wan2.2 Checkpoint**: `wan2.2-i2v-rapid-aio-v10-nsfw.safetensors`
- **CLIP Vision**: `clip_vision_h.safetensors` (for Wan2.2)
- **IP-Adapter**: `ip-adapter_pulid_sdxl_fp16.safetensors` (for SDXL)
- **ReActor Models**: `inswapper_128.onnx`, `reswapper_128.onnx`, `hyperswap_1a/b/c_256.onnx`
- **FaceRestore Models**: `GFPGANv1.4.pth`, `GPEN-BFR-512.onnx`
- **Upscale Models**: `RealESRGAN_x2.pth`
- **InsightFace Models**: AntelopeV2 models for face recognition
- **Multiple LoRAs**: SDXL and Wan2.2 LoRAs for various styles and effects

### Custom Nodes:

- **PuLID_ComfyUI** - Advanced face control and identity preservation
- **ComfyUI-ReActor** - Face swapping and restoration
- **rgthree-comfy** - Additional utility nodes
- **ComfyUI-KJNodes** - Enhanced workflow nodes
- **ComfyUI-Manager** - Node and model management
- **was-node-suite-comfyui** - Advanced image processing and BLIP models
- **ComfyUI-Crystools** - Workflow utilities
- **ComfyUI-VideoHelperSuite** - Video processing capabilities
- **comfyui-mixlab-nodes** - Additional workflow enhancements
- **ComfyUI-Frame-Interpolation** - Video frame interpolation

> **Note**: Models can be stored in Network Volume instead of the image to reduce build time. See [Build Optimization](#build-optimization) section.

## Local Development & Testing

For detailed instructions, see [docs/development.md](docs/development.md) and [docs/local-testing-and-publish.md](docs/local-testing-and-publish.md).

This repository includes:

- `docker-compose.yml` (one-click local startup with ports 8000/8188 mapped)
- `test_input copy 4.json` (contains URL image input and complete workflow)
- `test_local.py` (local runsync test script)

## API Specification

Provides standard RunPod Serverless-style endpoints (also available locally): `/run`, `/runsync`, `/health`.

- Default returns Base64 images; if S3 is configured, returns S3 URLs (see [Configuration Guide](docs/configuration.md)).
- `/runsync`: Synchronously waits for results; `/run`: Asynchronously returns jobId, then poll `/status`.

### Input

```json
{
  "input": {
    "workflow": { ... workflow JSON ... },
    "images": [
      {
        "name": "test_img.jpg",
        "image": "https://example.com/your_image.jpg"
      }
    ],
    "comfy_org_api_key": "optional-api-key"
  }
}
```

The following tables describe the fields within the `input` object:

| Field Path                | Type   | Required | Description                                                                                                                                |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `input`                   | Object | Yes      | Top-level object containing request data.                                                                                                  |
| `input.workflow`          | Object | Yes      | The ComfyUI workflow exported in the required format.                                                                                      |
| `input.images`            | Array  | No       | Optional array of input images. Each image is uploaded to ComfyUI's `input` directory and can be referenced by its `name` in the workflow. |
| `input.comfy_org_api_key` | String | No       | Optional per-request Comfy.org API key for API Nodes. Overrides the `COMFY_ORG_API_KEY` environment variable if both are set.              |

#### `input.images` Object

Each object within the `input.images` array must contain:

| Field Name | Type   | Required | Description                                                                                                                         |
| ---------- | ------ | -------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `name`     | String | Yes      | Filename used to reference the image in the workflow (e.g., via a "Load Image" node). Must be unique within the array.             |
| `image`    | String | Yes      | Supports Base64 (with optional `data:image/...;base64,` prefix) or HTTP(S) URL. If URL, it will be automatically downloaded and converted to Base64 on the server. |

> [!NOTE]
> The `input.images` array supports two formats:
> - **Base64 encoded string**: Use `data:image/png;base64,<base64_string>` or just `<base64_string>`
> - **Image URL**: Use `http://` or `https://` URL to the image (handler will download automatically)
> 
> **Size Constraints**: RunPod API limits (10MB for `/run`, 20MB for `/runsync`) apply to the entire request. Using image URLs instead of base64 can significantly reduce request size.

### Output

```json
{
  "id": "sync-uuid-string",
  "status": "COMPLETED",
  "output": {
    "images": [
      {
        "filename": "ComfyUI_00001_.png",
        "type": "base64",
        "data": "iVBORw0KGgoAAAANSUhEUg..."
      }
    ]
  },
  "delayTime": 123,
  "executionTime": 4567
}
```

> **Note**: The output format changed in version 5.0.0+. Images are returned as an array in `output.images`. Each image object contains `filename`, `type` (either `"base64"` or `"s3_url"`), and `data` (the base64 string or S3 URL). Videos are also supported and returned in the same format.

## Usage

Interact with deployed RunPod endpoints in the same way:

1. **Synchronous**: POST to `/runsync`, wait for response.
2. **Asynchronous**: POST to `/run` to get `jobId`, then poll `/status`.

Local direct access (default ports):

- API Documentation (Swagger): http://localhost:8000/docs
- Synchronous endpoint: `POST http://localhost:8000/runsync`

### Example Request

This example shows a simplified SDXL image-to-image workflow using an image URL:

```json
{
  "input": {
    "images": [
      {
        "name": "test_img.jpg",
        "image": "https://pic.imgdd.cc/item/69071860c1e67097311264a1.jpg"
      }
    ],
    "workflow": {
      "3": {
        "inputs": {
          "seed": 814583843642114,
          "steps": 8,
          "cfg": 1.1,
          "sampler_name": "lcm",
          "scheduler": "exponential",
          "denoise": 1,
          "model": ["4", 0],
          "positive": ["22", 0],
          "negative": ["23", 0],
          "latent_image": ["46", 0]
        },
        "class_type": "KSampler",
        "_meta": {
          "title": "KSampler"
        }
      },
      "4": {
        "inputs": {
          "ckpt_name": "SDXL/ultraRealisticByStable_v20FP16.safetensors"
        },
        "class_type": "CheckpointLoaderSimple",
        "_meta": {
          "title": "Load Checkpoint"
        }
      },
      "8": {
        "inputs": {
          "samples": ["3", 0],
          "vae": ["4", 2]
        },
        "class_type": "VAEDecode",
        "_meta": {
          "title": "VAE Decode"
        }
      },
      "12": {
        "inputs": {
          "image": "test_img.jpg"
        },
        "class_type": "LoadImage",
        "_meta": {
          "title": "Load Image"
        }
      },
      "22": {
        "inputs": {
          "text": "a beautiful woman, high quality, detailed",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode",
        "_meta": {
          "title": "CLIP Text Encode (Prompt)"
        }
      },
      "23": {
        "inputs": {
          "text": "lowres, low quality, worst quality, artifacts",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode",
        "_meta": {
          "title": "CLIP Text Encode (Negative Prompt)"
        }
      },
      "46": {
        "inputs": {
          "dimensions": " 832 x 1216  (portrait)",
          "clip_scale": 1,
          "batch_size": 1
        },
        "class_type": "SDXL Empty Latent Image (rgthree)",
        "_meta": {
          "title": "SDXL Empty Latent Image (rgthree)"
        }
      },
      "112": {
        "inputs": {
          "filename_prefix": "ComfyUI",
          "images": ["8", 0]
        },
        "class_type": "SaveImage",
        "_meta": {
          "title": "Save Image"
        }
      }
    }
  }
}
```

## Getting the Workflow JSON

To export workflow JSON for API use:

1. Open ComfyUI
2. Navigate to `Workflow > Export (API)` in the top menu
3. Use the downloaded JSON as the value for `input.workflow`

> **Tip**: If your workflow contains Windows-style paths (e.g., `SDXL\\xxx.safetensors`), this service will automatically convert them to Unix-style (`SDXL/xxx.safetensors`).

## Build Optimization

The standard `Dockerfile` includes all models, resulting in:
- **Build time**: 1.5-5 hours
- **Image size**: ~92 GB
- **Push time**: Several hours

To optimize build time, use `Dockerfile.optimized` with Network Volume:

- **Build time**: 10-30 minutes (80-90% reduction)
- **Image size**: ~5-10 GB (85-90% reduction)
- **Push time**: 10-30 minutes (80-90% reduction)
- **Flexibility**: Update models without rebuilding the image

See [Network Volume Setup Guide](docs/network-volume-setup.md) for detailed instructions.

**Quick Model Download**: Use the automated script `scripts/download-models-to-volume.sh` to download all models in one go. See the guide for details.

## Publish to Docker Hub

> **⚠️ Important Note (2024 Update)**:
> 
> The new Docker Hub interface (2024-2025) **no longer provides automatic build functionality** (or only for paid users). When creating a repository, you won't find the "Create Automated Build" option, and there's no "Builds" tab in repository settings.
> 
> **We recommend using GitHub Actions** for automated builds and pushes.

### Recommended: Use GitHub Actions for Automated Builds (Primary Method)

GitHub Actions provides powerful CI/CD functionality to automatically build and push Docker images to Docker Hub.

**Configuration Steps**:
1. Create a repository on Docker Hub (e.g., `your-username/comfyui-cuda128`)
2. Configure Secrets in your GitHub repository:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Docker Hub Access Token
3. For detailed configuration, see: [GitHub Actions Automated Build Configuration Guide](docs/dockerhub-setup.md)

**Advantages**:
- ✅ Free to use (GitHub Actions free tier)
- ✅ Powerful and highly customizable
- ✅ Supports multiple trigger conditions (push, tag, manual trigger, etc.)
- ✅ Can use GitHub Actions Cache to speed up builds

**Note**:
- GitHub Actions free runners have limited disk space (~14GB), which may not be enough to build a 92GB image
- If build fails, consider using paid runners or cloud build services

### Alternative: Docker Hub Automatic Build (If Available)

If Docker Hub automatic build functionality is still available in your account, you can try:

**Configuration Steps**:
1. Create a repository on Docker Hub
2. Look for the "Builds" tab or "Create Automated Build" option
3. For detailed configuration, see: [Docker Hub Automatic Build Configuration Guide](docs/dockerhub-autobuild-setup.md)

**Note**: According to the 2024-2025 new interface, this feature may no longer be available or may require payment.

### Alternative 2: Local Build and Push

If you need to build and push locally, see:

- [docs/local-testing-and-publish.md](docs/local-testing-and-publish.md)

Core commands (example):

```powershell
docker build --platform linux/amd64 -t your-username/comfyui-cuda128:latest .
docker login
docker push your-username/comfyui-cuda128:latest
```

**Note**:
- Using standard `Dockerfile`: Image size ~92GB, local push may take several hours and is prone to network failures
- Using `Dockerfile.optimized` + Network Volume: Image size ~5-10GB, faster push, see [Network Volume Setup Guide](docs/network-volume-setup.md)

## Further Documentation

- **[QUICK_START.md](QUICK_START.md)** — Quick start: Local testing and publishing
- **[Development Guide](docs/development.md)** — Local development and unit testing
- **[Configuration Guide](docs/configuration.md)** — Environment variables and S3 configuration
- **[Customization Guide](docs/customization.md)** — Custom nodes and models (including Network Volume approach)
- **[Network Volume Setup](docs/network-volume-setup.md)** — 🚀 **Optimize Build Time**: Use Network Volume to store models, reducing build time from 1.5-5 hours to 10-30 minutes
- **[extra_model_paths.yaml FAQ](docs/extra_model_paths-faq.md)** — Common questions about model path configuration
- **[Deployment Guide](docs/deployment.md)** — Deploy endpoints on RunPod
- **[CI/CD Guide](docs/ci-cd.md)** — Automated builds and publishing
- **[Acknowledgments](docs/acknowledgments.md)** — Acknowledgments

---

If you just want to quickly start local testing and publishing, see:

- [QUICK_START.md](./QUICK_START.md)
- [docs/local-testing-and-publish.md](docs/local-testing-and-publish.md)
