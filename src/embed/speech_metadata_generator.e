note
	description: "[
		SPEECH_METADATA_GENERATOR - Generate FFmpeg metadata files.
		
		Creates FFMETADATA format files for chapter embedding and
		generates subtitle formats suitable for container embedding.
	]"
	author: "Larry Rix"

class
	SPEECH_METADATA_GENERATOR

create
	make

feature {NONE} -- Initialization

	make
			-- Create metadata generator.
		do
			-- Ready to generate
		end

feature -- FFMETADATA Generation

	generate_ffmetadata (chapters: LIST [SPEECH_CHAPTER]): STRING_8
			-- Generate FFMETADATA content for chapters.
			-- Format: https://ffmpeg.org/ffmpeg-formats.html#Metadata-1
		local
			l_start_ms, l_end_ms: INTEGER_64
		do
			create Result.make (1000)
			Result.append (";FFMETADATA1%N")
			
			across chapters as ch loop
				l_start_ms := (ch.start_time * 1000).truncated_to_integer.to_integer_64
				l_end_ms := (ch.end_time * 1000).truncated_to_integer.to_integer_64
				
				Result.append ("[CHAPTER]%N")
				Result.append ("TIMEBASE=1/1000%N")
				Result.append ("START=" + l_start_ms.out + "%N")
				Result.append ("END=" + l_end_ms.out + "%N")
				Result.append ("title=" + escape_metadata_value (ch.title.to_string_8) + "%N")
				Result.append ("%N")
			end
		ensure
			result_attached: Result /= Void
		end

	write_ffmetadata (chapters: LIST [SPEECH_CHAPTER]; a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Write FFMETADATA file to path.
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_8
		do
			l_content := generate_ffmetadata (chapters)
			create l_file.make_create_read_write (a_path.to_string_8)
			if l_file.is_open_write then
				l_file.put_string (l_content)
				l_file.close
				Result := True
			end
		end

feature -- SRT Generation (for embedding)

	generate_srt (segments: LIST [SPEECH_SEGMENT]): STRING_8
			-- Generate SRT subtitle content.
		local
			l_index: INTEGER
		do
			create Result.make (5000)
			l_index := 0
			
			across segments as seg loop
				l_index := l_index + 1
				Result.append (l_index.out + "%N")
				Result.append (format_srt_time (seg.start_time))
				Result.append (" --> ")
				Result.append (format_srt_time (seg.end_time))
				Result.append ("%N")
				Result.append (seg.text.to_string_8)
				Result.append ("%N%N")
			end
		ensure
			result_attached: Result /= Void
		end

	write_srt (segments: LIST [SPEECH_SEGMENT]; a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Write SRT file to path.
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_8
		do
			l_content := generate_srt (segments)
			create l_file.make_create_read_write (a_path.to_string_8)
			if l_file.is_open_write then
				l_file.put_string (l_content)
				l_file.close
				Result := True
			end
		end

feature -- VTT Generation (for WebM embedding)

	generate_vtt (segments: LIST [SPEECH_SEGMENT]): STRING_8
			-- Generate WebVTT subtitle content.
		do
			create Result.make (5000)
			Result.append ("WEBVTT%N%N")
			
			across segments as seg loop
				Result.append (format_vtt_time (seg.start_time))
				Result.append (" --> ")
				Result.append (format_vtt_time (seg.end_time))
				Result.append ("%N")
				Result.append (seg.text.to_string_8)
				Result.append ("%N%N")
			end
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Implementation

	format_srt_time (a_seconds: REAL_64): STRING_8
			-- Format as HH:MM:SS,mmm (SRT uses comma).
		local
			l_total_ms: INTEGER
			l_hours, l_mins, l_secs, l_ms: INTEGER
		do
			l_total_ms := (a_seconds * 1000).truncated_to_integer
			l_hours := l_total_ms // 3600000
			l_mins := (l_total_ms - (l_hours * 3600000)) // 60000
			l_secs := (l_total_ms - (l_hours * 3600000) - (l_mins * 60000)) // 1000
			l_ms := l_total_ms - (l_hours * 3600000) - (l_mins * 60000) - (l_secs * 1000)
			
			create Result.make (12)
			if l_hours < 10 then Result.append_character ('0') end
			Result.append_integer (l_hours)
			Result.append_character (':')
			if l_mins < 10 then Result.append_character ('0') end
			Result.append_integer (l_mins)
			Result.append_character (':')
			if l_secs < 10 then Result.append_character ('0') end
			Result.append_integer (l_secs)
			Result.append_character (',')
			if l_ms < 100 then Result.append_character ('0') end
			if l_ms < 10 then Result.append_character ('0') end
			Result.append_integer (l_ms)
		end

	format_vtt_time (a_seconds: REAL_64): STRING_8
			-- Format as HH:MM:SS.mmm (VTT uses period).
		local
			l_total_ms: INTEGER
			l_hours, l_mins, l_secs, l_ms: INTEGER
		do
			l_total_ms := (a_seconds * 1000).truncated_to_integer
			l_hours := l_total_ms // 3600000
			l_mins := (l_total_ms - (l_hours * 3600000)) // 60000
			l_secs := (l_total_ms - (l_hours * 3600000) - (l_mins * 60000)) // 1000
			l_ms := l_total_ms - (l_hours * 3600000) - (l_mins * 60000) - (l_secs * 1000)
			
			create Result.make (12)
			if l_hours < 10 then Result.append_character ('0') end
			Result.append_integer (l_hours)
			Result.append_character (':')
			if l_mins < 10 then Result.append_character ('0') end
			Result.append_integer (l_mins)
			Result.append_character (':')
			if l_secs < 10 then Result.append_character ('0') end
			Result.append_integer (l_secs)
			Result.append_character ('.')
			if l_ms < 100 then Result.append_character ('0') end
			if l_ms < 10 then Result.append_character ('0') end
			Result.append_integer (l_ms)
		end

	escape_metadata_value (a_value: STRING_8): STRING_8
			-- Escape special characters for FFMETADATA.
		local
			i: INTEGER
			c: CHARACTER_8
		do
			create Result.make (a_value.count)
			from i := 1 until i > a_value.count loop
				c := a_value.item (i)
				if c = '=' or c = ';' or c = '#' or c = '\' or c = '%N' then
					Result.append_character ('\')
				end
				Result.append_character (c)
				i := i + 1
			end
		end

end
