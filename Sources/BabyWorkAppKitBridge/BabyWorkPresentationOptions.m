#import "BabyWorkPresentationOptions.h"

#import <AppKit/AppKit.h>
#import <os/log.h>

static os_log_t BabyWorkPresentationLog(void) {
  static os_log_t log;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    log = os_log_create("app.cmdbaby.CmdBaby", "Presentation");  // AppIdentity.logSubsystem
  });
  return log;
}

bool BabyWorkTrySetPresentationOptions(uint64_t raw) {
  @try {
    NSApp.presentationOptions = (NSApplicationPresentationOptions)raw;
    return true;
  } @catch (NSException *exception) {
    os_log_error(BabyWorkPresentationLog(), "%{public}@", exception.reason);
    return false;
  }
}
