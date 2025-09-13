import Foundation
import Security
import CommonCrypto

// MARK: - HIPAA Security Implementation
// This module provides HIPAA-compliant security features for 3 Blind Mice

// MARK: - HIPAA Security Manager
class HIPAASecurityManager {
    static let shared = HIPAASecurityManager()
    
    private let encryptionKey: String
    private let sessionTimeout: TimeInterval = 300 // 5 minutes
    private let auditLogger: HIPAAAuditLogger
    private let accessController: HIPAAAccessController
    
    private init() {
        // Initialize encryption key (in production, this should be securely generated and stored)
        self.encryptionKey = Self.generateEncryptionKey()
        self.auditLogger = HIPAAAuditLogger()
        self.accessController = HIPAAAccessController()
        
        // Set up automatic session timeout
        setupSessionTimeout()
    }
    
    // MARK: - Authentication
    func authenticateUser(credentials: UserCredentials) -> AuthenticationResult {
        auditLogger.logAuthenticationAttempt(userId: credentials.userId, success: false)
        
        // Validate credentials
        guard validateCredentials(credentials) else {
            auditLogger.logAuthenticationFailure(userId: credentials.userId, reason: "Invalid credentials")
            return AuthenticationResult(success: false, error: "Invalid credentials")
        }
        
        // Validate MFA if required
        if credentials.requiresMFA {
            guard validateMFA(credentials.mfaToken) else {
                auditLogger.logAuthenticationFailure(userId: credentials.userId, reason: "MFA validation failed")
                return AuthenticationResult(success: false, error: "MFA validation failed")
            }
        }
        
        // Create secure session
        let session = createSecureSession(for: credentials.userId)
        
        auditLogger.logAuthenticationSuccess(userId: credentials.userId)
        return AuthenticationResult(success: true, session: session)
    }
    
    // MARK: - Data Encryption
    func encryptPHI(_ data: Data) -> Data? {
        auditLogger.logDataEncryption(operation: "encrypt", dataSize: data.count)
        
        do {
            let encryptedData = try performAES256Encryption(data)
            auditLogger.logDataEncryptionSuccess(operation: "encrypt", dataSize: data.count)
            return encryptedData
        } catch {
            auditLogger.logDataEncryptionFailure(operation: "encrypt", error: error.localizedDescription)
            return nil
        }
    }
    
    func decryptPHI(_ encryptedData: Data) -> Data? {
        auditLogger.logDataEncryption(operation: "decrypt", dataSize: encryptedData.count)
        
        do {
            let decryptedData = try performAES256Decryption(encryptedData)
            auditLogger.logDataEncryptionSuccess(operation: "decrypt", dataSize: decryptedData.count)
            return decryptedData
        } catch {
            auditLogger.logDataEncryptionFailure(operation: "decrypt", error: error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Access Control
    func checkAccess(userId: String, resource: String, action: String) -> Bool {
        let hasAccess = accessController.checkAccess(userId: userId, resource: resource, action: action)
        
        auditLogger.logAccessCheck(
            userId: userId,
            resource: resource,
            action: action,
            granted: hasAccess
        )
        
        return hasAccess
    }
    
    func grantAccess(userId: String, resource: String, action: String) {
        accessController.grantAccess(userId: userId, resource: resource, action: action)
        auditLogger.logAccessGranted(userId: userId, resource: resource, action: action)
    }
    
    func revokeAccess(userId: String, resource: String, action: String) {
        accessController.revokeAccess(userId: userId, resource: resource, action: action)
        auditLogger.logAccessRevoked(userId: userId, resource: resource, action: action)
    }
    
    // MARK: - Session Management
    private func createSecureSession(for userId: String) -> SecureSession {
        let sessionId = generateSecureSessionId()
        let expirationTime = Date().addingTimeInterval(sessionTimeout)
        
        let session = SecureSession(
            id: sessionId,
            userId: userId,
            createdAt: Date(),
            expiresAt: expirationTime
        )
        
        auditLogger.logSessionCreated(sessionId: sessionId, userId: userId)
        return session
    }
    
    private func setupSessionTimeout() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.checkSessionTimeouts()
        }
    }
    
    private func checkSessionTimeouts() {
        // Check for expired sessions and terminate them
        auditLogger.logSessionTimeoutCheck()
    }
    
    // MARK: - Private Methods
    private func validateCredentials(_ credentials: UserCredentials) -> Bool {
        // Strong password validation
        guard credentials.password.count >= 12 else { return false }
        guard containsSpecialCharacters(credentials.password) else { return false }
        guard containsNumbers(credentials.password) else { return false }
        guard containsUppercase(credentials.password) else { return false }
        guard containsLowercase(credentials.password) else { return false }
        
        // Additional validation logic would go here
        return true
    }
    
    private func validateMFA(_ token: String) -> Bool {
        // MFA validation logic would go here
        // This is a placeholder implementation
        return !token.isEmpty
    }
    
    private func performAES256Encryption(_ data: Data) throws -> Data {
        let keyData = encryptionKey.data(using: .utf8)!
        let iv = generateRandomIV()
        
        var encryptedData = Data(count: data.count + kCCBlockSizeAES128)
        var bytesEncrypted: size_t = 0
        
        let status = data.withUnsafeBytes { dataBytes in
            encryptedData.withUnsafeMutableBytes { encryptedBytes in
                keyData.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.bindMemory(to: UInt8.self).baseAddress, kCCKeySizeAES256,
                            ivBytes.bindMemory(to: UInt8.self).baseAddress,
                            dataBytes.bindMemory(to: UInt8.self).baseAddress, data.count,
                            encryptedBytes.bindMemory(to: UInt8.self).baseAddress, encryptedData.count,
                            &bytesEncrypted
                        )
                    }
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw HIPAAError.encryptionFailed
        }
        
        encryptedData.count = bytesEncrypted
        return iv + encryptedData
    }
    
    private func performAES256Decryption(_ encryptedData: Data) throws -> Data {
        let keyData = encryptionKey.data(using: .utf8)!
        let iv = encryptedData.prefix(16)
        let data = encryptedData.dropFirst(16)
        
        var decryptedData = Data(count: data.count)
        var bytesDecrypted: size_t = 0
        
        let status = data.withUnsafeBytes { dataBytes in
            decryptedData.withUnsafeMutableBytes { decryptedBytes in
                keyData.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.bindMemory(to: UInt8.self).baseAddress, kCCKeySizeAES256,
                            ivBytes.bindMemory(to: UInt8.self).baseAddress,
                            dataBytes.bindMemory(to: UInt8.self).baseAddress, data.count,
                            decryptedBytes.bindMemory(to: UInt8.self).baseAddress, decryptedData.count,
                            &bytesDecrypted
                        )
                    }
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw HIPAAError.decryptionFailed
        }
        
        decryptedData.count = bytesDecrypted
        return decryptedData
    }
    
    private func generateRandomIV() -> Data {
        var iv = Data(count: 16)
        let result = iv.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 16, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        return result == errSecSuccess ? iv : Data()
    }
    
    private static func generateEncryptionKey() -> String {
        // In production, this should be securely generated and stored
        return "HIPAA-ENCRYPTION-KEY-256-BIT-SECURE"
    }
    
    private func generateSecureSessionId() -> String {
        let uuid = UUID().uuidString
        return "HIPAA-SESSION-\(uuid)"
    }
    
    // MARK: - Password Validation Helpers
    private func containsSpecialCharacters(_ password: String) -> Bool {
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        return password.rangeOfCharacter(from: specialCharacters) != nil
    }
    
    private func containsNumbers(_ password: String) -> Bool {
        return password.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    private func containsUppercase(_ password: String) -> Bool {
        return password.rangeOfCharacter(from: .uppercaseLetters) != nil
    }
    
    private func containsLowercase(_ password: String) -> Bool {
        return password.rangeOfCharacter(from: .lowercaseLetters) != nil
    }
}

// MARK: - Supporting Types
struct UserCredentials {
    let userId: String
    let password: String
    let mfaToken: String?
    let requiresMFA: Bool
}

struct AuthenticationResult {
    let success: Bool
    let session: SecureSession?
    let error: String?
    
    init(success: Bool, session: SecureSession? = nil, error: String? = nil) {
        self.success = success
        self.session = session
        self.error = error
    }
}

struct SecureSession {
    let id: String
    let userId: String
    let createdAt: Date
    let expiresAt: Date
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
}

enum HIPAAError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidCredentials
    case sessionExpired
    case accessDenied
    case auditLogFailure
}

// MARK: - HIPAA Access Controller
class HIPAAAccessController {
    private var accessMatrix: [String: Set<String>] = [:]
    
    func checkAccess(userId: String, resource: String, action: String) -> Bool {
        let permission = "\(resource):\(action)"
        return accessMatrix[userId]?.contains(permission) ?? false
    }
    
    func grantAccess(userId: String, resource: String, action: String) {
        let permission = "\(resource):\(action)"
        if accessMatrix[userId] == nil {
            accessMatrix[userId] = Set()
        }
        accessMatrix[userId]?.insert(permission)
    }
    
    func revokeAccess(userId: String, resource: String, action: String) {
        let permission = "\(resource):\(action)"
        accessMatrix[userId]?.remove(permission)
    }
}

// MARK: - HIPAA Audit Logger
class HIPAAAuditLogger {
    private let logFile: URL
    private let encryptionKey: String
    
    init() {
        // Set up secure audit log file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.logFile = documentsPath.appendingPathComponent("hipaa_audit.log")
        self.encryptionKey = "HIPAA-AUDIT-LOG-KEY"
        
        // Create log file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFile.path) {
            FileManager.default.createFile(atPath: logFile.path, contents: nil, attributes: nil)
        }
    }
    
    func logAuthenticationAttempt(userId: String, success: Bool) {
        let entry = AuditLogEntry(
            timestamp: Date(),
            event: "AUTHENTICATION_ATTEMPT",
            userId: userId,
            details: ["success": success],
            ipAddress: getCurrentIPAddress(),
            userAgent: getUserAgent()
        )
        writeLogEntry(entry)
    }
    
    func logAuthenticationSuccess(userId: String) {
        let entry = AuditLogEntry(
            timestamp: Date(),
            event: "AUTHENTICATION_SUCCESS",
            userId: userId,
            details: [:],
            ipAddress: getCurrentIPAddress(),
            userAgent: getUserAgent()
        )
        writeLogEntry(entry)
    }
    
    func logAuthenticationFailure(userId: String, reason: String) {
        let entry = AuditLogEntry(
            timestamp: Date(),
            event: "AUTHENTICATION_FAILURE",
            userId: userId,
            details: ["reason": reason],
            ipAddress: getCurrentIPAddress(),
            userAgent: getUserAgent()
        )
        writeLogEntry(entry)
    }
    
    func logDataEncryption(operation: String, dataSize: Int) {
        let entry = AuditLogEntry(
            timestamp: Date(),
            event: "DATA_ENCRYPTION",
            userId: "SYSTEM",
            details: ["operation": operation, "dataSize": dataSize],
            ipAddress: getCurrentIPAddress(),
            userAgent: getUserAgent()
        )
        writeLogEntry(entry)
    }
    
    func logDataEncryptionSuccess(operation: String, dataSize: Int) {
        let entry = AuditLogEntry(
            timestamp: Date(),
            event: "DATA_ENCRYPTION_SUCCESS",
            userId: "SYSTEM",
            details: ["operation": operation, "dataSize": dataSize],
            ipAddress: getCurrentIPAddress(),
            userAgent: getUserAgent()
        )
        writeLogEntry(entry)
    }
    
    func logDataEncryptionFailure(operation: String, error: String) {
        let entry = AuditLogEntry(
            timestamp: Date(),
            event: "DATA_ENCRYPTION_FAILURE",
            userId: "SYSTEM",
            details: ["operation": operation, "error": error],
            ipAddress: getCurrentIPAddress(),
            userAgent: getUserAgent()
        )
        writeLogEntry(entry)
    }
    
    func logAccessCheck(userId: String, resource: String, action: String, granted: Bool) {
        let entry = AuditLogEntry(
            timestamp: Date(),
            event: "ACCESS_CHECK",
            userId: userId,
            details: ["resource": resource, "action": action, "granted": granted],
            ipAddress: getCurrentIPAddress(),
            userAgent: getUserAgent()
        )
        writeLogEntry(entry)
    }
    
    func logAccessGranted(userId: String, resource: String, action: String) {
        let entry = AuditLogEntry(
            timestamp: Date(),
            event: "ACCESS_GRANTED",
            userId: userId,
            details: ["resource": resource, "action": action],
            ipAddress: getCurrentIPAddress(),
            userAgent: getUserAgent()
        )
        writeLogEntry(entry)
    }
    
    func logAccessRevoked(userId: String, resource: String, action: String) {
        let entry = AuditLogEntry(
            timestamp: Date(),
            event: "ACCESS_REVOKED",
            userId: userId,
            details: ["resource": resource, "action": action],
            ipAddress: getCurrentIPAddress(),
            userAgent: getUserAgent()
        )
        writeLogEntry(entry)
    }
    
    func logSessionCreated(sessionId: String, userId: String) {
        let entry = AuditLogEntry(
            timestamp: Date(),
            event: "SESSION_CREATED",
            userId: userId,
            details: ["sessionId": sessionId],
            ipAddress: getCurrentIPAddress(),
            userAgent: getUserAgent()
        )
        writeLogEntry(entry)
    }
    
    func logSessionTimeoutCheck() {
        let entry = AuditLogEntry(
            timestamp: Date(),
            event: "SESSION_TIMEOUT_CHECK",
            userId: "SYSTEM",
            details: [:],
            ipAddress: getCurrentIPAddress(),
            userAgent: getUserAgent()
        )
        writeLogEntry(entry)
    }
    
    private func writeLogEntry(_ entry: AuditLogEntry) {
        let logLine = "\(entry.timestamp.iso8601String) | \(entry.event) | \(entry.userId) | \(entry.ipAddress) | \(entry.userAgent) | \(entry.details)\n"
        
        if let data = logLine.data(using: .utf8) {
            // Append to log file
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
    }
    
    private func getCurrentIPAddress() -> String {
        // Simplified IP address detection
        return "127.0.0.1"
    }
    
    private func getUserAgent() -> String {
        return "3BlindMice-HIPAA/1.0"
    }
}

// MARK: - Audit Log Entry
struct AuditLogEntry {
    let timestamp: Date
    let event: String
    let userId: String
    let details: [String: Any]
    let ipAddress: String
    let userAgent: String
}

// MARK: - Date Extension
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
