/* speech_gpu.h - live speech on the GPU: whisper.cpp 1.8.2 built with CUDA
   (D:\prod\whisper_cpp_build\build_cuda), used through its import libraries
   and whisper.dll / ggml*.dll at run time.

   Two services, each owning its own native context (no mutable C globals,
   so nothing here forks per translation unit):
     - sliding-window decoding with word timestamps, set up with the two
       lessons of the 2026-10-05 spike: no_context = true (overlapping windows
       must not inherit each other's text) and an initial prompt holding ONLY
       text already spoken (upcoming text makes whisper hallucinate);
     - Silero voice activity (the ggml Silero model through whisper_vad_*).
       whisper_vad_detect_speech clears its LSTM state on every call, so the
       caller scores a short trailing window and reads the LAST probability.

   Lineage: header-only per the ecosystem's inline-C rule; locals carry the
   l_ prefix (rpcndr.h macro hazard - see simple_shell.h). */

#ifndef SPEECH_GPU_H
#define SPEECH_GPU_H

#include <windows.h>
#include <string.h>
#include "whisper.h"

/* whisper.cpp logs every model detail to stderr; a teleprompter has no
   console to show it on. Silence it once per process. */
static void speech_gpu_quiet_log(enum ggml_log_level l_level, const char* l_text, void* l_data) {
    (void)l_level; (void)l_text; (void)l_data;
}

static void speech_gpu_silence(void) {
    whisper_log_set(speech_gpu_quiet_log, 0);
}

/* ---- whisper ---- */

static void* speech_gpu_whisper_load(const char* l_model_utf8, int l_use_gpu) {
    struct whisper_context_params l_cp;
    speech_gpu_silence();
    l_cp = whisper_context_default_params();
    l_cp.use_gpu = l_use_gpu ? true : false;
    l_cp.flash_attn = l_use_gpu ? true : false;
    return (void*)whisper_init_from_file_with_params(l_model_utf8, l_cp);
}

static void speech_gpu_whisper_free(void* l_ctx) {
    if (l_ctx) whisper_free((struct whisper_context*)l_ctx);
}

/* Decode l_n samples (16 kHz mono float). Answers 0 on success. */
static int speech_gpu_whisper_decode(void* l_ctx, const float* l_samples, int l_n,
        const char* l_prompt_utf8, int l_threads) {
    struct whisper_full_params l_fp;
    if (!l_ctx || !l_samples || l_n <= 0) return -1;
    l_fp = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    l_fp.n_threads = l_threads > 0 ? l_threads : 4;
    l_fp.no_context = true;                 /* spike gotcha 1 */
    l_fp.single_segment = false;
    l_fp.print_special = false;
    l_fp.print_progress = false;
    l_fp.print_realtime = false;
    l_fp.print_timestamps = false;
    l_fp.token_timestamps = true;
    l_fp.language = "en";
    l_fp.suppress_blank = true;
    l_fp.temperature_inc = 0.0f;            /* no slow temperature fallbacks */
    l_fp.greedy.best_of = 1;
    l_fp.initial_prompt = (l_prompt_utf8 && l_prompt_utf8[0]) ? l_prompt_utf8 : 0;   /* spike gotcha 2: already-read text only */
    return whisper_full((struct whisper_context*)l_ctx, l_fp, l_samples, l_n);
}

static int speech_gpu_n_segments(void* l_ctx) {
    return l_ctx ? whisper_full_n_segments((struct whisper_context*)l_ctx) : 0;
}

static int speech_gpu_n_tokens(void* l_ctx, int l_seg) {
    return l_ctx ? whisper_full_n_tokens((struct whisper_context*)l_ctx, l_seg) : 0;
}

/* Is token (seg, tok) a special token (timestamps, end of text ...)? */
static int speech_gpu_token_is_special(void* l_ctx, int l_seg, int l_tok) {
    struct whisper_context* l_c = (struct whisper_context*)l_ctx;
    return whisper_full_get_token_id(l_c, l_seg, l_tok) >= whisper_token_eot(l_c) ? 1 : 0;
}

/* Copy token text (UTF-8) into l_out (NUL-terminated); answers its length. */
static int speech_gpu_token_text(void* l_ctx, int l_seg, int l_tok, char* l_out, int l_cap) {
    const char* l_t = whisper_full_get_token_text((struct whisper_context*)l_ctx, l_seg, l_tok);
    int l_n = 0;
    if (!l_t || l_cap <= 0) return 0;
    while (l_t[l_n] && l_n < l_cap - 1) { l_out[l_n] = l_t[l_n]; l_n++; }
    l_out[l_n] = 0;
    return l_n;
}

/* Token start, end (seconds) and probability. */
static double speech_gpu_token_t0(void* l_ctx, int l_seg, int l_tok) {
    return whisper_full_get_token_data((struct whisper_context*)l_ctx, l_seg, l_tok).t0 / 100.0;
}

static double speech_gpu_token_t1(void* l_ctx, int l_seg, int l_tok) {
    return whisper_full_get_token_data((struct whisper_context*)l_ctx, l_seg, l_tok).t1 / 100.0;
}

static double speech_gpu_token_p(void* l_ctx, int l_seg, int l_tok) {
    return whisper_full_get_token_data((struct whisper_context*)l_ctx, l_seg, l_tok).p;
}

/* ---- Silero voice activity ---- */

static void* speech_gpu_vad_load(const char* l_model_utf8, int l_threads) {
    struct whisper_vad_context_params l_vp;
    speech_gpu_silence();
    l_vp = whisper_vad_default_context_params();
    l_vp.n_threads = l_threads > 0 ? l_threads : 1;
    l_vp.use_gpu = false;                   /* a tiny LSTM: the CPU is faster than a GPU round trip */
    return (void*)whisper_vad_init_from_file_with_params(l_model_utf8, l_vp);
}

static void speech_gpu_vad_free(void* l_vctx) {
    if (l_vctx) whisper_vad_free((struct whisper_vad_context*)l_vctx);
}

/* Score l_n samples; answers the speech probability of the LAST chunk, or
   -1 on failure. The model works in 512-sample chunks (32 ms at 16 kHz). */
static double speech_gpu_vad_last_probability(void* l_vctx, const float* l_samples, int l_n) {
    struct whisper_vad_context* l_v = (struct whisper_vad_context*)l_vctx;
    int l_count;
    if (!l_v || !l_samples || l_n <= 0) return -1.0;
    if (!whisper_vad_detect_speech(l_v, l_samples, l_n)) return -1.0;
    l_count = whisper_vad_n_probs(l_v);
    if (l_count <= 0) return -1.0;
    return (double)whisper_vad_probs(l_v)[l_count - 1];
}

#endif
