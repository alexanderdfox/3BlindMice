import Foundation

// MARK: - HIPAA Data Manager
// This module provides HIPAA-compliant data handling for 3 Blind Mice

class HIPAADataManager {
    static let shared = HIPAADataManager()
    
    private let securityManager: HIPAASecurityManager
    private let auditLogger: HIPAAAuditLogger
    private let dataRetentionManager: HIPAADataRetentionManager
    
    private init() {
        self.securityManager = HIPAASecurityManager.shared
        self.auditLogger = HIPAAAuditLogger()
        self.dataRetentionManager = HIPAADataRetentionManager()
    }
    
    // MARK: - PHI Data Handling
    func storePHI(_ phi: PHIData, userId: String) -> Bool {
        auditLogger.logPHIAccess(userId: userId, operation: "STORE", dataType: phi.type)
        
        // Check access permissions
        guard securityManager.checkAccess(userId: userId, resource: "PHI", action: "STORE") else {
            auditLogger.logAccessDenied(userId: userId, resource: "PHI", action: "STORE")
            return false
        }
        
        // Encrypt PHI data
        guard let encryptedData = securityManager.encryptPHI(phi.data) else {
            auditLogger.logDataEncryptionFailure(operation: "store", error: "Encryption failed")
            return false
        }
        
        // Store encrypted data
        let success = dataRetentionManager.storeData(encryptedData, metadata: phi.metadata)
        
        if success {
            auditLogger.logPHIStored(userId: userId, dataType: phi.type, dataSize: phi.data.count)
        } else {
            auditLogger.logPHIStorageFailure(userId: userId, dataType: phi.type, error: "Storage failed")
        }
        
        return success
    }
    
    func retrievePHI(_ dataId: String, userId: String) -> PHIData? {
        auditLogger.logPHIAccess(userId: userId, operation: "RETRIEVE", dataType: dataId)
        
        // Check access permissions
        guard securityManager.checkAccess(userId: userId, resource: "PHI", action: "RETRIEVE") else {
            auditLogger.logAccessDenied(userId: userId, resource: "PHI", action: "RETRIEVE")
            return nil
        }
        
        // Retrieve encrypted data
        guard let (encryptedData, metadata) = dataRetentionManager.retrieveData(dataId) else {
            auditLogger.logPHIRetrievalFailure(userId: userId, dataType: dataId, error: "Data not found")
            return nil
        }
        
        // Decrypt PHI data
        guard let decryptedData = securityManager.decryptPHI(encryptedData) else {
            auditLogger.logDataEncryptionFailure(operation: "retrieve", error: "Decryption failed")
            return nil
        }
        
        auditLogger.logPHIRetrieved(userId: userId, dataType: dataId, dataSize: decryptedData.count)
        
        return PHIData(
            id: dataId,
            type: metadata.type,
            data: decryptedData,
            metadata: metadata
        )
    }
    
    func updatePHI(_ phi: PHIData, userId: String) -> Bool {
        auditLogger.logPHIAccess(userId: userId, operation: "UPDATE", dataType: phi.type)
        
        // Check access permissions
        guard securityManager.checkAccess(userId: userId, resource: "PHI", action: "UPDATE") else {
            auditLogger.logAccessDenied(userId: userId, resource: "PHI", action: "UPDATE")
            return false
        }
        
        // Encrypt updated PHI data
        guard let encryptedData = securityManager.encryptPHI(phi.data) else {
            auditLogger.logDataEncryptionFailure(operation: "update", error: "Encryption failed")
            return false
        }
        
        // Update encrypted data
        let success = dataRetentionManager.updateData(phi.id, encryptedData: encryptedData, metadata: phi.metadata)
        
        if success {
            auditLogger.logPHIUpdated(userId: userId, dataType: phi.type, dataSize: phi.data.count)
        } else {
            auditLogger.logPHIUpdateFailure(userId: userId, dataType: phi.type, error: "Update failed")
        }
        
        return success
    }
    
    func deletePHI(_ dataId: String, userId: String) -> Bool {
        auditLogger.logPHIAccess(userId: userId, operation: "DELETE", dataType: dataId)
        
        // Check access permissions
        guard securityManager.checkAccess(userId: userId, resource: "PHI", action: "DELETE") else {
            auditLogger.logAccessDenied(userId: userId, resource: "PHI", action: "DELETE")
            return false
        }
        
        // Securely delete data
        let success = dataRetentionManager.deleteData(dataId)
        
        if success {
            auditLogger.logPHIDeleted(userId: userId, dataType: dataId)
        } else {
            auditLogger.logPHIDeletionFailure(userId: userId, dataType: dataId, error: "Deletion failed")
        }
        
        return success
    }
    
    // MARK: - Mouse Input Data Handling
    func storeMouseInputData(_ inputData: MouseInputData, userId: String) -> Bool {
        // Check if mouse input data contains PHI
        if inputData.containsPHI {
            return storePHI(PHIData(
                id: inputData.id,
                type: "MOUSE_INPUT",
                data: inputData.serializedData,
                metadata: PHIMetadata(
                    type: "MOUSE_INPUT",
                    createdBy: userId,
                    createdAt: Date(),
                    lastModified: Date(),
                    retentionPeriod: 7 * 365 * 24 * 60 * 60 // 7 years
                )
            ), userId: userId)
        } else {
            // Store as non-PHI data
            return dataRetentionManager.storeData(inputData.serializedData, metadata: inputData.metadata)
        }
    }
    
    func retrieveMouseInputData(_ dataId: String, userId: String) -> MouseInputData? {
        // Try to retrieve as PHI first
        if let phiData = retrievePHI(dataId, userId: userId) {
            return MouseInputData.fromPHIData(phiData)
        }
        
        // Try to retrieve as non-PHI data
        if let (data, metadata) = dataRetentionManager.retrieveData(dataId) {
            return MouseInputData.fromSerializedData(data, metadata: metadata)
        }
        
        return nil
    }
    
    // MARK: - Data Classification
    func classifyData(_ data: Data) -> DataClassification {
        // Simple classification logic - in production, this would be more sophisticated
        let dataString = String(data: data, encoding: .utf8) ?? ""
        
        // Check for PHI indicators
        if containsPHIIndicators(dataString) {
            return .restricted // PHI
        } else if containsSensitiveIndicators(dataString) {
            return .confidential // Sensitive but not PHI
        } else if containsInternalIndicators(dataString) {
            return .internal // Internal use only
        } else {
            return .public // Public data
        }
    }
    
    // MARK: - Data Minimization
    func minimizeData(_ data: Data, purpose: String) -> Data? {
        auditLogger.logDataMinimization(operation: "MINIMIZE", purpose: purpose, originalSize: data.count)
        
        // Implement data minimization based on purpose
        switch purpose {
        case "ANALYTICS":
            return anonymizeData(data)
        case "DEBUGGING":
            return removePHIFromData(data)
        case "REPORTING":
            return aggregateData(data)
        default:
            return data
        }
    }
    
    // MARK: - Private Methods
    private func containsPHIIndicators(_ dataString: String) -> Bool {
        let phiIndicators = [
            "patient", "medical record", "diagnosis", "treatment",
            "ssn", "social security", "date of birth", "dob",
            "medical id", "patient id", "health record"
        ]
        
        let lowercaseData = dataString.lowercased()
        return phiIndicators.contains { lowercaseData.contains($0) }
    }
    
    private func containsSensitiveIndicators(_ dataString: String) -> Bool {
        let sensitiveIndicators = [
            "password", "token", "key", "secret",
            "financial", "payment", "billing"
        ]
        
        let lowercaseData = dataString.lowercased()
        return sensitiveIndicators.contains { lowercaseData.contains($0) }
    }
    
    private func containsInternalIndicators(_ dataString: String) -> Bool {
        let internalIndicators = [
            "internal", "confidential", "proprietary",
            "system", "configuration", "settings"
        ]
        
        let lowercaseData = dataString.lowercased()
        return internalIndicators.contains { lowercaseData.contains($0) }
    }
    
    private func anonymizeData(_ data: Data) -> Data? {
        // Implement data anonymization
        // This is a simplified example
        let anonymizedString = String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "[0-9]{3}-[0-9]{2}-[0-9]{4}", with: "XXX-XX-XXXX", options: .regularExpression)
            .replacingOccurrences(of: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", with: "***@***.***", options: .regularExpression)
        
        return anonymizedString?.data(using: .utf8)
    }
    
    private func removePHIFromData(_ data: Data) -> Data? {
        // Remove PHI from data for debugging purposes
        let cleanedString = String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "[A-Za-z]+ [A-Za-z]+", with: "[NAME]", options: .regularExpression)
            .replacingOccurrences(of: "[0-9]{3}-[0-9]{2}-[0-9]{4}", with: "[SSN]", options: .regularExpression)
        
        return cleanedString?.data(using: .utf8)
    }
    
    private func aggregateData(_ data: Data) -> Data? {
        // Aggregate data for reporting purposes
        // This would implement statistical aggregation
        return data
    }
}

// MARK: - Supporting Types
struct PHIData {
    let id: String
    let type: String
    let data: Data
    let metadata: PHIMetadata
}

struct PHIMetadata {
    let type: String
    let createdBy: String
    let createdAt: Date
    let lastModified: Date
    let retentionPeriod: TimeInterval
    let classification: DataClassification
    let purpose: String?
    
    init(type: String, createdBy: String, createdAt: Date, lastModified: Date, retentionPeriod: TimeInterval, classification: DataClassification = .restricted, purpose: String? = nil) {
        self.type = type
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.retentionPeriod = retentionPeriod
        self.classification = classification
        self.purpose = purpose
    }
}

struct MouseInputData {
    let id: String
    let deviceId: String
    let position: CGPoint
    let timestamp: Date
    let userId: String?
    let containsPHI: Bool
    let metadata: DataMetadata
    
    var serializedData: Data {
        let dictionary: [String: Any] = [
            "id": id,
            "deviceId": deviceId,
            "position": ["x": position.x, "y": position.y],
            "timestamp": timestamp.timeIntervalSince1970,
            "userId": userId ?? "",
            "containsPHI": containsPHI
        ]
        
        return try! JSONSerialization.data(withJSONObject: dictionary)
    }
    
    static func fromPHIData(_ phiData: PHIData) -> MouseInputData? {
        guard let dictionary = try? JSONSerialization.jsonObject(with: phiData.data) as? [String: Any],
              let deviceId = dictionary["deviceId"] as? String,
              let positionDict = dictionary["position"] as? [String: Double],
              let timestamp = dictionary["timestamp"] as? TimeInterval,
              let userId = dictionary["userId"] as? String,
              let containsPHI = dictionary["containsPHI"] as? Bool else {
            return nil
        }
        
        let position = CGPoint(x: positionDict["x"] ?? 0, y: positionDict["y"] ?? 0)
        
        return MouseInputData(
            id: phiData.id,
            deviceId: deviceId,
            position: position,
            timestamp: Date(timeIntervalSince1970: timestamp),
            userId: userId.isEmpty ? nil : userId,
            containsPHI: containsPHI,
            metadata: DataMetadata(
                type: "MOUSE_INPUT",
                createdBy: phiData.metadata.createdBy,
                createdAt: phiData.metadata.createdAt,
                lastModified: phiData.metadata.lastModified,
                retentionPeriod: phiData.metadata.retentionPeriod
            )
        )
    }
    
    static func fromSerializedData(_ data: Data, metadata: DataMetadata) -> MouseInputData? {
        guard let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let deviceId = dictionary["deviceId"] as? String,
              let positionDict = dictionary["position"] as? [String: Double],
              let timestamp = dictionary["timestamp"] as? TimeInterval,
              let userId = dictionary["userId"] as? String,
              let containsPHI = dictionary["containsPHI"] as? Bool else {
            return nil
        }
        
        let position = CGPoint(x: positionDict["x"] ?? 0, y: positionDict["y"] ?? 0)
        
        return MouseInputData(
            id: UUID().uuidString,
            deviceId: deviceId,
            position: position,
            timestamp: Date(timeIntervalSince1970: timestamp),
            userId: userId.isEmpty ? nil : userId,
            containsPHI: containsPHI,
            metadata: metadata
        )
    }
}

struct DataMetadata {
    let type: String
    let createdBy: String
    let createdAt: Date
    let lastModified: Date
    let retentionPeriod: TimeInterval
}

enum DataClassification {
    case public
    case internal
    case confidential
    case restricted // PHI
}

// MARK: - HIPAA Data Retention Manager
class HIPAADataRetentionManager {
    private let storageDirectory: URL
    private let retentionPolicies: [String: TimeInterval]
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.storageDirectory = documentsPath.appendingPathComponent("HIPAA_Data")
        
        // Create storage directory if it doesn't exist
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        
        // Define retention policies
        self.retentionPolicies = [
            "MOUSE_INPUT": 7 * 365 * 24 * 60 * 60, // 7 years
            "AUDIT_LOG": 6 * 365 * 24 * 60 * 60,   // 6 years
            "SESSION_DATA": 24 * 60 * 60,           // 24 hours
            "TEMP_DATA": 60 * 60                    // 1 hour
        ]
    }
    
    func storeData(_ data: Data, metadata: DataMetadata) -> Bool {
        let fileName = "\(metadata.type)_\(UUID().uuidString).dat"
        let fileURL = storageDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            
            // Store metadata
            let metadataFile = fileURL.appendingPathExtension("meta")
            let metadataData = try JSONEncoder().encode(metadata)
            try metadataData.write(to: metadataFile)
            
            return true
        } catch {
            return false
        }
    }
    
    func retrieveData(_ dataId: String) -> (Data, DataMetadata)? {
        // Find file by ID (simplified implementation)
        let files = try? FileManager.default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
        
        for file in files ?? [] {
            if file.lastPathComponent.contains(dataId) {
                let metadataFile = file.appendingPathExtension("meta")
                
                guard let data = try? Data(contentsOf: file),
                      let metadataData = try? Data(contentsOf: metadataFile),
                      let metadata = try? JSONDecoder().decode(DataMetadata.self, from: metadataData) else {
                    continue
                }
                
                return (data, metadata)
            }
        }
        
        return nil
    }
    
    func updateData(_ dataId: String, encryptedData: Data, metadata: DataMetadata) -> Bool {
        // Find and update existing data
        let files = try? FileManager.default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
        
        for file in files ?? [] {
            if file.lastPathComponent.contains(dataId) {
                let metadataFile = file.appendingPathExtension("meta")
                
                do {
                    try encryptedData.write(to: file)
                    let metadataData = try JSONEncoder().encode(metadata)
                    try metadataData.write(to: metadataFile)
                    return true
                } catch {
                    return false
                }
            }
        }
        
        return false
    }
    
    func deleteData(_ dataId: String) -> Bool {
        // Find and delete data
        let files = try? FileManager.default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
        
        for file in files ?? [] {
            if file.lastPathComponent.contains(dataId) {
                let metadataFile = file.appendingPathExtension("meta")
                
                do {
                    try FileManager.default.removeItem(at: file)
                    try FileManager.default.removeItem(at: metadataFile)
                    return true
                } catch {
                    return false
                }
            }
        }
        
        return false
    }
    
    func cleanupExpiredData() {
        let files = try? FileManager.default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: [.creationDateKey])
        
        for file in files ?? [] {
            if file.pathExtension == "meta" {
                guard let metadataData = try? Data(contentsOf: file),
                      let metadata = try? JSONDecoder().decode(DataMetadata.self, from: metadataData) else {
                    continue
                }
                
                let retentionPeriod = retentionPolicies[metadata.type] ?? 365 * 24 * 60 * 60 // Default 1 year
                let expirationDate = metadata.createdAt.addingTimeInterval(retentionPeriod)
                
                if Date() > expirationDate {
                    let dataFile = file.deletingPathExtension()
                    try? FileManager.default.removeItem(at: dataFile)
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
    }
}

// MARK: - Extensions for JSON Encoding/Decoding
extension DataMetadata: Codable {}
extension PHIMetadata: Codable {}
