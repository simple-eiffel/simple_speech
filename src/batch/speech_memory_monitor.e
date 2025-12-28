note
	description: "[
		SPEECH_MEMORY_MONITOR - Memory monitoring for batch processing.
		
		Measures available system memory and calculates safe concurrency levels
		for memory-constrained batch processing. Uses Windows API via inline C.
		
		Key features:
		- Measure available physical memory
		- Estimate whisper model memory footprint
		- Calculate safe number of parallel I/O workers
		- Detect memory pressure conditions
		
		Example:
			create monitor.make
			if monitor.get_available_memory < 4_000_000_000 then
				print ("Low memory warning%N")
			end
			io_workers := monitor.calculate_safe_io_workers
	]"
	author: "Larry Rix"

class
	SPEECH_MEMORY_MONITOR

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize memory monitor.
		do
			whisper_model_estimate_mb := 500  -- Base model ~500MB
			memory_per_worker_mb := 50        -- Each I/O worker ~50MB
			min_free_memory_mb := 1024        -- Keep at least 1GB free
		end

feature -- Access

	get_available_memory: NATURAL_64
			-- Get available physical memory in bytes.
		do
			Result := c_get_available_memory
		end

	get_total_memory: NATURAL_64
			-- Get total physical memory in bytes.
		do
			Result := c_get_total_memory
		end

	get_process_memory: NATURAL_64
			-- Get current process memory usage in bytes.
		do
			Result := c_get_process_memory
		end

	get_available_memory_mb: INTEGER
			-- Get available physical memory in megabytes.
		do
			Result := (get_available_memory // 1_048_576).to_integer_32
		end

	get_total_memory_mb: INTEGER
			-- Get total physical memory in megabytes.
		do
			Result := (get_total_memory // 1_048_576).to_integer_32
		end

	get_process_memory_mb: INTEGER
			-- Get current process memory usage in megabytes.
		do
			Result := (get_process_memory // 1_048_576).to_integer_32
		end

feature -- Configuration

	whisper_model_estimate_mb: INTEGER
			-- Estimated memory for whisper model in MB.

	memory_per_worker_mb: INTEGER
			-- Estimated memory per I/O worker in MB.

	min_free_memory_mb: INTEGER
			-- Minimum free memory to maintain in MB.

	set_whisper_model_estimate (a_mb: INTEGER)
			-- Set estimated whisper model size.
		require
			positive: a_mb > 0
		do
			whisper_model_estimate_mb := a_mb
		ensure
			set: whisper_model_estimate_mb = a_mb
		end

	set_memory_per_worker (a_mb: INTEGER)
			-- Set estimated memory per worker.
		require
			positive: a_mb > 0
		do
			memory_per_worker_mb := a_mb
		ensure
			set: memory_per_worker_mb = a_mb
		end

	set_min_free_memory (a_mb: INTEGER)
			-- Set minimum free memory to maintain.
		require
			positive: a_mb > 0
		do
			min_free_memory_mb := a_mb
		ensure
			set: min_free_memory_mb = a_mb
		end

feature -- Calculation

	calculate_safe_io_workers: INTEGER
			-- Calculate safe number of parallel I/O workers based on available memory.
			-- Returns 1-8 workers.
		local
			l_available_mb, l_usable_mb: INTEGER
		do
			l_available_mb := get_available_memory_mb
			
			-- Subtract whisper model and minimum free memory
			l_usable_mb := l_available_mb - whisper_model_estimate_mb - min_free_memory_mb
			
			if l_usable_mb <= 0 then
				Result := 1  -- Minimal mode
			else
				Result := (l_usable_mb // memory_per_worker_mb).min (8)
				if Result < 1 then
					Result := 1
				end
			end
		ensure
			valid_range: Result >= 1 and Result <= 8
		end

	recommend_batch_size: INTEGER
			-- Recommend number of files to queue at once.
			-- Based on available memory, recommends 5-50 files.
		local
			l_available_mb: INTEGER
		do
			l_available_mb := get_available_memory_mb
			
			if l_available_mb < 4096 then
				Result := 5   -- Low memory: small batches
			elseif l_available_mb < 8192 then
				Result := 10  -- Medium memory
			elseif l_available_mb < 16384 then
				Result := 25  -- Good memory
			else
				Result := 50  -- Plenty of memory
			end
		ensure
			valid_range: Result >= 5 and Result <= 50
		end

	is_memory_pressure: BOOLEAN
			-- Is system under memory pressure? (< 20% free)
		local
			l_available, l_total: NATURAL_64
		do
			l_available := get_available_memory
			l_total := get_total_memory
			
			if l_total > 0 then
				Result := (l_available * 100 // l_total) < 20
			end
		end

	memory_percentage_free: INTEGER
			-- Percentage of memory currently free.
		local
			l_available, l_total: NATURAL_64
		do
			l_available := get_available_memory
			l_total := get_total_memory
			
			if l_total > 0 then
				Result := (l_available * 100 // l_total).to_integer_32
			end
		ensure
			valid_range: Result >= 0 and Result <= 100
		end

feature -- Reporting

	memory_status_string: STRING_8
			-- Human-readable memory status.
		do
			create Result.make (100)
			Result.append ("Available: ")
			Result.append (get_available_memory_mb.out)
			Result.append (" MB / ")
			Result.append (get_total_memory_mb.out)
			Result.append (" MB (")
			Result.append (memory_percentage_free.out)
			Result.append ("%% free)")
			if is_memory_pressure then
				Result.append (" [PRESSURE]")
			end
		end

	recommended_settings_string: STRING_8
			-- Human-readable recommended settings.
		do
			create Result.make (100)
			Result.append ("IO Workers: ")
			Result.append (calculate_safe_io_workers.out)
			Result.append (", Batch Size: ")
			Result.append (recommend_batch_size.out)
		end

feature {NONE} -- C externals (Windows API)

	c_get_available_memory: NATURAL_64
			-- Get available physical memory via Windows API.
		external
			"C inline use <windows.h>"
		alias
			"[
				MEMORYSTATUSEX statex;
				statex.dwLength = sizeof(statex);
				GlobalMemoryStatusEx(&statex);
				return (EIF_NATURAL_64)statex.ullAvailPhys;
			]"
		end

	c_get_total_memory: NATURAL_64
			-- Get total physical memory via Windows API.
		external
			"C inline use <windows.h>"
		alias
			"[
				MEMORYSTATUSEX statex;
				statex.dwLength = sizeof(statex);
				GlobalMemoryStatusEx(&statex);
				return (EIF_NATURAL_64)statex.ullTotalPhys;
			]"
		end

	c_get_process_memory: NATURAL_64
			-- Get current process memory usage via Windows API.
		external
			"C inline use <windows.h>, <psapi.h>"
		alias
			"[
				PROCESS_MEMORY_COUNTERS pmc;
				if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
					return (EIF_NATURAL_64)pmc.WorkingSetSize;
				}
				return 0;
			]"
		end

invariant
	positive_estimates: whisper_model_estimate_mb > 0 and 
	                    memory_per_worker_mb > 0 and 
	                    min_free_memory_mb > 0

end
