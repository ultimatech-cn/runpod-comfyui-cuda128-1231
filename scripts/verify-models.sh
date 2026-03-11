#!/usr/bin/env bash

# Verify that required models exist on the mounted RunPod volume and are not obviously truncated.
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

check_florence_model() {
    local candidates=(
        "$MODELS_DIR/LLM/model.safetensors"
        "$MODELS_DIR/LLM/Florence-2-large-PromptGen-v2.0/model.safetensors"
    )
    local candidate

    total_checks=$((total_checks + 1))

    for candidate in "${candidates[@]}"; do
        if [ -f "$candidate" ]; then
            local size_bytes
            local size_mb
            size_bytes="$(get_size_bytes "$candidate")"
            size_mb=$((size_bytes / 1024 / 1024))

            if [ "$size_mb" -ge 3000 ]; then
                passed_checks=$((passed_checks + 1))
                echo "[OK] Florence-2 Model"
                echo "  Path: $candidate"
                echo "  Size: ${size_mb} MB"
                return 0
            fi

            echo "[TOO SMALL] Florence-2 Model"
            echo "  Path: $candidate"
            echo "  Size: ${size_mb} MB (expected >= 3000 MB)"
            return 1
        fi
    done

    echo "[MISSING] Florence-2 Model"
    echo "  Checked: $MODELS_DIR/LLM/"
    return 1
}

print_section "Model Verification"
echo "Checking models under: $MODELS_DIR"
echo ""

print_section "1. Checkpoints"
check_file "$MODELS_DIR/checkpoints/SDXL/WAIillustriousSDXL.safetensors" 6000 "WAIillustriousSDXL" || true
check_file "$MODELS_DIR/checkpoints/SDXL/RealMixPony.safetensors" 6000 "RealMixPony" || true
check_file "$MODELS_DIR/checkpoints/Wan2.2/wan2.2-i2v-rapid-aio-v10-nsfw.safetensors" 14000 "Wan2.2 I2V" || true
echo ""

print_section "2. IP-Adapter"
check_file "$MODELS_DIR/ipadapter/ip-adapter-plus_sdxl_vit-h.safetensors" 800 "IP-Adapter Plus" || true
check_file "$MODELS_DIR/ipadapter/ip-adapter-plus-face_sdxl_vit-h.safetensors" 800 "IP-Adapter Plus Face" || true
echo ""

print_section "3. CLIP Vision"
check_file "$MODELS_DIR/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors" 2000 "CLIP Vision (IP-Adapter)" || true
check_file "$MODELS_DIR/clip_vision/wan/clip_vision_h.safetensors" 1000 "CLIP Vision (WAN)" || true
echo ""

print_section "4. FaceDetailer Dependencies"
check_file "$MODELS_DIR/ultralytics/bbox/face_yolov8m.pt" 40 "Face YOLOv8m" || true
check_file "$MODELS_DIR/facedetection/detection_Resnet50_Final.pth" 100 "Face Detection ResNet50" || true
check_file "$MODELS_DIR/facedetection/parsing_parsenet.pth" 70 "Face Parsing ParseNet" || true
echo ""

print_section "5. ReActor Models"
check_file "$MODELS_DIR/insightface/inswapper_128.onnx" 500 "ReActor inswapper" || true
check_file "$MODELS_DIR/facerestore_models/GPEN-BFR-512.onnx" 250 "GPEN Face Restore" || true
echo ""

print_section "6. RIFE VFI"
check_file "$MODELS_DIR/vfi/rife47.pth" 15 "RIFE VFI rife47" || true
echo ""

print_section "7. Florence-2"
check_florence_model || true
echo ""

print_section "8. Upscale Models"
check_file "$MODELS_DIR/upscale_models/RealESRGAN_x2.pth" 60 "RealESRGAN x2" || true
echo ""

print_section "Verification Summary"
echo "Total checks: $total_checks"
echo "Passed: $passed_checks"
echo "Failed: $((total_checks - passed_checks))"
echo ""

if [ "$passed_checks" -eq "$total_checks" ]; then
    echo "All required models passed verification."
    exit 0
fi

echo "Some models are missing or look incomplete."
echo "Re-download command:"
echo "  bash scripts/download-models-to-volume.sh $VOLUME_PATH"
exit 1
