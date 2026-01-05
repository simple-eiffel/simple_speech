note
	description: "[
		SPEECH_AI_CHAPTER_ENHANCER - AI-powered chapter enhancement.
		
		Uses AI to generate meaningful chapter titles, summaries,
		validate transitions, and translate chapter metadata.
	]"
	author: "Larry Rix"

class
	SPEECH_AI_CHAPTER_ENHANCER

create
	make

feature {NONE} -- Initialization

	make (a_client: AI_CLIENT)
			-- Create enhancer with AI client.
		require
			client_attached: a_client /= Void
		do
			ai_client := a_client
		ensure
			client_set: ai_client = a_client
		end

feature -- Access

	ai_client: AI_CLIENT
			-- AI client for API calls.

feature -- Enhancement

	enhance_chapters (chapters: LIST [SPEECH_CHAPTER]; segments: LIST [SPEECH_SEGMENT]): ARRAYED_LIST [SPEECH_CHAPTER]
			-- Enhance chapters with AI-generated titles and summaries.
		local
			l_segment_text: STRING_32
			l_enhanced: SPEECH_CHAPTER
		do
			create Result.make (chapters.count)
			
			across chapters as ch loop
				l_segment_text := get_text_for_chapter (ch, segments)
				create l_enhanced.make (ch.start_time, ch.end_time)
				l_enhanced.set_transition_type (ch.transition_type)
				l_enhanced.set_confidence (ch.confidence)
				
				-- Generate title
				if attached generate_chapter_title (l_segment_text) as title then
					l_enhanced.set_title (title)
				else
					l_enhanced.set_title (ch.title)
				end
				
				-- Generate summary
				if attached generate_chapter_summary (l_segment_text) as summary then
					l_enhanced.set_summary (summary)
				end
				
				-- Copy keywords
				across ch.keywords as kw loop
					l_enhanced.add_keyword (kw)
				end
				
				Result.extend (l_enhanced)
			end
		end

	generate_chapter_title (segment_text: READABLE_STRING_GENERAL): detachable STRING_32
			-- Generate a meaningful chapter title from segment text.
		local
			l_prompt: STRING_32
			l_response: AI_RESPONSE
		do
			create l_prompt.make (2100)
			l_prompt.append ("Generate a concise chapter title (3-7 words) for the following transcript segment. Return ONLY the title, no quotes or explanation:%N%N")
			l_prompt.append (segment_text.to_string_32.head (2000))
			
			ai_client.use_concise_responses
			l_response := ai_client.ask (l_prompt)
			
			if l_response.is_success and then attached l_response.text as content then
				Result := content.to_string_32
				Result.left_adjust
				Result.right_adjust
				if Result.count >= 2 and then Result.starts_with ("%"") and Result.ends_with ("%"") then
					Result := Result.substring (2, Result.count - 1)
				end
			end
		end

	generate_chapter_summary (segment_text: READABLE_STRING_GENERAL): detachable STRING_32
			-- Generate a brief summary of the chapter content.
		local
			l_prompt: STRING_32
			l_response: AI_RESPONSE
		do
			create l_prompt.make (3100)
			l_prompt.append ("Summarize the following transcript in 1-2 sentences:%N%N")
			l_prompt.append (segment_text.to_string_32.head (3000))
			
			ai_client.use_concise_responses
			l_response := ai_client.ask (l_prompt)
			
			if l_response.is_success and then attached l_response.text as content then
				Result := content.to_string_32
				Result.left_adjust
				Result.right_adjust
			end
		end

	validate_transition (context_before: READABLE_STRING_GENERAL; context_after: READABLE_STRING_GENERAL): TUPLE [is_valid: BOOLEAN; confidence: REAL_64]
			-- Validate if a transition is genuine topic change.
		local
			l_prompt: STRING_32
			l_response: AI_RESPONSE
			l_content: STRING_8
		do
			create l_prompt.make (1200)
			l_prompt.append ("Analyze these two transcript segments. Is there a topic or scene change between them? Answer with YES or NO followed by confidence (0.0-1.0).%N%NBEFORE:%N")
			l_prompt.append (context_before.to_string_32.head (500))
			l_prompt.append ("%N%NAFTER:%N")
			l_prompt.append (context_after.to_string_32.head (500))
			l_prompt.append ("%N%NFormat: YES 0.85 or NO 0.90")
			
			ai_client.use_concise_responses
			l_response := ai_client.ask (l_prompt)
			
			if l_response.is_success and then attached l_response.text as content then
				l_content := content.to_string_8.as_upper
				if l_content.has_substring ("YES") then
					Result := [True, extract_confidence (l_content)]
				else
					Result := [False, extract_confidence (l_content)]
				end
			else
				Result := [True, 0.5]
			end
		end

	translate_chapter_titles (chapters: LIST [SPEECH_CHAPTER]; target_languages: ARRAY [STRING_8])
			-- Add translated titles for target languages.
		local
			l_prompt: STRING_32
			l_response: AI_RESPONSE
			l_translated: STRING_8
		do
			across chapters as ch loop
				across target_languages as lang loop
					create l_prompt.make (200)
					l_prompt.append ("Translate this chapter title to ")
					l_prompt.append (lang.to_string_32)
					l_prompt.append (". Return ONLY the translation:%N")
					l_prompt.append (ch.title)
					
					ai_client.use_concise_responses
					l_response := ai_client.ask (l_prompt)
					
					if l_response.is_success and then attached l_response.text as content then
						l_translated := content.to_string_8
						l_translated.left_adjust
						l_translated.right_adjust
						ch.set_localized_title (lang, l_translated)
					end
				end
			end
		end

	extract_keywords (segment_text: READABLE_STRING_GENERAL; max_keywords: INTEGER): ARRAYED_LIST [STRING_32]
			-- Extract key topics/keywords from text.
		local
			l_prompt: STRING_32
			l_response: AI_RESPONSE
			l_content: STRING_8
			l_parts: LIST [STRING_8]
		do
			create Result.make (max_keywords)
			
			create l_prompt.make (2100)
			l_prompt.append ("Extract ")
			l_prompt.append (max_keywords.out)
			l_prompt.append (" key topics/keywords from this transcript. Return as comma-separated list:%N%N")
			l_prompt.append (segment_text.to_string_32.head (2000))
			
			ai_client.use_concise_responses
			l_response := ai_client.ask (l_prompt)
			
			if l_response.is_success and then attached l_response.text as content then
				l_content := content.to_string_8
				l_parts := l_content.split (',')
				across l_parts as part loop
					part.left_adjust
					part.right_adjust
					if not part.is_empty then
						Result.extend (part.to_string_32)
					end
				end
			end
		end

feature {NONE} -- Implementation

	get_text_for_chapter (a_chapter: SPEECH_CHAPTER; segments: LIST [SPEECH_SEGMENT]): STRING_32
			-- Get concatenated text for segments in chapter.
		do
			create Result.make (1000)
			across segments as seg loop
				if seg.start_time >= a_chapter.start_time and
				   seg.end_time <= a_chapter.end_time then
					Result.append (seg.text)
					Result.append_character (' ')
				end
			end
		end

	extract_confidence (a_response: STRING_8): REAL_64
			-- Extract confidence value from response.
		local
			l_parts: LIST [STRING_8]
		do
			Result := 0.5
			l_parts := a_response.split (' ')
			across l_parts as part loop
				if part.is_real then
					Result := part.to_real_64
				end
			end
		end

invariant
	ai_client_attached: ai_client /= Void

end
