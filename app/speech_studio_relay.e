note
	description: "[
		Speech Studio's go-between, on its own processor. It owns the transcriber, runs a
		job when the window asks, and hands everything back the way simple_gui requires:
		the GUI's mailbox, then its own GUI_WAKE. The window never waits on a job.

		The window gives it the file with `set_file' and then calls `start', which takes no
		arguments from the window's region, so the window's call returns at once. While a
		job runs, this processor waits on the transcriber, which calls back here.
	]"

class
	SPEECH_STUDIO_RELAY

inherit
	SPEECH_PROGRESS_HANDLER

	SPEECH_STUDIO_TAGS

create
	make

feature {NONE} -- Initialization

	make (a_mailbox: separate GUI_MAILBOX)
		do
			mailbox := a_mailbox
			create transcriber.make
			create file_path.make_empty
		ensure
			no_file: file_path.is_empty
		end

feature -- Access

	file_path: STRING_32
			-- The file the next job transcribes.

feature -- Commands (from the window)

	set_file (a_path: separate READABLE_STRING_GENERAL)
		do
			file_path := imported (a_path)
		ensure
			set: file_path.count = a_path.count
		end

	start
			-- Transcribe `file_path', reporting through the mailbox.
		require
			has_file: not file_path.is_empty
		do
			run_job (transcriber)
		end

feature -- SPEECH_PROGRESS_HANDLER

	on_progress (a_percent: INTEGER; a_phase: separate READABLE_STRING_GENERAL)
		local
			l_payload: STRING_32
		do
			create l_payload.make_from_string_general (a_percent.out)
			l_payload.append_character ('%T')
			l_payload.append (imported (a_phase))
			post (Tag_progress, l_payload)
		end

	on_transcription_complete (a_segments: separate ARRAYED_LIST [SPEECH_SEGMENT]; a_chapters: separate ARRAYED_LIST [SPEECH_CHAPTER])
		local
			i: INTEGER
		do
			from i := 1 until i > a_segments.count loop
				post (Tag_segment, segment_line (a_segments.i_th (i)))
				i := i + 1
			end
			from i := 1 until i > a_chapters.count loop
				post (Tag_chapter, chapter_line (a_chapters.i_th (i)))
				i := i + 1
			end
			post (Tag_done, {STRING_32} "")
		end

	on_transcription_error (a_message: separate READABLE_STRING_GENERAL)
		do
			post (Tag_error, imported (a_message))
		end

	on_transcription_cancelled
		do
			post (Tag_cancelled, {STRING_32} "")
		end

feature {NONE} -- Implementation

	mailbox: separate GUI_MAILBOX

	transcriber: separate SPEECH_ASYNC_TRANSCRIBER

	run_job (a_transcriber: separate SPEECH_ASYNC_TRANSCRIBER)
		do
			a_transcriber.transcribe_async (file_path, Current)
		end

	post (a_tag: INTEGER; a_payload: STRING_32)
			-- Hand the GUI one message and wake it.
		local
			l_wake: GUI_WAKE
		do
			put_message (mailbox, a_tag, a_payload)
			create l_wake
			l_wake.wake
		end

	put_message (a_mailbox: separate GUI_MAILBOX; a_tag: INTEGER; a_payload: STRING_32)
		do
			a_mailbox.put (a_tag, a_payload)
		end

	segment_line (a_segment: separate SPEECH_SEGMENT): STRING_32
		do
			create Result.make_from_string_general (a_segment.start_time.out)
			Result.append_character ('%T')
			Result.append_string_general (a_segment.end_time.out)
			Result.append_character ('%T')
			Result.append (imported (a_segment.text))
		end

	chapter_line (a_chapter: separate SPEECH_CHAPTER): STRING_32
		do
			create Result.make_from_string_general (a_chapter.start_time.out)
			Result.append_character ('%T')
			Result.append_string_general (a_chapter.end_time.out)
			Result.append_character ('%T')
			Result.append (imported (a_chapter.title))
		end

	imported (a_text: separate READABLE_STRING_GENERAL): STRING_32
			-- A copy on this processor, every character kept (not cut to 8 bits).
		local
			i: INTEGER
		do
			create Result.make (a_text.count)
			from i := 1 until i > a_text.count loop
				Result.extend (a_text.item (i))
				i := i + 1
			end
		ensure
			same_length: Result.count = a_text.count
		end

end
