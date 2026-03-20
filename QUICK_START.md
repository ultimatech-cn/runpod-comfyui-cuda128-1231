# Quick Start

This repository supports the MoshiMosh pipeline in two stages:

- `SDXL` for image generation / keyframe generation
- `Wan` for video generation from approved keyframes

## Prerequisites

- Docker Desktop is installed and running
- NVIDIA GPU support is available for Docker
- At least 150 GB of free disk space for image builds and model cache

## 1. Build the image

```powershell
cd "E:\Program Files\runpod-comfyui-cuda128-1231"
docker build --platform linux/amd64 -t runpod-comfyui-cuda128:local .
```

## 2. Prepare local data directories

```powershell
New-Item -ItemType Directory -Force -Path ".\data\comfyui\output"
New-Item -ItemType Directory -Force -Path ".\data\runpod-volume"
```

## 3. Start the stack

```powershell
docker-compose up
```

Available endpoints:

- ComfyUI: `http://localhost:8188`
- Worker API: `http://localhost:8000`
- Swagger UI: `http://localhost:8000/docs`

## 4. Test the default workflows

Default payloads:

- `test_resources/moshimosh_sdxl_runpod.json`
- `test_resources/moshimosh_videogen_runpod.json`

### Via Swagger

1. Open `http://localhost:8000/docs`
2. Use `/runsync`
3. Paste one of the default JSON payloads
4. Execute

### Via PowerShell

```powershell
$jsonContent = Get-Content "test_resources\moshimosh_sdxl_runpod.json" -Raw -Encoding UTF8
$response = Invoke-RestMethod -Uri "http://localhost:8000/runsync" -Method Post -Body $jsonContent -ContentType "application/json"
$response | ConvertTo-Json -Depth 10
```

Switch the file path to `test_resources\moshimosh_videogen_runpod.json` to test the video stage.

## 5. Verify models on a mounted volume

```powershell
bash scripts/verify-models.sh /workspace
```

The script reports both MoshiMosh stages:

- image stage (SDXL)
- video stage (Wan)

## 6. Stop the stack

```powershell
docker-compose down
```
