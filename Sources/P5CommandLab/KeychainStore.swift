import Foundation
import Security

enum KeychainLoadResult {
    case found(String)
    case missing
    case failed(OSStatus)
}

enum KeychainSaveResult {
    case saved
    case removed
    case failed(OSStatus)
}

enum KeychainStore {
    private static let service = "ca.matx.P5CommandLab"

    static func loadPassword(for profileID: UUID) -> KeychainLoadResult {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: profileID.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return .missing }
        guard status == errSecSuccess else { return .failed(status) }
        guard let data = item as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return .failed(errSecDecode)
        }
        return .found(password)
    }

    static func save(password: String, for profileID: UUID, label: String) -> KeychainSaveResult {
        let identity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: profileID.uuidString
        ]
        guard !password.isEmpty else {
            let status = SecItemDelete(identity as CFDictionary)
            return status == errSecSuccess || status == errSecItemNotFound ? .removed : .failed(status)
        }

        let updated: [String: Any] = [
            kSecValueData as String: Data(password.utf8),
            kSecAttrLabel as String: "P5 Command Lab — \(label)"
        ]
        let updateStatus = SecItemUpdate(identity as CFDictionary, updated as CFDictionary)
        if updateStatus == errSecSuccess { return .saved }
        guard updateStatus == errSecItemNotFound else { return .failed(updateStatus) }

        var item = identity
        item[kSecValueData as String] = Data(password.utf8)
        item[kSecAttrLabel as String] = "P5 Command Lab — \(label)"
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        return addStatus == errSecSuccess ? .saved : .failed(addStatus)
    }

    @discardableResult
    static func delete(profileID: UUID) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: profileID.uuidString
        ]
        return SecItemDelete(query as CFDictionary)
    }

    static func message(for status: OSStatus) -> String {
        (SecCopyErrorMessageString(status, nil) as String?) ?? "Keychain error \(status)"
    }
}
