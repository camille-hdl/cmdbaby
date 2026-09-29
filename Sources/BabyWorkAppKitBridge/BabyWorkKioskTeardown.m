#import "BabyWorkKioskTeardown.h"

#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <CoreFoundation/CoreFoundation.h>
#import <os/log.h>

static os_log_t BabyWorkTeardownLog(void) {
  static os_log_t log;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    log = os_log_create("fr.camille.babywork", "KioskTeardown");
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
  window.contentView = nil;
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

  return hidden;
}

void BabyWorkScheduleKioskTeardown(
  void *windows,
  uint64_t presentation_raw,
  void *tap_port,
  void *tap_loop,
  bool should_quit,
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

  os_log_info(
    BabyWorkTeardownLog(),
    "teardown.begin should_quit=%{public}s cover_count=%d caller=objc",
    should_quit ? "true" : "false",
    (int)windowArray.count
  );

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
    if (port != NULL) {
      CGEventTapEnable(port, false);
    }
    if (loop != NULL) {
      CFRunLoopStop(loop);
    }
  });

  __block BOOL didWork = NO;
  void (^work)(void) = ^{
    if (didWork) {
      return;
    }
    didWork = YES;
    int32_t hidden = BabyWorkPerformTeardown(windowArray, presentation_raw, port, loop);
    if (done != NULL) {
      os_log_info(
        BabyWorkTeardownLog(),
        "teardown.done should_quit=%{public}s cover_count=%d caller=objc",
        should_quit ? "true" : "false",
        hidden
      );
      done(hidden, context);
    }
    if (port != NULL) {
      CFRelease(port);
    }
    if (loop != NULL) {
      CFRelease(loop);
    }
    if (should_quit) {
      [[NSApplication sharedApplication] terminate:nil];
    }
  };

  // Une seule exécution : `commonModes` couvre le tracking kiosque, le
  // `dispatch_async` rattrape si la runloop n’est pas en tracking. Les
  // `dispatch_after` répétés fermaient les couvertures de la session suivante.
  CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, work);
  CFRunLoopWakeUp(CFRunLoopGetMain());
  dispatch_async(dispatch_get_main_queue(), work);
}
