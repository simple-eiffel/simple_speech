# S01 - Project Inventory: simple_speech

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_speech
**Version:** 1.0
**Date:** 2026-01-23

## Overview

Speech-to-text library for Eiffel wrapping whisper.cpp, providing file transcription, PCM sample processing, multi-language support, and configurable threading.

## Project Files

### Core Source Files
| File | Purpose |
|------|---------|
| `src/simple_speech.e` | Main facade class |
| `src/speech_engine.e` | Abstract engine interface |
| `src/speech_segment.e` | Transcription segment with timing |
| `src/wav_reader.e` | WAV file loading and PCM extraction |
| `src/engines/whisper_engine.e` | Whisper.cpp engine implementation |

### Engine Source Files
| File | Purpose |
|------|---------|
| `src/engines/` | Speech engine implementations |
| `src/async/` | Asynchronous transcription |
| `src/batch/` | Batch file processing |
| `src/export/` | VTT/SRT/JSON export formats |
| `src/pipeline/` | Video-to-text pipeline |
| `src/diarization/` | Speaker diarization |
| `src/chapters/` | Chapter detection |
| `src/ai/` | AI enhancement integration |

### Configuration Files
| File | Purpose |
|------|---------|
| `simple_speech.ecf` | EiffelStudio project configuration |
| `simple_speech.rc` | Windows resource file |

### Native Libraries
| File | Purpose |
|------|---------|
| `whisper.dll` | Whisper.cpp shared library |
| `ggml.dll` | GGML tensor library |
| `ggml-base.dll` | GGML base library |
| `ggml-cpu.dll` | GGML CPU backend |

### Model Files
| File | Purpose |
|------|---------|
| `models/` | Whisper model files (ggml format) |
| `download_models.sh` | Model download script |

## Dependencies

### ISE Libraries
- base (core Eiffel classes)

### simple_* Libraries
- None required for core functionality
- simple_ffmpeg (optional, for video pipeline)
- simple_ai_client (optional, for AI enhancement)

### External Libraries
- whisper.cpp (bundled DLLs)
- GGML (bundled DLLs)

## Build Targets
- `simple_speech` - Main library
- `simple_speech_tests` - Test suite
- `speech_cli` - Command-line interface
- `speech_studio` - GUI application
