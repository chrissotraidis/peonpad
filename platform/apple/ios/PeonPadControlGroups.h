#pragma once

#include <cstdint>

bool PeonPadControlGroupsPointerDown(std::int64_t pointerId,
	                                int x,
	                                int y,
	                                std::uint32_t ticks);
bool PeonPadControlGroupsPointerMove(std::int64_t pointerId, int x, int y);
bool PeonPadControlGroupsPointerUp(std::int64_t pointerId,
	                              int x,
	                              int y,
	                              std::uint32_t ticks);
void PeonPadControlGroupsCancel();
void PeonPadControlGroupsReset();
void PeonPadControlGroupsUpdate(std::uint32_t ticks);
void PeonPadDrawControlGroups();
