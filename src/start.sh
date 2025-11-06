#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Disable numba verbose debug output (SSA block analysis, etc.)
# This prevents excessive logging that can cause performance issues
export NUMBA_DEBUG=0
export NUMBA_DISABLE_ERROR_MESSAGE_HIGHLIGHTING=1
export NUMBA_DISABLE_JIT=0  # Keep JIT enabled but disable verbose output
export NUMBA_LOG_LEVEL=ERROR  # Set numba logging to ERROR level only
# Redirect numba's internal logging to reduce noise
export PYTHONWARNINGS="ignore::numba.NumbaWarning"
# Suppress numba's internal print statements (these bypass logging)
export NUMBA_CAPTURED_ERRORS=1

# Ensure ComfyUI-Manager runs in offline network mode inside the container
comfy-manager-set-mode offline || echo "worker-comfyui - Could not set ComfyUI-Manager network_mode" >&2

# Create symlinks from Network Volume to ComfyUI default paths for ReActor nodes
# Some nodes (like ReActor) may use hardcoded paths /comfyui/models/insightface/
# instead of reading from extra_model_paths.yaml
# This ensures they can find models in the Network Volume
if [ -d "/runpod-volume/models" ]; then
    echo "worker-comfyui: Setting up model directory symlinks for ReActor compatibility"
    
    # Create insightface symlink if Network Volume has the directory
    if [ -d "/runpod-volume/models/insightface" ]; then
        # Remove existing directory if it's empty or create backup
        if [ -d "/comfyui/models/insightface" ] && [ ! -L "/comfyui/models/insightface" ]; then
            # If directory exists and is not a symlink, check if it's empty
            if [ -z "$(ls -A /comfyui/models/insightface 2>/dev/null)" ]; then
                rmdir /comfyui/models/insightface 2>/dev/null || true
            fi
        fi
        # Create symlink if it doesn't exist
        if [ ! -e "/comfyui/models/insightface" ]; then
            mkdir -p /comfyui/models
            ln -sf /runpod-volume/models/insightface /comfyui/models/insightface
            echo "worker-comfyui: Created symlink /comfyui/models/insightface -> /runpod-volume/models/insightface"
        fi
    fi
    
    # Create reswapper symlink if Network Volume has the directory
    if [ -d "/runpod-volume/models/reswapper" ]; then
        if [ -d "/comfyui/models/reswapper" ] && [ ! -L "/comfyui/models/reswapper" ]; then
            if [ -z "$(ls -A /comfyui/models/reswapper 2>/dev/null)" ]; then
                rmdir /comfyui/models/reswapper 2>/dev/null || true
            fi
        fi
        if [ ! -e "/comfyui/models/reswapper" ]; then
            mkdir -p /comfyui/models
            ln -sf /runpod-volume/models/reswapper /comfyui/models/reswapper
            echo "worker-comfyui: Created symlink /comfyui/models/reswapper -> /runpod-volume/models/reswapper"
        fi
    fi
fi

echo "worker-comfyui: Starting ComfyUI"

# Allow operators to tweak verbosity; default is INFO (changed from DEBUG to reduce log volume)
# Set COMFY_LOG_LEVEL=DEBUG only when troubleshooting
: "${COMFY_LOG_LEVEL:=INFO}"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --listen --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py
fi