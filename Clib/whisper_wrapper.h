/*
 * Whisper wrapper for Eiffel - hides struct-by-value complexity
 */
#ifndef WHISPER_WRAPPER_H
#define WHISPER_WRAPPER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Initialize whisper context from model file */
void* whisper_wrapper_init(const char* model_path);

/* Run full transcription */
int whisper_wrapper_transcribe(
    void* ctx,
    const float* samples,
    int n_samples,
    int n_threads,
    const char* language,
    int translate
);

/* Get number of segments */
int whisper_wrapper_n_segments(void* ctx);

/* Get segment text */
const char* whisper_wrapper_segment_text(void* ctx, int i);

/* Get segment start time in centiseconds */
int64_t whisper_wrapper_segment_t0(void* ctx, int i);

/* Get segment end time in centiseconds */
int64_t whisper_wrapper_segment_t1(void* ctx, int i);

/* Free context */
void whisper_wrapper_free(void* ctx);

#ifdef __cplusplus
}
#endif

#endif /* WHISPER_WRAPPER_H */
