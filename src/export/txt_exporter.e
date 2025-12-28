note
	description: "[
		TXT_EXPORTER - Export speech segments to plain text format.
		
		Simple text output with optional timestamps.
		Plain mode: Just the transcript text
		Timestamped mode: [HH:MM:SS] text
	]"
	author: "Larry Rix"

class
	TXT_EXPORTER

create
	make

feature {NONE} -- Initialization

	make
			-- Create exporter.
		do
			create segments.make (0)
			include_timestamps := False
		end

feature -- Access

	segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Segments to export.

	include_timestamps: BOOLEAN
			-- Include timestamps in output?

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

	set_timestamps (a_include: BOOLEAN): like Current
			-- Enable/disable timestamp output.
		do
			include_timestamps := a_include
			Result := Current
		ensure
			timestamps_set: include_timestamps = a_include
			result_is_current: Result = Current
		end

feature -- Operations

	export_to_file (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Export segments to TXT file.
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
			-- Generate text content as string.
		local
			i: INTEGER
		do
			create Result.make (1024)
			
			from i := 1 until i > segments.count loop
				if include_timestamps then
					Result.append ("[" + format_time (segments[i].start_time) + "] ")
				end
				Result.append (segments[i].text.to_string_8)
				if i < segments.count then
					if include_timestamps then
						Result.append ("%N")
					else
						-- In plain mode, join with space
						Result.append (" ")
					end
				end
				i := i + 1
			end
			Result.append ("%N")
		end

feature {NONE} -- Implementation

	format_time (a_seconds: REAL_64): STRING_8
			-- Format time as HH:MM:SS.
		local
			h, m, s, total_s: INTEGER
		do
			total_s := a_seconds.truncated_to_integer
			s := total_s \\ 60
			m := (total_s // 60) \\ 60
			h := total_s // 3600

			create Result.make (8)
			if h < 10 then Result.append ("0") end
			Result.append_integer (h)
			Result.append (":")
			if m < 10 then Result.append ("0") end
			Result.append_integer (m)
			Result.append (":")
			if s < 10 then Result.append ("0") end
			Result.append_integer (s)
		end

end
