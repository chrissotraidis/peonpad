#include "PeonPadControlGroupLayout.h"

bool PeonPadCalculateControlGroupLayout(const int logicalWidth,
	                                    const int logicalHeight,
	                                    PeonPadControlGroupRects &rects)
{
	if (logicalWidth != PeonPadGameplayWidth || logicalHeight != PeonPadGameplayHeight) {
		return false;
	}

	constexpr int railWidth = 176;
	constexpr int bankTop = 480;
	constexpr int rowHeight = 60;
	constexpr int columns = 5;
	constexpr std::array<int, PeonPadControlGroupCount> groupOrder = {
		1, 2, 3, 4, 5,
		6, 7, 8, 9, 0,
	};

	for (int slot = 0; slot < PeonPadControlGroupCount; ++slot) {
		const int column = slot % columns;
		const int row = slot / columns;
		const int left = column * railWidth / columns;
		const int right = (column + 1) * railWidth / columns;
		rects[groupOrder[slot]] = {left, bankTop + row * rowHeight,
		                           right - left, rowHeight};
	}
	return true;
}

int PeonPadControlGroupAt(const PeonPadControlGroupRects &rects,
	                     const int x,
	                     const int y)
{
	for (int group = 0; group < PeonPadControlGroupCount; ++group) {
		if (rects[group].Contains(x, y)) {
			return group;
		}
	}
	return -1;
}
