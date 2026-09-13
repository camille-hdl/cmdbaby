#import "BabyWorkKioskTeardown.h"

#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <CoreFoundation/CoreFoundation.h>
#import <os/log.h>

static os_log_t BabyWorkTeardownLog(void) {
  static os_log_t log;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    log = os_log_create("fr.camille.babywork.diagnostics", "KioskTeardown");
  });
  return log;
}

static NSString *BabyWorkWindowIdentifier(NSWindow *window) {
  id identifier = window.identifier;
  if ([identifier isKindOfClass:[NSString class]]) {
    return (NSString *)identifier;
  }
  return @"";
}

static void BabyWorkHideWindow(NSWindow *window) {
  window.ignoresMouseEvents = YES;
  window.alphaValue = 0;
  window.level = NSNormalWindowLevel;
  [window orderOut:nil];
}

static int32_t BabyWorkPerformTeardown(
  NSArray *windows,
  uint64_t presentationRaw,
  CFMachPortRef port,
  CFRunLoopRef loop
) {
  if (port != NULL) {
    CGEventTapEnable(port, false);
  }
  if (loop != NULL) {
    CFRunLoopStop(loop);
  }

  NSApplication *app = [NSApplication sharedApplication];
  app.presentationOptions = (NSApplicationPresentationOptions)presentationRaw;

  NSMutableSet<NSWindow *> *seen = [NSMutableSet set];
  int32_t hidden = 0;

  void (^hide)(NSWindow *) = ^(NSWindow *window) {
    if (window == nil || [seen containsObject:window]) {
      return;
    }
    [seen addObject:window];
    BabyWorkHideWindow(window);
  };

  for (id object in windows) {
    if ([object isKindOfClass:[NSWindow class]]) {
      hide((NSWindow *)object);
      hidden += 1;
    }
  }

  for (NSWindow *window in app.windows) {
    NSString *identifier = BabyWorkWindowIdentifier(window);
    if ([identifier hasPrefix:@"fr.camille.babywork.cover."]) {
      BOOL already = [seen containsObject:window];
      hide(window);
      if (!already) {
        hidden += 1;
      }
    }
  }

  os_log_info(BabyWorkTeardownLog(), "kiosque démonté, %d couverture(s)", hidden);
  return hidden;
}

void BabyWorkScheduleKioskTeardown(
  void *windows,
  uint64_t presentation_raw,
  void *tap_port,
  void *tap_loop,
  BabyWorkTeardownDone done,
  void *context
) {
  NSArray *windowArray = windows ? (__bridge_transfer NSArray *)windows : @[];
  CFMachPortRef port = (CFMachPortRef)tap_port;
  CFRunLoopRef loop = (CFRunLoopRef)tap_loop;
  if (port != NULL) {
    CFRetain(port);
  }
  if (loop != NULL) {
    CFRetain(loop);
  }

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
    if (port != NULL) {
      CGEventTapEnable(port, false);
    }
    if (loop != NULL) {
      CFRunLoopStop(loop);
    }
  });

  __block BOOL notified = NO;
  void (^work)(void) = ^{
    int32_t hidden = BabyWorkPerformTeardown(windowArray, presentation_raw, port, loop);
    if (!notified && done != NULL) {
      notified = YES;
      done(hidden, context);
    }
    [[NSApplication sharedApplication] terminate:nil];
  };

  dispatch_async(dispatch_get_main_queue(), work);
  CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, work);
  CFRunLoopWakeUp(CFRunLoopGetMain());
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), work);
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    work();
    if (port != NULL) {
      CFRelease(port);
    }
    if (loop != NULL) {
      CFRelease(loop);
    }
  });
}
