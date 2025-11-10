#!/bin/bash
# 批量下载模型到 Network Volume 的脚本
# 基于 Dockerfile 中的模型下载任务
# 使用方法：在临时 Pod 中运行此脚本（Network Volume 已挂载）
#
# 重要说明：Network Volume 挂载点差异
# - 临时 Pod：Network Volume 通常挂载在 /workspace
# - Endpoint：Network Volume 挂载在 /runpod-volume
# 这是同一个 Network Volume，只是挂载点不同
# 在临时 Pod 中下载到 /workspace/models/ 的文件
# 在 Endpoint 中可以从 /runpod-volume/models/ 访问
#
# 用法：
#   bash scripts/download-models-to-volume.sh [VOLUME_PATH]
#   如果不指定 VOLUME_PATH，默认使用 /workspace（RunPod 临时 Pod 的默认挂载点）
#   如果临时 Pod 中 Network Volume 挂载到 /runpod-volume，使用：
#   bash scripts/download-models-to-volume.sh /runpod-volume

set -e  # 遇到错误立即退出

# 获取 Volume 路径（默认为 /workspace，RunPod 临时 Pod 的默认挂载点）
VOLUME_PATH="${1:-/workspace}"
MODELS_DIR="$VOLUME_PATH/models"

echo "=========================================="
echo "ComfyUI 模型批量下载脚本"
echo "基于 Dockerfile 模型下载任务"
echo "=========================================="
echo "目标路径: $MODELS_DIR"
echo ""

# 检查 Volume 路径是否存在
if [ ! -d "$VOLUME_PATH" ]; then
    echo "❌ 错误: Volume 路径不存在: $VOLUME_PATH"
    echo "请确认 Network Volume 已正确挂载"
    exit 1
fi

# 创建目录结构
echo "创建目录结构..."
mkdir -p "$MODELS_DIR/checkpoints/SDXL"
mkdir -p "$MODELS_DIR/checkpoints/Wan2.2"
mkdir -p "$MODELS_DIR/clip_vision/wan"
mkdir -p "$MODELS_DIR/pulid"
mkdir -p "$MODELS_DIR/insightface/models"
mkdir -p "$MODELS_DIR/insightface"  # 确保 insightface 根目录存在（用于 inswapper_128.onnx）
mkdir -p "$MODELS_DIR/reswapper"
mkdir -p "$MODELS_DIR/hyperswap"
mkdir -p "$MODELS_DIR/facerestore_models"
mkdir -p "$MODELS_DIR/upscale_models"
mkdir -p "$MODELS_DIR/loras/SDXL"
mkdir -p "$MODELS_DIR/loras/Wan2.2"
mkdir -p "$MODELS_DIR/blip"
mkdir -p "$MODELS_DIR/diffusion_models"
mkdir -p "$MODELS_DIR/prompt_generator/MiniCPM-V-2_6-int4"
mkdir -p "$MODELS_DIR/ultralytics/bbox"
mkdir -p "$MODELS_DIR/sams"
echo "✓ 目录结构创建完成"
echo ""

# 简单的下载函数：使用 wget -nc 自动跳过已存在的文件
download_file() {
    local url=$1
    local output_path=$2
    local description=$3
    
    mkdir -p "$(dirname "$output_path")"
    echo "下载: $description"
    wget -q --show-progress -nc -O "$output_path" "$url" || true
}

# ============================================
# InsightFace AntelopeV2 模型
# ============================================
echo "=========================================="
echo "下载 InsightFace AntelopeV2 模型"
echo "=========================================="

if [ ! -d "$MODELS_DIR/insightface/models/antelopev2" ] || [ -z "$(ls -A "$MODELS_DIR/insightface/models/antelopev2" 2>/dev/null)" ]; then
    echo "下载 InsightFace AntelopeV2..."
    TEMP_ZIP="/tmp/antelopev2.zip"
    wget -q --show-progress -nc -O "$TEMP_ZIP" "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip" || true
    if [ -f "$TEMP_ZIP" ]; then
        unzip -q "$TEMP_ZIP" -d "$MODELS_DIR/insightface/models/"
        rm "$TEMP_ZIP"
        echo "✓ InsightFace AntelopeV2 下载并解压完成"
    fi
else
    echo "⚠ InsightFace AntelopeV2 已存在，跳过"
fi

echo ""

# ============================================
# Checkpoint 模型
# ============================================
echo "=========================================="
echo "下载 Checkpoint 模型"
echo "=========================================="

download_file \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/ultraRealisticByStable_v20FP16.safetensors" \
    "$MODELS_DIR/checkpoints/SDXL/ultraRealisticByStable_v20FP16.safetensors" \
    "SDXL Checkpoint"

download_file \
    "https://huggingface.co/Phr00t/WAN2.2-14B-Rapid-AllInOne/resolve/main/v10/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors" \
    "$MODELS_DIR/checkpoints/Wan2.2/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors" \
    "WAN2.2 Checkpoint"

echo ""

# ============================================
# CLIP Vision 和 PuLID 模型
# ============================================
echo "=========================================="
echo "下载 CLIP Vision 和 PuLID 模型"
echo "=========================================="

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
    "$MODELS_DIR/clip_vision/wan/clip_vision_h.safetensors" \
    "CLIP Vision (WAN)"

download_file \
    "https://huggingface.co/huchenlei/ipadapter_pulid/resolve/main/ip-adapter_pulid_sdxl_fp16.safetensors" \
    "$MODELS_DIR/pulid/ip-adapter_pulid_sdxl_fp16.safetensors" \
    "PuLID IP-Adapter"

echo ""

# ============================================
# ReActor 和 HyperSwap 模型
# ============================================
echo "=========================================="
echo "下载 ReActor 和 HyperSwap 模型"
echo "=========================================="

# 根据 ComfyUI-ReActor 官方文档 (https://github.com/Gourieff/ComfyUI-ReActor)：
# - swap_model 参数的值是 "inswapper_128.onnx"
# - inswapper_128.onnx 必须放在 ComfyUI/models/insightface/ 根目录
# - ReActor 节点使用 folder_paths.get_folder_paths("insightface") 来查找 .onnx 文件
# - reswapper_128.onnx 放在 ComfyUI/models/reswapper/ 目录（用于其他功能）

# 下载 inswapper_128.onnx 到 insightface 目录（swap_model 参数使用此文件）
download_file \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx" \
    "$MODELS_DIR/insightface/inswapper_128.onnx" \
    "ReActor inswapper (insightface根目录 - swap_model参数使用此文件)"

# 下载 reswapper_128.onnx 到 reswapper 目录（用于其他功能）
download_file \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/reswapper_128.onnx" \
    "$MODELS_DIR/reswapper/reswapper_128.onnx" \
    "ReActor reswapper (reswapper目录)"

# 验证文件是否下载成功
echo "验证 ReActor 模型文件..."
if [ -f "$MODELS_DIR/insightface/inswapper_128.onnx" ]; then
    echo "✓ inswapper_128.onnx 已下载到 insightface/ (swap_model 参数使用此文件)"
    ls -lh "$MODELS_DIR/insightface/inswapper_128.onnx" | awk '{print "  文件大小: " $5}'
else
    echo "✗ 警告: inswapper_128.onnx 下载失败 - 这是 swap_model 参数必需的文件！"
fi

if [ -f "$MODELS_DIR/reswapper/reswapper_128.onnx" ]; then
    echo "✓ reswapper_128.onnx 已下载到 reswapper/"
    ls -lh "$MODELS_DIR/reswapper/reswapper_128.onnx" | awk '{print "  文件大小: " $5}'
else
    echo "✗ 警告: reswapper_128.onnx 下载失败"
fi

# 列出 insightface 目录中的所有 .onnx 文件，帮助调试
echo "  insightface 目录中的 .onnx 文件（ReActor swap_model 从此目录读取）："
find "$MODELS_DIR/insightface" -maxdepth 1 -name "*.onnx" -type f 2>/dev/null | head -10 || echo "    (未找到 .onnx 文件)"

download_file \
    "https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1a_256.onnx" \
    "$MODELS_DIR/hyperswap/hyperswap_1a_256.onnx" \
    "HyperSwap 1a"

download_file \
    "https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1b_256.onnx" \
    "$MODELS_DIR/hyperswap/hyperswap_1b_256.onnx" \
    "HyperSwap 1b"

download_file \
    "https://huggingface.co/facefusion/models-3.3.0/resolve/main/hyperswap_1c_256.onnx" \
    "$MODELS_DIR/hyperswap/hyperswap_1c_256.onnx" \
    "HyperSwap 1c"

echo ""

# ============================================
# 面部修复和超分辨率模型
# ============================================
echo "=========================================="
echo "下载面部修复和超分辨率模型"
echo "=========================================="

download_file \
    "https://huggingface.co/ai-forever/Real-ESRGAN/resolve/main/RealESRGAN_x2.pth" \
    "$MODELS_DIR/upscale_models/RealESRGAN_x2.pth" \
    "RealESRGAN x2"

download_file \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/facerestore_models/GFPGANv1.4.pth" \
    "$MODELS_DIR/facerestore_models/GFPGANv1.4.pth" \
    "GFPGAN v1.4"

download_file \
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/facerestore_models/GPEN-BFR-512.onnx" \
    "$MODELS_DIR/facerestore_models/GPEN-BFR-512.onnx" \
    "GPEN-BFR-512"

echo ""

# ============================================
# LoRA 模型 (SDXL)
# ============================================
echo "=========================================="
echo "下载 LoRA 模型 (SDXL)"
echo "=========================================="

download_file \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/subtle-analsex-xl3.safetensors" \
    "$MODELS_DIR/loras/SDXL/subtle-analsex-xl3.safetensors" \
    "SDXL LoRA: subtle-analsex-xl3"

download_file \
    "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/SDXL/LCMV2-PONYplus-PAseer.safetensors" \
    "$MODELS_DIR/loras/SDXL/LCMV2-PONYplus-PAseer.safetensors" \
    "SDXL LoRA: LCMV2-PONYplus-PAseer"

echo ""

# ============================================
# LoRA 模型 (Wan2.2)
# ============================================
echo "=========================================="
echo "下载 LoRA 模型 (Wan2.2)"
echo "=========================================="

# 定义 Wan2.2 LoRA 列表（与 Dockerfile 保持一致）
declare -a wan22_loras=(
    "DR34MJOB_I2V_14b_HighNoise.safetensors"
    "DR34MJOB_I2V_14b_LowNoise.safetensors"
    "W22_NSFW_Posing_Nude_i2v_HN_v1.safetensors"
    "W22_NSFW_Posing_Nude_i2v_LN_v1.safetensors"
    "huge-titfuck-high.safetensors"
    "huge-titfuck-low.safetensors"
    "mql_massage_tits_wan22_i2v_v1_high_noise.safetensors"
    "mql_massage_tits_wan22_i2v_v1_low_noise.safetensors"
    "nsfw_wan_14b_spooning_leg_lifted_sex_position.safetensors"
    "pworship_high_noise.safetensors"
    "pworship_low_noise.safetensors"
    "spanking_for_wan_v1_e128.safetensors"
    "sockjob_wan_v1.safetensors"
    "wan-thiccum-v3.safetensors"
    "wan2.2-i2v-high-oral-insertion-v1.0.safetensors"
    "wan2.2-i2v-low-oral-insertion-v1.0.safetensors"
    "wan22-jellyhips-i2v-13epoc-high-k3nk.safetensors"
    "wan22-jellyhips-i2v-23epoc-low-k3nk.safetensors"
    "wan_shoejob_footjob_14B_v10_e15.safetensors"
    "zurimix-high-i2v.safetensors"
    "zurimix-low-i2v.safetensors"
)

for lora in "${wan22_loras[@]}"; do
    download_file \
        "https://huggingface.co/datasets/Robin9527/LoRA/resolve/main/Wan22/$lora" \
        "$MODELS_DIR/loras/Wan2.2/$lora" \
        "Wan2.2 LoRA: $lora"
done

echo ""


# ============================================
# MiniCPM-V-2_6-int4 模型（使用 huggingface_hub 下载整个目录）
# ============================================
echo "=========================================="
echo "下载 MiniCPM-V-2_6-int4 模型"
echo "=========================================="

if command -v python3 &> /dev/null; then
    # 检查并安装 huggingface_hub
    echo "检查 huggingface_hub 是否已安装..."
    continue_section=false
    if ! python3 -c "import huggingface_hub" 2>/dev/null; then
        echo "huggingface_hub 未安装，正在自动安装..."
        if pip install --quiet huggingface_hub 2>/dev/null || pip3 install --quiet huggingface_hub 2>/dev/null; then
            echo "✓ huggingface_hub 安装完成"
            continue_section=true
        else
            echo "✗ 无法安装 huggingface_hub，跳过 MiniCPM-V-2_6-int4 模型下载"
            echo "  提示: 请手动安装: pip install huggingface_hub"
        fi
    else
        echo "✓ huggingface_hub 已安装"
        continue_section=true
    fi
    
    if [ "$continue_section" = "true" ]; then
    
    echo "使用 Python huggingface_hub 下载 MiniCPM-V-2_6-int4 模型..."
    python3 << PYTHON_SCRIPT
from huggingface_hub import snapshot_download
import os

model_dir = '$MODELS_DIR/prompt_generator/MiniCPM-V-2_6-int4'
os.makedirs(model_dir, exist_ok=True)

print('下载 MiniCPM-V-2_6-int4 模型（完整目录）...')
try:
    snapshot_download(
        repo_id='openbmb/MiniCPM-V-2_6-int4',
        local_dir=model_dir
    )
    print('✓ MiniCPM-V-2_6-int4 模型下载完成')
except Exception as e:
    print(f'✗ 下载失败: {e}')
    print('提示: 请检查网络连接或手动安装: pip install huggingface_hub')
PYTHON_SCRIPT
    fi
else
    echo "⚠ Python3 未找到，跳过 MiniCPM-V-2_6-int4 模型下载"
    echo "  提示: 请安装 Python3 和 huggingface_hub: pip install huggingface_hub"
fi

echo ""

# ============================================
# BLIP 模型（可选，使用 transformers 下载）
# ============================================
echo "=========================================="
echo "下载 BLIP 模型（用于图像描述）"
echo "=========================================="

if command -v python3 &> /dev/null; then
    # 检查并安装 transformers
    echo "检查 transformers 是否已安装..."
    continue_section=false
    if ! python3 -c "import transformers" 2>/dev/null; then
        echo "transformers 未安装，正在自动安装..."
        if pip install --quiet transformers 2>/dev/null || pip3 install --quiet transformers 2>/dev/null; then
            echo "✓ transformers 安装完成"
            continue_section=true
        else
            echo "✗ 无法安装 transformers，跳过 BLIP 模型下载"
            echo "  提示: 请手动安装: pip install transformers"
        fi
    else
        echo "✓ transformers 已安装"
        continue_section=true
    fi
    
    if [ "$continue_section" = "true" ]; then
        # 检查并安装 hf_transfer（如果环境启用了快速下载）
        if [ "$HF_HUB_ENABLE_HF_TRANSFER" = "1" ] && ! python3 -c "import hf_transfer" 2>/dev/null; then
            echo "检测到 HF_HUB_ENABLE_HF_TRANSFER=1，正在安装 hf_transfer..."
            pip install --quiet hf_transfer 2>/dev/null || pip3 install --quiet hf_transfer 2>/dev/null || {
                echo "⚠ hf_transfer 安装失败，禁用快速下载模式"
                export HF_HUB_ENABLE_HF_TRANSFER=0
            }
        fi
        
        echo "使用 Python transformers 下载 BLIP 模型..."
        python3 << PYTHON_SCRIPT
from transformers import BlipProcessor, BlipForConditionalGeneration, BlipForQuestionAnswering
import os

blip_cache = '$MODELS_DIR/blip'
# 设置所有相关的 Hugging Face 环境变量，确保下载和运行时都能找到模型
os.environ['HF_HUB_CACHE'] = blip_cache
os.environ['TRANSFORMERS_CACHE'] = blip_cache
os.environ['HF_HOME'] = blip_cache
os.environ['HUGGINGFACE_HUB_CACHE'] = blip_cache

# 如果 hf_transfer 不可用，禁用快速下载
if os.environ.get('HF_HUB_ENABLE_HF_TRANSFER') == '1':
    try:
        import hf_transfer
    except ImportError:
        os.environ['HF_HUB_ENABLE_HF_TRANSFER'] = '0'

print('下载 BLIP 图像描述模型...')
processor_caption = BlipProcessor.from_pretrained('Salesforce/blip-image-captioning-base', cache_dir=blip_cache)
model_caption = BlipForConditionalGeneration.from_pretrained('Salesforce/blip-image-captioning-base', cache_dir=blip_cache)
print('✓ BLIP 图像描述模型下载完成')

print('下载 BLIP VQA 模型...')
processor_vqa = BlipProcessor.from_pretrained('Salesforce/blip-vqa-base', cache_dir=blip_cache)
model_vqa = BlipForQuestionAnswering.from_pretrained('Salesforce/blip-vqa-base', cache_dir=blip_cache)
print('✓ BLIP VQA 模型下载完成')

# 验证模型文件是否存在
import glob
model_dirs = glob.glob(os.path.join(blip_cache, 'models--Salesforce--*'))
print(f'找到 {len(model_dirs)} 个模型目录:')
for model_dir in model_dirs:
    print(f'  - {model_dir}')

print('✓ BLIP 模型下载和验证完成')
PYTHON_SCRIPT
    fi
else
    echo "⚠ Python3 未找到，跳过 BLIP 模型下载"
    echo "  提示: BLIP 模型会在首次使用时自动下载"
fi

echo ""

# ============================================
# 完成
# ============================================
echo "=========================================="
echo "下载完成！"
echo "=========================================="
echo ""
echo "模型存储位置: $MODELS_DIR"
echo ""
echo "目录结构："
if command -v tree &> /dev/null; then
    tree -L 3 "$MODELS_DIR" 2>/dev/null || find "$MODELS_DIR" -type d -maxdepth 3 | head -30
else
    find "$MODELS_DIR" -type d -maxdepth 3 | sort | head -30
fi
echo ""
echo "文件统计："
echo "  Checkpoints: $(find "$MODELS_DIR/checkpoints" -type f 2>/dev/null | wc -l) 个文件"
echo "  LoRAs: $(find "$MODELS_DIR/loras" -type f 2>/dev/null | wc -l) 个文件"
echo "  其他模型: $(find "$MODELS_DIR" -type f -not -path "*/checkpoints/*" -not -path "*/loras/*" 2>/dev/null | wc -l) 个文件"
echo ""
echo "下一步："
echo "1. 验证模型文件是否完整"
echo "2. 在 Endpoint 配置中附加此 Network Volume"
echo "3. 部署优化版镜像（使用 Dockerfile）"
echo ""

