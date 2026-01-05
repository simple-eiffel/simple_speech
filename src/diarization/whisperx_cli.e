note
	description: "[
		WHISPERX_CLI - Command-line wrapper for WhisperX diarization.

		WhisperX provides speech transcription with speaker diarization.
		This class wraps the whisperx Python CLI tool to provide:
		- Audio transcription with speaker identification
		- Per-segment speaker labels (SPEAKER_00, SPEAKER_01, etc.)
		- JSON output parsing into SPEECH_SEGMENTs

		Requirements:
		- Python 3.8+
		- whisperx installed: pip install whisperx
		- HuggingFace token for pyannote (first-time setup)

		Usage:
			create cli.make
			if cli.is_available then
				segments := cli.transcribe_with_diarization ("audio.wav")
			end
	]"
	author: "Larry Rix"
	date: "$Date$"

class
	WHISPERX_CLI

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize WhisperX CLI wrapper.
		do
			create last_error.make_empty
			create model.make_from_string ("medium")
			create device.make_from_string ("cuda")
			create compute_type.make_from_string ("float16")
			check_availability
		end

feature -- Status

	is_available: BOOLEAN
			-- Is WhisperX available on this system?

	has_error: BOOLEAN
			-- Did the last operation fail?
		do
			Result := not last_error.is_empty
		end

	last_error: STRING_32
			-- Error message from last operation.

	has_python: BOOLEAN
			-- Is Python available?

	has_whisperx: BOOLEAN
			-- Is whisperx package installed?

	has_hf_token: BOOLEAN
			-- Is HF_TOKEN environment variable set?

	setup_status_json: STRING
			-- JSON object with detailed setup status for UI.
			-- Format: {"python":true/false, "whisperx":true/false, "hf_token":true/false, "ready":true/false}
		do
			create Result.make (200)
			Result.append ("{%"python%":")
			Result.append (if has_python then "true" else "false" end)
			Result.append (",%"whisperx%":")
			Result.append (if has_whisperx then "true" else "false" end)
			Result.append (",%"hf_token%":")
			Result.append (if has_hf_token then "true" else "false" end)
			Result.append (",%"ready%":")
			Result.append (if is_available then "true" else "false" end)
			Result.append ("}")
		end


feature -- Configuration

	model: STRING_32
			-- Whisper model to use (tiny, base, small, medium, large-v2, large-v3).

	language: detachable STRING_32
			-- Language code (en, es, fr, etc.) or Void for auto-detect.

	device: STRING_32
			-- Compute device (cuda, cpu).

	compute_type: STRING_32
			-- Compute type (float16, int8, float32).

	min_speakers: INTEGER
			-- Minimum number of speakers (0 = auto).

	max_speakers: INTEGER
			-- Maximum number of speakers (0 = auto).

feature -- Configuration Commands

	set_model (a_model: READABLE_STRING_GENERAL)
			-- Set Whisper model.
		require
			valid_model: not a_model.is_empty
		do
			create model.make_from_string_general (a_model)
		ensure
			model_set: model.same_string_general (a_model)
		end

	set_language (a_lang: detachable READABLE_STRING_GENERAL)
			-- Set language or Void for auto-detect.
		do
			if attached a_lang as l then
				create language.make_from_string_general (l)
			else
				language := Void
			end
		end

	set_device (a_device: READABLE_STRING_GENERAL)
			-- Set compute device (cuda or cpu).
		require
			valid_device: a_device.same_string ("cuda") or a_device.same_string ("cpu")
		do
			create device.make_from_string_general (a_device)
		ensure
			device_set: device.same_string_general (a_device)
		end

	set_speaker_range (a_min, a_max: INTEGER)
			-- Set expected speaker count range.
		require
			valid_range: a_min >= 0 and (a_max = 0 or a_max >= a_min)
		do
			min_speakers := a_min
			max_speakers := a_max
		ensure
			min_set: min_speakers = a_min
			max_set: max_speakers = a_max
		end

feature -- Operations

	transcribe_with_diarization (a_audio_path: READABLE_STRING_GENERAL): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Transcribe audio with speaker diarization.
			-- Returns segments with speaker_id and speaker_label set.
		require
			available: is_available
			file_exists: file_exists (a_audio_path)
		local
			l_cmd: STRING_32
			l_output_dir, l_json_path: STRING_32
			l_proc: SIMPLE_PROCESS
			l_json_content: detachable STRING_32
		do
			create Result.make (50)
			create last_error.make_empty

			-- Create temp output directory
			l_output_dir := temp_directory

			-- Build whisperx command
			l_cmd := build_command (a_audio_path, l_output_dir)

			-- Execute whisperx
			create l_proc.make
			l_proc.execute (l_cmd)

			if not l_proc.was_successful then
				last_error := {STRING_32} "WhisperX failed: "
				if attached l_proc.last_error as err then
					last_error.append (err)
				else
					last_error.append ({STRING_32} "exit code " + l_proc.last_exit_code.out)
				end
			else
				-- Find and parse the JSON output
				l_json_path := find_json_output (l_output_dir, a_audio_path)
				if not l_json_path.is_empty and then file_exists (l_json_path) then
					l_json_content := read_file_content (l_json_path)
					if attached l_json_content as json then
						Result := parse_whisperx_json (json)
					else
						last_error := {STRING_32} "Failed to read WhisperX output"
					end
				else
					last_error := {STRING_32} "WhisperX output file not found"
				end
			end
		ensure
			result_exists: Result /= Void
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

	check_availability
			-- Check if WhisperX is available with detailed status.
		local
			l_proc: SIMPLE_PROCESS
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			
			-- Check Python (try 'py' first for Windows, then 'python')
			create l_proc.make
			l_proc.execute ({STRING_32} "py --version")
			has_python := l_proc.was_successful
			if not has_python then
				create l_proc.make
				l_proc.execute ({STRING_32} "python --version")
				has_python := l_proc.was_successful
			end
			
			-- Check whisperx package (use py -c or python -c)
			if has_python then
				create l_proc.make
				l_proc.execute ({STRING_32} "py -c %"import whisperx; print('ok')%"")
				has_whisperx := l_proc.was_successful
				if not has_whisperx then
					create l_proc.make
					l_proc.execute ({STRING_32} "python -c %"import whisperx; print('ok')%"")
					has_whisperx := l_proc.was_successful
				end
			else
				has_whisperx := False
			end
			
			-- Check HuggingFace token (check registry first on Windows, then env)
			has_hf_token := check_hf_token_available
			
			-- Overall availability
			is_available := has_python and has_whisperx and has_hf_token
			
			-- Build detailed error message
			if not is_available then
				create last_error.make (200)
				if not has_python then
					last_error.append ({STRING_32} "Python not found (tried py and python). ")
				elseif not has_whisperx then
					last_error.append ({STRING_32} "WhisperX not installed. Run: pip install whisperx. ")
				end
				if not has_hf_token then
					last_error.append ({STRING_32} "HF_TOKEN not set.")
				end
			end
		end

	build_command (a_audio: READABLE_STRING_GENERAL; a_output_dir: READABLE_STRING_GENERAL): STRING_32
			-- Build whisperx command line.
			-- Uses 'python -m whisperx' for better compatibility (works without Scripts in PATH)
		do
			create Result.make (300)
			Result.append ({STRING_32} "python -m whisperx %"")
			Result.append_string_general (a_audio)
			Result.append ({STRING_32} "%" --model ")
			Result.append (model)
			Result.append ({STRING_32} " --diarize")
			Result.append ({STRING_32} " --output_format json")
			Result.append ({STRING_32} " --output_dir %"")
			Result.append_string_general (a_output_dir)
			Result.append ({STRING_32} "%"")
			Result.append ({STRING_32} " --device ")
			Result.append (device)
			Result.append ({STRING_32} " --compute_type ")
			Result.append (compute_type)

			if attached language as lang then
				Result.append ({STRING_32} " --language ")
				Result.append (lang)
			end

			if min_speakers > 0 then
				Result.append ({STRING_32} " --min_speakers ")
				Result.append_integer (min_speakers)
			end
			if max_speakers > 0 then
				Result.append ({STRING_32} " --max_speakers ")
				Result.append_integer (max_speakers)
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	parse_whisperx_json (a_json: STRING_32): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Parse WhisperX JSON output into segments.
			-- WhisperX JSON format:
			-- { "segments": [{ "start": 0.0, "end": 1.5, "text": "...", "speaker": "SPEAKER_00" }, ...] }
		local
			l_parser: SIMPLE_JSON
			l_parsed: detachable SIMPLE_JSON_VALUE
			l_obj: detachable SIMPLE_JSON_OBJECT
			l_segments: detachable SIMPLE_JSON_ARRAY
			l_seg_obj: detachable SIMPLE_JSON_OBJECT
			l_start, l_end: REAL_64
			l_text, l_speaker: detachable STRING_32
			l_speaker_id: INTEGER
			l_segment: SPEECH_SEGMENT
			i: INTEGER
		do
			create Result.make (50)
			create l_parser

			l_parsed := l_parser.parse (a_json)
			if attached l_parsed then
				l_obj := l_parsed.as_object
			end
			if attached l_obj then
				l_segments := l_obj.array_item ("segments")
				if attached l_segments then
					from i := 1 until i > l_segments.count loop
						l_seg_obj := l_segments.object_item (i)
						if attached l_seg_obj then
							l_start := l_seg_obj.real_item ("start")
							l_end := l_seg_obj.real_item ("end")
							l_text := l_seg_obj.string_item ("text")
							l_speaker := l_seg_obj.string_item ("speaker")

							if attached l_text as txt and then not txt.is_empty then
								if attached l_speaker as spk then
									-- Extract speaker ID from "SPEAKER_00" format
									l_speaker_id := extract_speaker_id (spk)
									create l_segment.make_with_speaker (txt, l_start, l_end, l_speaker_id, spk)
								else
									-- No speaker info, just create basic segment
									create l_segment.make (txt, l_start, l_end)
								end
								Result.extend (l_segment)
							end
						end
						i := i + 1
					end
				else
					last_error := {STRING_32} "No segments found in WhisperX output"
				end
			else
				last_error := {STRING_32} "Failed to parse WhisperX JSON"
			end
		ensure
			result_exists: Result /= Void
		end

	extract_speaker_id (a_speaker_label: STRING_32): INTEGER
			-- Extract numeric ID from speaker label like "SPEAKER_00".
		local
			l_pos: INTEGER
			l_num: STRING_32
		do
			l_pos := a_speaker_label.last_index_of ('_', a_speaker_label.count)
			if l_pos > 0 and l_pos < a_speaker_label.count then
				l_num := a_speaker_label.substring (l_pos + 1, a_speaker_label.count)
				if l_num.is_integer then
					Result := l_num.to_integer + 1  -- Convert 0-based to 1-based
				else
					Result := 1
				end
			else
				Result := 1
			end
		ensure
			positive: Result >= 1
		end

	find_json_output (a_dir, a_audio: READABLE_STRING_GENERAL): STRING_32
			-- Find the JSON output file from WhisperX.
		local
			l_base: STRING_32
		do
			-- WhisperX names output as {basename}.json
			l_base := extract_basename (a_audio.to_string_32)
			create Result.make (100)
			Result.append_string_general (a_dir)
			Result.append ({STRING_32} "\")
			Result.append (l_base)
			Result.append ({STRING_32} ".json")
		ensure
			result_not_empty: not Result.is_empty
		end

	extract_basename (a_path: STRING_32): STRING_32
			-- Extract filename without extension.
		local
			l_sep, l_dot: INTEGER
		do
			l_sep := a_path.last_index_of ('\', a_path.count)
			if l_sep = 0 then
				l_sep := a_path.last_index_of ('/', a_path.count)
			end
			if l_sep > 0 then
				Result := a_path.substring (l_sep + 1, a_path.count)
			else
				Result := a_path.twin
			end
			l_dot := Result.last_index_of ('.', Result.count)
			if l_dot > 1 then
				Result := Result.substring (1, l_dot - 1)
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	temp_directory: STRING_32
			-- Get or create temp directory for output.
		local
			l_env: EXECUTION_ENVIRONMENT
			l_dir: DIRECTORY
		do
			create l_env
			if attached l_env.item ("TEMP") as tmp then
				create Result.make (50)
				Result.append (tmp.to_string_32)
				Result.append ({STRING_32} "\whisperx_output")
			else
				Result := {STRING_32} "C:\Temp\whisperx_output"
			end
			create l_dir.make (Result)
			if not l_dir.exists then
				l_dir.recursive_create_dir
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	check_hf_token_available: BOOLEAN
			-- Check if HF_TOKEN is available (registry or environment).
		local
			l_env: EXECUTION_ENVIRONMENT
			l_proc: SIMPLE_PROCESS
		do
			-- First try process environment
			create l_env
			if attached l_env.item ("HF_TOKEN") as tok and then not tok.is_empty then
				Result := True
			else
				-- On Windows, check registry for user environment variables
				-- This catches variables set via System Properties that haven't propagated yet
				create l_proc.make
				l_proc.execute ({STRING_32} "python -c %"import winreg; k=winreg.OpenKey(winreg.HKEY_CURRENT_USER,'Environment'); v,_=winreg.QueryValueEx(k,'HF_TOKEN'); print('OK' if v else '')%"")
				Result := l_proc.was_successful and then attached l_proc.last_output as l_out and then l_out.has_substring ("OK")
			end
		end

	read_file_content (a_path: READABLE_STRING_GENERAL): detachable STRING_32
			-- Read file contents as STRING_32.
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_8
		do
			create l_file.make_with_name (a_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				create l_content.make (l_file.count)
				l_file.read_stream (l_file.count)
				l_content := l_file.last_string
				l_file.close
				create Result.make_from_string (l_content)
			end
		end

end
