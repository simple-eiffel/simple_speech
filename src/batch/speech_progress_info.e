note
	description: "[
		SPEECH_PROGRESS_INFO - Progress tracking for batch processing.
	]"
	author: "Larry Rix"

class
	SPEECH_PROGRESS_INFO

create
	make

feature {NONE} -- Initialization

	make
		do
			current_file := ""
			current_phase := "idle"
			create start_time.make_now
		end

feature -- Access

	current_file: STRING_32
	current_file_index: INTEGER
	total_files: INTEGER
	bytes_processed: NATURAL_64
	bytes_total: NATURAL_64

	elapsed_seconds: REAL_64
		local
			l_now: DATE_TIME
		do
			create l_now.make_now
			Result := l_now.definite_duration (start_time).seconds_count.to_double
		end

	estimated_remaining_seconds: REAL_64
		local
			l_remaining, l_current: REAL_64
		do
			if current_file_index > 0 and then elapsed_seconds > 0 then
				if bytes_total > 0 and then bytes_processed > 0 then
					Result := elapsed_seconds * ((bytes_total - bytes_processed).to_real_64 / bytes_processed.to_real_64)
				elseif total_files > 0 then
					l_remaining := (total_files - current_file_index) * 1.0
					l_current := current_file_index * 1.0
					Result := elapsed_seconds * (l_remaining / l_current)
				end
			end
		end

	current_phase: STRING_8
	memory_usage_mb: INTEGER
	files_succeeded: INTEGER
	files_failed: INTEGER

feature -- Status

	percentage_complete: REAL_64
		local
			l_idx, l_tot: REAL_64
		do
			if bytes_total > 0 then
				Result := (bytes_processed.to_real_64 / bytes_total.to_real_64) * 100.0
			elseif total_files > 0 then
				l_idx := current_file_index * 1.0
				l_tot := total_files * 1.0
				Result := (l_idx / l_tot) * 100.0
			end
		ensure
			valid_range: Result >= 0 and Result <= 100
		end

	is_complete: BOOLEAN
		do
			Result := current_file_index >= total_files and total_files > 0
		end

	formatted_eta: STRING_8
		local
			l_secs, l_mins, l_hours, l_rem: INTEGER
		do
			l_secs := estimated_remaining_seconds.truncated_to_integer
			if l_secs < 60 then
				Result := l_secs.out + "s"
			elseif l_secs < 3600 then
				l_mins := l_secs // 60
				l_rem := l_secs - (l_mins * 60)
				Result := l_mins.out + "m " + l_rem.out + "s"
			else
				l_hours := l_secs // 3600
				l_mins := (l_secs - (l_hours * 3600)) // 60
				Result := l_hours.out + "h " + l_mins.out + "m"
			end
		end

	formatted_elapsed: STRING_8
		local
			l_secs, l_mins, l_hours, l_rem: INTEGER
		do
			l_secs := elapsed_seconds.truncated_to_integer
			if l_secs < 60 then
				Result := l_secs.out + "s"
			elseif l_secs < 3600 then
				l_mins := l_secs // 60
				l_rem := l_secs - (l_mins * 60)
				Result := l_mins.out + "m " + l_rem.out + "s"
			else
				l_hours := l_secs // 3600
				l_mins := (l_secs - (l_hours * 3600)) // 60
				Result := l_hours.out + "h " + l_mins.out + "m"
			end
		end

feature -- Element change

	set_current_file (a_file: READABLE_STRING_GENERAL; a_index: INTEGER)
		require
			valid_index: a_index >= 1 and a_index <= total_files
		do
			current_file := a_file.to_string_32
			current_file_index := a_index
		end

	set_total_files (a_count: INTEGER)
		require
			positive: a_count > 0
		do
			total_files := a_count
		end

	set_bytes (a_processed, a_total: NATURAL_64)
		do
			bytes_processed := a_processed
			bytes_total := a_total
		end

	add_bytes_processed (a_bytes: NATURAL_64)
		do
			bytes_processed := bytes_processed + a_bytes
		end

	set_phase (a_phase: STRING_8)
		require
			valid_phase: a_phase.same_string ("extracting") or 
			             a_phase.same_string ("transcribing") or 
			             a_phase.same_string ("exporting") or
			             a_phase.same_string ("idle")
		do
			current_phase := a_phase
		end

	set_memory_usage (a_mb: INTEGER)
		require
			non_negative: a_mb >= 0
		do
			memory_usage_mb := a_mb
		end

	increment_succeeded
		do
			files_succeeded := files_succeeded + 1
		end

	increment_failed
		do
			files_failed := files_failed + 1
		end

	reset
		do
			current_file := ""
			current_file_index := 0
			total_files := 0
			bytes_processed := 0
			bytes_total := 0
			current_phase := "idle"
			memory_usage_mb := 0
			files_succeeded := 0
			files_failed := 0
			create start_time.make_now
		end

feature {NONE} -- Implementation

	start_time: DATE_TIME

invariant
	current_file_attached: current_file /= Void
	current_phase_attached: current_phase /= Void
	valid_index: current_file_index >= 0 and current_file_index <= total_files
	non_negative_memory: memory_usage_mb >= 0

end
