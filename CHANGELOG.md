# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-09-02

### Fixed
- Test target did not compile after `ONNX_SESSION.make` gained its second argument. `simple_onnx` reworked `ONNX_SESSION` onto the real ONNX Runtime C API, and `make` became `make (a_model: ONNX_MODEL; a_env: ONNX_ENVIRONMENT)` - the session needs the environment's `api_ptr` and `env_ptr` to create and release the native `OrtSession`. `TEST_ONNX_INTEGRATION.test_onnx_session_creation` still passed one argument, so `simple_speech_tests` failed to compile with VUAR(1). The call now takes its environment from a `SIMPLE_ONNX` facade instance, the same pairing `SIMPLE_ONNX.create_session` and `SIMPLE_ONNX.load_model` use in production, and the test additionally checks that the environment landed on the session. No production code under `src/` referenced `ONNX_SESSION`, so nothing else carried the drift.

## [1.1.0]

- Phase 0-7 release: whisper.cpp transcription, sherpa-onnx diarization, export
  (SRT / VTT / JSON), chapter detection, AI enhancement, CLI and Speech Studio.
