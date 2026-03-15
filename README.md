# Shad's OBS Background Removal

Real-time AI background removal plugin for OBS Studio. No green screen required. Uses [Robust Video Matting](https://github.com/PeterL1n/RobustVideoMatting) for the AI model and runs on your GPU through DirectML.

## Features

- Background removal at 1080p 60fps
- GPU accelerated with DirectML (works on NVIDIA, AMD, and Intel GPUs)
- 8 settings you can tweak in real time
- Comes with an installer that auto-detects your OBS installation
- Around 7ms per frame on an RTX 5080

## Requirements

- OBS Studio 30.0 or newer (64-bit)
- Windows 10 or 11 (64-bit)
- A DirectX 12 compatible GPU (NVIDIA GTX 1060+, AMD RX 580+, Intel Arc)

## Installation

1. Grab the latest `OBS-BG-Removal-x.x.x-Setup.exe` from [Releases](../../releases)
2. Run the installer
3. Restart OBS

## How to Use

1. Right-click your video source and go to **Filters**
2. Hit the **+** button under Effect Filters and pick **BG Removal**
3. Tweak the sliders until it looks good

### Recommended Settings

| Setting | Value | What it does |
|---------|-------|-------------|
| Inference Scale | 0.25 | Fastest tracking speed. Higher = sharper edges but slower |
| Responsiveness | 0.3 | Helps the mask keep up with fast movement |
| Alpha Threshold | 0.15 | Cleans up faint background bleed |
| Edge Feather | 0.05 | Softens the cutoff edge |
| Mask Erosion | 1 | Trims the bright halo around your outline |
| Edge Blur | 1 | Smooths out jagged mask edges |
| Temporal Smoothing | 0.05 | Reduces flicker when you're sitting still |

## Building from Source

### What you need
- Visual Studio 2022 with the C++ Desktop workload
- CMake 3.28+
- OBS Studio source/libs
- [ONNX Runtime 1.24.3 DirectML NuGet package](https://www.nuget.org/packages/Microsoft.ML.OnnxRuntime.DirectML/1.24.3)

### Build
```cmd
# Open x64 Native Tools Command Prompt for VS 2022 as Admin
cd C:\Projects\obs-bg-removal
cmake --preset windows-x64
cmake --build build_x64 --config Release
```

### Build the Installer
```cmd
# You'll need Inno Setup 6: https://jrsoftware.org/isdl.php
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

- CUDA doesn't work on RTX 50-series (Blackwell) yet. ONNX Runtime hasn't added SM 12.0 support as of March 2026, so the plugin uses DirectML instead.
- There's a performance cliff in DirectML where inference jumps from 5ms to 26ms between 480x270 and 576x324. Keeping Inference Scale at 0.25 avoids this.
- The model's internal downsample_ratio has to stay at 1.0. Other values crash DirectML.

## License

[MIT License](LICENSE) + Commons Clause

## Credits

- [Robust Video Matting](https://github.com/PeterL1n/RobustVideoMatting) by Peter Lin
- [ONNX Runtime](https://github.com/microsoft/onnxruntime) by Microsoft
- [OBS Studio](https://obsproject.com/)
- [obs-backgroundremoval](https://github.com/royshil/obs-backgroundremoval) by Roy Shilkrot (used as reference)
