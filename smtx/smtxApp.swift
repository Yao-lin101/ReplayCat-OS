//
//  smtxApp.swift
//  smtx
//
//  Created by Enkidu ㅤ on 2024/12/23.
//

import SwiftUI

@main
struct SmtxApp: App {
    init() {
        // 确保在应用启动时就配置好音频会话
        _ = AudioSessionManager.shared
    }
    
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    if isFirstLaunch {
                        setupInitialLanguageSections()
                        isFirstLaunch = false
                    }
                }
        }
    }
    
    private func setupInitialLanguageSections() {
        let defaultSections = [
            ("English"),
            ("中文"),
            ("日本語"),
            ("한국어"),
            ("Français"),
            ("Deutsch")
        ]
        
        defaultSections.forEach { name in
            _ = try? TemplateStorage.shared.createLanguageSection(name: name)
        }
    }
}
