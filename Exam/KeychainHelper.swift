import Security
import Foundation

class KeychainHelper {
    static let shared = KeychainHelper()

    func set(value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }
    
    func saveLocalImagePath(_ path: URL, forKey key: String) {
        UserDefaults.standard.set(path.absoluteString, forKey: key)
    }
    
    func getLocalImagePath(forKey key: String) -> URL? {
        if let pathString = UserDefaults.standard.string(forKey: key) {
            return URL(string: pathString)
        }
        return nil
    }
}
