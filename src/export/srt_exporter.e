note
	description: "[
		SRT_EXPORTER - Export speech segments to SubRip (SRT) format.

		SRT is a widely supported subtitle format.
		Format:
			1
			00:00:00,000 --> 00:00:01,000
			First caption text

			2
			00:00:01,000 --> 00:00:03,000
			Second caption text

		CQS Pattern:
		- Command: set_segments
		- Fluent: with_segments, from_segments (alias)
	]"
	author: "Larry Rix"

class
	SRT_EXPORTER

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

feature -- Configuration Commands

	set_segments (a_segments: like segments)
			-- Set segments to export.
		do
			segments := a_segments
		ensure
			segments_set: segments = a_segments
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

feature -- Operations

	export_to_file (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Export segments to SRT file.
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
			-- Generate SRT content as string.
		local
			i: INTEGER
		do
			create Result.make (1024)

			-- Each segment as a numbered subtitle
			from i := 1 until i > segments.count loop
				Result.append (format_subtitle (i, segments[i]))
				if i < segments.count then
					Result.append ("%N")
				end
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	format_subtitle (a_number: INTEGER; a_segment: SPEECH_SEGMENT): STRING_8
			-- Format a single SRT subtitle entry.
			-- If speaker info available, prefixes text with [SPEAKER_N].
		do
			create Result.make (128)
			-- Sequence number
			Result.append_integer (a_number)
			Result.append ("%N")
			-- Timestamp line
			Result.append (format_time (a_segment.start_time))
			Result.append (" --> ")
			Result.append (format_time (a_segment.end_time))
			Result.append ("%N")
			-- Speaker label (if available)
			if a_segment.has_speaker then
				Result.append ("[")
				Result.append (a_segment.speaker_label_or_default.to_string_8)
				Result.append ("] ")
			end
			-- Text
			Result.append (a_segment.text.to_string_8)
			Result.append ("%N")
		end

	format_time (a_seconds: REAL_64): STRING_8
			-- Format time as HH:MM:SS,mmm (SRT format with comma).
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
			Result.append (",")  -- SRT uses comma, not period
			if ms < 100 then Result.append ("0") end
			if ms < 10 then Result.append ("0") end
			Result.append_integer (ms)
		end

end
