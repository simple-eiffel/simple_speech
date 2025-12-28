/*
 * Minimal whisper.h declarations for Eiffel inline C.
 * Avoids macro conflicts with Eiffel's generated code.
 */
#ifndef WHISPER_EIFFEL_H
#define WHISPER_EIFFEL_H

#include <stdint.h>
#include <stdbool.h>

/* Opaque context pointer - we don't need the full struct */
struct whisper_context;

/* Sampling strategies */
enum whisper_sampling_strategy {
    WHISPER_SAMPLING_GREEDY = 0,
    WHISPER_SAMPLING_BEAM_SEARCH = 1
};

/* Context params - simplified for our needs */
struct whisper_context_params {
    bool use_gpu;
    bool flash_attn;
    int gpu_device;
    bool dtw_token_timestamps;
    int dtw_aheads_preset;
    int dtw_n_top;
    void* dtw_aheads_heads;
    size_t dtw_aheads_n;
    size_t dtw_mem_size;
};

/* Forward declarations of the functions we use */
#ifdef __cplusplus
extern "C" {
#endif

struct whisper_context_params whisper_context_default_params(void);
struct whisper_context* whisper_init_from_file_with_params(const char* path_model, struct whisper_context_params params);
void whisper_free(struct whisper_context* ctx);

/* Full params is complex - we get by pointer */
struct whisper_full_params;
struct whisper_full_params* whisper_full_default_params_by_ref(enum whisper_sampling_strategy strategy);
void whisper_free_params(struct whisper_full_params* params);

/* Transcription */
int whisper_full(struct whisper_context* ctx, struct whisper_full_params params, const float* samples, int n_samples);

/* Results */
int whisper_full_n_segments(struct whisper_context* ctx);
const char* whisper_full_get_segment_text(struct whisper_context* ctx, int i_segment);
int64_t whisper_full_get_segment_t0(struct whisper_context* ctx, int i_segment);
int64_t whisper_full_get_segment_t1(struct whisper_context* ctx, int i_segment);

#ifdef __cplusplus
}
#endif

#endif /* WHISPER_EIFFEL_H */
