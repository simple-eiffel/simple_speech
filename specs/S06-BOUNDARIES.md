# S06 - Boundaries: simple_speech

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_speech
**Date:** 2026-01-23

## Scope Boundaries

### In Scope
- Speech-to-text transcription
- WAV file loading
- PCM sample processing
- Multi-language support (99+ languages)
- Subtitle export (VTT, SRT, JSON)
- Timing information extraction
- Basic speaker diarization
- Video pipeline (with simple_ffmpeg)

### Out of Scope
- **Text-to-speech** - No speech synthesis
- **Voice recognition** - No speaker identification
- **Real-time streaming** - Batch processing only
- **Audio editing** - No audio manipulation
- **Model training** - Inference only
- **GPU acceleration** - CPU-only (whisper.cpp limitation)

## API Boundaries

### Public API (SIMPLE_SPEECH facade)
- Initialization with model path
- Configuration (language, threads, translate)
- File transcription
- PCM transcription
- Cleanup

### Internal API (not exported)
- Native whisper.cpp bindings
- WAV parsing internals
- GGML tensor operations

## Integration Boundaries

### Input Boundaries

| Input Type | Format | Validation |
|------------|--------|------------|
| Model path | STRING | File must exist |
| WAV path | STRING | File must exist, valid WAV |
| PCM samples | ARRAY [REAL_32] | Non-empty |
| Sample rate | INTEGER | Must be > 0 |
| Language | STRING | ISO 639-1 or "auto" |
| Threads | INTEGER | Must be >= 1 |

### Output Boundaries

| Output Type | Format | Notes |
|-------------|--------|-------|
| Segments | LIST [SPEECH_SEGMENT] | Always non-void |
| Text | STRING_32 | UTF-32 encoded |
| Timing | INTEGER_64 | Milliseconds |
| Confidence | REAL_64 | 0.0 to 1.0 |

## Performance Boundaries

### Expected Performance

| Operation | Time | Notes |
|-----------|------|-------|
| Model load | 1-15 sec | Depends on model size |
| Transcribe (1 min audio) | 5-60 sec | Depends on model |
| Export VTT | < 1 sec | String operations only |

### Resource Limits

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 1 GB | 4 GB |
| Disk (models) | 39 MB | 244 MB |
| CPU threads | 1 | 4+ |

## Extension Points

### Custom Engines
1. Implement SPEECH_ENGINE deferred class
2. Use `make_with_engine` to inject
3. Implement `transcribe`, `set_language`, etc.

### Custom Exporters
1. Create class inheriting export interface
2. Implement format-specific output

## Dependency Boundaries

### Required Dependencies
- EiffelBase
- whisper.cpp DLLs

### Optional Dependencies
- simple_ffmpeg (video pipeline)
- simple_ai_client (AI enhancement)
- simple_json (JSON export)

## Quality Boundaries

### Accuracy Expectations

| Model | Word Error Rate |
|-------|-----------------|
| tiny | ~10-15% |
| base | ~7-10% |
| small | ~5-7% |
| medium | ~4-5% |
| large-v3 | ~3-4% |

### Language Accuracy
- Best: English, Spanish, French, German
- Good: Chinese, Japanese, Korean
- Variable: Low-resource languages
