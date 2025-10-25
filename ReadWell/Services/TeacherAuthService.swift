import Foundation
import Security

@MainActor
class TeacherAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authError: String = ""
    
    private let defaultPIN = "1234" // Default PIN for first-time setup
    private let keychainService = "com.readwell.teacherauth"
    private let keychainAccount = "teacherPIN"
    
    // MARK: - Authentication
    
    func authenticate(pin: String) -> Bool {
        let storedPIN = getStoredPIN() ?? defaultPIN
        
        if pin == storedPIN {
            isAuthenticated = true
            authError = ""
            return true
        } else {
            authError = "Incorrect PIN. Please try again."
            return false
        }
    }
    
    func logout() {
        isAuthenticated = false
    }
    
    // MARK: - PIN Management
    
    func setPIN(_ newPIN: String) -> Bool {
        guard newPIN.count == 4, newPIN.allSatisfy({ $0.isNumber }) else {
            authError = "PIN must be 4 digits"
            return false
        }
        
        return savePIN(newPIN)
    }
    
    func changePIN(currentPIN: String, newPIN: String) -> Bool {
        // Verify current PIN
        guard authenticate(pin: currentPIN) else {
            authError = "Current PIN is incorrect"
            return false
        }
        
        // Validate new PIN
        guard newPIN.count == 4, newPIN.allSatisfy({ $0.isNumber }) else {
            authError = "New PIN must be 4 digits"
            return false
        }
        
        // Save new PIN
        if savePIN(newPIN) {
            authError = ""
            return true
        } else {
            authError = "Failed to save new PIN"
            return false
        }
    }
    
    func resetToDefault() -> Bool {
        return savePIN(defaultPIN)
    }
    
    // MARK: - Keychain Operations
    
    private func savePIN(_ pin: String) -> Bool {
        guard let data = pin.data(using: .utf8) else { return false }
        
        // Delete any existing PIN
        deletePIN()
        
        // Create new keychain item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func getStoredPIN() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let pin = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return pin
    }
    
    private func deletePIN() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Helper Methods
    
    func isDefaultPIN() -> Bool {
        return getStoredPIN() == nil || getStoredPIN() == defaultPIN
    }
    
    func hasPINSet() -> Bool {
        return getStoredPIN() != nil
    }
}

