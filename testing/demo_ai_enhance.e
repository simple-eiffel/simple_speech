note
	description: "Demo: AI enhancement of transcriptions"
	author: "Larry Rix"

class
	DEMO_AI_ENHANCE

create
	make

feature {NONE} -- Initialization

	make
		local
			speech: SIMPLE_SPEECH
			l_segs: ARRAYED_LIST [SPEECH_SEGMENT]
			ai_client: OLLAMA_CLIENT
			enhancer: SPEECH_AI_ENHANCER
			translated: ARRAYED_LIST [SPEECH_SEGMENT]
			corrected: ARRAYED_LIST [SPEECH_SEGMENT]
			summary: STRING_32
			multi_export: SPEECH_MULTI_LANGUAGE_EXPORTER
		do
			print ("=== Simple Speech AI Enhancement Demo ===%N%N")

			-- First, transcribe a sample
			print ("1. Transcribing sample audio...%N")
			create speech.make ("models/ggml-base.en.bin")
			if not speech.is_valid then
				print ("ERROR: Could not load whisper model%N")
			else
				l_segs := speech.transcribe_file ("testing/samples/librispeech/sample_8khz.wav")
				print ("   Transcribed " + l_segs.count.out + " segments%N%N")

				if l_segs.count = 0 then
					print ("No segments to enhance. Exiting.%N")
				else
					-- Show original
					print ("Original transcription:%N")
					show_segments (l_segs, 3)

					-- Create AI client (Ollama local)
					print ("%N2. Connecting to Ollama AI...%N")
					create ai_client.make
					ai_client.set_model ("llama3.2")

					-- Create enhancer
					create enhancer.make (ai_client)

					-- Test correction
					print ("%N3. Correcting transcription...%N")
					corrected := enhancer.correct (l_segs)
					if enhancer.has_error then
						print ("   ERROR: " + (if attached enhancer.last_error as e then e.to_string_8 else "unknown" end) + "%N")
					else
						print ("Corrected transcription:%N")
						show_segments (corrected, 3)
					end

					-- Test translation (Spanish)
					print ("%N4. Translating to Spanish...%N")
					translated := enhancer.translate (l_segs, "Spanish")
					if enhancer.has_error then
						print ("   ERROR: " + (if attached enhancer.last_error as e then e.to_string_8 else "unknown" end) + "%N")
					else
						print ("Spanish translation:%N")
						show_segments (translated, 3)
					end

					-- Test summarization
					print ("%N5. Generating summary...%N")
					summary := enhancer.summarize (l_segs)
					if enhancer.has_error then
						print ("   ERROR: " + (if attached enhancer.last_error as e then e.to_string_8 else "unknown" end) + "%N")
					else
						print ("Summary:%N")
						print (summary.to_string_8 + "%N")
					end

					-- Test multi-language export
					print ("%N6. Multi-language export...%N")
					create multi_export.make (ai_client, l_segs)
					multi_export.set_output_folder ("testing/output/")
					            .set_base_name ("sample")
					            .set_format ("vtt")
					            .set_languages (<<"spanish", "french", "german">>)
					            .do_nothing

					if multi_export.export_all then
						print ("   Exported to " + multi_export.languages.count.out + " languages%N")
						if attached multi_export.exported_files as files then
							across files as f loop
								print ("   - " + f.to_string_8 + "%N")
							end
						end
					else
						print ("   Export failed: " + (if attached multi_export.last_error as e then e.to_string_8 else "unknown" end) + "%N")
					end
				end

				speech.dispose
			end

			print ("%N=== Demo Complete ===%N")
		end

	show_segments (a_segs: ARRAYED_LIST [SPEECH_SEGMENT]; a_max: INTEGER)
			-- Show first a_max segments.
		local
			i, n: INTEGER
		do
			n := a_segs.count.min (a_max)
			from i := 1 until i > n loop
				print ("   [" + format_time (a_segs[i].start_time) + "] " +
				       a_segs[i].text.to_string_8 + "%N")
				i := i + 1
			end
			if a_segs.count > a_max then
				print ("   ... (" + (a_segs.count - a_max).out + " more)%N")
			end
		end

	format_time (a_seconds: REAL_64): STRING_8
			-- Format seconds as MM:SS.
		local
			m, s: INTEGER
		do
			m := (a_seconds / 60).truncated_to_integer
			s := (a_seconds - m * 60).truncated_to_integer
			create Result.make (6)
			if m < 10 then Result.append ("0") end
			Result.append_integer (m)
			Result.append (":")
			if s < 10 then Result.append ("0") end
			Result.append_integer (s)
		end

end
