//
//  Visual_QA_App.swift
//  Visual Q&A
//
//  Created by Thai Tran on 6/25/23.
//

import SwiftUI

@main
struct Visual_Q_AApp: App {
    @StateObject private var modelData = ModelData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelData)
        }
    }
}
