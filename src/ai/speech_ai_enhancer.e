note
	description: "[
		SPEECH_AI_ENHANCER - AI-powered enhancement for speech segments.

		Provides AI-powered enhancements for transcription segments:
		- Translation: Translate segments to any target language
		- Correction: Fix transcription errors using AI
		- Summarization: Generate meeting notes/summaries

		Example:
			create enhancer.make (ai_client)
			translated := enhancer.translate (segments, "spanish")
			corrected := enhancer.correct (segments)
			summary := enhancer.summarize (segments)
	]"
	author: "Larry Rix"

class
	SPEECH_AI_ENHANCER

create
	make

feature {NONE} -- Initialization

	make (a_client: AI_CLIENT)
			-- Create enhancer with AI client.
		require
			client_attached: a_client /= Void
		do
			client := a_client
			batch_size := Default_batch_size
		ensure
			client_set: client = a_client
		end

feature -- Access

	client: AI_CLIENT
			-- AI client for enhancements.

	batch_size: INTEGER
			-- Number of segments to process at once.

	last_error: detachable STRING_32
			-- Last error message.

feature -- Status

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_error /= Void
		end

feature -- Configuration

	set_batch_size (a_size: INTEGER): like Current
			-- Set batch size for processing.
		require
			positive: a_size > 0
		do
			batch_size := a_size
			Result := Current
		ensure
			batch_size_set: batch_size = a_size
			result_is_current: Result = Current
		end

feature -- Translation

	translate (a_segments: ARRAYED_LIST [SPEECH_SEGMENT]; a_target_language: READABLE_STRING_GENERAL): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Translate segments to target language.
		require
			segments_attached: a_segments /= Void
			has_segments: a_segments.count > 0
			language_not_empty: not a_target_language.is_empty
		local
			l_text: STRING_32
			l_prompt: STRING_32
			l_response: AI_RESPONSE
			l_translated_text: STRING_32
			l_lines: LIST [STRING_32]
			i: INTEGER
		do
			clear_error
			create Result.make (a_segments.count)

			-- Build combined text
			l_text := combine_segment_texts (a_segments)

			-- Build prompt
			create l_prompt.make (500)
			l_prompt.append ("Translate the following transcription to ")
			l_prompt.append (a_target_language.to_string_32)
			l_prompt.append (". Keep the same line structure (one segment per line). Only output the translation, no explanations:%N%N")
			l_prompt.append (l_text)

			-- Call AI
			l_response := client.ask_with_system (Translation_system_prompt, l_prompt)

			if l_response.is_success then
				l_translated_text := l_response.text
				l_lines := l_translated_text.split ('%N')

				-- Create translated segments with original timing
				from
					i := 1
					a_segments.start
				until
					a_segments.after or i > l_lines.count
				loop
					Result.extend (create {SPEECH_SEGMENT}.make (
						l_lines.i_th (i),
						a_segments.item.start_time,
						a_segments.item.end_time
					))
					a_segments.forth
					i := i + 1
				end
			else
				set_error (l_response.error_message)
				-- Return original segments on error
				Result := a_segments.twin
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Correction

	correct_with_context (a_segments: ARRAYED_LIST [SPEECH_SEGMENT]; a_topic_hint: READABLE_STRING_GENERAL): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Fix transcription errors in segments using topic context.
			-- `a_topic_hint` provides domain context for better corrections
			-- (e.g., "Eiffel programming tutorial" helps correct "eyeful" to "Eiffel").
		require
			segments_attached: a_segments /= Void
			has_segments: a_segments.count > 0
			hint_not_empty: not a_topic_hint.is_empty
		local
			l_text: STRING_32
			l_prompt: STRING_32
			l_response: AI_RESPONSE
			l_corrected_text: STRING_32
			l_lines: LIST [STRING_32]
			i: INTEGER
		do
			clear_error
			create Result.make (a_segments.count)

			-- Build combined text
			l_text := combine_segment_texts (a_segments)

			-- Build prompt with topic context
			create l_prompt.make (800)
			l_prompt.append ("Context: This is a transcription about: ")
			l_prompt.append (a_topic_hint.to_string_32)
			l_prompt.append ("%N%N")
			l_prompt.append ("Fix any transcription errors, especially domain-specific terminology that may have been misheard. ")
			l_prompt.append ("For example, if this is about '")
			l_prompt.append (a_topic_hint.to_string_32)
			l_prompt.append ("', correct related terms that Whisper may have transcribed incorrectly. ")
			l_prompt.append ("Keep the same line structure (one segment per line). Only output the corrected text, no explanations:%N%N")
			l_prompt.append (l_text)

			-- Call AI with enhanced system prompt
			l_response := client.ask_with_system (Context_correction_system_prompt, l_prompt)

			if l_response.is_success then
				l_corrected_text := l_response.text
				l_lines := l_corrected_text.split ('%N')

				-- Create corrected segments with original timing
				from
					i := 1
					a_segments.start
				until
					a_segments.after or i > l_lines.count
				loop
					Result.extend (create {SPEECH_SEGMENT}.make (
						l_lines.i_th (i),
						a_segments.item.start_time,
						a_segments.item.end_time
					))
					a_segments.forth
					i := i + 1
				end
			else
				set_error (l_response.error_message)
				-- Return original segments on error
				Result := a_segments.twin
			end
		ensure
			result_attached: Result /= Void
		end

	correct (a_segments: ARRAYED_LIST [SPEECH_SEGMENT]): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Fix transcription errors in segments.
		require
			segments_attached: a_segments /= Void
			has_segments: a_segments.count > 0
		local
			l_text: STRING_32
			l_prompt: STRING_32
			l_response: AI_RESPONSE
			l_corrected_text: STRING_32
			l_lines: LIST [STRING_32]
			i: INTEGER
		do
			clear_error
			create Result.make (a_segments.count)

			-- Build combined text
			l_text := combine_segment_texts (a_segments)

			-- Build prompt
			create l_prompt.make (500)
			l_prompt.append ("Fix any transcription errors, typos, or grammatical issues in the following text. ")
			l_prompt.append ("Keep the same line structure (one segment per line). Only output the corrected text, no explanations:%N%N")
			l_prompt.append (l_text)

			-- Call AI
			l_response := client.ask_with_system (Correction_system_prompt, l_prompt)

			if l_response.is_success then
				l_corrected_text := l_response.text
				l_lines := l_corrected_text.split ('%N')

				-- Create corrected segments with original timing
				from
					i := 1
					a_segments.start
				until
					a_segments.after or i > l_lines.count
				loop
					Result.extend (create {SPEECH_SEGMENT}.make (
						l_lines.i_th (i),
						a_segments.item.start_time,
						a_segments.item.end_time
					))
					a_segments.forth
					i := i + 1
				end
			else
				set_error (l_response.error_message)
				-- Return original segments on error
				Result := a_segments.twin
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Summarization

	summarize (a_segments: ARRAYED_LIST [SPEECH_SEGMENT]): STRING_32
			-- Generate summary of transcription.
		require
			segments_attached: a_segments /= Void
			has_segments: a_segments.count > 0
		local
			l_text: STRING_32
			l_prompt: STRING_32
			l_response: AI_RESPONSE
		do
			clear_error

			-- Build combined text
			l_text := combine_segment_texts (a_segments)

			-- Build prompt
			create l_prompt.make (500)
			l_prompt.append ("Summarize the following transcription into concise meeting notes or bullet points:%N%N")
			l_prompt.append (l_text)

			-- Call AI
			l_response := client.ask_with_system (Summary_system_prompt, l_prompt)

			if l_response.is_success then
				Result := l_response.text
			else
				set_error (l_response.error_message)
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

	summarize_with_format (a_segments: ARRAYED_LIST [SPEECH_SEGMENT]; a_format: READABLE_STRING_GENERAL): STRING_32
			-- Generate summary in specified format.
			-- Format can be: "bullets", "paragraphs", "outline", "action_items"
		require
			segments_attached: a_segments /= Void
			has_segments: a_segments.count > 0
			format_not_empty: not a_format.is_empty
		local
			l_text: STRING_32
			l_prompt: STRING_32
			l_response: AI_RESPONSE
		do
			clear_error

			-- Build combined text
			l_text := combine_segment_texts (a_segments)

			-- Build prompt
			create l_prompt.make (500)
			l_prompt.append ("Summarize the following transcription in ")
			l_prompt.append (a_format.to_string_32)
			l_prompt.append (" format:%N%N")
			l_prompt.append (l_text)

			-- Call AI
			l_response := client.ask_with_system (Summary_system_prompt, l_prompt)

			if l_response.is_success then
				Result := l_response.text
			else
				set_error (l_response.error_message)
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Implementation

	combine_segment_texts (a_segments: ARRAYED_LIST [SPEECH_SEGMENT]): STRING_32
			-- Combine all segment texts into one string (one per line).
		do
			create Result.make (a_segments.count * 100)
			across a_segments as seg loop
				Result.append (seg.text)
				Result.append_character ('%N')
			end
		end

	clear_error
			-- Clear last error.
		do
			last_error := Void
		end

	set_error (a_msg: detachable STRING_32)
			-- Set error message.
		do
			if attached a_msg as m then
				last_error := m
			else
				last_error := "Unknown error"
			end
		end

feature {NONE} -- Constants

	Default_batch_size: INTEGER = 20
			-- Default number of segments to process at once.

	Translation_system_prompt: STRING_32
		once
			Result := "You are a professional translator. Translate text accurately while preserving meaning and natural flow. Maintain the same line structure as the input."
		end

	Correction_system_prompt: STRING_32
		once
			Result := "You are a professional proofreader. Fix spelling, grammar, and transcription errors while preserving the original meaning. Maintain the same line structure as the input."
		end

	Summary_system_prompt: STRING_32
		once
			Result := "You are a professional note-taker. Create concise, well-organized summaries that capture key points and action items."
		end

	Context_correction_system_prompt: STRING_32
		once
			Result := "You are a professional transcription editor with expertise in domain-specific terminology. Fix transcription errors based on the provided context. Focus on correcting domain-specific words that may have been misheard. Maintain the same line structure as the input."
		end

invariant
	client_attached: client /= Void
	positive_batch_size: batch_size > 0

end
