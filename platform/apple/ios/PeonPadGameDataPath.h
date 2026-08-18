#pragma once

#include <string>

bool PeonPadValidateGameDataPath(const std::string &path, std::string *reason = nullptr);

std::string PeonPadSelectGameDataPath(const std::string &documentsPath,
                                      const std::string &bundledPath,
                                      std::string *reason = nullptr);
