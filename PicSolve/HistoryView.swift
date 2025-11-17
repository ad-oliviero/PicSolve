//
//  HistoryView.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 16/11/25.
//

import SwiftUI

struct HistoryView: View {
    @StateObject var photoSelector: PhotoSelectorViewModel
    let entries: [(image: UIImage?, date: String)] = [
        (UIImage(named: "sampleMath.png"), "2025-11-16"),
        (UIImage(named: "sampleMath.png"), "2025-11-15"),
        (UIImage(named: "sampleMath.png"), "2025-11-14"),
        (UIImage(named: "sampleMath.png"), "2025-11-13"),
        (UIImage(named: "sampleMath.png"), "2025-11-12"),
        (UIImage(named: "sampleMath.png"), "2025-11-11"),
        (UIImage(named: "sampleMath.png"), "2025-11-10"),
        (UIImage(named: "sampleMath.png"), "2025-11-09"),
        (UIImage(named: "sampleMath.png"), "2025-11-08"),
        (UIImage(named: "sampleMath.png"), "2025-11-07"),
        (UIImage(named: "sampleMath.png"), "2025-11-06"),
        (UIImage(named: "sampleMath.png"), "2025-11-05"),
        (UIImage(named: "sampleMath.png"), "2025-11-04"),
        (UIImage(named: "sampleMath.png"), "2025-11-03"),
        (UIImage(named: "sampleMath.png"), "2025-11-02"),
        (UIImage(named: "sampleMath.png"), "2025-11-01"),
        (UIImage(named: "sampleMath.png"), "2025-10-31"),
        (UIImage(named: "sampleMath.png"), "2025-10-30"),
        (UIImage(named: "sampleMath.png"), "2025-10-29"),
        (UIImage(named: "sampleMath.png"), "2025-10-28")
    ]

    var body: some View {
        ScrollView {
            ForEach(0 ..< entries.count, id: \.self) { i in
                NavigationLink {
                    SolveView(photoSelector: photoSelector)
                        .onAppear {
                            photoSelector.image = entries[i].image!
                        }
                } label: {
                    HStack {
                        Image(uiImage: entries[i].image!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(.capsule)
                        Spacer()
                        Text(entries[i].date)
                    }.padding(20)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
