# S05 - Constraints: simple_speech

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_speech
**Date:** 2026-01-23

## Audio Format Constraints

### Input Requirements (Whisper)

| Parameter | Required Value | Notes |
|-----------|----------------|-------|
| Sample rate | 16000 Hz | WAV_READER handles conversion |
| Channels | Mono | Stereo converted to mono |
| Bit depth | 16-bit | Floating point normalized |
| Format | PCM | WAV or raw PCM |

### WAV File Constraints

```
Maximum file size: Limited by memory
Minimum duration: 0.1 seconds
Maximum duration: No hard limit (streaming for long files)
```

## Threading Constraints

| Parameter | Min | Max | Default | Notes |
|-----------|-----|-----|---------|-------|
| `threads` | 1 | CPU cores | 4 | More threads = faster, more memory |

### Memory Usage by Thread Count

```
1 thread:  ~500 MB (base model)
4 threads: ~800 MB (base model)
8 threads: ~1.2 GB (base model)
```

## Model Constraints

### Model Requirements

| Constraint | Description |
|------------|-------------|
| Path must exist | Model file must be accessible |
| Format | GGML binary format |
| Naming | `ggml-*.bin` pattern |

### Model Memory Usage

| Model | VRAM/RAM | Load Time |
|-------|----------|-----------|
| tiny | ~400 MB | ~1 sec |
| base | ~500 MB | ~2 sec |
| small | ~1 GB | ~4 sec |
| medium | ~2 GB | ~8 sec |
| large-v3 | ~4 GB | ~15 sec |

## Language Constraints

### Language Code Format
- ISO 639-1 two-letter codes
- Special value: `auto` for auto-detection

### Translation Constraints
- Translation always outputs English
- Not available for all language pairs
- Quality varies by source language

## Timing Constraints

### Segment Timing
```eiffel
-- Invariant
end_ms >= start_ms
-- Typical segment duration
100 ms <= duration_ms <= 30000 ms
```

### Processing Time Estimates
| Audio Length | tiny | base | large-v3 |
|--------------|------|------|----------|
| 1 minute | ~5 sec | ~10 sec | ~60 sec |
| 10 minutes | ~30 sec | ~90 sec | ~10 min |
| 1 hour | ~3 min | ~9 min | ~1 hour |

## Platform Constraints

### Windows-Specific
- Requires Visual C++ 2019 runtime
- DLLs must be in PATH or application directory

### DLL Dependencies
```
whisper.dll
ggml.dll
ggml-base.dll
ggml-cpu.dll
```

## Error Handling Constraints

### Non-Recoverable Errors
- Model file not found
- Invalid model format
- Out of memory

### Recoverable Errors
- Invalid WAV format (returns empty result)
- Unrecognized language (falls back to auto)
- Thread count too high (capped to CPU cores)

## SCOOP Constraints

### Thread Safety
- WHISPER_ENGINE is not thread-safe
- Use separate processors for concurrent transcription
- Model can be shared read-only after loading
