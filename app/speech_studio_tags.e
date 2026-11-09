note
	description: "[
		The messages Speech Studio's relay puts in the GUI's mailbox. Payloads are text,
		fields separated by a tab; the last field may itself hold tabs.
	]"

class
	SPEECH_STUDIO_TAGS

feature -- Tags

	Tag_progress: INTEGER = 1
			-- "percent<TAB>phase"

	Tag_segment: INTEGER = 2
			-- "start<TAB>end<TAB>text", times in seconds

	Tag_chapter: INTEGER = 3
			-- "start<TAB>end<TAB>title"

	Tag_done: INTEGER = 4
			-- Every segment and chapter has been sent.

	Tag_error: INTEGER = 5
			-- The message

	Tag_cancelled: INTEGER = 6
			-- The transcriber stopped between phases.

end
