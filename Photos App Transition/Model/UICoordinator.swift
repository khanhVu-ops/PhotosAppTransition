//
//  UICoordinator.swift
//  Photos App Transition
//
//  Created by User on 08/05/24.
//

import SwiftUI

class UICoordinator: ObservableObject {
    @Published var items: [Item] = sampleItem.compactMap({
        Item(title: $0.title, image: $0.image, previewImage: $0.image)
    })
    
    @Published var selectedItem: Item?
    @Published var animateView: Bool = false
    @Published var showDetailView: Bool = false
    @Published var detailScrollPosition: String?
    
    // Gesture
    @Published var offset: CGSize = .zero
    @Published var dragProcess: CGFloat = 0
    
    func didDetailPageChange() {
        if let updateIem = items.first(where: {$0.id == detailScrollPosition}) {
            selectedItem = updateIem
        }
    }
    func toogleView(show: Bool) {
        if show {
            detailScrollPosition = selectedItem?.id
            withAnimation(.easeInOut(duration: 0.25)){
                animateView = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.showDetailView = true
            }
            
        } else {
            showDetailView = false
            withAnimation(.easeInOut(duration : 0.25)){
                animateView = false
                offset = .zero
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.resetAnimationProperties()
            }
        }
    }
    
    func resetAnimationProperties(){
        selectedItem = nil
        detailScrollPosition = nil
        offset = .zero
        dragProcess = 0
    }
    

}

