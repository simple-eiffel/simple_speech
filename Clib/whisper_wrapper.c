/*
 * Whisper wrapper implementation - hides struct-by-value complexity from Eiffel
 */
#include "whisper.h"
#include "whisper_wrapper.h"

void* whisper_wrapper_init(const char* model_path) {
    struct whisper_context_params cparams = whisper_context_default_params();
    cparams.use_gpu = false;
    return whisper_init_from_file_with_params(model_path, cparams);
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
        whisper_free((struct whisper_context*)ctx);
    }
}
