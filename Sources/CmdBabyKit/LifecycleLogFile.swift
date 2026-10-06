import Foundation

/// Fichier rotatif : un fichier par jour, relais numéroté au-delà de ~2 Mo.
/// Écrit sur une file série : l’appel peut venir du callback du tap, qui ne doit pas attendre le disque.
/// Fichiers en 600, dossier en 700, liens symboliques jamais suivis.
public final class LifecycleLogFile: LifecycleLogSink, @unchecked Sendable {
  public static let defaultDirectory = AppIdentity.supportDirectory
    .appendingPathComponent("logs", isDirectory: true)

  public static let defaultMaxBytes = 2 * 1024 * 1024

  private let directory: URL
  private let calendar: Calendar
  private let now: @Sendable () -> Date
  private let maxBytes: Int
  private let fileManager: FileManager
  private let queue = DispatchQueue(label: "\(AppIdentity.bundleIdentifier).log-file")

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
    let timestamp = now()
    let line = LifecycleLog.fileLine(for: event, at: timestamp, timeZone: calendar.timeZone)
    queue.async { [self] in
      append(Data((line + "\n").utf8), at: timestamp)
    }
  }

  /// Attend que les écritures en file soient sur le disque.
  public func flush() {
    queue.sync {}
  }

  /// Supprime les journaux de plus de 14 jours, puis plafonne le dossier à 20 Mo.
  /// Resserre aussi les permissions des journaux écrits par une version précédente.
  public func purgeOldFiles() {
    queue.async { [self] in
      let names = (try? fileManager.contentsOfDirectory(atPath: directory.path)) ?? []
      let files = names.map { LogFileInfo(name: $0, size: fileSize(directory.appendingPathComponent($0))) }
      let deleted = Set(LifecycleLogRetention.filesToDelete(files, today: now(), calendar: calendar))
      for name in names {
        let url = directory.appendingPathComponent(name)
        if deleted.contains(name) {
          try? fileManager.removeItem(at: url)
        } else if name.hasSuffix(".log") {
          try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        }
      }
      if !names.isEmpty {
        try? fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
      }
    }
  }

  private func append(_ data: Data, at timestamp: Date) {
    try? fileManager.createDirectory(
      at: directory,
      withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o700]
    )
    let url = urlForWriting(byteCount: data.count, at: timestamp)
    let descriptor = open(url.path, O_WRONLY | O_APPEND | O_CREAT | O_NOFOLLOW | O_CLOEXEC, 0o600)
    guard descriptor >= 0 else { return }
    defer { close(descriptor) }
    data.withUnsafeBytes { buffer in
      _ = Darwin.write(descriptor, buffer.baseAddress, buffer.count)
    }
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
    let name = index == 1 ? "cmdbaby-\(stamp).log" : "cmdbaby-\(stamp)-\(index).log"
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
