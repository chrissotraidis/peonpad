#include "PeonPadControlGroups.h"

#include "PeonPadControlGroupLayout.h"

#include "font.h"
#include "interface.h"
#include "ui.h"
#include "unit.h"
#include "video.h"

#include <cmath>
#include <string>

namespace {

constexpr std::uint32_t AssignDelay = 500;
constexpr int MovementTolerance = 12;
constexpr int NoPointer = -1;

struct ControlGroupPointerState {
	bool active = false;
	bool cancelled = false;
	bool assigned = false;
	std::int64_t pointerId = NoPointer;
	int group = -1;
	int startX = 0;
	int startY = 0;
	std::uint32_t startTicks = 0;
	int lastTapGroup = -1;
	std::uint32_t lastTapTicks = 0;
};

ControlGroupPointerState PointerState;

bool GetLayout(PeonPadControlGroupRects &rects)
{
	return PeonPadCalculateControlGroupLayout(Video.Width, Video.Height, rects);
}

void SetGroupStatus(const int group, const std::string &message)
{
	UI.StatusLine.Set("Group " + std::to_string(group) + message);
}

void AssignGroup()
{
	if (!UiAssignControlGroup(PointerState.group)) {
		UI.StatusLine.Set("Select units before assigning Group "
		                  + std::to_string(PointerState.group));
	} else {
		const std::size_t unitCount = GetUnitsOfGroup(PointerState.group).size();
		SetGroupStatus(PointerState.group,
		               " assigned: "
		               + std::to_string(unitCount)
		               + (unitCount == 1 ? " unit" : " units"));
	}
	PointerState.assigned = true;
}

void UpdateMovement(const int x, const int y)
{
	if (std::abs(x - PointerState.startX) > MovementTolerance
	    || std::abs(y - PointerState.startY) > MovementTolerance) {
		PointerState.cancelled = true;
	}
}

void DrawButton(const PeonPadControlGroupRect &hitRect,
	            const int group,
	            const bool assigned,
	            const bool pressed)
{
	constexpr int horizontalInset = 3;
	constexpr int verticalInset = 8;
	const int offset = pressed ? 1 : 0;
	const int x = hitRect.x + horizontalInset;
	const int y = hitRect.y + verticalInset;
	const int width = hitRect.width - horizontalInset * 2;
	const int height = hitRect.height - verticalInset * 2;

	const Uint32 black = Video.MapRGB(TheScreen->format, 8, 8, 8);
	const Uint32 edge = Video.MapRGB(TheScreen->format, 108, 108, 104);
	const Uint32 face = Video.MapRGB(TheScreen->format, 34, 34, 32);
	const Uint32 gold = Video.MapRGB(TheScreen->format, 214, 166, 43);

	Video.FillRectangleClip(black, x, y, width, height);
	Video.DrawRectangleClip(assigned ? gold : edge, x + 1, y + 1,
	                        width - 2, height - 2);
	Video.FillRectangleClip(face, x + 3, y + 3, width - 6, height - 6);
	if (pressed) {
		Video.DrawRectangleClip(black, x + 2, y + 2, width - 4, height - 4);
	}

	CLabel label(GetGameFont());
	label.SetNormalColor(assigned ? FontYellow : FontGrey);
	label.DrawCentered(x + width / 2 + offset,
	                   y + (height - label.Height()) / 2 + offset,
	                   std::to_string(group));
}

} // namespace

bool PeonPadControlGroupsPointerDown(const std::int64_t pointerId,
	                                const int x,
	                                const int y,
	                                const std::uint32_t ticks)
{
	PeonPadControlGroupRects rects;
	if (!GameRunning || GameObserve || PointerState.active || !GetLayout(rects)) {
		return false;
	}

	const int group = PeonPadControlGroupAt(rects, x, y);
	if (group < 0) {
		return false;
	}

	PointerState.active = true;
	PointerState.cancelled = false;
	PointerState.assigned = false;
	PointerState.pointerId = pointerId;
	PointerState.group = group;
	PointerState.startX = x;
	PointerState.startY = y;
	PointerState.startTicks = ticks;
	return true;
}

bool PeonPadControlGroupsPointerMove(const std::int64_t pointerId,
	                                const int x,
	                                const int y)
{
	if (!PointerState.active || PointerState.pointerId != pointerId) {
		return false;
	}
	UpdateMovement(x, y);
	return true;
}

bool PeonPadControlGroupsPointerUp(const std::int64_t pointerId,
	                              const int x,
	                              const int y,
	                              const std::uint32_t ticks)
{
	if (!PointerState.active || PointerState.pointerId != pointerId) {
		return false;
	}

	UpdateMovement(x, y);
	if (!PointerState.cancelled && !PointerState.assigned) {
		if (ticks - PointerState.startTicks >= AssignDelay) {
			AssignGroup();
		} else if (GetUnitsOfGroup(PointerState.group).empty()) {
			SetGroupStatus(PointerState.group, " is empty");
		} else {
			const bool center = PointerState.lastTapGroup == PointerState.group
			                    && ticks - PointerState.lastTapTicks <= DoubleClickDelay;
			UiSelectControlGroup(PointerState.group, center);
			PointerState.lastTapGroup = PointerState.group;
			PointerState.lastTapTicks = ticks;
		}
	}

	PointerState.active = false;
	PointerState.pointerId = NoPointer;
	PointerState.group = -1;
	return true;
}

void PeonPadControlGroupsCancel()
{
	PointerState.cancelled = true;
}

void PeonPadControlGroupsReset()
{
	PointerState = {};
}

void PeonPadControlGroupsUpdate(const std::uint32_t ticks)
{
	if (PointerState.active && !PointerState.cancelled && !PointerState.assigned
	    && ticks - PointerState.startTicks >= AssignDelay) {
		AssignGroup();
	}
}

void PeonPadDrawControlGroups()
{
	PeonPadControlGroupRects rects;
	if (!GameRunning || GameObserve || !GetLayout(rects) || !IsGameFontReady()) {
		return;
	}

	for (int group = 0; group < PeonPadControlGroupCount; ++group) {
		const bool assigned = !GetUnitsOfGroup(group).empty();
		const bool pressed = PointerState.active && !PointerState.cancelled
		                     && PointerState.group == group;
		DrawButton(rects[group], group, assigned, pressed);
	}
}
