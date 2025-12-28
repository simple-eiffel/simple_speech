note
	description: "[
		SPEECH_CHAPTERED_RESULT - Container for segments with detected chapters.
		
		Combines the original transcription segments with detected chapter
		boundaries. Provides export functionality for chaptered VTT and JSON.
	]"
	author: "Larry Rix"

class
	SPEECH_CHAPTERED_RESULT

create
	make

feature {NONE} -- Initialization

	make (a_segments: LIST [SPEECH_SEGMENT]; a_chapters: LIST [SPEECH_CHAPTER])
			-- Create result with segments and chapters.
		require
			segments_attached: a_segments /= Void
			chapters_attached: a_chapters /= Void
		do
			create segments.make (a_segments.count)
			across a_segments as s loop
				segments.extend (s)
			end
			create chapters.make (a_chapters.count)
			across a_chapters as c loop
				chapters.extend (c)
			end
		ensure
			segments_copied: segments.count = a_segments.count
			chapters_copied: chapters.count = a_chapters.count
		end

feature -- Access

	segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Original transcription segments.

	chapters: ARRAYED_LIST [SPEECH_CHAPTER]
			-- Detected chapter boundaries.

feature -- Status

	has_chapters: BOOLEAN
			-- Are there any chapters?
		do
			Result := not chapters.is_empty
		end

	chapter_count: INTEGER
			-- Number of chapters.
		do
			Result := chapters.count
		end

	segment_count: INTEGER
			-- Number of segments.
		do
			Result := segments.count
		end

	total_duration: REAL_64
			-- Total duration in seconds.
		do
			if not segments.is_empty then
				Result := segments.last.end_time - segments.first.start_time
			end
		end

feature -- Query

	get_chapter_for_time (a_seconds: REAL_64): detachable SPEECH_CHAPTER
			-- Get chapter containing the given time.
		do
			across chapters as ch loop
				if a_seconds >= ch.start_time and a_seconds < ch.end_time then
					Result := ch
				end
			end
		end

	get_chapter_index_for_time (a_seconds: REAL_64): INTEGER
			-- Get 1-based chapter index for time, 0 if not found.
		local
			l_index: INTEGER
		do
			l_index := 0
			across chapters as ch loop
				l_index := l_index + 1
				if a_seconds >= ch.start_time and a_seconds < ch.end_time then
					Result := l_index
				end
			end
		end

	segments_in_chapter (a_chapter: SPEECH_CHAPTER): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Get segments within a chapter.
		do
			create Result.make (20)
			across segments as seg loop
				if seg.start_time >= a_chapter.start_time and
				   seg.end_time <= a_chapter.end_time then
					Result.extend (seg)
				end
			end
		end

feature -- Export

	export_chapters_vtt (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Export chapters as VTT with chapter markers.
		local
			l_file: PLAIN_TEXT_FILE
			l_index: INTEGER
		do
			create l_file.make_create_read_write (a_path.to_string_8)
			if l_file.is_open_write then
				l_file.put_string ("WEBVTT%N%N")
				
				l_index := 0
				across chapters as ch loop
					l_index := l_index + 1
					l_file.put_string ("NOTE Chapter " + l_index.out + ": " + ch.title.to_string_8 + "%N")
					l_file.put_string (format_vtt_time (ch.start_time) + " --> " + format_vtt_time (ch.end_time) + "%N")
					l_file.put_string (ch.title.to_string_8 + "%N%N")
				end
				
				l_file.close
				Result := True
			end
		end

	export_chapters_json (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Export chapters as JSON.
		local
			l_file: PLAIN_TEXT_FILE
			l_index: INTEGER
			l_chapter: SPEECH_CHAPTER
		do
			create l_file.make_create_read_write (a_path.to_string_8)
			if l_file.is_open_write then
				l_file.put_string ("{%N")
				l_file.put_string ("  %"chapters%": [%N")
				
				l_index := 0
				across chapters as ch loop
					l_index := l_index + 1
					l_chapter := ch
					if l_index > 1 then
						l_file.put_string (",%N")
					end
					l_file.put_string ("    {%N")
					l_file.put_string ("      %"index%": " + l_index.out + ",%N")
					l_file.put_string ("      %"title%": %"" + escape_json (l_chapter.title) + "%",%N")
					l_file.put_string ("      %"start_time%": " + l_chapter.start_time.out + ",%N")
					l_file.put_string ("      %"end_time%": " + l_chapter.end_time.out + ",%N")
					l_file.put_string ("      %"formatted_start%": %"" + l_chapter.formatted_start + "%",%N")
					l_file.put_string ("      %"formatted_end%": %"" + l_chapter.formatted_end + "%",%N")
					l_file.put_string ("      %"confidence%": " + l_chapter.confidence.out + ",%N")
					l_file.put_string ("      %"transition_type%": %"" + l_chapter.transition_type + "%"%N")
					l_file.put_string ("    }")
				end
				
				l_file.put_string ("%N  ],%N")
				l_file.put_string ("  %"total_chapters%": " + chapters.count.out + ",%N")
				l_file.put_string ("  %"total_duration%": " + total_duration.out + "%N")
				l_file.put_string ("}%N")
				
				l_file.close
				Result := True
			end
		end

	export_full_vtt (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Export full VTT with segments and chapter notes.
		local
			l_file: PLAIN_TEXT_FILE
			l_index, l_chapter_idx: INTEGER
			l_current_chapter: detachable SPEECH_CHAPTER
		do
			create l_file.make_create_read_write (a_path.to_string_8)
			if l_file.is_open_write then
				l_file.put_string ("WEBVTT%N%N")
				
				l_chapter_idx := 0
				l_index := 0
				across segments as seg loop
					l_index := l_index + 1
					
					-- Check if new chapter starts
					if attached get_chapter_for_time (seg.start_time) as ch then
						if l_current_chapter /= ch then
							l_current_chapter := ch
							l_chapter_idx := l_chapter_idx + 1
							l_file.put_string ("NOTE Chapter " + l_chapter_idx.out + ": " + ch.title.to_string_8 + "%N%N")
						end
					end
					
					l_file.put_string (l_index.out + "%N")
					l_file.put_string (format_vtt_time (seg.start_time) + " --> " + format_vtt_time (seg.end_time) + "%N")
					l_file.put_string (seg.text.to_string_8 + "%N%N")
				end
				
				l_file.close
				Result := True
			end
		end

feature {NONE} -- Implementation

	format_vtt_time (a_seconds: REAL_64): STRING_8
			-- Format seconds as HH:MM:SS.mmm for VTT.
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

	escape_json (a_string: STRING_32): STRING_8
			-- Escape string for JSON.
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_string.count)
			from i := 1 until i > a_string.count loop
				c := a_string.item (i)
				if c = '"' then
					Result.append_string ("\%"")
				elseif c = '\' then
					Result.append_string ("\\")
				elseif c = '%N' then
					Result.append_string ("\n")
				elseif c = '%R' then
					Result.append_string ("\r")
				elseif c = '%T' then
					Result.append_string ("\t")
				elseif c.natural_32_code < 128 then
					Result.append_character (c.to_character_8)
				else
					Result.append_character ('?')
				end
				i := i + 1
			end
		end

invariant
	segments_attached: segments /= Void
	chapters_attached: chapters /= Void

end
