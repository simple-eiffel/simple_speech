# S07 - Specification Summary: simple_speech

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_speech
**Date:** 2026-01-23

## Executive Summary

simple_speech is a speech-to-text library for Eiffel wrapping OpenAI's whisper.cpp, providing high-accuracy transcription with multi-language support, timing extraction, and subtitle export.

## Key Statistics

| Metric | Value |
|--------|-------|
| Total Classes | ~14+ |
| Public Features | ~30 |
| Languages Supported | 99+ |
| Dependencies | base + whisper.cpp |

## Architecture Overview

```
+-------------------+
|   SIMPLE_SPEECH   |  <-- Facade
+-------------------+
         |
    +----+----+
    |         |
+--------+ +--------+
| Engine | |WAV_READ|
+--------+ +--------+
    |
+--------+
|Whisper |
| .cpp   |
+--------+
    |
+--------+
| GGML   |
+--------+
```

## Core Value Proposition

1. **Simple API** - Transcribe in 5 lines of code
2. **High Accuracy** - OpenAI Whisper model quality
3. **Multi-Language** - 99+ languages supported
4. **Timing Info** - Word/segment timing for subtitles
5. **Fluent Config** - Chainable configuration

## Contract Summary

| Category | Preconditions | Postconditions |
|----------|---------------|----------------|
| Initialization | Valid model path | Engine ready |
| Configuration | Valid values | Current returned |
| Transcription | Engine valid, input valid | Non-void result |

## Feature Categories

| Category | Count | Purpose |
|----------|-------|---------|
| Initialization | 2 | Create facade |
| Configuration | 6 | Language, threads, etc. |
| Transcription | 2 | File and PCM input |
| Export | 3 | VTT, SRT, JSON |
| Status | 3 | Valid, loaded, error |

## Constraints Summary

1. Audio must be 16kHz mono (auto-converted)
2. Model file must exist and be GGML format
3. Thread count must be >= 1
4. Not thread-safe (use SCOOP processors)

## Known Limitations

1. CPU-only (no GPU acceleration)
2. Batch processing (no real-time streaming)
3. Large models require significant RAM
4. Translation only to English

## Integration Points

| Library | Integration |
|---------|-------------|
| simple_ffmpeg | Extract audio from video |
| simple_ai_client | Post-process for corrections |
| simple_json | JSON export format |
| simple_sql | Store transcriptions |

## Future Directions

1. GPU acceleration via CUDA
2. Real-time streaming transcription
3. Speaker diarization improvements
4. Custom vocabulary support
