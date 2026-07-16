#pragma once

#include <array>

constexpr int PeonPadControlGroupCount = 10;
constexpr int PeonPadGameplayWidth = 800;
constexpr int PeonPadGameplayHeight = 600;

struct PeonPadControlGroupRect {
	int x = 0;
	int y = 0;
	int width = 0;
	int height = 0;

	bool Contains(int px, int py) const
	{
		return x <= px && px < x + width && y <= py && py < y + height;
	}
};

using PeonPadControlGroupRects =
	std::array<PeonPadControlGroupRect, PeonPadControlGroupCount>;

bool PeonPadCalculateControlGroupLayout(int logicalWidth,
	                                    int logicalHeight,
	                                    PeonPadControlGroupRects &rects);
int PeonPadControlGroupAt(const PeonPadControlGroupRects &rects, int x, int y);
