//
//  abc.swift
//  Photos App Transition
//
//  Created by Khanh Vu on 11/3/25.
//

import SwiftUI

struct ImageDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let images: [UIImage]
    @State private var currentIndex: Int
    @State private var offset: CGSize = .zero
    @State private var backgroundOpacity: Double = 1.0
    @GestureState private var dragState = DragState.inactive
    
    init(images: [UIImage], initialIndex: Int = 0) {
        self.images = images
        _currentIndex = State(initialValue: initialIndex)
    }
    
    enum DragState {
        case inactive
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()
                
                // Image Pager
                TabView(selection: $currentIndex) {
                    ForEach(0..<images.count, id: \.self) { index in
                        ZoomableImageView(image: images[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .offset(y: offset.height)
                .animation(.interactiveSpring(), value: offset)
            }
            .gesture(
                DragGesture()
                    .updating($dragState) { value, state, _ in
                        // Only track vertical drags that start from image
                        if abs(value.translation.height) > abs(value.translation.width) {
                            state = .dragging(translation: value.translation)
                        }
                    }
                    .onChanged { value in
                        // Only apply offset for vertical drags
                        if abs(value.translation.height) > abs(value.translation.width) {
                            offset = value.translation
                            // Calculate background opacity based on drag distance
                            let dragPercentage = min(1.0, abs(value.translation.height) / 300)
                            backgroundOpacity = 1.0 - dragPercentage * 0.8
                        }
                    }
                    .onEnded { value in
                        // If dragged far enough, dismiss the view
                        if abs(value.translation.height) > geometry.size.height * 0.2 {
                            dismiss()
                        } else {
                            // Reset position with animation
                            withAnimation(.interactiveSpring()) {
                                offset = .zero
                                backgroundOpacity = 1.0
                            }
                        }
                    }
            )
            .statusBar(hidden: true)
        }
    }
}

struct ZoomableImageView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var position: CGSize = .zero
    @State private var lastPosition: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(x: position.width, y: position.height)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                // Limit minimum scale
                                scale = max(1.0, scale * delta)
                            }
                            .onEnded { _ in
                                // Reset to original scale if zoomed out too much
                                if scale < 1.0 {
                                    withAnimation {
                                        scale = 1.0
                                    }
                                }
                                // Remember last scale for next gesture
                                lastScale = 1.0
                            },
                        DragGesture()
                            .onChanged { value in
                                // Only allow dragging when zoomed in
                                if scale > 1.0 {
                                    let newPosition = CGSize(
                                        width: lastPosition.width + value.translation.width,
                                        height: lastPosition.height + value.translation.height
                                    )
                                    
                                    // Calculate bounds to prevent dragging outside image boundaries
                                    let maxX = (geometry.size.width * (scale - 1)) / 2
                                    let maxY = (geometry.size.height * (scale - 1)) / 2
                                    
                                    position = CGSize(
                                        width: newPosition.width.clamped(to: -maxX...maxX),
                                        height: newPosition.height.clamped(to: -maxY...maxY)
                                    )
                                }
                            }
                            .onEnded { _ in
                                // Remember last position for next gesture
                                lastPosition = position
                                
                                // If scale returned to 1, reset position
                                if scale <= 1.0 {
                                    withAnimation {
                                        position = .zero
                                        lastPosition = .zero
                                    }
                                }
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    // Double tap to reset or zoom
                    withAnimation {
                        if scale > 1.0 {
                            scale = 1.0
                            position = .zero
                            lastPosition = .zero
                        } else {
                            scale = 2.0
                        }
                    }
                }
        }
    }
}

// Helper extension for clamping values
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

// Usage example
struct ContentView1: View {
    @State private var showingDetail = false
    
    // Sample images - replace with your actual images
    let sampleImages = [
        UIImage(named: "Pic001")!,
        UIImage(named: "Pic002")!,
        UIImage(named: "Pic003")!
    ]
    
    var body: some View {
        Button("Show Image Gallery") {
            showingDetail = true
        }
        .fullScreenCover(isPresented: $showingDetail) {
            ImageDetailView(images: sampleImages)
        }
    }
}

#Preview(body: {
    ContentView1()
})
