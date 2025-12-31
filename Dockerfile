# 优化版 Dockerfile - 使用 Network Volume 存储所有模型
# 此版本完全移除了所有模型下载（包括 insightface、BLIP 等），构建时间从 1.5-5 小时缩短到 10-30 分钟
# 所有模型必须通过 download-models-to-volume.sh 下载到 Network Volume
# 模型将通过软链接从 Network Volume 加载，详见 docs/network-volume-setup.md

FROM runpod/worker-comfyui:5.7.1-base-cuda12.8.1

# Set environment variables for better maintainability
ENV COMFYUI_PATH=/comfyui
ENV DEBIAN_FRONTEND=noninteractive

# Copy custom handler.py to override the base image's handler
# This allows you to use your enhanced handler with URL image support and path normalization
COPY handler.py /handler.py

# Copy custom start.sh to override the base image's start script
# This includes symlink setup for Network Volume model directories
COPY src/start.sh /start.sh
RUN chmod +x /start.sh

# Ensure required tools are installed (wget, git, unzip should already be in base image, but verify)
# Note: build-essential, g++, and python3-dev are needed to compile insightface (Cython/C++ extensions)
# python3-dev provides Python.h header files needed for compiling Python extensions
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        git \
        unzip \
        ffmpeg \
        curl \
        ca-certificates \
        build-essential \
        g++ \
        python3-dev \
    && rm -rf /var/lib/apt/lists/*

# 注意：不再创建模型目录，因为模型将存储在 Network Volume 中
# Network Volume 挂载到 /runpod-volume，通过软链接映射到 /comfyui/models/...
# 软链接在容器启动时由 start.sh 自动创建

# Install all custom nodes in a single RUN block (optimizes Docker layers)
# Each node installs its requirements.txt if it exists
# Note: Using python3 instead of /venv/bin/python as the base image may not have /venv
# Remove existing directories before cloning to avoid "already exists" errors
# Configure git to avoid credential prompts and handle network issues
RUN git config --global --add safe.directory '*' && \
    git config --global credential.helper '' && \
    git config --global url."https://github.com/".insteadOf git@github.com: && \
    git config --global http.sslVerify true && \
    git config --global http.postBuffer 524288000 && \
    cd $COMFYUI_PATH/custom_nodes && \
    # Install ComfyUI-Manager (Essential utility)
    rm -rf ComfyUI-Manager && \
    git clone --depth 1 https://github.com/Comfy-Org/ComfyUI-Manager.git ComfyUI-Manager && \
    (cd ComfyUI-Manager && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-Florence2
    rm -rf ComfyUI-Florence2 && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-Florence2.git ComfyUI-Florence2 && \
    (cd ComfyUI-Florence2 && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI_Comfyroll_CustomNodes
    rm -rf ComfyUI_Comfyroll_CustomNodes && \
    git clone --depth 1 https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git ComfyUI_Comfyroll_CustomNodes && \
    (cd ComfyUI_Comfyroll_CustomNodes && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI_essentials
    rm -rf ComfyUI_essentials && \
    git clone --depth 1 https://github.com/cubiq/ComfyUI_essentials.git ComfyUI_essentials && \
    (cd ComfyUI_essentials && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-Frame-Interpolation
    rm -rf ComfyUI-Frame-Interpolation && \
    git clone --depth 1 https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git ComfyUI-Frame-Interpolation && \
    (cd ComfyUI-Frame-Interpolation && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install was-node-suite-comfyui
    rm -rf was-node-suite-comfyui && \
    git clone --depth 1 https://github.com/WASasquatch/was-node-suite-comfyui.git was-node-suite-comfyui && \
    (cd was-node-suite-comfyui && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-Logic
    rm -rf ComfyUI-Logic && \
    git clone --depth 1 https://github.com/theUpsider/ComfyUI-Logic.git ComfyUI-Logic && \
    (cd ComfyUI-Logic && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI_IPAdapter_plus
    rm -rf ComfyUI_IPAdapter_plus && \
    git clone --depth 1 https://github.com/cubiq/ComfyUI_IPAdapter_plus.git ComfyUI_IPAdapter_plus && \
    (cd ComfyUI_IPAdapter_plus && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-Easy-Use
    rm -rf ComfyUI-Easy-Use && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git ComfyUI-Easy-Use && \
    (cd ComfyUI-Easy-Use && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-Impact-Pack
    rm -rf ComfyUI-Impact-Pack && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack.git ComfyUI-Impact-Pack && \
    (cd ComfyUI-Impact-Pack && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    (python3 ComfyUI-Impact-Pack/install.py || true) && \
    \
    # Install ComfyUI-Impact-Subpack
    rm -rf ComfyUI-Impact-Subpack && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git ComfyUI-Impact-Subpack && \
    (cd ComfyUI-Impact-Subpack && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    (python3 ComfyUI-Impact-Subpack/install.py || true) && \
    \
    # Install ComfyUI-ReActor
    rm -rf ComfyUI-ReActor && \
    git clone --depth 1 https://github.com/Gourieff/comfyui-reactor.git ComfyUI-ReActor && \
    (cd ComfyUI-ReActor && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    # Disable NSFW detection in ReActor by modifying reactor_sfw.py to always return False
    (python3 -c "import re; f=open('$COMFYUI_PATH/custom_nodes/ComfyUI-ReActor/scripts/reactor_sfw.py','r',encoding='utf-8'); c=f.read(); f.close(); c=re.sub(r'def nsfw_image\([^)]+\):.*?(?=\n\ndef |\nclass |\Z)', 'def nsfw_image(img_data, model_path: str):\n    return False', c, flags=re.DOTALL); f=open('$COMFYUI_PATH/custom_nodes/ComfyUI-ReActor/scripts/reactor_sfw.py','w',encoding='utf-8'); f.write(c); f.close()" 2>/dev/null || true) && \
    \
    # Install ComfyUI-VideoHelperSuite (Required for Video Workflows)
    rm -rf comfyui-videohelpersuite && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git comfyui-videohelpersuite && \
    (cd comfyui-videohelpersuite && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    # Install ComfyUI-KJNodes
    rm -rf comfyui-kjnodes && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git comfyui-kjnodes && \
    (cd comfyui-kjnodes && [ ! -f requirements.txt ] || python3 -m pip install --no-cache-dir -r requirements.txt || true) && \
    \
    cd $COMFYUI_PATH

# Support for Network Volume - Use symlinks instead of extra_model_paths.yaml
# Symlinks are created at runtime in start.sh to link /comfyui/models/* to /runpod-volume/models/*
# This approach is more transparent and compatible with all nodes (including those with hardcoded paths)
# No need to copy extra_model_paths.yaml - symlinks handle everything automatically
#
# IMPORTANT: All models must be downloaded to Network Volume using download-models-to-volume.sh
# The following models are NO LONGER downloaded during image build:
# - ReActor inswapper_128.onnx (should be in /runpod-volume/models/insightface/)
# - InsightFace AntelopeV2 (should be in /runpod-volume/models/insightface/models/antelopev2/)
# - BLIP models (should be in /runpod-volume/models/blip/)
# 
# Use the download script before deploying:
#   bash scripts/download-models-to-volume.sh /runpod-volume
#
# If Network Volume doesn't have these models, nodes will attempt to download them at runtime,
# but this may cause delays or failures. It's recommended to pre-download all models.

# ============================================
# 模型下载已完全移除 - 使用 Network Volume 存储所有模型
# ============================================
# 所有模型（checkpoints、LoRAs、VAE、ControlNet、insightface、BLIP 等）应存储在 Network Volume 中
# Network Volume 挂载路径: /runpod-volume
# 模型目录结构: /runpod-volume/models/checkpoints/, /runpod-volume/models/loras/, 等
# 
# 使用软链接方式（而非 extra_model_paths.yaml）：
# - 容器启动时，start.sh 会自动创建软链接 /comfyui/models/* -> /runpod-volume/models/*
# - 这种方式更透明，兼容所有节点（包括使用硬编码路径的节点）
# - 无需维护配置文件，自动适配所有模型目录
# 
# 配置步骤：
# 1. 在 RunPod 控制台创建 Network Volume
# 2. 在临时 Pod 中运行下载脚本（Network Volume 已挂载）：
#    bash scripts/download-models-to-volume.sh /runpod-volume
# 3. 在 Endpoint 配置中附加 Network Volume
# 
# 注意：
# - 如果 Network Volume 中没有模型，节点会在运行时尝试下载，但可能导致延迟或失败
# - 强烈建议在部署前使用 download-models-to-volume.sh 预下载所有模型
# - 构建时间将从 1.5-5 小时缩短到 10-30 分钟（仅安装节点，不下载模型）
# 
# 详细说明请参考: docs/network-volume-setup.md
# ============================================

