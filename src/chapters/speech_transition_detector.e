note
	description: "[
		SPEECH_TRANSITION_DETECTOR - Algorithmic detection of topic/scene transitions.

		Analyzes speech segments to detect topic changes, scene transitions,
		and structural boundaries WITHOUT using AI. Uses phrase patterns,
		temporal gaps, and vocabulary shift analysis.

		CQS Pattern:
		- Commands: set_sensitivity, set_min_chapter_duration, set_min_gap_seconds
		- Fluent: with_sensitivity, with_min_chapter_duration, with_min_gap_seconds
	]"
	author: "Larry Rix"

class
	SPEECH_TRANSITION_DETECTOR

create
	make

feature {NONE} -- Initialization

	make
			-- Create detector with default settings.
		do
			sensitivity := Sensitivity_medium
			min_chapter_duration := 30.0
			min_gap_seconds := 3.0
			create transition_patterns.make (50)
			initialize_patterns
		end

feature -- Access

	sensitivity: INTEGER

	min_chapter_duration: REAL_64

	min_gap_seconds: REAL_64

feature -- Constants

	Sensitivity_low: INTEGER = 1
	Sensitivity_medium: INTEGER = 2
	Sensitivity_high: INTEGER = 3

	Weight_high: REAL_64 = 1.0
	Weight_medium: REAL_64 = 0.6
	Weight_low: REAL_64 = 0.3

feature -- Configuration Commands

	set_sensitivity (a_level: INTEGER)
			-- Set detection sensitivity level.
		require
			valid_level: a_level >= Sensitivity_low and a_level <= Sensitivity_high
		do
			sensitivity := a_level
		ensure
			sensitivity_set: sensitivity = a_level
		end

	set_min_chapter_duration (a_seconds: REAL_64)
			-- Set minimum chapter duration in seconds.
		require
			positive: a_seconds > 0
		do
			min_chapter_duration := a_seconds
		ensure
			duration_set: min_chapter_duration = a_seconds
		end

	set_min_gap_seconds (a_seconds: REAL_64)
			-- Set minimum gap for temporal detection.
		require
			positive: a_seconds > 0
		do
			min_gap_seconds := a_seconds
		ensure
			gap_set: min_gap_seconds = a_seconds
		end

feature -- Configuration Fluent

	with_sensitivity (a_level: INTEGER): like Current
			-- Fluent: set sensitivity and return Current.
		require
			valid_level: a_level >= Sensitivity_low and a_level <= Sensitivity_high
		do
			set_sensitivity (a_level)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	with_min_chapter_duration (a_seconds: REAL_64): like Current
			-- Fluent: set minimum chapter duration and return Current.
		require
			positive: a_seconds > 0
		do
			set_min_chapter_duration (a_seconds)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	with_min_gap_seconds (a_seconds: REAL_64): like Current
			-- Fluent: set minimum gap and return Current.
		require
			positive: a_seconds > 0
		do
			set_min_gap_seconds (a_seconds)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Detection

	detect_transitions (segments: LIST [SPEECH_SEGMENT]): ARRAYED_LIST [SPEECH_CHAPTER]
		local
			l_index: INTEGER
			l_score: REAL_64
			l_type: STRING_8
			l_chapter_start: REAL_64
			l_prev_end: REAL_64
			l_threshold: REAL_64
			l_segment: SPEECH_SEGMENT
		do
			create Result.make (10)

			if segments.is_empty then
				-- Nothing to do
			else
				l_threshold := threshold_for_sensitivity
				l_chapter_start := segments.first.start_time
				l_prev_end := segments.first.end_time
				l_index := 0

				across segments as seg loop
					l_index := l_index + 1
					l_segment := seg
					l_score := 0.0
					l_type := "topic_shift"

					if l_segment.start_time - l_prev_end >= min_gap_seconds then
						l_score := l_score + Weight_high
						l_type := "temporal"
					end

					l_score := l_score + score_text (l_segment.text)

					if l_score >= l_threshold and then
					   l_segment.start_time - l_chapter_start >= min_chapter_duration then
						Result.extend (create_chapter (l_chapter_start, l_prev_end, l_type, l_score))
						l_chapter_start := l_segment.start_time
					end

					l_prev_end := l_segment.end_time
				end

				if not segments.is_empty then
					Result.extend (create_chapter (l_chapter_start, l_prev_end, "topic_shift", 1.0))
				end

				number_chapters (Result)
			end
		end

	detect_single (segment: SPEECH_SEGMENT; previous_end: REAL_64): TUPLE [is_transition: BOOLEAN; score: REAL_64; transition_type: STRING_8]
		local
			l_score: REAL_64
			l_type: STRING_8
			l_threshold: REAL_64
		do
			l_threshold := threshold_for_sensitivity
			l_score := 0.0
			l_type := "topic_shift"

			if segment.start_time - previous_end >= min_gap_seconds then
				l_score := l_score + Weight_high
				l_type := "temporal"
			end

			l_score := l_score + score_text (segment.text)
			Result := [l_score >= l_threshold, l_score, l_type]
		end

feature {NONE} -- Implementation

	transition_patterns: ARRAYED_LIST [TUPLE [pattern: STRING_8; weight: REAL_64; ptype: STRING_8]]

	initialize_patterns
		do
			add_pattern ("now let's", Weight_high, "explicit")
			add_pattern ("let's move on", Weight_high, "explicit")
			add_pattern ("next we'll", Weight_high, "explicit")
			add_pattern ("next, we", Weight_high, "explicit")
			add_pattern ("moving on to", Weight_high, "explicit")
			add_pattern ("i want to turn to", Weight_high, "explicit")
			add_pattern ("this brings us to", Weight_high, "explicit")
			add_pattern ("on a different topic", Weight_high, "explicit")
			add_pattern ("let's talk about", Weight_high, "explicit")
			add_pattern ("turning to", Weight_high, "explicit")
			add_pattern ("first,", Weight_high, "sequence")
			add_pattern ("first of all", Weight_high, "sequence")
			add_pattern ("second,", Weight_high, "sequence")
			add_pattern ("secondly", Weight_high, "sequence")
			add_pattern ("third,", Weight_high, "sequence")
			add_pattern ("finally,", Weight_high, "sequence")
			add_pattern ("lastly", Weight_high, "sequence")
			add_pattern ("the next point", Weight_high, "sequence")
			add_pattern ("another thing", Weight_medium, "sequence")
			add_pattern ("speaking of", Weight_medium, "topic_shift")
			add_pattern ("that reminds me", Weight_medium, "topic_shift")
			add_pattern ("on the subject of", Weight_medium, "topic_shift")
			add_pattern ("which brings up", Weight_medium, "topic_shift")
			add_pattern ("anyway,", Weight_high, "explicit")
			add_pattern ("at any rate", Weight_high, "explicit")
			add_pattern ("but i digress", Weight_high, "explicit")
			add_pattern ("so, moving on", Weight_high, "explicit")
			add_pattern ("getting back to", Weight_high, "explicit")
			add_pattern ("so,", Weight_medium, "topic_shift")
			add_pattern ("well,", Weight_medium, "topic_shift")
			add_pattern ("okay,", Weight_medium, "topic_shift")
			add_pattern ("alright,", Weight_medium, "topic_shift")
			add_pattern ("now,", Weight_medium, "topic_shift")
			add_pattern ("later that day", Weight_high, "temporal")
			add_pattern ("the next morning", Weight_high, "temporal")
			add_pattern ("the next day", Weight_high, "temporal")
			add_pattern ("hours later", Weight_high, "temporal")
			add_pattern ("days later", Weight_high, "temporal")
			add_pattern ("weeks later", Weight_high, "temporal")
			add_pattern ("years later", Weight_high, "temporal")
			add_pattern ("meanwhile,", Weight_high, "spatial")
			add_pattern ("elsewhere,", Weight_high, "spatial")
			add_pattern ("back at the", Weight_high, "spatial")
			add_pattern ("across town", Weight_high, "spatial")
		end

	add_pattern (a_pattern: STRING_8; a_weight: REAL_64; a_type: STRING_8)
		do
			transition_patterns.extend ([a_pattern, a_weight, a_type])
		end

	score_text (a_text: READABLE_STRING_GENERAL): REAL_64
		local
			l_lower: STRING_32
			l_best_weight: REAL_64
		do
			l_lower := a_text.to_string_32.as_lower
			l_best_weight := 0.0

			across transition_patterns as pat loop
				if l_lower.has_substring (pat.pattern) then
					if pat.weight > l_best_weight then
						l_best_weight := pat.weight
					end
				end
			end

			Result := l_best_weight
		end

	threshold_for_sensitivity: REAL_64
		do
			inspect sensitivity
			when Sensitivity_low then
				Result := 0.9
			when Sensitivity_medium then
				Result := 0.6
			when Sensitivity_high then
				Result := 0.3
			else
				Result := 0.6
			end
		end

	create_chapter (a_start, a_end: REAL_64; a_type: STRING_8; a_score: REAL_64): SPEECH_CHAPTER
		do
			create Result.make (a_start, a_end)
			Result.set_transition_type (a_type)
			Result.set_confidence (a_score.min (1.0))
		end

	number_chapters (chapters: LIST [SPEECH_CHAPTER])
		local
			l_index: INTEGER
		do
			l_index := 0
			across chapters as ch loop
				l_index := l_index + 1
				ch.set_title ("Chapter " + l_index.out)
			end
		end

invariant
	valid_sensitivity: sensitivity >= Sensitivity_low and sensitivity <= Sensitivity_high
	positive_min_duration: min_chapter_duration > 0
	positive_min_gap: min_gap_seconds > 0
	patterns_attached: transition_patterns /= Void

end
