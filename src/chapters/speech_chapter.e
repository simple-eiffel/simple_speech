note
	description: "[
		SPEECH_CHAPTER - Represents a detected chapter/topic boundary.
		
		Contains timing information, title, optional summary, confidence score,
		and transition type classification.
	]"
	author: "Larry Rix"

class
	SPEECH_CHAPTER

create
	make,
	make_with_title

feature {NONE} -- Initialization

	make (a_start, a_end: REAL_64)
			-- Create chapter with timing.
		require
			valid_timing: a_start >= 0 and a_end >= a_start
		do
			start_time := a_start
			end_time := a_end
			title := "Chapter"
			transition_type := "topic_shift"
			confidence := 0.5
			create keywords.make (5)
			create localized_titles.make (5)
		ensure
			start_set: start_time = a_start
			end_set: end_time = a_end
		end

	make_with_title (a_start, a_end: REAL_64; a_title: READABLE_STRING_GENERAL)
			-- Create chapter with timing and title.
		require
			valid_timing: a_start >= 0 and a_end >= a_start
			title_not_empty: not a_title.is_empty
		do
			start_time := a_start
			end_time := a_end
			title := a_title.to_string_32
			transition_type := "topic_shift"
			confidence := 0.5
			create keywords.make (5)
			create localized_titles.make (5)
		ensure
			start_set: start_time = a_start
			end_set: end_time = a_end
			title_set: title.same_string_general (a_title)
		end

feature -- Access

	start_time: REAL_64
			-- Start time in seconds.

	end_time: REAL_64
			-- End time in seconds.

	title: STRING_32
			-- Chapter title (auto-generated or AI-enhanced).

	summary: detachable STRING_32
			-- Optional chapter summary (AI-only).

	confidence: REAL_64
			-- Detection confidence (0.0 to 1.0).

	transition_type: STRING_8
			-- Type: "explicit", "temporal", "spatial", "topic_shift", "sequence"

	keywords: ARRAYED_LIST [STRING_32]
			-- Keywords extracted from chapter content.

	localized_titles: STRING_TABLE [STRING_32]
			-- Titles in different languages (key = lang code, value = title).

feature -- Status

	duration: REAL_64
			-- Duration in seconds.
		do
			Result := end_time - start_time
		ensure
			non_negative: Result >= 0
		end

	has_summary: BOOLEAN
			-- Does this chapter have a summary?
		do
			Result := attached summary
		end

	has_keywords: BOOLEAN
			-- Does this chapter have keywords?
		do
			Result := not keywords.is_empty
		end

	formatted_start: STRING_8
			-- Start time as HH:MM:SS.
		do
			Result := format_time (start_time)
		end

	formatted_end: STRING_8
			-- End time as HH:MM:SS.
		do
			Result := format_time (end_time)
		end

	formatted_duration: STRING_8
			-- Duration as HH:MM:SS.
		do
			Result := format_time (duration)
		end

feature -- Element change

	set_title (a_title: READABLE_STRING_GENERAL)
			-- Set chapter title.
		require
			not_empty: not a_title.is_empty
		do
			title := a_title.to_string_32
		ensure
			title_set: title.same_string_general (a_title)
		end

	set_summary (a_summary: READABLE_STRING_GENERAL)
			-- Set chapter summary.
		do
			summary := a_summary.to_string_32
		ensure
			summary_set: attached summary as s and then s.same_string_general (a_summary)
		end

	set_confidence (a_confidence: REAL_64)
			-- Set detection confidence.
		require
			valid_range: a_confidence >= 0.0 and a_confidence <= 1.0
		do
			confidence := a_confidence
		ensure
			confidence_set: confidence = a_confidence
		end

	set_transition_type (a_type: STRING_8)
			-- Set transition type.
		require
			valid_type: a_type.same_string ("explicit") or
			            a_type.same_string ("temporal") or
			            a_type.same_string ("spatial") or
			            a_type.same_string ("topic_shift") or
			            a_type.same_string ("sequence")
		do
			transition_type := a_type
		ensure
			type_set: transition_type.same_string (a_type)
		end

	add_keyword (a_keyword: READABLE_STRING_GENERAL)
			-- Add a keyword.
		require
			not_empty: not a_keyword.is_empty
		do
			keywords.extend (a_keyword.to_string_32)
		ensure
			added: keywords.has (a_keyword.to_string_32)
		end

	set_localized_title (a_language: READABLE_STRING_GENERAL; a_title: READABLE_STRING_GENERAL)
			-- Set title for specific language.
		require
			language_not_empty: not a_language.is_empty
			title_not_empty: not a_title.is_empty
		do
			localized_titles.force (a_title.to_string_32, a_language.to_string_32)
		ensure
			title_set: attached localized_titles.item (a_language.to_string_32) as t and then t.same_string_general (a_title)
		end

	get_localized_title (a_language: READABLE_STRING_GENERAL): STRING_32
			-- Get title for language, falling back to default title.
		do
			if attached localized_titles.item (a_language.to_string_32) as t then
				Result := t
			else
				Result := title
			end
		end

feature {NONE} -- Implementation

	format_time (a_seconds: REAL_64): STRING_8
			-- Format seconds as HH:MM:SS.
		local
			l_total, l_hours, l_mins, l_secs: INTEGER
		do
			l_total := a_seconds.truncated_to_integer
			l_hours := l_total // 3600
			l_mins := (l_total - (l_hours * 3600)) // 60
			l_secs := l_total - (l_hours * 3600) - (l_mins * 60)
			create Result.make (10)
			if l_hours < 10 then Result.append_character ('0') end
			Result.append_integer (l_hours)
			Result.append_character (':')
			if l_mins < 10 then Result.append_character ('0') end
			Result.append_integer (l_mins)
			Result.append_character (':')
			if l_secs < 10 then Result.append_character ('0') end
			Result.append_integer (l_secs)
		end

invariant
	valid_timing: start_time >= 0 and end_time >= start_time
	title_attached: title /= Void
	transition_type_attached: transition_type /= Void
	valid_confidence: confidence >= 0.0 and confidence <= 1.0
	keywords_attached: keywords /= Void
	localized_titles_attached: localized_titles /= Void

end