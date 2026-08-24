// Copyright (C) 2023 M4xw

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 2.0 or later versions.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License 2.0 for more details.

// A copy of the GPL 2.0 should have been included with the program.
// If not, see http://www.gnu.org/licenses/

#include "ppsspp_config.h"
#if PPSSPP_PLATFORM(SWITCH)

#include <stdio.h>
#include <malloc.h> // memalign
#include <string.h> // memset
#include <switch.h>

#include "Common/MemArena.h"

static uintptr_t memoryBase = 0;
static uintptr_t memoryCodeBase = 0;
static uintptr_t memorySrcBase = 0;

// Switch read-alias support.
//
// Horizon svcMapProcessMemory() creates a ProcessMem destination
// alias from memoryCodeBase.  Some CPU reads through that
// ProcessMem alias have faulted on hardware even while
// svcQueryMemory reports the region mapped R/W.
//
// Keep the source alias for each successful view so narrowly
// selected read paths can access the exact same backing bytes.
struct SwitchReadAliasView {
        uintptr_t destination;
        uintptr_t source;
        size_t size;
};

static SwitchReadAliasView switchReadAliasViews[64]{};
static size_t switchReadAliasViewCount = 0;

// SWITCH_READ_ALIAS_LIFECYCLE_05
//
// Remove a readable source-alias record only after the
// corresponding ProcessMem destination view was successfully
// unmapped. This prevents stale aliases from surviving a
// PSP memory teardown/reinitialization cycle.
static void SwitchForgetMappedViewReadAlias(
        const void *address,
        size_t size
) {
        const uintptr_t destination =
                reinterpret_cast<uintptr_t>(address);

        size_t i = 0;

        while (i < switchReadAliasViewCount) {
                const SwitchReadAliasView &view =
                        switchReadAliasViews[i];

                if (view.destination != destination ||
                        view.size != size) {
                        ++i;
                        continue;
                }

                const size_t last =
                        switchReadAliasViewCount - 1;

                if (i != last) {
                        switchReadAliasViews[i] =
                                switchReadAliasViews[last];
                }

                switchReadAliasViews[last] = {};
                --switchReadAliasViewCount;
        }
}


extern "C" const void *SwitchResolveMappedViewReadAlias(
        const void *address
) {
        const uintptr_t value =
                reinterpret_cast<uintptr_t>(address);

        for (size_t i = 0;
                i < switchReadAliasViewCount;
                ++i) {

                const SwitchReadAliasView &view =
                        switchReadAliasViews[i];

                if (value < view.destination) {
                        continue;
                }

                const uintptr_t relative =
                        value - view.destination;

                if (relative >= view.size) {
                        continue;
                }

                return reinterpret_cast<const void *>(
                        view.source + relative
                );
        }

        return nullptr;
}


static void *ReserveVirtmem(size_t size, bool code) {
	virtmemLock();
	void *address = code ? virtmemFindCodeMemory(size, 0x1000) : virtmemFindAslr(size, 0x1000);
	VirtmemReservation *reservation = address ? virtmemAddReservation(address, size) : nullptr;
	virtmemUnlock();
	return reservation ? address : nullptr;
}

size_t MemArena::roundup(size_t x) {
	return x;
}

bool MemArena::NeedsProbing() {
	return false;
}

bool MemArena::GrabMemSpace(size_t size) {
	return true;
}

void MemArena::ReleaseSpace() {
	// Invalidate readable aliases before their source mapping disappears.
	switchReadAliasViewCount = 0;
	if (R_FAILED(svcUnmapProcessCodeMemory(envGetOwnProcessHandle(), (u64)memoryCodeBase, (u64)memorySrcBase, 0x10000000)))
		printf("Failed to release view space...\n");

	free((void *)memorySrcBase);
	memorySrcBase = 0;
}

void *MemArena::CreateView(s64 offset, size_t size, void *base) {
	Result rc = svcMapProcessMemory(base, envGetOwnProcessHandle(), (u64)(memoryCodeBase + offset), size);
	if (R_FAILED(rc)) {
		printf("Fatal error creating the view... base: %p offset: %p size: %p src: %p err: %d\n",
			   (void *)base, (void *)offset, (void *)size, (void *)(memoryCodeBase + offset), rc);
	} else {
		printf("Created the view... base: %p offset: %p size: %p src: %p err: %d\n",
			   (void *)base, (void *)offset, (void *)size, (void *)(memoryCodeBase + offset), rc);
	}


	// Record only successful mappings.
	if (!R_FAILED(rc) &&
			switchReadAliasViewCount <
				sizeof(switchReadAliasViews) /
				sizeof(switchReadAliasViews[0])) {

		SwitchReadAliasView &view =
				switchReadAliasViews[
						switchReadAliasViewCount++
				];

		view.destination =
				reinterpret_cast<uintptr_t>(base);

		view.source =
				memoryCodeBase +
				static_cast<uintptr_t>(offset);

		view.size = size;
	}

	return base;
}

void MemArena::ReleaseView(s64 offset, void *view, size_t size) {
	Result rc = svcUnmapProcessMemory(view, envGetOwnProcessHandle(), (u64)(memoryCodeBase + offset), size);
	if (R_FAILED(rc))
		printf("Failed to unmap view...\n");
	if (R_SUCCEEDED(rc)) {
		SwitchForgetMappedViewReadAlias(view, size);
	}
}

u8 *MemArena::Find4GBBase() {
	switchReadAliasViewCount = 0;
	memorySrcBase = (uintptr_t)memalign(0x1000, 0x10000000);

	// STARTUP_STRIPES_DIAG09_ZERO_BACKING_MEMORY
	// Diagnostic only: remove previous heap contents from
	// the Switch PSP backing allocation on every game boot.
	if (memorySrcBase) {
	        memset((void *)memorySrcBase, 0, 0x10000000);
	}

	if (!memoryBase)
		memoryBase = (uintptr_t)ReserveVirtmem(0x10000000, false);

	if (!memoryCodeBase)
		memoryCodeBase = (uintptr_t)ReserveVirtmem(0x10000000, true);

	if (R_FAILED(svcMapProcessCodeMemory(envGetOwnProcessHandle(), (u64)memoryCodeBase, (u64)memorySrcBase, 0x10000000)))
		printf("Failed to map memory...\n");
	if (R_FAILED(svcSetProcessMemoryPermission(envGetOwnProcessHandle(), memoryCodeBase, 0x10000000, Perm_Rx)))
		printf("Failed to set perms...\n");

	return (u8 *)memoryBase;
}

#endif // PPSSPP_PLATFORM(SWITCH)
