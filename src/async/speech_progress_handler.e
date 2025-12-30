note
	description: "[
		SPEECH_PROGRESS_HANDLER - Interface for async transcription progress callbacks.

		Implement this class to receive progress updates from SPEECH_ASYNC_TRANSCRIBER.
		Used with SCOOP for thread-safe UI updates during long-running transcription.

		Progress phases:
		- 0-10%: Probing video
		- 10-30%: Extracting audio
		- 30-90%: Transcribing (whisper)
		- 90-100%: Detecting chapters
	]"
	author: "Larry Rix"
	date: "2025-12-29"

deferred class
	SPEECH_PROGRESS_HANDLER

feature -- Callbacks

	on_progress (a_percent: INTEGER; a_phase: separate READABLE_STRING_GENERAL)
			-- Called when transcription progress updates.
			-- `a_percent': 0-100 completion percentage
			-- `a_phase': Description of current phase (separate for SCOOP)
		require
			valid_percent: a_percent >= 0 and a_percent <= 100
		deferred
		end

	on_transcription_complete (a_segments: separate ARRAYED_LIST [SPEECH_SEGMENT]; a_chapters: separate ARRAYED_LIST [SPEECH_CHAPTER])
			-- Called when transcription successfully completes.
			-- `a_segments': Transcribed segments with timestamps (separate for SCOOP)
			-- `a_chapters': Detected chapter markers (separate for SCOOP)
		deferred
		end

	on_transcription_error (a_message: separate READABLE_STRING_GENERAL)
			-- Called when transcription fails.
			-- `a_message': Error description (separate for SCOOP)
		deferred
		end

	on_transcription_cancelled
			-- Called when transcription is cancelled by user.
		deferred
		end

end
