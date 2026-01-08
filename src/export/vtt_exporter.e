note
	description: "[
		VTT_EXPORTER - Export speech segments to WebVTT format.

		WebVTT (Web Video Text Tracks) is a W3C standard for video captions.

		CQS Pattern:
		- Command: set_segments
		- Fluent: with_segments, from_segments (alias)
	]"
	author: "Larry Rix"

class
	VTT_EXPORTER

create
	make

feature {NONE} -- Initialization

	make
			-- Create exporter.
		do
			create segments.make (0)
		end

feature -- Access

	segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Segments to export.

	last_error: detachable STRING_32
			-- Last error message.

	ai_provider: detachable STRING_8
			-- AI provider used for transcription (e.g., "claude", "ollama", "google").

	ai_model: detachable STRING_8
			-- AI model name (e.g., "claude-sonnet-4-20250514", "llama3.2:latest").

feature -- Configuration Commands

	set_segments (a_segments: like segments)
			-- Set segments to export.
		do
			segments := a_segments
		ensure
			segments_set: segments = a_segments
		end

	set_ai_source (a_provider: STRING_8; a_model: STRING_8)
			-- Set AI provider and model used for transcription.
		require
			provider_not_empty: not a_provider.is_empty
		do
			ai_provider := a_provider
			ai_model := a_model
		ensure
			provider_set: ai_provider ~ a_provider
			model_set: ai_model ~ a_model
		end

feature -- Configuration Fluent

	from_segments,
	with_segments (a_segments: like segments): like Current
			-- Fluent: set segments and return Current.
		do
			set_segments (a_segments)
			Result := Current
		ensure
			segments_set: segments = a_segments
			result_is_current: Result = Current
		end

	with_ai_source (a_provider: STRING_8; a_model: STRING_8): like Current
			-- Fluent: set AI source and return Current.
		require
			provider_not_empty: not a_provider.is_empty
		do
			set_ai_source (a_provider, a_model)
			Result := Current
		ensure
			provider_set: ai_provider ~ a_provider
			result_is_current: Result = Current
		end

feature -- Operations

	export_to_file (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Export segments to VTT file.
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_8
		do
			l_content := to_string
			create l_file.make_with_name (a_path.to_string_8)
			l_file.open_write
			l_file.put_string (l_content)
			l_file.close
			Result := True
		rescue
			last_error := {STRING_32} "Failed to write file: " + a_path.to_string_32
			Result := False
		end

	to_string: STRING_8
			-- Generate VTT content as string.
			-- Includes AI source NOTE comment if ai_provider is set.
		local
			i: INTEGER
			l_date: DATE_TIME
		do
			create Result.make (1024)

			-- WebVTT header
			Result.append ("WEBVTT%N")

			-- AI source metadata (NOTE comments after header)
			if attached ai_provider as l_provider then
				Result.append ("NOTE AI-Source: ")
				Result.append (l_provider)
				if attached ai_model as l_model and then not l_model.is_empty then
					Result.append (" (")
					Result.append (l_model)
					Result.append (")")
				end
				Result.append ("%N")
				create l_date.make_now
				Result.append ("NOTE Processed: ")
				Result.append (l_date.formatted_out ("yyyy-[0]mm-[0]dd [0]hh:[0]mi:[0]ss"))
			end
			Result.append ("%N%N")

			-- Each segment as a cue
			from i := 1 until i > segments.count loop
				Result.append (format_cue (segments[i]))
				if i < segments.count then
					Result.append ("%N")
				end
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	format_cue (a_segment: SPEECH_SEGMENT): STRING_8
			-- Format a single VTT cue.
		do
			create Result.make (128)
			Result.append (format_time (a_segment.start_time))
			Result.append (" --> ")
			Result.append (format_time (a_segment.end_time))
			Result.append ("%N")
			Result.append (a_segment.text.to_string_8)
			Result.append ("%N")
		end

	format_time (a_seconds: REAL_64): STRING_8
			-- Format time as HH:MM:SS.mmm (VTT format).
		local
			h, m, s, ms: INTEGER
			total_ms: INTEGER_64
		do
			total_ms := (a_seconds * 1000).truncated_to_integer_64
			ms := (total_ms \\ 1000).to_integer_32
			s := ((total_ms // 1000) \\ 60).to_integer_32
			m := ((total_ms // 60000) \\ 60).to_integer_32
			h := (total_ms // 3600000).to_integer_32

			create Result.make (12)
			if h < 10 then Result.append ("0") end
			Result.append_integer (h)
			Result.append (":")
			if m < 10 then Result.append ("0") end
			Result.append_integer (m)
			Result.append (":")
			if s < 10 then Result.append ("0") end
			Result.append_integer (s)
			Result.append (".")
			if ms < 100 then Result.append ("0") end
			if ms < 10 then Result.append ("0") end
			Result.append_integer (ms)
		end

end
