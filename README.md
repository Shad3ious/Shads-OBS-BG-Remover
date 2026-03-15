# Shad's OBS Background Removal

Real-time AI-powered background removal for OBS Studio using [Robust Video Matting](https://github.com/PeterL1n/RobustVideoMatting).

Runs entirely on your GPU via DirectML — no green screen needed.

## Features

- **Real-time background removal** at 1080p 60fps
- **GPU-accelerated** via DirectML (NVIDIA, AMD, Intel)
- **8 tunable settings** — inference scale, responsiveness, threshold, feather, erosion, blur, smoothing
- **Zero setup** — just install and add the filter
- **Lightweight** — ~7ms per frame on RTX 5080

## Requirements

- **OBS Studio** 30.0+ (64-bit)
- **Windows 10/11** (64-bit)
- **DirectX 12 compatible GPU** (NVIDIA GTX 1060+, AMD RX 580+, Intel Arc)

## Installation

1. Download the latest `OBS-BG-Removal-x.x.x-Setup.exe` from [Releases](../../releases)
2. Run the installer — it auto-detects your OBS installation
3. Restart OBS

## Usage

1. Right-click your video source → **Filters**
2. Click **+** under Effect Filters → **BG Removal**
3. Adjust settings to taste

### Recommended Settings

| Setting | Value | Notes |
|---------|-------|-------|
| Inference Scale | 0.25 | Fastest. Increase for sharper edges (slower) |
| Responsiveness | 0.3 | Reduces mask lag on fast movement |
| Alpha Threshold | 0.15 | Removes background ghosts |
| Edge Feather | 0.05 | Soft edge blend |
| Mask Erosion | 1 | Removes halo around silhouette |
| Edge Blur | 1 | Smooths jagged mask edges |
| Temporal Smoothing | 0.05 | Reduces flicker when still |

## Building from Source

### Prerequisites
- Visual Studio 2022 (C++ Desktop workload)
- CMake 3.28+
- OBS Studio source/libs
- [ONNX Runtime 1.24.3 DirectML NuGet package](https://www.nuget.org/packages/Microsoft.ML.OnnxRuntime.DirectML/1.24.3)

### Build
```cmd
# From x64 Native Tools Command Prompt for VS 2022 (as Administrator)
cd C:\Projects\obs-bg-removal
cmake --preset windows-x64
cmake --build build_x64 --config Release
```

### Build Installer
```cmd
# Requires Inno Setup 6: https://jrsoftware.org/isdl.php
cd installer
powershell -ExecutionPolicy Bypass -File Build-Installer.ps1
```

## Tech Stack

| Component | Details |
|-----------|---------|
| AI Model | Robust Video Matting (MobileNetV3, FP32 ONNX) |
| Inference | ONNX Runtime 1.24.3 + DirectML |
| Language | C++ / HLSL |
| Build | CMake + MSVC |

## Known Limitations

- **CUDA not supported on RTX 50-series (Blackwell)** — ONNX Runtime doesn't support SM 12.0 yet. DirectML works as a fallback.
- **DirectML performance cliff** — inference jumps from 5ms to 26ms between 480×270 and 576×324. Use Inference Scale 0.25 for best performance.
- **downsample_ratio locked to 1.0** — other values crash DirectML's Expand node.

## License

[MIT License](LICENSE) + Commons Clause

## Credits

- [Robust Video Matting](https://github.com/PeterL1n/RobustVideoMatting) by Peter Lin
- [ONNX Runtime](https://github.com/microsoft/onnxruntime) by Microsoft
- [OBS Studio](https://obsproject.com/)
- [obs-backgroundremoval](https://github.com/royshil/obs-backgroundremoval) by Roy Shilkrot (reference)
