//
//  ContentView.swift
//  Photos App Transition
//
//  Created by User on 08/05/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var coordinator: UICoordinator = .init()
    var body: some View {
        NavigationStack{
            Home()
                .environmentObject(coordinator)
                .allowsHitTesting(coordinator.selectedItem == nil)
        }
        
        .overlay{
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
                .opacity(coordinator.animateView ? 1 : 0)
        }
        
        .overlay{
            if coordinator.selectedItem != nil {
                Detail()
                    .environmentObject(coordinator)
                    .allowsHitTesting(coordinator.showDetailView)
            }
        }
        .overlayPreferenceValue(HeroKey.self){ value in
            if let selectedItem = coordinator.selectedItem,
               let sAnchor = value[selectedItem.id + "SOURCE"],
               let dAnchor = value[selectedItem.id + "DEST"]{
                Hero(
                item: selectedItem,
                sAnchor: sAnchor,
                dAnchor: dAnchor
                )
                .environmentObject(coordinator)
            }
        }
    }
}

#Preview {
    ContentView()
}
