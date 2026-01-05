note
	description: "[
		SPEECH_SEGMENT - A single transcribed segment with timing information.

		Represents one piece of transcribed speech with:
		- text: The transcribed text
		- start_time: When this segment begins (seconds)
		- end_time: When this segment ends (seconds)
		- confidence: Optional confidence score (0.0-1.0)
		- speaker_id: Optional speaker identifier for diarization
		- speaker_label: Optional human-readable speaker label
	]"
	author: "Larry Rix"

class
	SPEECH_SEGMENT

create
	make,
	make_with_confidence,
	make_with_speaker

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_GENERAL; a_start, a_end: REAL_64)
			-- Create segment with text and timing.
		require
			text_not_empty: not a_text.is_empty
			valid_times: a_start >= 0 and a_end >= a_start
		do
			create text.make_from_string_general (a_text)
			start_time := a_start
			end_time := a_end
			confidence := -1.0
		ensure
			text_set: text.same_string_general (a_text)
			start_set: start_time = a_start
			end_set: end_time = a_end
		end

	make_with_confidence (a_text: READABLE_STRING_GENERAL; a_start, a_end: REAL_64; a_confidence: REAL_32)
			-- Create segment with text, timing, and confidence.
		require
			text_not_empty: not a_text.is_empty
			valid_times: a_start >= 0 and a_end >= a_start
			valid_confidence: a_confidence >= 0.0 and a_confidence <= 1.0
		do
			make (a_text, a_start, a_end)
			confidence := a_confidence
		ensure
			confidence_set: confidence = a_confidence
		end

	make_with_speaker (a_text: READABLE_STRING_GENERAL; a_start, a_end: REAL_64; a_speaker_id: INTEGER; a_speaker_label: READABLE_STRING_GENERAL)
			-- Create segment with text, timing, and speaker information.
		require
			text_not_empty: not a_text.is_empty
			valid_times: a_start >= 0 and a_end >= a_start
			valid_speaker_id: a_speaker_id >= 0
		do
			make (a_text, a_start, a_end)
			speaker_id := a_speaker_id
			create speaker_label.make_from_string_general (a_speaker_label)
		ensure
			speaker_id_set: speaker_id = a_speaker_id
			speaker_label_attached: attached speaker_label
			has_speaker: has_speaker
		end

feature -- Access

	text: STRING_32
			-- The transcribed text.

	start_time: REAL_64
			-- Start time in seconds.

	end_time: REAL_64
			-- End time in seconds.

	confidence: REAL_32
			-- Confidence score (0.0-1.0), or -1.0 if not available.

	speaker_id: INTEGER
			-- Speaker identifier (0 = unknown, 1+ = identified speaker).

	speaker_label: detachable STRING_32
			-- Human-readable speaker label (e.g., "SPEAKER_1", "Host").

feature -- Queries

	duration: REAL_64
			-- Duration of this segment in seconds.
		do
			Result := end_time - start_time
		ensure
			non_negative: Result >= 0
		end

	has_confidence: BOOLEAN
			-- Is confidence score available?
		do
			Result := confidence >= 0.0
		end

	has_speaker: BOOLEAN
			-- Is speaker information available?
		do
			Result := speaker_id > 0
		end

	speaker_label_or_default: STRING_32
			-- Speaker label, or "SPEAKER_N" if not set.
		do
			if attached speaker_label as lbl and then not lbl.is_empty then
				Result := lbl
			else
				create Result.make (12)
				Result.append ("SPEAKER_")
				Result.append_integer (speaker_id.max (1))
			end
		end

	start_time_formatted: STRING_8
			-- Start time as HH:MM:SS.mmm
		do
			Result := format_time (start_time)
		end

	end_time_formatted: STRING_8
			-- End time as HH:MM:SS.mmm
		do
			Result := format_time (end_time)
		end

feature -- Speaker modification

	set_speaker (a_id: INTEGER; a_label: READABLE_STRING_GENERAL)
			-- Set speaker information.
		require
			valid_id: a_id >= 0
		do
			speaker_id := a_id
			create speaker_label.make_from_string_general (a_label)
		ensure
			id_set: speaker_id = a_id
			label_set: attached speaker_label as lbl implies lbl.same_string_general (a_label)
		end

	clear_speaker
			-- Remove speaker information.
		do
			speaker_id := 0
			speaker_label := Void
		ensure
			no_speaker: not has_speaker
		end

feature {NONE} -- Implementation

	format_time (seconds: REAL_64): STRING_8
			-- Format seconds as HH:MM:SS.mmm
		local
			h, m, s, ms: INTEGER
			total_ms: INTEGER_64
		do
			total_ms := (seconds * 1000).truncated_to_integer_64
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

invariant
	valid_times: start_time >= 0 and end_time >= start_time
	text_exists: text /= Void

end
