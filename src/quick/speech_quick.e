note
	description: "Facade for simple_speech - one-stop API for common workflows"
	author: "Larry Rix"
	design: "Wraps pipeline, detector, embedder for simple usage"

class
	SPEECH_QUICK

create
	make,
	make_with_model

feature {NONE} -- Initialization

	make
			-- Create with default model path.
		do
			make_with_model ("models/ggml-base.en.bin")
		end

	make_with_model (a_model_path: STRING)
			-- Create with specified Whisper model.
		require
			path_not_empty: not a_model_path.is_empty
		do
			model_path := a_model_path
			create pipeline.make (a_model_path)
			create detector.make
			create internal_segments.make (0)
			create internal_chapters.make (0)
		ensure
			model_set: model_path.same_string (a_model_path)
		end

feature -- Status

	is_ready: BOOLEAN
			-- Is the pipeline ready for transcription?
		do
			Result := pipeline.is_ready
		end

	has_segments: BOOLEAN
			-- Have segments been transcribed?
		do
			Result := not internal_segments.is_empty
		end

	has_chapters: BOOLEAN
			-- Have chapters been detected?
		do
			Result := not internal_chapters.is_empty
		end

	last_error: detachable STRING
			-- Last error message if any.

feature -- Access

	segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Transcribed segments.
		do
			Result := internal_segments
		end

	chapters: ARRAYED_LIST [SPEECH_CHAPTER]
			-- Detected chapters.
		do
			Result := internal_chapters
		end

	segment_count: INTEGER
			-- Number of transcribed segments.
		do
			Result := internal_segments.count
		end

	chapter_count: INTEGER
			-- Number of detected chapters.
		do
			Result := internal_chapters.count
		end

feature -- One-Liner Operations

	process_video (a_input, a_output: STRING): BOOLEAN
			-- Complete workflow: transcribe, detect chapters, embed all.
			-- Returns True on success.
		require
			ready: is_ready
			input_not_empty: not a_input.is_empty
			output_not_empty: not a_output.is_empty
		local
			l_dummy: like Current
		do
			l_dummy := transcribe (a_input)
			if has_segments then
				l_dummy := detect_chapters
				l_dummy := embed_to (a_output)
				Result := last_error = Void
			end
		end

	transcribe_and_export (a_input, a_output_vtt: STRING): BOOLEAN
			-- Transcribe and export to VTT.
		require
			ready: is_ready
		local
			l_dummy: like Current
		do
			l_dummy := transcribe (a_input)
			if has_segments then
				l_dummy := export_vtt (a_output_vtt)
				Result := True
			end
		end

feature -- Fluent API

	transcribe (a_file: STRING): like Current
			-- Transcribe audio or video file.
		require
			ready: is_ready
			file_not_empty: not a_file.is_empty
		do
			last_error := Void
			current_input := a_file
			if attached pipeline.transcribe (a_file) as segs then
				internal_segments.wipe_out
				across segs as seg loop
					internal_segments.extend (seg)
				end
			else
				last_error := pipeline.last_error
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	detect_chapters: like Current
			-- Detect chapter transitions in transcribed segments.
		require
			has_segments: has_segments
		do
			last_error := Void
			if attached detector.detect_transitions (internal_segments) as chaps then
				internal_chapters.wipe_out
				across chaps as ch loop
					internal_chapters.extend (ch)
				end
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_sensitivity (a_value: REAL_64): like Current
			-- Set chapter detection sensitivity (0.0 to 1.0).
		require
			valid_range: a_value >= 0.0 and a_value <= 1.0
		local
			l_dummy: like detector
		do
			l_dummy := detector.set_sensitivity (a_value)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_min_chapter_duration (a_seconds: REAL_64): like Current
			-- Set minimum chapter duration in seconds.
		require
			positive: a_seconds > 0.0
		local
			l_dummy: like detector
		do
			l_dummy := detector.set_min_chapter_duration (a_seconds)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Export

	export_vtt (a_path: STRING): like Current
			-- Export segments to VTT format.
		require
			has_segments: has_segments
		local
			exporter: VTT_EXPORTER
		do
			create exporter.make
			exporter.export_to_file (internal_segments, a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	export_srt (a_path: STRING): like Current
			-- Export segments to SRT format.
		require
			has_segments: has_segments
		local
			exporter: SRT_EXPORTER
		do
			create exporter.make
			exporter.export_to_file (internal_segments, a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	export_json (a_path: STRING): like Current
			-- Export segments to JSON format.
		require
			has_segments: has_segments
		local
			exporter: JSON_EXPORTER
		do
			create exporter.make
			exporter.export_to_file (internal_segments, a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	export_chapters_json (a_path: STRING): like Current
			-- Export chapters to JSON format.
		require
			has_chapters: has_chapters
		local
			result_obj: SPEECH_CHAPTERED_RESULT
		do
			create result_obj.make (internal_segments)
			result_obj.set_chapters (internal_chapters)
			result_obj.export_chapters_json (a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	export_chapters_vtt (a_path: STRING): like Current
			-- Export chapters to VTT format.
		require
			has_chapters: has_chapters
		local
			result_obj: SPEECH_CHAPTERED_RESULT
		do
			create result_obj.make (internal_segments)
			result_obj.set_chapters (internal_chapters)
			result_obj.export_chapters_vtt (a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Embedding

	embed_to (a_output: STRING): like Current
			-- Embed captions and chapters into video.
		require
			has_segments: has_segments
			has_input: current_input /= Void
		local
			embedder: SPEECH_VIDEO_EMBEDDER
		do
			last_error := Void
			create embedder.make (pipeline)
			if attached current_input as inp then
				if has_chapters then
					if not embedder.embed_all (inp, internal_segments, internal_chapters, a_output) then
						last_error := embedder.last_error
					end
				else
					if not embedder.embed_captions (inp, internal_segments, a_output) then
						last_error := embedder.last_error
					end
				end
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	embed_captions_only (a_output: STRING): like Current
			-- Embed only captions (no chapters).
		require
			has_segments: has_segments
			has_input: current_input /= Void
		local
			embedder: SPEECH_VIDEO_EMBEDDER
		do
			last_error := Void
			create embedder.make (pipeline)
			if attached current_input as inp then
				if not embedder.embed_captions (inp, internal_segments, a_output) then
					last_error := embedder.last_error
				end
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	embed_chapters_only (a_output: STRING): like Current
			-- Embed only chapters (no captions).
		require
			has_chapters: has_chapters
			has_input: current_input /= Void
		local
			embedder: SPEECH_VIDEO_EMBEDDER
		do
			last_error := Void
			create embedder.make (pipeline)
			if attached current_input as inp then
				if not embedder.embed_chapters (inp, internal_chapters, a_output) then
					last_error := embedder.last_error
				end
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature {NONE} -- Implementation

	model_path: STRING
			-- Path to Whisper model.

	pipeline: SPEECH_PIPELINE
			-- Underlying transcription pipeline.

	detector: SPEECH_TRANSITION_DETECTOR
			-- Chapter detection.

	internal_segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Stored segments.

	internal_chapters: ARRAYED_LIST [SPEECH_CHAPTER]
			-- Stored chapters.

	current_input: detachable STRING
			-- Current input file path.

invariant
	pipeline_exists: pipeline /= Void
	detector_exists: detector /= Void

end
