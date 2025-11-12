//
//  PicSolveApp.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 07/11/25.
//

import os
import SwiftUI

@main
struct PicSolveApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

let logger = Logger()

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
