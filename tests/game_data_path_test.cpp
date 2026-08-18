#include "PeonPadGameDataPath.h"

#include <cassert>
#include <filesystem>
#include <fstream>
#include <string>

namespace fs = std::filesystem;

static void CreateValidData(const fs::path &root)
{
	fs::create_directories(root / "scripts");
	fs::create_directories(root / "graphics");
	fs::create_directories(root / "maps");
	fs::create_directories(root / "sounds");
	std::ofstream(root / "scripts/stratagus.lua") << "-- fixture\n";
	std::ofstream(root / "extracted") << "fixture\n";
}

int main(int argc, char **argv)
{
	assert(argc == 2);
	const fs::path root(argv[1]);
	const fs::path documents = root / "Documents/data.Wargus";
	const fs::path bundled = root / "PeonPad.app/Aleona";
	fs::remove_all(root);

	std::string reason;
	assert(PeonPadSelectGameDataPath(documents.string(), bundled.string(), &reason).empty());
	assert(reason == "data.Wargus is missing");

	CreateValidData(bundled);
	assert(PeonPadSelectGameDataPath(documents.string(), bundled.string(), &reason)
	       == bundled.string());
	assert(reason.empty());

	CreateValidData(documents);
	assert(PeonPadSelectGameDataPath(documents.string(), bundled.string(), &reason)
	       == documents.string());

	fs::remove(documents / "sounds");
	assert(PeonPadSelectGameDataPath(documents.string(), "", &reason).empty());
	assert(reason == "data.Wargus is missing sounds/");

	fs::remove_all(root);
	return 0;
}
