import Foundation

/// Fichier rotatif : un fichier par jour, relais numéroté au-delà de ~2 Mo.
public final class LifecycleLogFile: LifecycleLogSink, @unchecked Sendable {
  public static let defaultDirectory = URL.applicationSupportDirectory
    .appendingPathComponent("BabyWorks", isDirectory: true)
    .appendingPathComponent("logs", isDirectory: true)

  public static let defaultMaxBytes = 2 * 1024 * 1024

  private let directory: URL
  private let calendar: Calendar
  private let now: @Sendable () -> Date
  private let maxBytes: Int
  private let fileManager: FileManager
  private let lock = NSLock()

  public init(
    directory: URL = LifecycleLogFile.defaultDirectory,
    calendar: Calendar = .current,
    now: @escaping @Sendable () -> Date = { Date() },
    maxBytes: Int = LifecycleLogFile.defaultMaxBytes,
    fileManager: FileManager = .default
  ) {
    self.directory = directory
    self.calendar = calendar
    self.now = now
    self.maxBytes = maxBytes
    self.fileManager = fileManager
  }

  public func write(_ event: LifecycleLogEvent) {
    lock.lock()
    defer { lock.unlock() }
    let timestamp = now()
    let line = LifecycleLog.fileLine(for: event, at: timestamp, timeZone: calendar.timeZone)
    let data = Data((line + "\n").utf8)
    let url = urlForWriting(byteCount: data.count, at: timestamp)
    try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    if !fileManager.fileExists(atPath: url.path) {
      fileManager.createFile(atPath: url.path, contents: nil)
    }
    guard let handle = try? FileHandle(forWritingTo: url) else { return }
    defer { try? handle.close() }
    _ = try? handle.seekToEnd()
    try? handle.write(contentsOf: data)
  }

  private func urlForWriting(byteCount: Int, at date: Date) -> URL {
    let stamp = dayStamp(date)
    var index = 1
    while true {
      let url = fileURL(stamp: stamp, index: index)
      let size = fileSize(url)
      if size == 0 || size + byteCount <= maxBytes {
        return url
      }
      index += 1
    }
  }

  private func fileURL(stamp: String, index: Int) -> URL {
    let name = index == 1 ? "babywork-\(stamp).log" : "babywork-\(stamp)-\(index).log"
    return directory.appendingPathComponent(name)
  }

  private func dayStamp(_ date: Date) -> String {
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    let year = components.year ?? 0
    let month = components.month ?? 0
    let day = components.day ?? 0
    return String(format: "%04d%02d%02d", year, month, day)
  }

  private func fileSize(_ url: URL) -> Int {
    let values = try? url.resourceValues(forKeys: [.fileSizeKey])
    return values?.fileSize ?? 0
  }
}
