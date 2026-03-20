# MoshiMosh Test Resources

This directory keeps the default API payloads for the current MoshiMosh pipeline.

## Default inputs

- `moshimosh_sdxl_runpod.json`
  - SDXL image-stage request.
  - Produces a still image / keyframe.
  - References `test_img.jpg` through `input.images`.

- `moshimosh_videogen_runpod.json`
  - Wan video-stage request.
  - Starts from an input image and produces a video.
  - Uses the current `RIFE VFI` node signature expected by the installed nodes.

## Original customer file

- `API_MoshiMoshAI(VideoGen) (2).json`
  - Preserved as provided by the customer.
  - Kept for traceability; prefer the standardized file above for routine testing.

## Notes

- Files under `archive/` are historical references and are not the default test entrypoints.
- `input.images[].name` must match the filename referenced by `LoadImage` nodes in the workflow.
