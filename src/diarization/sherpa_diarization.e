note
	description: "[
		SHERPA_DIARIZATION - Pure C/C++ speaker diarization using sherpa-onnx.

		NO Python dependency. NO HuggingFace account required.
		Uses ONNX models for offline speaker diarization.

		Requirements:
		- sherpa-onnx-c-api.dll in application path
		- onnxruntime.dll in application path
		- Segmentation model (e.g., pyannote-segmentation-3-0)
		- Speaker embedding model (e.g., 3dspeaker)

		Usage:
			create diarization.make ("path/to/segmentation/model.onnx",
			                         "path/to/embedding/model.onnx")
			if diarization.is_initialized then
				segments := diarization.diarize ("audio.wav")
			end
	]"
	author: "Larry Rix"
	date: "$Date$"

class
	SHERPA_DIARIZATION

create
	make,
	make_with_defaults,
	make_with_config

feature {NONE} -- Initialization

	make (a_segmentation_model, a_embedding_model: READABLE_STRING_GENERAL)
			-- Initialize with model paths.
		require
			segmentation_model_not_empty: not a_segmentation_model.is_empty
			embedding_model_not_empty: not a_embedding_model.is_empty
		do
			create segmentation_model_path.make_from_string_general (a_segmentation_model)
			create embedding_model_path.make_from_string_general (a_embedding_model)
			create last_error.make_empty
			num_threads := 4
			clustering_threshold := 0.75
			min_duration_on := 0.2
			min_duration_off := 0.5
			initialize_engine
		end

	make_with_defaults
			-- Initialize with default model paths (in common app data).
		local
			l_models_dir: STRING_32
		do
			l_models_dir := default_models_directory
			make (l_models_dir + "\sherpa-onnx-pyannote-segmentation-3-0\model.onnx",
			      l_models_dir + "\3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx")
		end


	make_with_config (a_segmentation_model, a_embedding_model: READABLE_STRING_GENERAL;
	                  a_threshold: REAL_32; a_num_speakers: INTEGER)
			-- Initialize with model paths and clustering configuration.
			-- `a_threshold`: Clustering threshold (0.0-1.0). Higher = fewer speakers (default 0.75).
			-- `a_num_speakers`: Expected speaker count. 0 = auto-detect.
		require
			segmentation_model_not_empty: not a_segmentation_model.is_empty
			embedding_model_not_empty: not a_embedding_model.is_empty
			valid_threshold: a_threshold > 0.0 and a_threshold < 1.0
			valid_speakers: a_num_speakers >= 0
		do
			create segmentation_model_path.make_from_string_general (a_segmentation_model)
			create embedding_model_path.make_from_string_general (a_embedding_model)
			create last_error.make_empty
			num_threads := 4
			clustering_threshold := a_threshold
			num_speakers := a_num_speakers
			min_duration_on := 0.2
			min_duration_off := 0.5
			initialize_engine
		ensure
			threshold_set: clustering_threshold = a_threshold
			speakers_set: num_speakers = a_num_speakers
		end

feature -- Status

	is_initialized: BOOLEAN
			-- Is the diarization engine ready?

	has_error: BOOLEAN
			-- Did the last operation fail?
		do
			Result := not last_error.is_empty
		end

	last_error: STRING_32
			-- Error message from last operation.

	expected_sample_rate: INTEGER
			-- Expected sample rate for input audio.
		do
			if is_initialized and sd_handle /= default_pointer then
				Result := c_get_sample_rate (sd_handle)
			else
				Result := 16000  -- Default
			end
		end

feature -- Configuration

	segmentation_model_path: STRING_32
			-- Path to segmentation ONNX model.

	embedding_model_path: STRING_32
			-- Path to speaker embedding ONNX model.

	num_threads: INTEGER
			-- Number of threads to use.

	clustering_threshold: REAL_32
			-- Clustering threshold (smaller = more speakers, larger = fewer).

	num_speakers: INTEGER
			-- Expected number of speakers (0 = auto-detect).

	min_duration_on: REAL_32
			-- Minimum segment duration in seconds.

	min_duration_off: REAL_32
			-- Minimum gap between segments of same speaker.

feature -- Configuration Commands

	set_num_threads (a_count: INTEGER)
			-- Set thread count.
		require
			positive: a_count > 0
		do
			num_threads := a_count
		ensure
			set: num_threads = a_count
		end

	set_clustering_threshold (a_threshold: REAL_32)
			-- Set clustering threshold.
		require
			valid_range: a_threshold > 0.0 and a_threshold < 1.0
		do
			clustering_threshold := a_threshold
		ensure
			set: clustering_threshold = a_threshold
		end

	set_num_speakers (a_count: INTEGER)
			-- Set expected number of speakers (0 = auto-detect).
		require
			non_negative: a_count >= 0
		do
			num_speakers := a_count
		ensure
			set: num_speakers = a_count
		end

	set_duration_params (a_min_on, a_min_off: REAL_32)
			-- Set minimum duration parameters.
		require
			positive_on: a_min_on > 0.0
			positive_off: a_min_off > 0.0
		do
			min_duration_on := a_min_on
			min_duration_off := a_min_off
		ensure
			on_set: min_duration_on = a_min_on
			off_set: min_duration_off = a_min_off
		end

feature -- Operations

	diarize (a_audio_path: READABLE_STRING_GENERAL): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Perform speaker diarization on audio file.
			-- Returns segments with speaker_id and speaker_label set.
			-- Note: These segments only contain speaker info, NOT transcription.
		require
			initialized: is_initialized
			file_exists: file_exists (a_audio_path)
		local
			l_wav: WAV_READER
			l_samples: detachable ARRAY [REAL_32]
			l_result_ptr: POINTER
			l_segments_ptr: POINTER
			l_num_segments, l_num_speakers: INTEGER
			l_start, l_end: REAL_32
			l_speaker: INTEGER
			l_segment: SPEECH_SEGMENT
			i: INTEGER
			l_managed: MANAGED_POINTER
		do
			create Result.make (50)
			create last_error.make_empty

			-- Load audio
			create l_wav.make
			l_wav.set_target_sample_rate (expected_sample_rate)
			l_samples := l_wav.load_file (a_audio_path)

			if not attached l_samples then
				last_error := {STRING_32} "Failed to load audio: "
				if attached l_wav.last_error as err then
					last_error.append (err)
				end
			elseif l_samples.count = 0 then
				last_error := {STRING_32} "Audio file is empty"
			else
				-- Process with sherpa-onnx
				-- Convert Eiffel array to C pointer
				create l_managed.make (l_samples.count * 4)  -- 4 bytes per REAL_32
				from i := 1 until i > l_samples.count loop
					l_managed.put_real_32 (l_samples[i], (i - 1) * 4)
					i := i + 1
				end

				l_result_ptr := c_process (sd_handle, l_managed.item, l_samples.count)

				if l_result_ptr = default_pointer then
					last_error := {STRING_32} "Diarization processing failed"
				else
					l_num_segments := c_get_num_segments (l_result_ptr)
					l_num_speakers := c_get_num_speakers (l_result_ptr)

					if l_num_segments > 0 then
						l_segments_ptr := c_sort_by_start_time (l_result_ptr)

						if l_segments_ptr /= default_pointer then
							from i := 0 until i >= l_num_segments loop
								l_start := c_segment_start (l_segments_ptr, i)
								l_end := c_segment_end (l_segments_ptr, i)
								l_speaker := c_segment_speaker (l_segments_ptr, i)

								-- Create segment with speaker info (empty text since this is diarization only)
								create l_segment.make_with_speaker (
									"[Speaker segment]",
									l_start.to_double,
									l_end.to_double,
									l_speaker + 1,  -- Convert 0-based to 1-based
									"SPEAKER_" + l_speaker.out
								)
								Result.extend (l_segment)
								i := i + 1
							end

							c_destroy_segment (l_segments_ptr)
						end
					end

					c_destroy_result (l_result_ptr)
				end
			end
		ensure
			result_exists: Result /= Void
		end

	diarize_samples (a_samples: ARRAY [REAL_32]): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Perform speaker diarization on raw audio samples.
			-- Samples must be 16kHz mono float32 in range [-1, 1].
		require
			initialized: is_initialized
			samples_exist: a_samples /= Void and then a_samples.count > 0
		local
			l_result_ptr: POINTER
			l_segments_ptr: POINTER
			l_num_segments: INTEGER
			l_start, l_end: REAL_32
			l_speaker: INTEGER
			l_segment: SPEECH_SEGMENT
			i: INTEGER
			l_managed: MANAGED_POINTER
		do
			create Result.make (50)
			create last_error.make_empty

			-- Convert Eiffel array to C pointer
			create l_managed.make (a_samples.count * 4)
			from i := 1 until i > a_samples.count loop
				l_managed.put_real_32 (a_samples[i], (i - 1) * 4)
				i := i + 1
			end

			l_result_ptr := c_process (sd_handle, l_managed.item, a_samples.count)

			if l_result_ptr = default_pointer then
				last_error := {STRING_32} "Diarization processing failed"
			else
				l_num_segments := c_get_num_segments (l_result_ptr)

				if l_num_segments > 0 then
					l_segments_ptr := c_sort_by_start_time (l_result_ptr)

					if l_segments_ptr /= default_pointer then
						from i := 0 until i >= l_num_segments loop
							l_start := c_segment_start (l_segments_ptr, i)
							l_end := c_segment_end (l_segments_ptr, i)
							l_speaker := c_segment_speaker (l_segments_ptr, i)

							create l_segment.make_with_speaker (
								"[Speaker segment]",
								l_start.to_double,
								l_end.to_double,
								l_speaker + 1,
								"SPEAKER_" + l_speaker.out
							)
							Result.extend (l_segment)
							i := i + 1
						end

						c_destroy_segment (l_segments_ptr)
					end
				end

				c_destroy_result (l_result_ptr)
			end
		ensure
			result_exists: Result /= Void
		end


	diarize_media (a_media_path: READABLE_STRING_GENERAL): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Perform speaker diarization on any media file (WAV, MP4, MOV, MKV, etc.).
			-- Automatically extracts audio from video files using ffmpeg.
		require
			initialized: is_initialized
			file_exists: file_exists (a_media_path)
		local
			l_ffmpeg: FFMPEG_CLI
			l_temp_wav: STRING_32
			l_temp_file: RAW_FILE
			l_ext: STRING_32
		do
			create last_error.make_empty
			l_ext := file_extension (a_media_path).as_lower

			if l_ext.is_equal ("wav") then
				-- Direct WAV file - use as is
				Result := diarize (a_media_path)
			else
				-- Video or other audio format - extract to temp WAV
				create l_ffmpeg.make
				if not l_ffmpeg.is_available then
					last_error := {STRING_32} "FFmpeg not available for audio extraction"
					create Result.make (0)
				else
					-- Generate unique temp file path
					l_temp_wav := temp_directory + {STRING_32} "\sherpa_diar_" + c_time_ms.out + ".wav"
					
					if extract_audio_to_wav (l_ffmpeg, a_media_path, l_temp_wav) then
						Result := diarize (l_temp_wav)
						-- Clean up temp file
						create l_temp_file.make_with_name (l_temp_wav)
						if l_temp_file.exists then
							l_temp_file.delete
						end
					else
						create Result.make (0)
						-- last_error already set by extract_audio_to_wav
					end
				end
			end
		ensure
			result_exists: Result /= Void
		end

feature -- Audio extraction

	extract_audio_to_wav (a_ffmpeg: FFMPEG_CLI; a_input, a_output: READABLE_STRING_GENERAL): BOOLEAN
			-- Extract audio from media file as 16kHz mono WAV.
		require
			ffmpeg_available: a_ffmpeg /= Void and then a_ffmpeg.is_available
			input_exists: file_exists (a_input)
		local
			l_cmd: STRING_32
		do
			if attached a_ffmpeg.ffmpeg_path as fp then
				create l_cmd.make (400)
				l_cmd.append (fp)
				l_cmd.append (" -y -i %"")
				l_cmd.append (a_input.to_string_32)
				l_cmd.append ("%" -ac 1 -ar 16000 -f wav %"")
				l_cmd.append (a_output.to_string_32)
				l_cmd.append ("%"")
				
				a_ffmpeg.execute (l_cmd)
				Result := a_ffmpeg.was_successful
				
				if not Result then
					last_error := {STRING_32} "Audio extraction failed: " + a_input.to_string_32
				end
			else
				last_error := {STRING_32} "FFmpeg path not set"
				Result := False
			end
		end

	file_extension (a_path: READABLE_STRING_GENERAL): STRING_32
			-- Get file extension (without dot).
		local
			l_pos: INTEGER
			l_path: STRING_32
		do
			l_path := a_path.to_string_32
			l_pos := l_path.last_index_of ('.', l_path.count)
			if l_pos > 0 and l_pos < l_path.count then
				Result := l_path.substring (l_pos + 1, l_path.count)
			else
				create Result.make_empty
			end
		ensure
			result_exists: Result /= Void
		end

	temp_directory: STRING_32
			-- Get system temp directory.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.item ("TEMP") as t then
				Result := t.to_string_32
			elseif attached l_env.item ("TMP") as t then
				Result := t.to_string_32
			else
				Result := {STRING_32} "."
			end
		ensure
			result_exists: Result /= Void
		end

	c_time_ms: INTEGER_64
			-- Current time in milliseconds for unique temp file names.
		external
			"C inline use <windows.h>"
		alias
			"return (EIF_INTEGER_64)GetTickCount64();"
		end


feature -- Cleanup

	dispose
			-- Release native resources.
		do
			if sd_handle /= default_pointer then
				c_destroy_diarization (sd_handle)
				sd_handle := default_pointer
			end
			is_initialized := False
		end

feature -- File queries

	file_exists (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Does file exist?
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			Result := l_file.exists
		end

feature {NONE} -- Implementation

	sd_handle: POINTER
			-- Native sherpa-onnx diarization handle.

	initialize_engine
			-- Initialize sherpa-onnx speaker diarization engine.
		local
			l_seg_path_c, l_emb_path_c: C_STRING
			l_provider: C_STRING
		do
			is_initialized := False
			create last_error.make_empty

			-- Check model files exist
			if not file_exists (segmentation_model_path) then
				last_error := {STRING_32} "Segmentation model not found: " + segmentation_model_path
			elseif not file_exists (embedding_model_path) then
				last_error := {STRING_32} "Embedding model not found: " + embedding_model_path
			else
				-- Create C strings for paths
				create l_seg_path_c.make (segmentation_model_path)
				create l_emb_path_c.make (embedding_model_path)
				create l_provider.make ("cpu")

				sd_handle := c_create_diarization (
					l_seg_path_c.item,      -- segmentation model
					l_emb_path_c.item,      -- embedding model
					l_provider.item,        -- provider ("cpu")
					num_threads,            -- num_threads
					num_speakers,           -- num_clusters (0 = auto)
					clustering_threshold,   -- threshold
					min_duration_on,        -- min_duration_on
					min_duration_off        -- min_duration_off
				)

				if sd_handle = default_pointer then
					last_error := {STRING_32} "Failed to create diarization engine (check DLLs and models)"
				else
					is_initialized := True
				end
			end
		end

	default_models_directory: STRING_32
			-- Default directory for VoxCraft models.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.item ("PROGRAMDATA") as pd then
				create Result.make_from_string (pd.to_string_32)
				Result.append ({STRING_32} "\VoxCraft\models")
			else
				Result := {STRING_32} "C:\ProgramData\VoxCraft\models"
			end
		end

feature {NONE} -- C Externals

	c_create_diarization (a_seg_model, a_emb_model, a_provider: POINTER;
	                      a_num_threads, a_num_clusters: INTEGER;
	                      a_threshold, a_min_on, a_min_off: REAL_32): POINTER
			-- Create offline speaker diarization instance.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				SherpaOnnxOfflineSpeakerDiarizationConfig config;
				memset(&config, 0, sizeof(config));

				// Segmentation model config (pyannote)
				config.segmentation.pyannote.model = (const char*)$a_seg_model;
				config.segmentation.num_threads = (int32_t)$a_num_threads;
				config.segmentation.debug = 0;
				config.segmentation.provider = (const char*)$a_provider;

				// Embedding extractor config
				config.embedding.model = (const char*)$a_emb_model;
				config.embedding.num_threads = (int32_t)$a_num_threads;
				config.embedding.debug = 0;
				config.embedding.provider = (const char*)$a_provider;

				// Clustering config
				config.clustering.num_clusters = (int32_t)$a_num_clusters;
				config.clustering.threshold = (float)$a_threshold;

				// Duration config
				config.min_duration_on = (float)$a_min_on;
				config.min_duration_off = (float)$a_min_off;

				return (EIF_POINTER)SherpaOnnxCreateOfflineSpeakerDiarization(&config);
			]"
		end

	c_destroy_diarization (a_sd: POINTER)
			-- Destroy speaker diarization instance.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				SherpaOnnxDestroyOfflineSpeakerDiarization((const SherpaOnnxOfflineSpeakerDiarization*)$a_sd);
			]"
		end

	c_get_sample_rate (a_sd: POINTER): INTEGER
			-- Get expected sample rate.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				return (EIF_INTEGER)SherpaOnnxOfflineSpeakerDiarizationGetSampleRate(
					(const SherpaOnnxOfflineSpeakerDiarization*)$a_sd);
			]"
		end

	c_process (a_sd, a_samples: POINTER; a_n: INTEGER): POINTER
			-- Process audio samples.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				return (EIF_POINTER)SherpaOnnxOfflineSpeakerDiarizationProcess(
					(const SherpaOnnxOfflineSpeakerDiarization*)$a_sd,
					(const float*)$a_samples,
					(int32_t)$a_n);
			]"
		end

	c_get_num_segments (a_result: POINTER): INTEGER
			-- Get number of segments in result.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				return (EIF_INTEGER)SherpaOnnxOfflineSpeakerDiarizationResultGetNumSegments(
					(const SherpaOnnxOfflineSpeakerDiarizationResult*)$a_result);
			]"
		end

	c_get_num_speakers (a_result: POINTER): INTEGER
			-- Get number of unique speakers.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				return (EIF_INTEGER)SherpaOnnxOfflineSpeakerDiarizationResultGetNumSpeakers(
					(const SherpaOnnxOfflineSpeakerDiarizationResult*)$a_result);
			]"
		end

	c_sort_by_start_time (a_result: POINTER): POINTER
			-- Get segments sorted by start time.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				return (EIF_POINTER)SherpaOnnxOfflineSpeakerDiarizationResultSortByStartTime(
					(const SherpaOnnxOfflineSpeakerDiarizationResult*)$a_result);
			]"
		end

	c_segment_start (a_segments: POINTER; a_index: INTEGER): REAL_32
			-- Get segment start time.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				const SherpaOnnxOfflineSpeakerDiarizationSegment* segs =
					(const SherpaOnnxOfflineSpeakerDiarizationSegment*)$a_segments;
				return (EIF_REAL_32)segs[$a_index].start;
			]"
		end

	c_segment_end (a_segments: POINTER; a_index: INTEGER): REAL_32
			-- Get segment end time.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				const SherpaOnnxOfflineSpeakerDiarizationSegment* segs =
					(const SherpaOnnxOfflineSpeakerDiarizationSegment*)$a_segments;
				return (EIF_REAL_32)segs[$a_index].end;
			]"
		end

	c_segment_speaker (a_segments: POINTER; a_index: INTEGER): INTEGER
			-- Get segment speaker ID.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				const SherpaOnnxOfflineSpeakerDiarizationSegment* segs =
					(const SherpaOnnxOfflineSpeakerDiarizationSegment*)$a_segments;
				return (EIF_INTEGER)segs[$a_index].speaker;
			]"
		end

	c_destroy_segment (a_segments: POINTER)
			-- Free segments array.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				SherpaOnnxOfflineSpeakerDiarizationDestroySegment(
					(const SherpaOnnxOfflineSpeakerDiarizationSegment*)$a_segments);
			]"
		end

	c_destroy_result (a_result: POINTER)
			-- Free result.
		external
			"C inline use <sherpa-onnx/c-api/c-api.h>"
		alias
			"[
				SherpaOnnxOfflineSpeakerDiarizationDestroyResult(
					(const SherpaOnnxOfflineSpeakerDiarizationResult*)$a_result);
			]"
		end

invariant
	valid_threads: num_threads > 0
	valid_threshold: clustering_threshold > 0.0 and clustering_threshold < 1.0

end
