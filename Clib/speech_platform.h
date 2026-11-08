/*
 * speech_platform.h - memory figures and a millisecond clock for simple_speech,
 * on Windows, macOS and Linux. The Windows bodies are the ones the Eiffel
 * classes used inline before.
 */
#ifndef SPEECH_PLATFORM_H
#define SPEECH_PLATFORM_H

#include <stdint.h>

#if defined(_WIN32)
#include <windows.h>
#include <psapi.h>

/* Physical memory free for use, in bytes. */
static uint64_t speech_available_memory(void) {
	MEMORYSTATUSEX statex;
	statex.dwLength = sizeof(statex);
	GlobalMemoryStatusEx(&statex);
	return (uint64_t) statex.ullAvailPhys;
}

/* Installed physical memory, in bytes. */
static uint64_t speech_total_memory(void) {
	MEMORYSTATUSEX statex;
	statex.dwLength = sizeof(statex);
	GlobalMemoryStatusEx(&statex);
	return (uint64_t) statex.ullTotalPhys;
}

/* This process's working set, in bytes. */
static uint64_t speech_process_memory(void) {
	PROCESS_MEMORY_COUNTERS pmc;
	if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
		return (uint64_t) pmc.WorkingSetSize;
	}
	return 0;
}

/* Milliseconds from a steady clock. */
static int64_t speech_time_ms(void) {
	return (int64_t) GetTickCount64();
}

#else
#include <time.h>
#include <unistd.h>

#if defined(__APPLE__)
#include <sys/sysctl.h>
#include <mach/mach.h>

static uint64_t speech_available_memory(void) {
		/* Free, inactive and purgeable pages: what macOS can hand out without paging. */
	vm_statistics64_data_t l_stats;
	mach_msg_type_number_t l_count = HOST_VM_INFO64_COUNT;
	vm_size_t l_page = 0;
	if (host_page_size(mach_host_self(), &l_page) != KERN_SUCCESS) return 0;
	if (host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t) &l_stats, &l_count) != KERN_SUCCESS) return 0;
	return ((uint64_t) l_stats.free_count + l_stats.inactive_count + l_stats.purgeable_count) * (uint64_t) l_page;
}

static uint64_t speech_total_memory(void) {
	uint64_t l_size = 0;
	size_t l_length = sizeof(l_size);
	if (sysctlbyname("hw.memsize", &l_size, &l_length, NULL, 0) != 0) return 0;
	return l_size;
}

static uint64_t speech_process_memory(void) {
	struct mach_task_basic_info l_info;
	mach_msg_type_number_t l_count = MACH_TASK_BASIC_INFO_COUNT;
	if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t) &l_info, &l_count) != KERN_SUCCESS) return 0;
	return (uint64_t) l_info.resident_size;
}

#else /* Linux */
#include <stdio.h>
#include <string.h>

/* Value of `a_key' in /proc/meminfo, in bytes; 0 when absent. */
static uint64_t speech_meminfo(const char* a_key) {
	FILE* l_file = fopen("/proc/meminfo", "r");
	char l_line[256];
	unsigned long long l_kb = 0;
	size_t l_key_length = strlen(a_key);
	if (!l_file) return 0;
	while (fgets(l_line, sizeof(l_line), l_file)) {
		if (strncmp(l_line, a_key, l_key_length) == 0 && l_line[l_key_length] == ':') {
			sscanf(l_line + l_key_length + 1, "%llu", &l_kb);
			break;
		}
	}
	fclose(l_file);
	return (uint64_t) l_kb * 1024u;
}

static uint64_t speech_available_memory(void) { return speech_meminfo("MemAvailable"); }

static uint64_t speech_total_memory(void) { return speech_meminfo("MemTotal"); }

static uint64_t speech_process_memory(void) {
	FILE* l_file = fopen("/proc/self/statm", "r");
	unsigned long long l_size = 0, l_resident = 0;
	if (!l_file) return 0;
	if (fscanf(l_file, "%llu %llu", &l_size, &l_resident) != 2) l_resident = 0;
	fclose(l_file);
	return (uint64_t) l_resident * (uint64_t) sysconf(_SC_PAGESIZE);
}
#endif

static int64_t speech_time_ms(void) {
	struct timespec l_now;
	clock_gettime(CLOCK_MONOTONIC, &l_now);
	return (int64_t) l_now.tv_sec * 1000 + l_now.tv_nsec / 1000000;
}
#endif

#endif /* SPEECH_PLATFORM_H */
