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