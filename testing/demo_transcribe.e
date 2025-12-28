note
	description: "Demo: Speech-to-text transcription"
	author: "Larry Rix"

class
	DEMO_TRANSCRIBE

create
	make

feature {NONE} -- Initialization

	make
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			l_dummy: SIMPLE_SPEECH
		do
			print ("=== Simple Speech Demo ===%N%N")
			print ("Loading model...%N")
			
			create speech.make ("models/ggml-base.en.bin")
			
			if speech.is_valid then
				print ("Model loaded successfully!%N%N")
				l_dummy := speech.set_language ("en").set_threads (4)
				
				print ("Transcribing audio file...%N%N")
				segments := speech.transcribe_file ("testing/samples/test_audio.wav")
				
				print ("=== Transcription Results ===%N%N")
				across segments as seg loop
					print ("[" + seg.start_time_formatted + " --> " + seg.end_time_formatted + "]%N")
					print (seg.text + "%N%N")
				end
				
				print ("=== Summary ===%N")
				print ("Total segments: " + segments.count.out + "%N")
				
				speech.dispose
			else
				print ("Failed to load model!%N")
				if attached speech.last_error as err then
					print ("Error: " + err + "%N")
				end
			end
		end

end
