#!/usr/bin/env bash

# Verify the model groups used by the MoshiMosh image stage (SDXL) and video stage (Wan).
# Usage: bash scripts/verify-models.sh [VOLUME_PATH]

set -u

VOLUME_PATH="${1:-/workspace}"

if [ -d "$VOLUME_PATH/storage" ]; then
    MODELS_DIR="$VOLUME_PATH/storage/models"
else
    MODELS_DIR="$VOLUME_PATH/models"
fi

total_checks=0
passed_checks=0

print_section() {
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

get_size_bytes() {
    local file_path="$1"

    if stat -c%s "$file_path" >/dev/null 2>&1; then
        stat -c%s "$file_path"
    elif stat -f%z "$file_path" >/dev/null 2>&1; then
        stat -f%z "$file_path"
    else
        echo "0"
    fi
}

check_file() {
    local file_path="$1"
    local min_size_mb="$2"
    local description="$3"

    total_checks=$((total_checks + 1))

    if [ ! -f "$file_path" ]; then
        echo "[MISSING] $description"
        echo "  Path: $file_path"
        return 1
    fi

    local size_bytes
    local size_mb
    size_bytes="$(get_size_bytes "$file_path")"
    size_mb=$((size_bytes / 1024 / 1024))

    if [ "$size_mb" -ge "$min_size_mb" ]; then
        passed_checks=$((passed_checks + 1))
        echo "[OK] $description"
        echo "  Path: $file_path"
        echo "  Size: ${size_mb} MB"
        return 0
    fi

    echo "[TOO SMALL] $description"
    echo "  Path: $file_path"
    echo "  Size: ${size_mb} MB (expected >= ${min_size_mb} MB)"
    return 1
}

check_first_existing() {
    local description="$1"
    local min_size_mb="$2"
    shift 2

    total_checks=$((total_checks + 1))

    local candidate
    for candidate in "$@"; do
        if [ -f "$candidate" ]; then
            local size_bytes
            local size_mb
            size_bytes="$(get_size_bytes "$candidate")"
            size_mb=$((size_bytes / 1024 / 1024))

            if [ "$size_mb" -ge "$min_size_mb" ]; then
                passed_checks=$((passed_checks + 1))
                echo "[OK] $description"
                echo "  Path: $candidate"
                echo "  Size: ${size_mb} MB"
                return 0
            fi

            echo "[TOO SMALL] $description"
            echo "  Path: $candidate"
            echo "  Size: ${size_mb} MB (expected >= ${min_size_mb} MB)"
            return 1
        fi
    done

    echo "[MISSING] $description"
    return 1
}

print_section "Model Verification"
echo "Checking models under: $MODELS_DIR"
echo ""

print_section "1. MoshiMosh Image Stage (SDXL)"
check_file "$MODELS_DIR/checkpoints/SDXL/RealMixPony.safetensors" 6000 "SDXL checkpoint: RealMixPony" || true
check_file "$MODELS_DIR/checkpoints/SDXL/WAIillustriousSDXL.safetensors" 6000 "SDXL checkpoint: WAIillustriousSDXL" || true
check_file "$MODELS_DIR/checkpoints/SDXL/ultraRealisticByStable_v20FP16.safetensors" 6000 "SDXL checkpoint: ultraRealisticByStable" || true
check_file "$MODELS_DIR/ipadapter/ip-adapter-plus_sdxl_vit-h.safetensors" 800 "IP-Adapter Plus (SDXL)" || true
check_file "$MODELS_DIR/ipadapter/ip-adapter-plus-face_sdxl_vit-h.safetensors" 800 "IP-Adapter Plus Face (SDXL)" || true
check_file "$MODELS_DIR/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors" 2000 "CLIP Vision (IP-Adapter)" || true
check_file "$MODELS_DIR/ultralytics/bbox/face_yolov8m.pt" 40 "FaceDetailer detector" || true
check_file "$MODELS_DIR/facedetection/detection_Resnet50_Final.pth" 100 "Face detection ResNet50" || true
check_file "$MODELS_DIR/facedetection/parsing_parsenet.pth" 70 "Face parsing ParseNet" || true
check_file "$MODELS_DIR/insightface/inswapper_128.onnx" 500 "ReActor inswapper" || true
check_file "$MODELS_DIR/facerestore_models/GPEN-BFR-512.onnx" 250 "GPEN face restore" || true
check_first_existing "Florence-2 model" 3000 \
    "$MODELS_DIR/LLM/model.safetensors" \
    "$MODELS_DIR/LLM/Florence-2-large-PromptGen-v2.0/model.safetensors" || true
echo ""

print_section "2. MoshiMosh Video Stage (Wan)"
check_file "$MODELS_DIR/checkpoints/Wan2.2/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors" 14000 "Wan2.2 checkpoint" || true
check_file "$MODELS_DIR/unet/DaSiWaV9HIGH.safetensors" 50 "Wan UNET: DaSiWaV9HIGH" || true
check_file "$MODELS_DIR/unet/DaSiWaV9LOW.safetensors" 50 "Wan UNET: DaSiWaV9LOW" || true
check_file "$MODELS_DIR/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors" 500 "Wan CLIP: umt5_xxl_fp8_e4m3fn_scaled" || true
check_file "$MODELS_DIR/vae/wan_2.1_vae.safetensors" 50 "Wan VAE: wan_2.1_vae" || true
check_file "$MODELS_DIR/loras/GeneralHIGH.safetensors" 1 "Wan LoRA: GeneralHIGH" || true
check_file "$MODELS_DIR/loras/DR34ML4YHIGH.safetensors" 1 "Wan LoRA: DR34ML4YHIGH" || true
check_file "$MODELS_DIR/loras/CumshotHIGH.safetensors" 1 "Wan LoRA: CumshotHIGH" || true
check_file "$MODELS_DIR/loras/GeneralLOW.safetensors" 1 "Wan LoRA: GeneralLOW" || true
check_file "$MODELS_DIR/loras/DR34ML4YLOW.safetensors" 1 "Wan LoRA: DR34ML4YLOW" || true
check_file "$MODELS_DIR/loras/CumshotLOW.safetensors" 1 "Wan LoRA: CumshotLOW" || true
check_file "$MODELS_DIR/vfi/rife47.pth" 15 "RIFE VFI rife47" || true
check_file "$MODELS_DIR/clip_vision/wan/clip_vision_h.safetensors" 1000 "CLIP Vision (WAN)" || true
echo ""

print_section "3. Shared Utility Models"
check_file "$MODELS_DIR/upscale_models/RealESRGAN_x2.pth" 60 "RealESRGAN x2" || true
echo ""

print_section "Verification Summary"
echo "Total checks: $total_checks"
echo "Passed: $passed_checks"
echo "Failed: $((total_checks - passed_checks))"
echo ""

if [ "$passed_checks" -eq "$total_checks" ]; then
    echo "All required MoshiMosh image and video stage models passed verification."
    exit 0
fi

echo "Some MoshiMosh image-stage or video-stage models are missing or look incomplete."
echo "Re-download command:"
echo "  bash scripts/download-models-to-volume.sh $VOLUME_PATH"
exit 1
