# MoshiMosh ComfyUI Worker

MoshiMosh image and video generation worker built on `runpod/worker-comfyui`.

This repository serves a single MoshiMosh production pipeline with two stages:

- `SDXL` generates images / keyframes.
- `Wan` turns approved keyframes into videos.

The project still keeps historical workflows for reference, but the default supported entrypoints are the current MoshiMosh image-stage and video-stage requests.

## Default test entrypoints

Current default API payloads live in [test_resources](./test_resources):

- `test_resources/moshimosh_sdxl_runpod.json`
  - Default SDXL image-stage request.
- `test_resources/moshimosh_videogen_runpod.json`
  - Default Wan video-stage request.
- `test_resources/API_MoshiMoshAI(VideoGen) (2).json`
  - Original customer-provided workflow, kept for traceability.

Historical workflows remain under `test_resources/archive/` and are not the default test inputs.

## Runtime model groups

The repository now treats models as two grouped stages of the same MoshiMosh pipeline.

### Image stage (SDXL)

Typical dependencies:

- `models/checkpoints/SDXL/RealMixPony.safetensors`
- `models/checkpoints/SDXL/WAIillustriousSDXL.safetensors`
- `models/checkpoints/SDXL/ultraRealisticByStable_v20FP16.safetensors`
- `models/ipadapter/ip-adapter-plus_sdxl_vit-h.safetensors`
- `models/ipadapter/ip-adapter-plus-face_sdxl_vit-h.safetensors`
- `models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors`
- Florence-2, FaceDetailer, ReActor, and restore dependencies when the workflow uses them

### Video stage (Wan)

Typical dependencies:

- `models/unet/DaSiWaV9HIGH.safetensors`
- `models/unet/DaSiWaV9LOW.safetensors`
- `models/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors`
- `models/vae/wan_2.1_vae.safetensors`
- `models/loras/GeneralHIGH.safetensors`
- `models/loras/DR34ML4YHIGH.safetensors`
- `models/loras/CumshotHIGH.safetensors`
- `models/loras/GeneralLOW.safetensors`
- `models/loras/DR34ML4YLOW.safetensors`
- `models/loras/CumshotLOW.safetensors`
- `models/vfi/rife47.pth`

Use `scripts/verify-models.sh` to verify both stages against a mounted RunPod volume.

## Local usage

1. Build the image:

```powershell
cd "E:\Program Files\runpod-comfyui-cuda128-1231"
docker build --platform linux/amd64 -t runpod-comfyui-cuda128:local .
```

2. Start local services:

```powershell
docker-compose up
```

3. Call the worker API:

- Swagger: `http://localhost:8000/docs`
- ComfyUI: `http://localhost:8188`

The worker expects standard RunPod-style input:

```json
{
  "input": {
    "workflow": { "...": "ComfyUI workflow JSON" },
    "images": [
      {
        "name": "test_img.jpg",
        "image": "https://example.com/input.jpg"
      }
    ]
  }
}
```

`input.images[].name` must match the filename referenced by `LoadImage` nodes in the workflow.

## Notes

- `Dockerfile`, `src/start.sh`, and `handler.py` include the RunPod Serverless CUDA initialization fix required for stable startup on supported GPUs.
- Workflow compatibility depends on the currently installed node versions. When a node signature changes, update the workflow JSON rather than relying on older exported payloads.
- The repository name still contains `1231` for historical reasons. This release only normalizes the project description, not the repo or image names.

## Further reading

- [QUICK_START.md](./QUICK_START.md)
- [docs/network-volume-setup.md](./docs/network-volume-setup.md)
- [docs/local-testing-and-publish.md](./docs/local-testing-and-publish.md)
