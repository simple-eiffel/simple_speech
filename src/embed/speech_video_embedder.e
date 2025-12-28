note
	description: "[
		SPEECH_VIDEO_EMBEDDER - Embed captions and chapters into video containers.
		
		Uses FFmpeg to embed:
		- Soft subtitles (toggleable captions)
		- Chapter metadata (navigable markers)
		
		Supports MP4, MKV, and WebM containers.
		No re-encoding - copies video/audio streams for fast operation.
	]"
	author: "Larry Rix"

class
	SPEECH_VIDEO_EMBEDDER

create
	make

feature {NONE} -- Initialization

	make (a_ffmpeg: FFMPEG_CLI)
			-- Create embedder with FFmpeg CLI.
		require
			ffmpeg_attached: a_ffmpeg /= Void
			ffmpeg_available: a_ffmpeg.is_available
		do
			ffmpeg := a_ffmpeg
			create metadata_generator.make
			output_container := "mp4"
			caption_format := "mov_text"
			temp_dir := "."
		ensure
			ffmpeg_set: ffmpeg = a_ffmpeg
		end

feature -- Access

	ffmpeg: FFMPEG_CLI
			-- FFmpeg CLI wrapper.

	metadata_generator: SPEECH_METADATA_GENERATOR
			-- Metadata file generator.

	output_container: STRING_8
			-- Output container format (mp4, mkv, webm).

	caption_format: STRING_8
			-- Caption codec (mov_text, srt, ass, webvtt).

	temp_dir: STRING_8
			-- Directory for temporary files.

	last_error: detachable STRING_32
			-- Last error message.

feature -- Status

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_error /= Void
		end

feature -- Configuration

	set_output_container (a_format: STRING_8): like Current
			-- Set output container format.
		require
			valid_format: a_format.same_string ("mp4") or
			              a_format.same_string ("mkv") or
			              a_format.same_string ("webm")
		do
			output_container := a_format
			-- Set appropriate caption format
			if a_format.same_string ("mp4") then
				caption_format := "mov_text"
			elseif a_format.same_string ("mkv") then
				caption_format := "srt"
			elseif a_format.same_string ("webm") then
				caption_format := "webvtt"
			end
			Result := Current
		end

	set_temp_dir (a_dir: STRING_8): like Current
			-- Set temporary directory for intermediate files.
		do
			temp_dir := a_dir
			Result := Current
		end

feature -- Embedding

	embed_captions (a_input: READABLE_STRING_GENERAL;
	                segments: LIST [SPEECH_SEGMENT];
	                a_output: READABLE_STRING_GENERAL): BOOLEAN
			-- Embed captions into video.
		local
			l_srt_path: STRING_32
		do
			clear_error
			
			-- Write temp SRT file
			l_srt_path := temp_path ("captions.srt")
			if metadata_generator.write_srt (segments, l_srt_path) then
				Result := run_embed_captions (a_input, l_srt_path, a_output)
				delete_temp_file (l_srt_path)
			else
				last_error := "Failed to write subtitle file"
			end
		end

	embed_chapters (a_input: READABLE_STRING_GENERAL;
	                chapters: LIST [SPEECH_CHAPTER];
	                a_output: READABLE_STRING_GENERAL): BOOLEAN
			-- Embed chapter metadata into video.
		local
			l_meta_path: STRING_32
		do
			clear_error
			
			-- Write temp FFMETADATA file
			l_meta_path := temp_path ("chapters.txt")
			if metadata_generator.write_ffmetadata (chapters, l_meta_path) then
				Result := run_embed_chapters (a_input, l_meta_path, a_output)
				delete_temp_file (l_meta_path)
			else
				last_error := "Failed to write metadata file"
			end
		end

	embed_all (a_input: READABLE_STRING_GENERAL;
	           segments: LIST [SPEECH_SEGMENT];
	           chapters: LIST [SPEECH_CHAPTER];
	           a_output: READABLE_STRING_GENERAL): BOOLEAN
			-- Embed both captions and chapters into video.
		local
			l_srt_path, l_meta_path: STRING_32
		do
			clear_error
			
			-- Write temp files
			l_srt_path := temp_path ("captions.srt")
			l_meta_path := temp_path ("chapters.txt")
			
			if metadata_generator.write_srt (segments, l_srt_path) and
			   metadata_generator.write_ffmetadata (chapters, l_meta_path) then
				Result := run_embed_all (a_input, l_srt_path, l_meta_path, a_output)
				delete_temp_file (l_srt_path)
				delete_temp_file (l_meta_path)
			else
				last_error := "Failed to write metadata files"
			end
		end

feature {NONE} -- Implementation

	run_embed_captions (a_input, a_srt, a_output: READABLE_STRING_GENERAL): BOOLEAN
			-- Run FFmpeg to embed captions.
		do
			Result := ffmpeg.transcode_with_args (a_input, a_output,
				"-i %"" + a_srt.to_string_8 + "%" -c copy -c:s " + caption_format)
			if ffmpeg.has_error then
				last_error := ffmpeg.last_error
			end
		end

	run_embed_chapters (a_input, a_meta, a_output: READABLE_STRING_GENERAL): BOOLEAN
			-- Run FFmpeg to embed chapters.
		do
			Result := ffmpeg.transcode_with_args (a_input, a_output,
				"-i %"" + a_meta.to_string_8 + "%" -map_metadata 1 -codec copy")
			if ffmpeg.has_error then
				last_error := ffmpeg.last_error
			end
		end

	run_embed_all (a_input, a_srt, a_meta, a_output: READABLE_STRING_GENERAL): BOOLEAN
			-- Run FFmpeg to embed captions and chapters.
		do
			Result := ffmpeg.transcode_with_args (a_input, a_output,
				"-i %"" + a_srt.to_string_8 + "%" -i %"" + a_meta.to_string_8 + 
				"%" -map 0 -map 1 -map_metadata 2 -c copy -c:s " + caption_format)
			if ffmpeg.has_error then
				last_error := ffmpeg.last_error
			end
		end

	temp_path (a_name: STRING_8): STRING_32
			-- Generate temp file path.
		do
			create Result.make (100)
			Result.append (temp_dir)
			Result.append_character ('/')
			Result.append (a_name)
		end

	delete_temp_file (a_path: STRING_32)
			-- Delete temporary file.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			if l_file.exists then
				l_file.delete
			end
		end

	clear_error
			-- Clear last error.
		do
			last_error := Void
		end

invariant
	ffmpeg_attached: ffmpeg /= Void
	metadata_generator_attached: metadata_generator /= Void

end
