#pragma once

#include <string>

std::string PeonPadIOSDocumentsGameDataPath();
std::string PeonPadIOSBundledGameDataPath();
void PeonPadIOSShowGameDataSetupMessage(const std::string &reason);

// Sends engine output to Documents/PeonPad.log (the previous launch is kept as
// PeonPad.previous.log) so players can attach it to a report from Files.
void PeonPadIOSStartLog();

// Shows why the engine is about to quit. Without this, a Lua error or fatal
// engine error closes the app with no message. A null or empty detail uses the
// last lines of PeonPad.log.
void PeonPadIOSShowFatalError(const char *detail);
