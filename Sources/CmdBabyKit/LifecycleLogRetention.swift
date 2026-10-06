import Foundation

public struct LogFileInfo: Equatable, Sendable {
  public let name: String
  public let size: Int

  public init(name: String, size: Int) {
    self.name = name
    self.size = size
  }
}

/// Purge du dossier des journaux, au lancement : plus de 14 jours, puis plafond de 20 Mo.
public enum LifecycleLogRetention {
  public static let maxAgeDays = 14
  public static let maxTotalBytes = 20 * 1024 * 1024

  /// Noms à supprimer, du plus ancien au plus récent. Ne touche qu’aux `cmdbaby-AAAAMMJJ[-n].log`,
  /// et jamais au plus récent d’entre eux.
  public static func filesToDelete(_ files: [LogFileInfo], today: Date, calendar: Calendar) -> [String] {
    let logs = files.compactMap { file in stamp(of: file.name).map { (file, $0) } }
      .sorted { ($0.1.day, $0.1.index) < ($1.1.day, $1.1.index) }
    guard let todayStart = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: today)),
      let oldestKept = calendar.date(byAdding: .day, value: -maxAgeDays, to: todayStart)
    else {
      return []
    }
    let cutoff = dayNumber(oldestKept, calendar: calendar)

    var deleted: [String] = []
    var kept: [LogFileInfo] = []
    for (file, stamp) in logs {
      if stamp.day < cutoff {
        deleted.append(file.name)
      } else {
        kept.append(file)
      }
    }
    var total = kept.reduce(0) { $0 + $1.size }
    while total > maxTotalBytes, kept.count > 1 {
      let oldest = kept.removeFirst()
      deleted.append(oldest.name)
      total -= oldest.size
    }
    return deleted
  }

  /// `cmdbaby-20261006.log` → (20261006, 1) ; `cmdbaby-20261006-2.log` → (20261006, 2).
  private static func stamp(of name: String) -> (day: Int, index: Int)? {
    guard name.hasPrefix("cmdbaby-"), name.hasSuffix(".log") else { return nil }
    let core = name.dropFirst("cmdbaby-".count).dropLast(".log".count)
    let parts = core.split(separator: "-")
    guard (1...2).contains(parts.count), parts[0].count == 8, let day = Int(parts[0]) else { return nil }
    let index = parts.count == 2 ? Int(parts[1]) : 1
    return index.map { (day, $0) }
  }

  private static func dayNumber(_ date: Date, calendar: Calendar) -> Int {
    let c = calendar.dateComponents([.year, .month, .day], from: date)
    return (c.year ?? 0) * 10_000 + (c.month ?? 0) * 100 + (c.day ?? 0)
  }
}
