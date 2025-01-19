import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let savedEmails = "savedEmails"
        static let savedPasswords = "savedPasswords"
        static let rememberPassword = "rememberPassword"
        static let lastUsedEmail = "lastUsedEmail"
        static let lastUsedPassword = "lastUsedPassword"
    }
    
    // 保存邮箱到历史记录
    func saveEmail(_ email: String) {
        var emails = savedEmails
        if !emails.contains(email) {
            emails.append(email)
            defaults.set(emails, forKey: Keys.savedEmails)
        }
        defaults.set(email, forKey: Keys.lastUsedEmail)
    }
    
    // 获取历史邮箱列表
    var savedEmails: [String] {
        get { defaults.stringArray(forKey: Keys.savedEmails) ?? [] }
    }
    
    // 获取最后使用的邮箱
    var lastUsedEmail: String? {
        get { defaults.string(forKey: Keys.lastUsedEmail) }
    }
    
    // 保存密码
    func savePassword(_ password: String, forEmail email: String) {
        var passwords = savedPasswords
        passwords[email] = password
        defaults.set(passwords, forKey: Keys.savedPasswords)
    }
    
    // 获取指定邮箱的密码
    func password(forEmail email: String) -> String? {
        return savedPasswords[email]
    }
    
    // 获取所有保存的密码
    private var savedPasswords: [String: String] {
        get { defaults.dictionary(forKey: Keys.savedPasswords) as? [String: String] ?? [:] }
    }
    
    var rememberPassword: Bool {
        get { defaults.bool(forKey: Keys.rememberPassword) }
        set { defaults.set(newValue, forKey: Keys.rememberPassword) }
    }
    
    // 清除指定邮箱的密码
    func clearPassword(forEmail email: String) {
        var passwords = savedPasswords
        passwords.removeValue(forKey: email)
        defaults.set(passwords, forKey: Keys.savedPasswords)
    }
    
    // 清除所有密码
    func clearAllPasswords() {
        defaults.removeObject(forKey: Keys.savedPasswords)
        defaults.removeObject(forKey: Keys.rememberPassword)
    }
    
    // 获取最后使用的密码
    var lastUsedPassword: String? {
        get { defaults.string(forKey: Keys.lastUsedPassword) }
    }
    
    // 保存最后使用的邮箱和密码
    func saveLastUsedCredentials(email: String, password: String?) {
        defaults.set(email, forKey: Keys.lastUsedEmail)
        if let password = password {
            defaults.set(password, forKey: Keys.lastUsedPassword)
        } else {
            defaults.removeObject(forKey: Keys.lastUsedPassword)
        }
    }
    
    // 清除最后使用的凭证
    func clearLastUsedCredentials() {
        defaults.removeObject(forKey: Keys.lastUsedEmail)
        defaults.removeObject(forKey: Keys.lastUsedPassword)
    }
    
    // 删除历史邮箱
    func removeEmail(_ email: String) {
        var emails = savedEmails
        emails.removeAll { $0 == email }
        defaults.set(emails, forKey: Keys.savedEmails)
        
        // 如果删除的是最后使用的邮箱，也清除它
        if lastUsedEmail == email {
            defaults.removeObject(forKey: Keys.lastUsedEmail)
        }
        
        // 同时清除该邮箱对应的密码
        clearPassword(forEmail: email)
    }
} 