#include "PeonPadIOSDataPath.h"

#include <SDL.h>
#include <Foundation/Foundation.h>

std::string PeonPadIOSDocumentsGameDataPath()
{
	NSURL *documents = [[[NSFileManager defaultManager]
		URLsForDirectory:NSDocumentDirectory
		inDomains:NSUserDomainMask] firstObject];
	if (!documents) {
		return {};
	}
	NSURL *data = [documents URLByAppendingPathComponent:@"data.Wargus" isDirectory:YES];
	return data.fileSystemRepresentation ?: "";
}

std::string PeonPadIOSBundledGameDataPath()
{
	char *basePath = SDL_GetBasePath();
	if (!basePath) {
		return {};
	}
	NSString *base = [NSString stringWithUTF8String:basePath];
	SDL_free(basePath);
	if (!base) {
		return {};
	}
	return [[base stringByAppendingPathComponent:@"Aleona"] fileSystemRepresentation];
}

void PeonPadIOSShowGameDataSetupMessage(const std::string &reason)
{
	std::string message =
		"PeonPad does not include Warcraft II game data.\n\n"
		"Copy your complete data.Wargus folder to:\n"
		"On My iPad > PeonPad > data.Wargus\n\n"
		"Then relaunch PeonPad.";
	if (!reason.empty()) {
		message += "\n\nProblem: " + reason;
	}
	SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Warcraft II data required",
	                         message.c_str(), nullptr);
}
