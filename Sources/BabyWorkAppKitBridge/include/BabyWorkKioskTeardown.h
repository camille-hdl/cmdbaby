#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*BabyWorkTeardownDone)(int32_t hidden_count, void *context);

/// Restaure la présentation, masque les couvertures, puis le callback peut débloquer
/// la terminaison. L’appelant enchaîne `-[NSApplication terminate:]`.
/// `windows` : NSArray * de NSWindow, +1 (cette fonction consomme le retain).
/// `tap_port` / `tap_loop` : non consommés.
void BabyWorkScheduleKioskTeardown(
  void *windows,
  uint64_t presentation_raw,
  void *tap_port,
  void *tap_loop,
  BabyWorkTeardownDone done,
  void *context
);

#ifdef __cplusplus
}
#endif
