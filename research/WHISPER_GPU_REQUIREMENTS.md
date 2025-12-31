# Whisper & CrisperWhisper: GPU Requirements Research

**Date:** 2025-12-31
**Status:** Complete
**Relevance:** simple_speech uses whisper.cpp; this documents hardware requirements

---

## Executive Summary

**GPU is NOT required** for Whisper or CrisperWhisper, but GPU dramatically improves speed (10-20x faster). simple_speech uses **whisper.cpp**, the most CPU-efficient implementation.

---

## Whisper Model Requirements

### Memory Requirements by Model Size

| Model | Parameters | VRAM (GPU) | RAM (CPU) | Relative Speed |
|-------|------------|------------|-----------|----------------|
| tiny | 39M | ~1 GB | ~1 GB | Fastest |
| base | 74M | ~1 GB | ~1 GB | Fast |
| small | 244M | ~2 GB | ~2 GB | Moderate |
| medium | 769M | ~5 GB | ~5 GB | Slow |
| large | 1550M | ~10 GB | ~10 GB | Slowest |
| large-v3 | 1550M | ~10 GB | ~10 GB | Slowest |

### CPU vs GPU Speed Comparison

| Hardware | 13 min Audio | Notes |
|----------|--------------|-------|
| Xeon CPU (OpenAI Whisper) | 10 min 31 sec | Slower than realtime |
| Xeon CPU (faster-whisper) | 2 min 44 sec | 4x faster with CTranslate2 |
| RTX 3060 GPU | ~30 sec | 20x faster than CPU |
| RTX 4090 GPU | ~10 sec | Fastest consumer GPU |

**Key insight:** CPU can be slower than realtime for large models, making GPU essential for production workloads with medium/large models.

---

## Whisper Implementations Compared

### 1. OpenAI Whisper (Python)

```bash
pip install openai-whisper
```

- **GPU:** Requires CUDA 11.x+ and cuDNN
- **CPU:** Works but slow; uses PyTorch backend
- **Memory:** High (full PyTorch overhead)

### 2. whisper.cpp (C/C++) - Used by simple_speech

```bash
# Already included in simple_speech as whisper.dll
```

- **GPU:** Optional (CUDA, Metal, OpenCL, Vulkan supported)
- **CPU:** Highly optimized, 4-10x faster than Python
- **Memory:** Low (no Python/PyTorch overhead)
- **Special:** Apple Neural Engine (ANE) support via Core ML

**Why simple_speech uses whisper.cpp:**
- No Python dependency
- Runs efficiently on CPU
- Small binary size
- Cross-platform (Windows, Mac, Linux)

### 3. faster-whisper (CTranslate2)

```bash
pip install faster-whisper
```

- **GPU:** CUDA 12 + cuDNN 9 for GPU
- **CPU:** Optimized with INT8 quantization
- **Memory:** 2x less than OpenAI Whisper
- **Speed:** 4x faster than OpenAI Whisper

### 4. CrisperWhisper (Verbatim + Filler Detection)

```bash
pip install crisperwhisper  # or clone from GitHub
```

- **GPU:** Optional (cuBLAS 11.x + cuDNN 8.x)
- **CPU:** Falls back to float32 (slower but works)
- **Special:** Verbatim transcription with filler word timestamps

**From GitHub:**
> Prerequisites: Python 3.10, PyTorch 2.0, and NVIDIA Libraries (cuBLAS 11.x and cuDNN 8.x **for GPU execution**)

The "(for GPU execution)" note confirms GPU is optional.

---

## CPU Optimization Techniques

### 1. Quantization

Reduce precision from float32 → float16 → int8:
- **INT8:** 2-4x faster, minimal accuracy loss
- Available in: faster-whisper, whisper.cpp

### 2. Apple Neural Engine (M1/M2/M3)

whisper.cpp supports Core ML acceleration:
- 3x faster than CPU-only on Apple Silicon
- No discrete GPU required

### 3. OpenVINO (Intel)

whisper.cpp supports Intel acceleration:
- Works on Intel CPUs and integrated GPUs
- Significant speedup on modern Intel processors

### 4. Batch Processing

Process multiple audio chunks in parallel:
- Better CPU utilization
- Requires more RAM

---

## Recommendations for simple_speech

### Current State

simple_speech uses **whisper.cpp**, which is already the most CPU-efficient option:
- No GPU required
- Runs on any modern CPU
- ~4-10x faster than Python Whisper on CPU

### For Filler Word Detection (VoxCraft Clean)

Options to add CrisperWhisper-style verbatim transcription:

1. **Prompt-based approach** (simple)
   - Use existing whisper.cpp
   - Add initial prompt: "Umm, let me think like, hmm..."
   - Forces model to transcribe fillers
   - No new dependencies

2. **Post-processing approach** (no model change)
   - Detect gaps between transcribed words
   - Flag as potential filler locations
   - Cross-reference with audio energy

3. **CrisperWhisper integration** (most accurate)
   - Requires Python + PyTorch
   - GPU recommended but not required
   - Best filler detection accuracy

### Hardware Recommendations

| Use Case | Minimum | Recommended |
|----------|---------|-------------|
| Short clips (<5 min) | Any CPU | Any CPU |
| Long audio (30+ min) | Modern CPU | GPU or Apple Silicon |
| Batch processing | Multi-core CPU | GPU |
| Real-time transcription | GPU | GPU |

---

## Performance Benchmarks

### whisper.cpp on Various Hardware

| Hardware | Model | 10 min Audio | Realtime Factor |
|----------|-------|--------------|-----------------|
| M1 Mac (ANE) | base | 45 sec | 13x |
| M1 Mac (CPU) | base | 2 min | 5x |
| Ryzen 5800X | base | 1 min 30 sec | 6.7x |
| Intel i7-12700 | base | 1 min 15 sec | 8x |
| RTX 3080 | base | 15 sec | 40x |

### simple_speech Expected Performance

Since simple_speech uses whisper.cpp with the **base** model by default:
- **Typical:** 5-10x faster than realtime on modern CPUs
- **Example:** 10 min audio → 1-2 min processing

---

## Sources

- [OpenAI Whisper Inference on CPU Comparison](https://medium.com/@miosipof/openai-whisper-inference-on-cpu-comparison-e851d8609048)
- [whisper.cpp GitHub](https://github.com/ggml-org/whisper.cpp)
- [faster-whisper GitHub](https://github.com/SYSTRAN/faster-whisper)
- [CrisperWhisper GitHub](https://github.com/nyrahealth/CrisperWhisper)
- [Whisper GPU Benchmarks - Tom's Hardware](https://www.tomshardware.com/news/whisper-audio-transcription-gpus-benchmarked)
- [OpenAI Whisper Memory Requirements Discussion](https://github.com/openai/whisper/discussions/5)

---

*Research completed: 2025-12-31*
