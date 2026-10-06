note
	description: "One word heard by the recognizer: its text and when it was said (seconds into the decoded window)."
	author: "Larry Rix"

class
	SPEECH_TIMED_WORD

create
	make

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_32; a_t0, a_t1, a_probability: REAL_64)
		require
			text_present: not a_text.is_empty
			times_ordered: a_t0 >= 0 and a_t0 <= a_t1
			probability_range: a_probability >= 0 and a_probability <= 1
		do
			create text.make_from_string (a_text)
			t0 := a_t0
			t1 := a_t1
			probability := a_probability
		ensure
			text_set: text.same_string (a_text)
			times_set: t0 = a_t0 and t1 = a_t1
			probability_set: probability = a_probability
		end

feature -- Access

	text: STRING_32
			-- As written by the recognizer (leading space removed).

	t0, t1: REAL_64
			-- Start and end, seconds into the window.

	probability: REAL_64
			-- The recognizer's confidence (its least sure token).

invariant
	text_present: not text.is_empty
	times_ordered: t0 >= 0 and t0 <= t1
	probability_range: probability >= 0 and probability <= 1

end
