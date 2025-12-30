note
	description: "Demo: Transcribe and export to multiple formats"
	author: "Larry Rix"

class
	DEMO_EXPORT

create
	make

feature {NONE} -- Initialization

	make
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			exporter: SPEECH_EXPORTER
			l_ok: SPEECH_EXPORTER
		do
			print ("=== Simple Speech Export Demo ===%N%N")
			print ("Loading model...%N")
			
			create speech.make ("models/ggml-base.en.bin")
			
			if speech.is_valid then
				print ("Model loaded!%N%N")
				speech.set_language ("en")
				speech.set_threads (4)
				
				print ("Transcribing audio file...%N")
				segments := speech.transcribe_file ("testing/samples/test_audio.wav")
				print ("Transcription complete: " + segments.count.out + " segments%N%N")
				
				print ("Exporting to multiple formats...%N")
				create exporter.make (segments)
				
				l_ok := exporter.then_export_vtt ("testing/output/transcription.vtt")
				                .then_export_srt ("testing/output/transcription.srt")
				                .then_export_json ("testing/output/transcription.json")
				                .then_export_text ("testing/output/transcription.txt")
				
				if exporter.is_ok then
					print ("  Created: transcription.vtt%N")
					print ("  Created: transcription.srt%N")
					print ("  Created: transcription.json%N")
					print ("  Created: transcription.txt%N")
					print ("%N=== Export Complete ===%N%N")
					
					-- Show VTT preview
					print ("VTT Preview:%N")
					print ("-----------%N")
					print (exporter.to_vtt.substring (1, 500))
					print ("...%N")
				else
					print ("Export failed!%N")
				end
				
				speech.dispose
			else
				print ("Failed to load model!%N")
			end
		end

end
