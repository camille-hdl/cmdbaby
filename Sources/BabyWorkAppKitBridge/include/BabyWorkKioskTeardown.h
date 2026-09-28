#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*BabyWorkTeardownDone)(int32_t hidden_count, void *context);

/// Restaure la présentation et masque les couvertures.
/// `should_quit` : si vrai, enchaîne `-[NSApplication terminate:]` après le démontage.
/// Une sortie adulte passe faux : le process reste vivant.
/// `windows` : NSArray * de NSWindow, +1 (cette fonction consomme le retain).
/// `tap_port` / `tap_loop` : non consommés.
void BabyWorkScheduleKioskTeardown(
  void *windows,
  uint64_t presentation_raw,
  void *tap_port,
  void *tap_loop,
  bool should_quit,
  BabyWorkTeardownDone done,
  void *context
);

#ifdef __cplusplus
}
#endif
