#include "PeonPadControlGroupLayout.h"

#include <cassert>

int main()
{
	PeonPadControlGroupRects rects;
	assert(!PeonPadCalculateControlGroupLayout(640, 480, rects));
	assert(PeonPadCalculateControlGroupLayout(800, 600, rects));

	for (int group = 0; group < PeonPadControlGroupCount; ++group) {
		const auto &rect = rects[group];
		assert(rect.x >= 0);
		assert(rect.y >= 480);
		assert(rect.x + rect.width <= 176);
		assert(rect.y + rect.height <= 600);
		assert(PeonPadControlGroupAt(rects,
		                             rect.x + rect.width / 2,
		                             rect.y + rect.height / 2) == group);
	}

	assert(rects[1].y == rects[5].y);
	assert(rects[6].y == rects[0].y);
	assert(rects[5].x > rects[1].x);
	assert(rects[0].x > rects[9].x);
	assert(PeonPadControlGroupAt(rects, 176, 599) == -1);
	assert(PeonPadControlGroupAt(rects, 20, 479) == -1);
	return 0;
}
