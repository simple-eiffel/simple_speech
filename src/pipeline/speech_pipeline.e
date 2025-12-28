note
	description: "[
		SPEECH_PIPELINE - Video-to-text pipeline using FFmpeg and Whisper.

		Provides one-call video captioning:
			create pipeline.make ("models/ggml-base.en.bin")
			segments := pipeline.process_video ("video.mp4")
			pipeline.export_vtt ("captions.vtt")

		Internally:
		1. Probes video for audio stream
		2. Extracts audio as 16kHz mono WAV (temp file)
		3. Transcribes with whisper
		4. Cleans up temp file
		5. Returns segments for export
	]"
	author: "Larry Rix"

class
	SPEECH_PIPELINE

create
	make

feature {NONE} -- Initialization

	make (a_model_path: READABLE_STRING_GENERAL)
			-- Create pipeline with whisper model.
		do
			model_path := a_model_path.to_string_32
			create ffmpeg.make
			create segments.make (0)
			temp_counter := 0
			-- If ffmpeg not found in PATH, try common Windows location
			if not ffmpeg.is_available then
				try_common_ffmpeg_paths
			end
		ensure
			model_set: model_path.same_string_general (a_model_path)
		end

feature -- Access

	model_path: STRING_32
			-- Path to whisper model.

	segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Transcription segments from last process_video call.

	last_error: detachable STRING_32
			-- Last error message.

	video_info: detachable FFMPEG_MEDIA_INFO
			-- Info about last processed video.

	ffmpeg_cli: FFMPEG_CLI
			-- Access to FFmpeg CLI for embedding operations.
		do
			Result := ffmpeg
		end

feature -- Status

	is_ready: BOOLEAN
			-- Is pipeline ready for processing?
		do
			Result := ffmpeg.is_available
		end

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_error /= Void
		end

feature -- Configuration

	set_language (a_lang: READABLE_STRING_GENERAL): like Current
			-- Set transcription language.
		do
			language := a_lang.to_string_32
			Result := Current
		ensure
			language_set: attached language as l and then l.same_string_general (a_lang)
			result_is_current: Result = Current
		end

	set_translate (a_translate: BOOLEAN): like Current
			-- Enable/disable translation to English.
		do
			translate := a_translate
			Result := Current
		ensure
			translate_set: translate = a_translate
			result_is_current: Result = Current
		end

feature -- Processing

	process_video (a_video_path: READABLE_STRING_GENERAL): like segments
			-- Process video file and return transcription segments.
			-- Extracts audio, transcribes, cleans up temp files.
		require
			ready: is_ready
			path_not_empty: not a_video_path.is_empty
		local
			l_temp_wav: STRING_32
			l_speech: SIMPLE_SPEECH
			l_dummy: SIMPLE_SPEECH
		do
			clear_error
			create segments.make (10)
			Result := segments

			-- Probe video
			video_info := ffmpeg.probe (a_video_path)
			if not attached video_info as vi then
				set_error ("Failed to probe video: " + a_video_path.to_string_32)
			elseif not vi.has_audio then
				set_error ("Video has no audio track: " + a_video_path.to_string_32)
			else
				-- Extract audio to temp WAV (16kHz mono for whisper)
				l_temp_wav := generate_temp_path
				if extract_audio_for_whisper (a_video_path, l_temp_wav) then
					-- Transcribe
					create l_speech.make (model_path)
					if l_speech.is_valid then
						-- Apply configuration
						if attached language as lang then
							l_dummy := l_speech.set_language (lang)
						end
						if translate then
							l_dummy := l_speech.set_translate (True)
						end

						-- Transcribe
						segments := l_speech.transcribe_file (l_temp_wav)
						Result := segments

						l_speech.dispose
					else
						set_error ("Failed to load whisper model: " + model_path)
					end

					-- Cleanup temp file
					cleanup_temp_file (l_temp_wav)
				end
			end
		ensure
			result_is_segments: Result = segments
		end

	process_video_to_vtt (a_video_path, a_vtt_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Process video and export directly to VTT.
		require
			ready: is_ready
		local
			l_segs: like segments
		do
			l_segs := process_video (a_video_path)
			if not has_error and then segments.count > 0 then
				Result := export_vtt (a_vtt_path)
			end
		end

	process_video_to_srt (a_video_path, a_srt_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Process video and export directly to SRT.
		require
			ready: is_ready
		local
			l_segs: like segments
		do
			l_segs := process_video (a_video_path)
			if not has_error and then segments.count > 0 then
				Result := export_srt (a_srt_path)
			end
		end

feature -- Export

	export_vtt (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Export segments to VTT file.
		require
			has_segments: segments.count > 0
		local
			exporter: SPEECH_EXPORTER
			l_dummy: SPEECH_EXPORTER
		do
			create exporter.make (segments)
			l_dummy := exporter.export_vtt (a_path)
			Result := exporter.is_ok
			if not Result then
				set_error ("VTT export failed: " + a_path.to_string_32)
			end
		end

	export_srt (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Export segments to SRT file.
		require
			has_segments: segments.count > 0
		local
			exporter: SPEECH_EXPORTER
			l_dummy: SPEECH_EXPORTER
		do
			create exporter.make (segments)
			l_dummy := exporter.export_srt (a_path)
			Result := exporter.is_ok
			if not Result then
				set_error ("SRT export failed: " + a_path.to_string_32)
			end
		end

	export_json (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Export segments to JSON file.
		require
			has_segments: segments.count > 0
		local
			exporter: SPEECH_EXPORTER
			l_dummy: SPEECH_EXPORTER
		do
			create exporter.make (segments)
			l_dummy := exporter.export_json (a_path)
			Result := exporter.is_ok
			if not Result then
				set_error ("JSON export failed: " + a_path.to_string_32)
			end
		end

	export_all (a_base_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Export to all formats (VTT, SRT, JSON, TXT).
		require
			has_segments: segments.count > 0
		local
			exporter: SPEECH_EXPORTER
			l_dummy: SPEECH_EXPORTER
			l_base: STRING_32
		do
			l_base := a_base_path.to_string_32
			create exporter.make (segments)
			l_dummy := exporter.export_vtt (l_base + ".vtt")
			                    .export_srt (l_base + ".srt")
			                    .export_json (l_base + ".json")
			                    .export_text (l_base + ".txt")
			Result := exporter.is_ok
		end

feature {NONE} -- Implementation

	ffmpeg: FFMPEG_CLI
			-- FFmpeg CLI wrapper.

	language: detachable STRING_32
			-- Language code for transcription.

	translate: BOOLEAN
			-- Translate to English?

	temp_counter: INTEGER
			-- Counter for unique temp file names.

	extract_audio_for_whisper (a_video, a_output: READABLE_STRING_GENERAL): BOOLEAN
			-- Extract audio from video as 16kHz mono WAV for whisper.
		local
			l_cmd: STRING_32
		do
			if attached ffmpeg.ffmpeg_path as fp then
				create l_cmd.make (400)
				l_cmd.append (fp)
				l_cmd.append (" -y -i %"")
				l_cmd.append (a_video.to_string_32)
				l_cmd.append ("%" -vn -acodec pcm_s16le -ar 16000 -ac 1 %"")
				l_cmd.append (a_output.to_string_32)
				l_cmd.append ("%"")

				ffmpeg.execute (l_cmd)
				Result := ffmpeg.was_successful
				if not Result then
					set_error ("Audio extraction failed: " + a_video.to_string_32)
				end
			else
				set_error ("FFmpeg not available")
			end
		end

	generate_temp_path: STRING_32
			-- Generate unique temp file path.
		do
			temp_counter := temp_counter + 1
			create Result.make (50)
			Result.append (temp_directory)
			Result.append ("speech_temp_")
			Result.append_integer (temp_counter)
			Result.append ("_")
			Result.append_integer ((create {TIME}.make_now).compact_time)
			Result.append (".wav")
		end

	temp_directory: STRING_32
			-- Get system temp directory.
		local
			l_env: EXECUTION_ENVIRONMENT
		once
			create l_env
			if attached l_env.item ("TEMP") as t then
				create Result.make_from_string_general (t)
				if not Result.is_empty and then Result.item (Result.count) /= '\' then
					Result.append_character ('\')
				end
			else
				Result := "C:\Temp\"
			end
		end

	cleanup_temp_file (a_path: READABLE_STRING_GENERAL)
			-- Delete temp file if it exists.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path.to_string_8)
			if l_file.exists then
				l_file.delete
			end
		rescue
			-- Ignore cleanup errors
		end

	try_common_ffmpeg_paths
			-- Try common FFmpeg locations and environment variables.
		local
			l_env: EXECUTION_ENVIRONMENT
			l_file: RAW_FILE
			l_paths: ARRAYED_LIST [STRING_32]
			l_found: BOOLEAN
			l_ffprobe: STRING_32
		do
			create l_env
			create l_paths.make (5)

			-- Check FFMPEG_PATH environment variable first
			if attached l_env.item ("FFMPEG_PATH") as env_path then
				l_paths.extend (env_path.to_string_32 + "\ffmpeg.exe")
				l_paths.extend (env_path.to_string_32 + "\bin\ffmpeg.exe")
			end

			-- Common Windows locations
			l_paths.extend ("D:\ffmpeg\bin\ffmpeg.exe")
			l_paths.extend ("D:\ffmpeg\ffmpeg.exe")
			l_paths.extend ("C:\ffmpeg\bin\ffmpeg.exe")
			l_paths.extend ("C:\Program Files\ffmpeg\bin\ffmpeg.exe")

			from l_paths.start until l_paths.after or l_found loop
				create l_file.make_with_name (l_paths.item)
				if l_file.exists then
					ffmpeg.set_ffmpeg_path (l_paths.item)
					-- Also set ffprobe path (same directory)
					l_ffprobe := l_paths.item.twin
					l_ffprobe.replace_substring_all ("ffmpeg.exe", "ffprobe.exe")
					create l_file.make_with_name (l_ffprobe)
					if l_file.exists then
						ffmpeg.set_ffprobe_path (l_ffprobe)
					end
					l_found := True
				end
				l_paths.forth
			end
		end

	clear_error
			-- Clear last error.
		do
			last_error := Void
		end

	set_error (a_msg: READABLE_STRING_GENERAL)
			-- Set error message.
		do
			last_error := a_msg.to_string_32
		end

end
