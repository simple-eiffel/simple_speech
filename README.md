<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
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

> *We don't just transcribe media. We make it self-describing - automatically.*

## Status

**Production** - Phases 0-7 complete, Phase 8 (real-time streaming) planned

## Core Principles

1. **Local-first, deterministic** - No cloud, no uploads, reproducible results
2. **Structure over text** - Chapters, navigation, semantic organization
3. **Media-native outputs** - Embedded captions and chapters in containers
4. **Algorithmic-first, AI-optional** - 45+ transition patterns, AI enhancement available

## Quick Start

```eiffel
local
    pipeline: SPEECH_PIPELINE
    result: SPEECH_CHAPTERED_RESULT
do
    -- Transcribe video with auto-chaptering
    create pipeline.make ("models/ggml-base.en.bin")
    
    if pipeline.is_ready then
        create result.make (pipeline.transcribe ("video.mp4"))
        result.detect_chapters
        
        -- Export chapters
        result.export_chapters_json ("chapters.json")
        result.export_full_vtt ("captions.vtt")
    end
end
```

## Embedded Media (Phase 7)

Create self-describing video files with embedded captions and navigable chapters:

```eiffel
local
    embedder: SPEECH_VIDEO_EMBEDDER
do
    create embedder.make (pipeline)
    
    -- Embed captions + chapters into video container
    if embedder.embed_all ("input.mp4", segments, chapters, "output.mp4") then
        print ("Video now contains embedded subtitles and chapter markers%N")
    end
end
```

The output video plays in VLC, YouTube, or any modern player with:
- Toggleable soft subtitles
- Navigable chapter markers
- No sidecar files needed

## Installation

1. Set environment variable:
```batch
set SIMPLE_EIFFEL=D:\prod
```

2. Add to your ECF:
```xml
<library name="simple_speech" location="$SIMPLE_EIFFEL/simple_speech/simple_speech.ecf"/>
```

3. Download Whisper model (any ggml format):
```
models/ggml-base.en.bin
```

Requires: FFmpeg in PATH for video support

## Capabilities by Phase

### Phase 0-1: Foundation
- Whisper.cpp integration (deterministic STT)
- Fully local execution

### Phase 2: Format Export
```eiffel
exporter.export_srt (segments, "output.srt")
exporter.export_vtt (segments, "output.vtt")
exporter.export_json (segments, "output.json")
```

### Phase 3: Video Pipeline
```eiffel
pipeline.transcribe ("video.mp4")  -- Automatic audio extraction
```

### Phase 4: AI Enhancement
```eiffel
enhancer.enhance_transcript (segments)    -- Clean up with AI
enhancer.translate_to ("es", segments)    -- Translate
```

### Phase 5: Batch Processing
```eiffel
create batch.make (pipeline)
batch.add_file ("video1.mp4")
batch.add_file ("video2.mp4")
batch.set_format ("vtt")
batch.run  -- Memory-conscious processing
```

### Phase 6: Smart Chaptering
```eiffel
create detector.make
detector.set_sensitivity (0.6)
chapters := detector.detect_transitions (segments)
-- Detected via 45+ phrase patterns + temporal analysis
```

### Phase 7: Metadata Embedding
```eiffel
embedder.embed_captions (video, segments, output)
embedder.embed_chapters (video, chapters, output)
embedder.embed_all (video, segments, chapters, output)
```

### Phase 8: Real-Time Streaming (Coming)
- Non-blocking streaming transcription
- Live chapter formation
- SCOOP-safe concurrency

## API Classes

| Class | Purpose |
|-------|---------|
| `SPEECH_PIPELINE` | End-to-end video/audio transcription |
| `SPEECH_EXPORTER` | SRT, VTT, JSON, TXT export |
| `SPEECH_TRANSITION_DETECTOR` | Algorithmic chapter detection |
| `SPEECH_CHAPTER` | Chapter data model with localization |
| `SPEECH_AI_CHAPTER_ENHANCER` | AI-powered chapter titles |
| `SPEECH_VIDEO_EMBEDDER` | Container metadata embedding |
| `SPEECH_BATCH_PROCESSOR` | Multi-file processing |
| `SPEECH_MEMORY_MONITOR` | Resource management |

## Demo Applications

```
demo_export    -- Format export demonstration
demo_pipeline  -- Video transcription pipeline
demo_batch     -- Batch processing with progress
demo_chapters  -- Chapter detection demo
demo_embed     -- Metadata embedding demo
```

Run demos:
```batch
cd simple_speech
ec -batch -config simple_speech.ecf -target demo_embed -c_compile
./EIFGENs/demo_embed/W_code/simple_speech.exe
```

## Dependencies

- simple_ffmpeg (video processing)
- simple_ai_client (optional AI features)
- ISE base, time

## License

MIT License - See LICENSE file

---

Part of the **Simple Eiffel** ecosystem - modern, contract-driven Eiffel libraries.
