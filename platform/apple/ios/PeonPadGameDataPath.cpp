#include "PeonPadGameDataPath.h"

#include <filesystem>

namespace {

bool SetFailure(std::string *reason, const std::string &message)
{
	if (reason) {
		*reason = message;
	}
	return false;
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
