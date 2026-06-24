# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A 3D skeleton keypoint viewer. Users upload `.npz` files containing motion capture / pose estimation keypoints, and the app renders a 3D skeleton animation using Three.js in the browser.

## Architecture

The entire application is two files:

- **[src/app.py](src/app.py)** — FastAPI server with a single endpoint `POST /api/upload_npz`. Accepts a `.npz` file via multipart upload, extracts keypoint data (looks for the `reconstruction` key first, then falls back to the first key in the archive), and returns JSON with `frames`, `bones_topology`, and `num_frames`. Uses `Path(__file__)` to resolve the static directory, so it works regardless of CWD (including in Docker).
- **[static/index.html](static/index.html)** — A self-contained HTML page with inline CSS and JS. Uses Three.js (r128, CDN-loaded) with OrbitControls for a 3D scene: a dark background, grid, ambient light, and a skeleton rendered as spheres (joints) connected by line segments (bones). Playback controls include play/pause, FPS slider (1–120), and a scrubber. The Y-axis is flipped (`-pos[1]`) to match common coordinate conventions.

The bone topology (`BONES` in [src/app.py:10-14](src/app.py#L10-L14)) is hardcoded as 16 pairs defining a 17-joint skeleton. The frontend receives this topology from the API response and uses it to draw bone lines between joint pairs.

## Commands

```bash
# Development server (from project root)
uv run uvicorn src.app:app --host 0.0.0.0 --port 8000 --reload

# Or use the convenience script
./run.sh

# Docker build
docker build -t keypoints-3d-viewer .

# Docker run
docker run -p 8000:8000 keypoints-3d-viewer
```

## CI/CD

GitHub Actions ([.github/workflows/build-and-push-docker-image.yml](.github/workflows/build-and-push-docker-image.yml)) builds and pushes a Docker image to `ghcr.io/<owner>/keypoints-3d-viewer:latest` on every push to `main`/`master`.

## Data format

The `.npz` file is expected to contain 3D keypoint data. The server handles both 3D arrays `(frames, joints, coords)` and 4D arrays `(1, frames, joints, coords)`, squeezing out a leading batch dimension if present. The `reconstruction` key is preferred; otherwise the first key in the archive is used.
