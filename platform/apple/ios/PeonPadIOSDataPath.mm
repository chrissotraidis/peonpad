#include "PeonPadIOSDataPath.h"

#include <SDL.h>
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <sys/utsname.h>

#include <cstdio>
#include <fstream>
#include <regex>
#include <vector>

namespace {

std::string LogPath;

NSURL *DocumentsURL()
{
	return [[[NSFileManager defaultManager]
		URLsForDirectory:NSDocumentDirectory
		inDomains:NSUserDomainMask] firstObject];
}

// Makes an engine error readable on screen: container paths become
// "data.Wargus/...", each engine source location starts a new line and is
// dropped, and only the last few lines are kept.
std::string ReadableError(std::string text, size_t maxLines)
{
	const size_t traceback = text.find("stack traceback:");
	if (traceback != std::string::npos) {
		text.erase(traceback);
	}
	text = std::regex_replace(text, std::regex(R"([^\s'"]*/data\.Wargus/)"), "data.Wargus/");
	// ErrorPrint prefixes come from __FILE__ (relative after -ffile-prefix-map)
	// and may follow a message that has no trailing newline.
	text = std::regex_replace(text, std::regex(R"((engine/stratagus/)?src/[^\s:]+:\d+: \w+: )"), "\n");

	std::vector<std::string> lines;
	size_t start = 0;
	while (start <= text.size()) {
		size_t end = text.find('\n', start);
		if (end == std::string::npos) {
			end = text.size();
		}
		std::string line = text.substr(start, end - start);
		if (line.find_first_not_of(" \t\r") != std::string::npos) {
			lines.push_back(line);
		}
		start = end + 1;
	}
	std::string result;
	const size_t first = lines.size() > maxLines ? lines.size() - maxLines : 0;
	for (size_t i = first; i < lines.size(); ++i) {
		result += (result.empty() ? "" : "\n") + lines[i];
	}
	return result;
}

std::string LogText()
{
	std::ifstream file(LogPath);
	return std::string(std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>());
}

} // namespace

std::string PeonPadIOSDocumentsGameDataPath()
{
	NSURL *documents = DocumentsURL();
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

void PeonPadIOSStartLog()
{
	NSURL *documents = DocumentsURL();
	if (!documents) {
		return;
	}
	NSURL *log = [documents URLByAppendingPathComponent:@"PeonPad.log"];
	NSURL *previous = [documents URLByAppendingPathComponent:@"PeonPad.previous.log"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtURL:previous error:nil];
	[fileManager moveItemAtURL:log toURL:previous error:nil];

	const char *path = log.fileSystemRepresentation;
	if (!path || !std::ofstream(path)) {
		return;
	}
	// Both streams append, so their lines interleave instead of overwriting.
	if (!freopen(path, "a", stderr) || !freopen(path, "a", stdout)) {
		return;
	}
	setvbuf(stdout, nullptr, _IOLBF, 0);
	setvbuf(stderr, nullptr, _IONBF, 0);
	LogPath = path;

	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	struct utsname system;
	uname(&system);
	printf("PeonPad %s (%s) on %s, iOS %s\n",
	       [info[@"CFBundleShortVersionString"] UTF8String] ?: "?",
	       [info[@"CFBundleVersion"] UTF8String] ?: "?",
	       system.machine,
	       [[[UIDevice currentDevice] systemVersion] UTF8String] ?: "?");
}

void PeonPadIOSShowFatalError(const char *detail)
{
	static bool shown = false;
	if (shown) {
		return;
	}
	shown = true;
	fflush(stdout);
	fflush(stderr);

	std::string problem = ReadableError(detail && *detail ? detail : LogText(), 2);
	if (problem.size() > 500) {
		problem = "..." + problem.substr(problem.size() - 500);
	}
	std::string message = "PeonPad had to stop.";
	if (!problem.empty()) {
		message += "\n\n" + problem;
	}
	message +=
		"\n\nIf this mentions a missing or bad file, copy your complete "
		"data.Wargus folder again.\n\n"
		"Details are saved in PeonPad.log in the PeonPad folder in Files.";
	SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "PeonPad stopped",
	                         message.c_str(), nullptr);
}
