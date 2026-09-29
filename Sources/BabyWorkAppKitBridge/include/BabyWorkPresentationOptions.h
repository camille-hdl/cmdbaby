#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Applique `NSApp.presentationOptions`. Retourne false (et journalise la raison
/// via os_log, subsystem "fr.camille.babywork", category "Presentation")
/// si AppKit rejette la combinaison ; ne lève jamais.
bool BabyWorkTrySetPresentationOptions(uint64_t raw);

#ifdef __cplusplus
}
#endif
