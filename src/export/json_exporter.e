note
	description: "[
		JSON_EXPORTER - Export speech segments to JSON format.
		
		Output format:
		{
			"segments": [
				{
					"start": 0.0,
					"end": 1.0,
					"text": "First caption"
				},
				...
			],
			"duration": 30.5,
			"segment_count": 21
		}
	]"
	author: "Larry Rix"

class
	JSON_EXPORTER

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

feature -- Configuration

	from_segments (a_segments: like segments): like Current
			-- Set segments to export.
		do
			segments := a_segments
			Result := Current
		ensure
			segments_set: segments = a_segments
			result_is_current: Result = Current
		end

feature -- Operations

	export_to_file (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Export segments to JSON file.
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
			-- Generate JSON content as string.
		local
			i: INTEGER
			l_duration: REAL_64
		do
			create Result.make (2048)
			
			-- Calculate total duration
			if segments.count > 0 then
				l_duration := segments[segments.count].end_time
			end
			
			Result.append ("{%N")
			Result.append ("  %"segments%": [%N")
			
			from i := 1 until i > segments.count loop
				Result.append (format_segment (segments[i]))
				if i < segments.count then
					Result.append (",%N")
				else
					Result.append ("%N")
				end
				i := i + 1
			end
			
			Result.append ("  ],%N")
			Result.append ("  %"duration%": " + l_duration.out + ",%N")
			Result.append ("  %"segment_count%": " + segments.count.out + "%N")
			Result.append ("}%N")
		end

feature {NONE} -- Implementation

	format_segment (a_segment: SPEECH_SEGMENT): STRING_8
			-- Format a single segment as JSON object.
		local
			l_text: STRING_8
		do
			create Result.make (256)
			l_text := escape_json (a_segment.text.to_string_8)
			
			Result.append ("    {%N")
			Result.append ("      %"start%": " + a_segment.start_time.out + ",%N")
			Result.append ("      %"end%": " + a_segment.end_time.out + ",%N")
			Result.append ("      %"text%": %"" + l_text + "%"%N")
			Result.append ("    }")
		end

	escape_json (a_string: STRING_8): STRING_8
			-- Escape special characters for JSON.
		local
			i: INTEGER
			c: CHARACTER_8
		do
			create Result.make (a_string.count)
			from i := 1 until i > a_string.count loop
				c := a_string[i]
				inspect c
				when '"' then Result.append ("\%"")
				when '\' then Result.append ("\\")
				when '%N' then Result.append ("\n")
				when '%R' then Result.append ("\r")
				when '%T' then Result.append ("\t")
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

end
