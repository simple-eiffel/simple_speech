note
	description: "[
		SPEECH_ASYNC_TRANSCRIBER - SCOOP processor for async transcription.

		Runs transcription in a separate SCOOP processor, keeping the UI responsive.
		Reports progress at phase boundaries and supports cancellation.

		Usage with SCOOP:
			transcriber: separate SPEECH_ASYNC_TRANSCRIBER

			create transcriber.make
			start_transcription (transcriber, file_path, handler)

			start_transcription (a_transcriber: separate SPEECH_ASYNC_TRANSCRIBER;
			                     a_file: STRING; a_handler: separate SPEECH_PROGRESS_HANDLER)
				do
					a_transcriber.transcribe_async (a_file, a_handler)
				end

		Progress phases:
		- 0-10%: Probing video
		- 10-30%: Extracting audio
		- 30-90%: Transcribing
		- 90-100%: Detecting chapters
	]"
	author: "Larry Rix"
	date: "2025-12-29"

class
	SPEECH_ASYNC_TRANSCRIBER

create
	make,
	make_with_model

feature {NONE} -- Initialization

	make
			-- Create with default model path.
		do
			make_with_model ("models/ggml-base.en.bin")
		end

	make_with_model (a_model_path: STRING)
			-- Create with specified Whisper model.
		require
			path_not_empty: not a_model_path.is_empty
		do
			model_path := a_model_path
			create internal_segments.make (0)
			create internal_chapters.make (0)
		ensure
			model_set: model_path.same_string (a_model_path)
		end

feature -- Status

	is_running: BOOLEAN
			-- Is transcription currently in progress?

	is_cancelled: BOOLEAN
			-- Has cancellation been requested?

	current_phase: STRING
			-- Description of current transcription phase.
		attribute
			Result := ""
		end

	current_percent: INTEGER
			-- Current progress percentage (0-100).

feature -- Results

	segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Transcribed segments after completion.
		do
			Result := internal_segments
		end

	chapters: ARRAYED_LIST [SPEECH_CHAPTER]
			-- Detected chapters after completion.
		do
			Result := internal_chapters
		end

	last_error: detachable STRING
			-- Error message if transcription failed.

feature -- Commands

	cancel
			-- Request cancellation of current transcription.
			-- The transcription will stop at the next phase boundary.
		do
			is_cancelled := True
		ensure
			cancelled: is_cancelled
		end

	transcribe_async (a_file: separate READABLE_STRING_GENERAL; a_handler: separate SPEECH_PROGRESS_HANDLER)
			-- Transcribe file asynchronously, reporting progress to handler.
			-- This runs in the transcriber's SCOOP processor.
		require
			handler_attached: a_handler /= Void
			not_already_running: not is_running
		local
			l_speech: SPEECH_QUICK
			l_file_path: STRING
		do
			-- Copy file path to local processor context (char by char for SCOOP)
			l_file_path := import_string (a_file)

			-- Initialize state
			is_running := True
			is_cancelled := False
			last_error := Void
			internal_segments.wipe_out
			internal_chapters.wipe_out

			-- Phase 1: Initialize (0-10%)
			report_progress (a_handler, 0, "Initializing...")
			create l_speech.make_with_model (model_path)

			if not l_speech.is_ready then
				report_error (a_handler, "Failed to initialize speech engine")
				is_running := False
			else
				report_progress (a_handler, 10, "Probing media file...")

				-- Check cancellation
				if is_cancelled then
					report_cancelled (a_handler)
					is_running := False
				else
					-- Phase 2: Transcribe (10-90%)
					report_progress (a_handler, 30, "Transcribing audio...")

					l_speech.transcribe (l_file_path)

					if not l_speech.has_segments then
						if attached l_speech.last_error as err then
							report_error (a_handler, err.to_string_8)
						else
							report_error (a_handler, "Transcription failed - no segments produced")
						end
						is_running := False
					elseif is_cancelled then
						report_cancelled (a_handler)
						is_running := False
					else
						-- Copy segments
						across l_speech.segments as seg loop
							internal_segments.extend (seg)
						end

						-- Phase 3: Detect chapters (90-100%)
						report_progress (a_handler, 90, "Detecting chapters...")

						l_speech.detect_chapters

						-- Copy chapters
						across l_speech.chapters as ch loop
							internal_chapters.extend (ch)
						end

						-- Complete
						report_progress (a_handler, 100, "Complete")
						report_complete (a_handler, internal_segments, internal_chapters)
						is_running := False
					end
				end
			end
		ensure
			not_running: not is_running
		end

feature {NONE} -- Progress Reporting

	report_progress (a_handler: separate SPEECH_PROGRESS_HANDLER; a_percent: INTEGER; a_phase: STRING)
			-- Report progress to handler (separate call).
		require
			valid_percent: a_percent >= 0 and a_percent <= 100
		do
			current_percent := a_percent
			current_phase := a_phase
			a_handler.on_progress (a_percent, a_phase)
		end

	report_complete (a_handler: separate SPEECH_PROGRESS_HANDLER;
	                 a_segments: ARRAYED_LIST [SPEECH_SEGMENT];
	                 a_chapters: ARRAYED_LIST [SPEECH_CHAPTER])
			-- Report completion to handler (separate call).
		do
			a_handler.on_transcription_complete (a_segments, a_chapters)
		end

	report_error (a_handler: separate SPEECH_PROGRESS_HANDLER; a_message: STRING)
			-- Report error to handler (separate call).
		do
			last_error := a_message
			a_handler.on_transcription_error (a_message)
		end

	report_cancelled (a_handler: separate SPEECH_PROGRESS_HANDLER)
			-- Report cancellation to handler (separate call).
		do
			a_handler.on_transcription_cancelled
		end

feature {NONE} -- Implementation

	model_path: STRING
			-- Path to Whisper model.

	internal_segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Stored segments.

	internal_chapters: ARRAYED_LIST [SPEECH_CHAPTER]
			-- Stored chapters.

	import_string (a_separate: separate READABLE_STRING_GENERAL): STRING
			-- Import string from separate processor by copying char by char.
			-- CHARACTER is expanded, so individual chars can cross processor boundaries.
		local
			i: INTEGER
		do
			create Result.make (a_separate.count)
			from i := 1 until i > a_separate.count loop
				Result.extend (a_separate.item (i).to_character_8)
				i := i + 1
			end
		end

invariant
	model_path_set: model_path /= Void

end
