#include "PeonPadGameDataPath.h"

#include <cstdio>
#include <filesystem>
#include <fstream>

namespace {

bool SetFailure(std::string *reason, const std::string &message)
{
	if (reason) {
		*reason = message;
	}
	return false;
}

// wartool writes its version to data.Wargus/extracted. Wargus 3.1 and older
// ship scripts that call engine functions PeonPad's Stratagus no longer has
// (SetFogOfWarOpacity became SetFogOfWarOpacityLevels in 3.2), so that data
// stops at its first script error. Unreadable or newer versions are accepted.
bool IsTooOldExtraction(const std::filesystem::path &marker, std::string &version)
{
	std::ifstream file(marker);
	std::getline(file, version);
	while (!version.empty() && (version.back() == '\r' || version.back() == ' ')) {
		version.pop_back();
	}
	int major = 0;
	int minor = 0;
	if (std::sscanf(version.c_str(), "%d.%d", &major, &minor) != 2) {
		return false;
	}
	return major < 3 || (major == 3 && minor < 2);
}

} // namespace

bool PeonPadValidateGameDataPath(const std::string &path, std::string *reason)
{
	if (path.empty()) {
		return SetFailure(reason, "the game-data path is unavailable");
	}

	const std::filesystem::path root(path);
	std::error_code error;
	if (!std::filesystem::is_directory(root, error)) {
		return SetFailure(reason, "data.Wargus is missing");
	}

	for (const char *file : {"scripts/stratagus.lua", "extracted"}) {
		error.clear();
		if (!std::filesystem::is_regular_file(root / file, error)) {
			return SetFailure(reason, std::string("data.Wargus is missing ") + file);
		}
	}

	for (const char *directory : {"graphics", "maps", "sounds"}) {
		error.clear();
		if (!std::filesystem::is_directory(root / directory, error)) {
			return SetFailure(reason, std::string("data.Wargus is missing ") + directory + "/");
		}
	}

	std::string version;
	if (IsTooOldExtraction(root / "extracted", version)) {
		return SetFailure(reason,
			"data.Wargus was made with Wargus " + version +
			", which PeonPad can't run. Extract your game again with Wargus 3.2 "
			"or newer, or with PeonPad's scripts/prepare-ipad-build.sh.");
	}

	if (reason) {
		reason->clear();
	}
	return true;
}

std::string PeonPadSelectGameDataPath(const std::string &documentsPath,
                                      const std::string &bundledPath,
                                      std::string *reason)
{
	std::string documentsReason;
	if (PeonPadValidateGameDataPath(documentsPath, &documentsReason)) {
		if (reason) {
			reason->clear();
		}
		return documentsPath;
	}

	if (PeonPadValidateGameDataPath(bundledPath, nullptr)) {
		if (reason) {
			reason->clear();
		}
		return bundledPath;
	}

	if (reason) {
		*reason = documentsReason;
	}
	return {};
}
