<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/.github/main/profile/assets/logo.svg" alt="simple_ library logo" width="400">
</p>

# simple_speech

**[Documentation](https://simple-eiffel.github.io/simple_speech/)** | **[GitHub](https://github.com/simple-eiffel/simple_speech)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

**Local-first speech-to-text and media-structuring engine** that automatically turns raw audio and video into navigable, captioned, chaptered media.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## What Makes This Different

Most speech-to-text tools stop at text. **simple_speech** delivers *structure*:

| Capability | Market Status | simple_speech |
|------------|---------------|---------------|
| Transcription | Commodity | Yes |
| Captions (SRT/VTT) | Expected | Yes |
| Auto-Chapters | Rare | Yes |
| Embedded metadata | Extremely rare | Yes |
| Offline determinism | High-trust differentiator | Yes |

> *We do not just transcribe media. We make it self-describing - automatically.*

## Status

**Production** - Phases 0-7 complete, Phase 8 (real-time streaming) planned

## Core Principles

1. **Local-first, deterministic** - No cloud, no uploads, reproducible results
2. **Structure over text** - Chapters, navigation, semantic organization
3. **Media-native outputs** - Embedded captions and chapters in containers
4. **Algorithmic-first, AI-optional** - 45+ transition patterns, AI enhancement available

## Installation

### 1. Environment Setup

Set the SIMPLE_EIFFEL environment variable to your installation directory:

**Windows (Command Prompt):**
```batch
set SIMPLE_EIFFEL=C:\path\to\your\eiffel\libraries
```

**Windows (PowerShell):**
```powershell
$env:SIMPLE_EIFFEL = "C:\path\to\your\eiffel\libraries"
```

**Windows (Permanent - System Properties):**
1. Open System Properties > Advanced > Environment Variables
2. Add new User or System variable:
   - Name: `SIMPLE_EIFFEL`
   - Value: `C:\path\to\your\eiffel\libraries`

### 2. FFmpeg Installation (Required for Video Support)

FFmpeg is required for video processing, audio extraction, and metadata embedding.

**Windows Installation:**

1. Download FFmpeg from [gyan.dev](https://www.gyan.dev/ffmpeg/builds/) (recommended)
   - Choose "ffmpeg-release-essentials.zip" for most users
   - Or "ffmpeg-release-full.zip" for all codecs

2. Extract to a permanent location (e.g., `C:\ffmpeg`)

3. Add to PATH:
   - Open System Properties > Advanced > Environment Variables
   - Edit the `Path` variable (User or System)
   - Add: `C:\ffmpeg\bin`

4. Verify installation:
```batch
ffmpeg -version
ffprobe -version
```

Both commands should display version information. If not, restart your terminal.

### 3. Whisper.cpp Setup (Required)

simple_speech uses [whisper.cpp](https://github.com/ggerganov/whisper.cpp) for local transcription.

**Option A: Download Pre-built Binary (Recommended)**

1. Go to [whisper.cpp Releases](https://github.com/ggerganov/whisper.cpp/releases)
2. Download the latest Windows release (e.g., `whisper-bin-x64.zip`)
3. Extract `whisper-cli.exe` to a folder in your PATH (e.g., `C:\whisper\`)
4. Add to PATH if needed

**Option B: Build from Source**

```batch
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
cmake -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release
```

The executable will be at `build\bin\Release\whisper-cli.exe`

**Verify Installation:**
```batch
whisper-cli --help
```

### 4. Whisper Model Setup (Required)

Download a Whisper model in GGML format. Place in your project models directory.

**Model Selection Guide:**

| Model | Size | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| ggml-tiny.en.bin | 75 MB | Fastest | Good | Quick drafts, testing |
| ggml-base.en.bin | 142 MB | Fast | Better | General use (recommended) |
| ggml-small.en.bin | 466 MB | Medium | High | Production transcription |
| ggml-medium.en.bin | 1.5 GB | Slow | Higher | Difficult audio |
| ggml-large-v3.bin | 3.1 GB | Slowest | Best | Maximum accuracy |

**Note:** Models ending in `.en` are English-only and faster. Models without `.en` support 99 languages.

**Download from Hugging Face:**
- [ggml-base.en.bin](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin) (recommended)
- [All models](https://huggingface.co/ggerganov/whisper.cpp/tree/main)

```batch
mkdir models
curl -L -o models/ggml-base.en.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
```

### 5. AI Enhancement Setup (Optional)

AI features (transcript cleanup, translation, smart chapter titles) require API keys.

**Cloud Providers:**

| Provider | Environment Variable | Get API Key |
|----------|---------------------|-------------|
| Anthropic (Claude) | ANTHROPIC_API_KEY | [console.anthropic.com](https://console.anthropic.com/) |
| Google (Gemini) | GEMINI_API_KEY | [aistudio.google.com](https://aistudio.google.com/) |
| xAI (Grok) | XAI_API_KEY | [x.ai](https://x.ai/) |
| OpenAI | OPENAI_API_KEY | [platform.openai.com](https://platform.openai.com/) |

**Windows (set environment variable):**
```batch
set ANTHROPIC_API_KEY=sk-ant-your-key-here
```

**Local AI with Ollama:**

1. Install Ollama from [ollama.com](https://ollama.com/)
2. Pull a model:
```batch
ollama pull llama3.2
```
3. Ollama runs locally at http://localhost:11434
4. No API key needed - simple_speech auto-detects Ollama

### 6. Add to Your ECF

```xml
<library name="simple_speech" location="$SIMPLE_EIFFEL/simple_speech/simple_speech.ecf"/>
```

## Command-Line Interface (CLI)

**simple_speech** v1.1.0 includes a full-featured CLI for standalone use without any Eiffel code.

### Installation Options

**Option 1: Windows Installer (Recommended)**
- Download `SimpleSpeech_Setup_1.1.0.exe` from [Releases](https://github.com/simple-eiffel/simple_speech/releases)
- Optionally add to PATH during installation
- Models directory created automatically

**Option 2: Manual**
- Copy `speech_cli.exe` and required DLLs to a folder
- Add to PATH
- Download Whisper models to `models/` subfolder

### CLI Commands

```bash
# Show help and version
speech_cli --help

# Transcribe to console
speech_cli transcribe video.mp4

# Transcribe and export to file
speech_cli export video.mp4 --output captions.srt --format srt

# Detect chapters
speech_cli chapters video.mp4 --output chapters.json --format json

# Batch process multiple files
speech_cli batch video1.mp4 video2.mp4 --output ./captions/

# Embed captions into video
speech_cli embed video.mp4 --output video_with_captions.mp4

# Show media file info
speech_cli info video.mp4
```

### CLI Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help |
| `-m, --model <path>` | Whisper model path (auto-detected if not specified) |
| `-l, --language <code>` | Source language: en, es, zh, etc. (default: en) |
| `-o, --output <path>` | Output file or directory |
| `-f, --format <fmt>` | Export format: vtt, srt, json, txt (default: vtt) |
| `-t, --threads <n>` | CPU threads (default: 4) |
| `--translate` | Translate to English |
| `-q, --quiet` | Suppress progress messages |

### Model Auto-Detection

The CLI automatically searches for models in:
1. `models/` folder next to the executable
2. `models/` in the current directory
3. Path specified via `--model`

## Quick Start with SPEECH_QUICK

```eiffel
local
    quick: SPEECH_QUICK
do
    create quick.make_with_model ("models/ggml-base.en.bin")
    if quick.is_ready and quick.process_video ("input.mp4", "output.mp4") then
        print ("Success: " + quick.segment_count.out + " segments, "
               + quick.chapter_count.out + " chapters%N")
    end
end
```

**Fluent API:**
```eiffel
local
    quick: SPEECH_QUICK
    l_dummy: like quick
do
    create quick.make_with_model ("models/ggml-base.en.bin")
    l_dummy := quick.transcribe ("video.mp4")
                    .set_sensitivity (0.6)
                    .detect_chapters
                    .export_vtt ("captions.vtt")
                    .embed_to ("output.mp4")
end
```

## API Classes

| Class | Purpose |
|-------|---------|
| SPEECH_QUICK | Facade - One-stop API for common workflows |
| SPEECH_PIPELINE | End-to-end video/audio transcription |
| SPEECH_EXPORTER | SRT, VTT, JSON, TXT export |
| SPEECH_TRANSITION_DETECTOR | Algorithmic chapter detection |
| SPEECH_VIDEO_EMBEDDER | Container metadata embedding |
| SPEECH_BATCH_PROCESSOR | Multi-file processing |

## Dependencies

- simple_ffmpeg (video processing)
- simple_ai_client (optional AI features)
- simple_datetime (time handling)
- ISE base

## License

MIT License - See LICENSE file

---

Part of the **Simple Eiffel** ecosystem.
