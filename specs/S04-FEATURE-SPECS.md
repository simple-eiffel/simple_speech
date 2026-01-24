# S04 - Feature Specifications: simple_speech

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_speech
**Date:** 2026-01-23

## Core Features

### SIMPLE_SPEECH (Facade)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `(model_path: STRING)` | Create with Whisper engine |
| `make_with_engine` | `(engine: SPEECH_ENGINE)` | Create with custom engine |
| `is_valid` | `: BOOLEAN` | Engine ready check |
| `is_model_loaded` | `: BOOLEAN` | Model loaded check |
| `last_error` | `: detachable STRING_32` | Last error message |
| `set_language` | `(lang: STRING)` | Set source language |
| `set_threads` | `(count: INTEGER)` | Set CPU thread count |
| `set_translate` | `(translate: BOOLEAN)` | Enable translation |
| `with_language` | `(lang: STRING): like Current` | Fluent language |
| `with_threads` | `(count: INTEGER): like Current` | Fluent threads |
| `with_translate` | `(translate: BOOLEAN): like Current` | Fluent translate |
| `transcribe_file` | `(wav_path: STRING): LIST [SPEECH_SEGMENT]` | Transcribe WAV file |
| `transcribe_pcm` | `(samples: ARRAY [REAL_32]; rate: INTEGER): LIST [SPEECH_SEGMENT]` | Transcribe PCM |
| `dispose` | `()` | Release resources |

### SPEECH_SEGMENT

| Feature | Signature | Description |
|---------|-----------|-------------|
| `text` | `: STRING_32` | Transcribed text |
| `start_ms` | `: INTEGER_64` | Start time (ms) |
| `end_ms` | `: INTEGER_64` | End time (ms) |
| `duration_ms` | `: INTEGER_64` | Duration (ms) |
| `start_time` | `: TIME` | Start as TIME object |
| `end_time` | `: TIME` | End as TIME object |
| `confidence` | `: REAL_64` | Confidence score 0.0-1.0 |
| `language` | `: STRING` | Detected language code |

### WAV_READER

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `()` | Create reader |
| `load_file` | `(path: STRING): detachable ARRAY [REAL_32]` | Load WAV file |
| `target_sample_rate` | `: INTEGER` | Required rate (16000) |
| `last_error` | `: detachable STRING_32` | Last error |
| `sample_count` | `: INTEGER` | Samples loaded |
| `duration_ms` | `: INTEGER_64` | Audio duration |

### WHISPER_ENGINE

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `()` | Create engine |
| `load_model` | `(path: STRING): BOOLEAN` | Load model file |
| `is_ready` | `: BOOLEAN` | Engine initialized |
| `is_model_loaded` | `: BOOLEAN` | Model loaded |
| `transcribe` | `(samples: ARRAY [REAL_32]; rate: INTEGER): LIST [SPEECH_SEGMENT]` | Transcribe |
| `set_language` | `(lang: STRING)` | Set language |
| `set_threads` | `(count: INTEGER)` | Set threads |
| `set_translate` | `(translate: BOOLEAN)` | Enable translation |
| `dispose` | `()` | Cleanup |

## Export Features

### VTT_EXPORTER

| Feature | Signature | Description |
|---------|-----------|-------------|
| `export` | `(segments: LIST [SPEECH_SEGMENT]): STRING` | Generate VTT |
| `export_to_file` | `(segments: LIST; path: STRING): BOOLEAN` | Write VTT file |

### SRT_EXPORTER

| Feature | Signature | Description |
|---------|-----------|-------------|
| `export` | `(segments: LIST [SPEECH_SEGMENT]): STRING` | Generate SRT |
| `export_to_file` | `(segments: LIST; path: STRING): BOOLEAN` | Write SRT file |

## Language Codes

| Code | Language | Code | Language |
|------|----------|------|----------|
| `en` | English | `de` | German |
| `es` | Spanish | `fr` | French |
| `ja` | Japanese | `zh` | Chinese |
| `ko` | Korean | `ru` | Russian |
| `auto` | Auto-detect | | |

## Model Sizes

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| tiny | 39 MB | Fastest | Good |
| base | 74 MB | Fast | Better |
| small | 244 MB | Medium | Good |
| medium | 769 MB | Slow | Great |
| large-v3 | 2.9 GB | Slowest | Best |
