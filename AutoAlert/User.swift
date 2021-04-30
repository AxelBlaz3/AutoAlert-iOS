//
//  User.swift
//  Speed Auditor
//
//  Created by Karthik on 21/04/21.
//

import Foundation

class User: Codable, ObservableObject {
    @Published var id: Int = -1
    @Published var email: String = ""
    @Published var username: String = ""
    @Published var appCycleId: Int = 0
    
    enum CodingKeys: CodingKey {
        case id, email, username, appCycleId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(username, forKey: .username)
        try container.encode(appCycleId, forKey: .appCycleId)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        appCycleId = try container.decode(Int.self, forKey: .appCycleId)
    }
    
    init() {
    }
    
    static func getUserId() -> Int {
        return UserDefaults.standard.integer(forKey: Constants.KEY_USER_ID)
    }
    
    static func getUserEmail() -> String {
        return UserDefaults.standard.string(forKey: Constants.KEY_EMAIL) ?? ""
    }
    
    static func getUserName() -> String {
        return UserDefaults.standard.string(forKey: Constants.KEY_USERNAME) ?? ""
    }
    
    static func getAppCycleId() -> Int {
        return UserDefaults.standard.integer(forKey: Constants.KEY_APP_CYCLE_ID)
    }
    
    static func getPrevAppCycleId() -> Int {
        return UserDefaults.standard.integer(forKey: Constants.KEY_PREV_APP_CYCLE_ID)
    }
    
    static func getLastClosedTimestamp() -> String {
        return UserDefaults.standard.string(forKey: Constants.KEY_LAST_CLOSED_TIMESTAMP) ?? ""
    }
    
    static func setUserDefaultPreference(key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
