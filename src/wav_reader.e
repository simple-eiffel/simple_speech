note
	description: "[
		WAV_READER - Simple WAV file reader for PCM audio.
		
		Reads 16-bit PCM WAV files and converts to 32-bit float samples
		at the requested sample rate (default 16000 Hz for whisper).
		
		Handles stereo to mono conversion and basic resampling.
	]"
	author: "Larry Rix"

class
	WAV_READER

create
	make

feature {NONE} -- Initialization

	make
			-- Create reader.
		do
			target_sample_rate := 16000
		end

feature -- Configuration

	target_sample_rate: INTEGER
			-- Target sample rate for output (default 16000 for whisper).

	set_target_sample_rate (a_rate: INTEGER)
			-- Set target sample rate.
		require
			positive: a_rate > 0
		do
			target_sample_rate := a_rate
		ensure
			set: target_sample_rate = a_rate
		end

feature -- Access

	last_error: detachable STRING_32
			-- Last error message.

	sample_rate: INTEGER
			-- Sample rate of last loaded file.

	channels: INTEGER
			-- Number of channels in last loaded file.

	bits_per_sample: INTEGER
			-- Bits per sample in last loaded file.

feature -- Operations

	load_file (a_path: READABLE_STRING_GENERAL): detachable ARRAY [REAL_32]
			-- Load WAV file and return samples as floats in range [-1, 1].
			-- Converts to mono and resamples to target_sample_rate.
		local
			l_file: RAW_FILE
			l_header: ARRAY [NATURAL_8]
			l_fmt_size: INTEGER
			l_audio_format: INTEGER
			l_byte_rate: INTEGER
			l_block_align: INTEGER
			l_data_size: INTEGER
			l_raw_samples: SPECIAL [NATURAL_8]
			i, j, n: INTEGER
			l_sample: INTEGER_16
			l_left, l_right: INTEGER_16
			l_mono: REAL_32
			l_samples: ARRAYED_LIST [REAL_32]
			l_resampled: ARRAY [REAL_32]
			l_resample_ratio: REAL_64
			l_src_idx: INTEGER
			l_chunk_id: STRING_8
		do
			create l_file.make_with_name (a_path.to_string_8)
			if not l_file.exists then
				last_error := {STRING_32} "File not found: " + a_path.to_string_32
			else
				l_file.open_read
				
				-- Read RIFF header (12 bytes)
				create l_header.make_filled (0, 1, 12)
				read_bytes (l_file, l_header, 12)
				
				-- Check RIFF/WAVE signatures
				if not (l_header[1] = 0x52 and l_header[2] = 0x49 and 
						l_header[3] = 0x46 and l_header[4] = 0x46) then
					last_error := {STRING_32} "Not a valid WAV file (missing RIFF)"
					l_file.close
				elseif not (l_header[9] = 0x57 and l_header[10] = 0x41 and 
						   l_header[11] = 0x56 and l_header[12] = 0x45) then
					last_error := {STRING_32} "Not a valid WAV file (missing WAVE)"
					l_file.close
				else
					-- Find fmt chunk (skip any LIST chunks etc.)
					from
						l_chunk_id := ""
					until
						l_chunk_id.same_string ("fmt ") or l_file.end_of_file
					loop
						create l_header.make_filled (0, 1, 8)
						read_bytes (l_file, l_header, 8)
						l_chunk_id := chunk_id (l_header)
						l_fmt_size := read_int32_le (l_header, 5)
						if not l_chunk_id.same_string ("fmt ") then
							-- Skip this chunk
							l_file.move (l_fmt_size)
						end
					end
					
					if not l_chunk_id.same_string ("fmt ") then
						last_error := {STRING_32} "Format chunk not found"
						l_file.close
					else
						-- Read fmt chunk data
						create l_header.make_filled (0, 1, l_fmt_size)
						read_bytes (l_file, l_header, l_fmt_size)
						
						l_audio_format := read_int16_le (l_header, 1)
						channels := read_int16_le (l_header, 3)
						sample_rate := read_int32_le (l_header, 5)
						l_byte_rate := read_int32_le (l_header, 9)
						l_block_align := read_int16_le (l_header, 13)
						bits_per_sample := read_int16_le (l_header, 15)
						
						if l_audio_format /= 1 then
							last_error := {STRING_32} "Only PCM format supported (got " + l_audio_format.out + ")"
							l_file.close
						elseif bits_per_sample /= 16 then
							last_error := {STRING_32} "Only 16-bit audio supported (got " + bits_per_sample.out + ")"
							l_file.close
						else
							-- Find data chunk
							from
								l_chunk_id := ""
							until
								l_chunk_id.same_string ("data") or l_file.end_of_file
							loop
								create l_header.make_filled (0, 1, 8)
								read_bytes (l_file, l_header, 8)
								l_chunk_id := chunk_id (l_header)
								l_data_size := read_int32_le (l_header, 5)
								if not l_chunk_id.same_string ("data") then
									l_file.move (l_data_size)
								end
							end
							
							if not l_chunk_id.same_string ("data") then
								last_error := {STRING_32} "Data chunk not found"
								l_file.close
							else
								-- Read raw PCM data using stream (fast bulk read)
								create l_raw_samples.make_filled (0, l_data_size)
								l_file.read_stream (l_data_size)
								if attached l_file.last_string as ls then
									from j := 0 until j >= ls.count or j >= l_data_size loop
										l_raw_samples[j] := ls.item (j + 1).code.to_natural_8
										j := j + 1
									end
								end
								l_file.close
								
								-- Convert to mono float samples
								create l_samples.make (l_data_size // (channels * 2))
								n := l_data_size // (channels * 2)
								
								from i := 0 until i >= n loop
									if channels = 1 then
										l_sample := read_sample_16 (l_raw_samples, i * 2)
										l_mono := (l_sample / 32768.0).truncated_to_real
									else
										-- Stereo: average left and right
										l_left := read_sample_16 (l_raw_samples, i * 4)
										l_right := read_sample_16 (l_raw_samples, i * 4 + 2)
										l_mono := ((l_left + l_right) / 65536.0).truncated_to_real
									end
									l_samples.extend (l_mono)
									i := i + 1
								end
								
								-- Resample to target rate if needed
								if sample_rate = target_sample_rate then
									create Result.make_from_array (l_samples.to_array)
								else
									l_resample_ratio := target_sample_rate / sample_rate
									n := (l_samples.count * l_resample_ratio).floor
									create l_resampled.make_filled (0.0, 1, n)
									from i := 1 until i > n loop
										l_src_idx := ((i - 1) / l_resample_ratio).floor + 1
										if l_src_idx <= l_samples.count then
											l_resampled[i] := l_samples[l_src_idx]
										end
										i := i + 1
									end
									Result := l_resampled
								end
							end
						end
					end
				end
			end
		end

feature {NONE} -- Implementation

	read_bytes (a_file: RAW_FILE; a_buffer: ARRAY [NATURAL_8]; a_count: INTEGER)
			-- Read bytes into buffer.
		local
			i: INTEGER
			c: CHARACTER_8
		do
			from i := 1 until i > a_count or a_file.end_of_file loop
				a_file.read_character
				c := a_file.last_character
				a_buffer[i] := c.code.to_natural_8
				i := i + 1
			end
		end

	chunk_id (a_header: ARRAY [NATURAL_8]): STRING_8
			-- Get 4-character chunk ID from header bytes.
		do
			create Result.make (4)
			Result.append_character (a_header[1].to_character_8)
			Result.append_character (a_header[2].to_character_8)
			Result.append_character (a_header[3].to_character_8)
			Result.append_character (a_header[4].to_character_8)
		end

	read_int16_le (a_buffer: ARRAY [NATURAL_8]; a_offset: INTEGER): INTEGER
			-- Read little-endian 16-bit integer.
		do
			Result := a_buffer[a_offset].to_integer_32 + 
					  a_buffer[a_offset + 1].to_integer_32 |<< 8
		end

	read_int32_le (a_buffer: ARRAY [NATURAL_8]; a_offset: INTEGER): INTEGER
			-- Read little-endian 32-bit integer.
		do
			Result := a_buffer[a_offset].to_integer_32 + 
					  a_buffer[a_offset + 1].to_integer_32 |<< 8 +
					  a_buffer[a_offset + 2].to_integer_32 |<< 16 +
					  a_buffer[a_offset + 3].to_integer_32 |<< 24
		end

	read_sample_16 (a_buffer: SPECIAL [NATURAL_8]; a_offset: INTEGER): INTEGER_16
			-- Read signed 16-bit sample from raw buffer.
		local
			l_val: INTEGER
		do
			l_val := a_buffer[a_offset].to_integer_32 + 
					 a_buffer[a_offset + 1].to_integer_32 |<< 8
			if l_val >= 32768 then
				l_val := l_val - 65536
			end
			Result := l_val.to_integer_16
		end

end
