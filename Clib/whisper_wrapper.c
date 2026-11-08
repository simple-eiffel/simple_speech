/*
 * Whisper wrapper implementation - hides struct-by-value complexity from Eiffel
 */
#include <whisper.h>  /* Windows: Clib's copy through /I; elsewhere the installed whisper.cpp */
#include "whisper_wrapper.h"

#if !defined(_WIN32)
#include <ggml-backend.h>

#include <stdlib.h>

/* ggml as packaged on macOS and Linux loads its CPU and GPU backends as plugins;
   until they are loaded, whisper finds no device and aborts. Windows links them in. */
static void whisper_wrapper_load_backends(void) {
    static int loaded = 0;
    if (!loaded) {
        ggml_backend_load_all();
        loaded = 1;
    }
}

/* Contexts still open. ggml's Metal backend asserts at exit that every buffer was
   freed, so a program that ends without dispose would abort. The exit handler frees
   what is left; it is registered after the first context exists, so it runs before
   the backend's own teardown. */
#define WHISPER_WRAPPER_MAX_OPEN 64
static void* whisper_wrapper_open[WHISPER_WRAPPER_MAX_OPEN];

static void whisper_wrapper_free_all(void) {
    for (int i = 0; i < WHISPER_WRAPPER_MAX_OPEN; i++) {
        if (whisper_wrapper_open[i]) {
            whisper_free((struct whisper_context*) whisper_wrapper_open[i]);
            whisper_wrapper_open[i] = NULL;
        }
    }
}

static void whisper_wrapper_track(void* ctx) {
    static int registered = 0;
    if (!ctx) return;
    if (!registered) {
        atexit(whisper_wrapper_free_all);
        registered = 1;
    }
    for (int i = 0; i < WHISPER_WRAPPER_MAX_OPEN; i++) {
        if (!whisper_wrapper_open[i]) { whisper_wrapper_open[i] = ctx; return; }
    }
}

static void whisper_wrapper_untrack(void* ctx) {
    for (int i = 0; i < WHISPER_WRAPPER_MAX_OPEN; i++) {
        if (whisper_wrapper_open[i] == ctx) { whisper_wrapper_open[i] = NULL; return; }
    }
}
#endif

void* whisper_wrapper_init(const char* model_path) {
#if !defined(_WIN32)
    whisper_wrapper_load_backends();
#endif
    struct whisper_context_params cparams = whisper_context_default_params();
    cparams.use_gpu = true;
    void* ctx = whisper_init_from_file_with_params(model_path, cparams);
#if !defined(_WIN32)
    whisper_wrapper_track(ctx);
#endif
    return ctx;
}

int whisper_wrapper_transcribe(
    void* ctx,
    const float* samples,
    int n_samples,
    int n_threads,
    const char* language,
    int translate
) {
    struct whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    wparams.n_threads = n_threads;
    wparams.print_progress = false;
    wparams.print_realtime = false;
    wparams.print_timestamps = false;
    wparams.print_special = false;
    if (language) {
        wparams.language = language;
    }
    wparams.translate = translate ? true : false;
    return whisper_full((struct whisper_context*)ctx, wparams, samples, n_samples);
}

int whisper_wrapper_n_segments(void* ctx) {
    return whisper_full_n_segments((struct whisper_context*)ctx);
}

const char* whisper_wrapper_segment_text(void* ctx, int i) {
    return whisper_full_get_segment_text((struct whisper_context*)ctx, i);
}

int64_t whisper_wrapper_segment_t0(void* ctx, int i) {
    return whisper_full_get_segment_t0((struct whisper_context*)ctx, i);
}

int64_t whisper_wrapper_segment_t1(void* ctx, int i) {
    return whisper_full_get_segment_t1((struct whisper_context*)ctx, i);
}

void whisper_wrapper_free(void* ctx) {
    if (ctx) {
#if !defined(_WIN32)
        whisper_wrapper_untrack(ctx);
#endif
        whisper_free((struct whisper_context*)ctx);
    }
}
