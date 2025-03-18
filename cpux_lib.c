// cpux_lib.c

#include "cpux_lib.h"
#include <sys/sysctl.h>
#include <stdlib.h>
#include <string.h>

CPUInfo* getCPUInfo() {
    CPUInfo* info = (CPUInfo*)malloc(sizeof(CPUInfo));
    if (!info) return NULL;

    memset(info, 0, sizeof(CPUInfo));

    size_t size = sizeof(info->model);
    if (sysctlbyname("hw.machine", &info->model, &size, NULL, 0) != 0) {
        strncpy(info->model, "Unknown", sizeof(info->model) - 1);
    }

    int coreCount;
    size = sizeof(coreCount);
    if (sysctlbyname("hw.ncpu", &coreCount, &size, NULL, 0) == 0){
        info->coreCount = coreCount;
        info->threadCount = coreCount;
    }

    return info;
}

void freeCPUInfo(CPUInfo* info) {
    free(info);
}

MemoryInfo* getMemoryInfo() {
    MemoryInfo* memInfo = (MemoryInfo*)malloc(sizeof(MemoryInfo));
    if (!memInfo) return NULL;

    int mib[] = {CTL_HW, HW_MEMSIZE};
    size_t length = sizeof(memInfo->totalMemory);
    if (sysctl(mib, 2, &memInfo->totalMemory, &length, NULL, 0) != 0) {
        free(memInfo);
        return NULL;
    }

    return memInfo;
}

void freeMemoryInfo(MemoryInfo* info) {
    free(info);
}