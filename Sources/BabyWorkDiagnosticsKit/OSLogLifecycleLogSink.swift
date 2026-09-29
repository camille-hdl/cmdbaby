import OSLog

public final class OSLogLifecycleLogSink: LifecycleLogSink, @unchecked Sendable {
  private let loggers: [LifecycleLog.Category: Logger]

  public init(subsystem: String = LifecycleLog.subsystem) {
    loggers = [
      .lifecycle: Logger(subsystem: subsystem, category: LifecycleLog.Category.lifecycle.rawValue),
      .session: Logger(subsystem: subsystem, category: LifecycleLog.Category.session.rawValue),
      .inputFilter: Logger(
        subsystem: subsystem,
        category: LifecycleLog.Category.inputFilter.rawValue
      ),
      .settings: Logger(subsystem: subsystem, category: LifecycleLog.Category.settings.rawValue),
      .kioskTeardown: Logger(
        subsystem: subsystem,
        category: LifecycleLog.Category.kioskTeardown.rawValue
      ),
    ]
  }

  public func write(_ event: LifecycleLogEvent) {
    loggers[event.category]?.log("\(event.message, privacy: .public)")
  }
}
