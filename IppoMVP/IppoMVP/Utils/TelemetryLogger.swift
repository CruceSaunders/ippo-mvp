import Foundation

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
    case success = "OK"
}

final class TelemetryLogger {
    static let shared = TelemetryLogger()
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()
    
    private init() {}
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        print("[\(level.rawValue)] [\(timestamp)] [\(filename):\(function)] \(message)")
        #endif
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function) {
        log(message, level: .debug, file: file, function: function)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function) {
        log(message, level: .info, file: file, function: function)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function) {
        log(message, level: .warning, file: file, function: function)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function) {
        log(message, level: .error, file: file, function: function)
    }
    
    func success(_ message: String, file: String = #file, function: String = #function) {
        log(message, level: .success, file: file, function: function)
    }
    
    // MARK: - Specialized Logging
    func logSprint(_ result: SprintResult) {
        let status = result.isValid ? "VALID" : "INVALID"
        log("Sprint \(status) - Score: \(Int(result.validationScore))% (HR: \(Int(result.hrScore))%, Cadence: \(Int(result.cadenceScore))%, HRD: \(Int(result.hrdScore))%)", level: .info)
    }
    
    func logRewards(_ rewards: SprintRewards) {
        var parts: [String] = []
        if rewards.rpBoxEarned { parts.append("RP Box earned") }
        if rewards.xp > 0 { parts.append("+\(rewards.xp) XP") }
        log("Rewards: \(parts.joined(separator: ", "))", level: .info)
    }
}
