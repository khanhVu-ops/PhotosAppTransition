//
//  ZoomablePannableView.swift
//  ScannerDocs
//
//  Created by Khánh Vũ on 14/2/25.
//

#if os(iOS)

import SwiftUI

struct ZoomableModifier: ViewModifier {
    let minZoomScale: CGFloat
    let maximumScale: CGFloat
    let doubleTapZoomScale: CGFloat
    @Binding var canDragDismiss: Bool
    @State private var lastTransform: CGAffineTransform = .identity
    @State private var transform: CGAffineTransform = .identity
    @State private var contentSize: CGSize = .zero
    
    @available(iOS, introduced: 16.0, deprecated: 17.0)
    @State private var anchorPoint: CGPoint = .zero
    func body(content: Content) -> some View {
        content
            .background(alignment: .topLeading) {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            contentSize = proxy.size
                        }
                }
            }
            .animatableTransformEffect(transform)
            .gesture(dragGesture, including: transform.isScaleIdentity ? .none : .all)
            .onChange(of: transform, perform: { newValue in
                canDragDismiss = transform.isScaleIdentity
                print(canDragDismiss)
            })
//            .gesture(dragDissmissGesture, including: transform.isScaleIdentity ? .all : .none)
//            .simultaneousGesture(oldMagnificationGesture)
            .modify { view in
                if #available(iOS 17.0, *) {
                    view.simultaneousGesture(magnificationGesture)
                } else {
                    view.gesture(oldMagnificationGesture)
                }
            }
            .gesture(doubleTapGesture)
    }

    @available(iOS, introduced: 16.0, deprecated: 17.0)
    private var oldMagnificationGesture: some Gesture {
        SimultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    anchorPoint = value.location // Capture start location of the pinch
                },
            MagnificationGesture()
                .onChanged { value in
                    let zoomFactor = 0.5
                    let scale = min(value * zoomFactor, maximumScale)
                    
                    // Compute transform relative to the anchor point
                    let newTransform = CGAffineTransform.anchoredScale(scale: scale, anchor: anchorPoint)
                    
                    withAnimation(.interactiveSpring()) {
                        transform = lastTransform.concatenating(newTransform)
                    }
                }
                .onEnded { _ in
                    onEndGesture()
                }
        )
    }

    @available(iOS 17.0, *)
    private var magnificationGesture: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0)
            .onChanged { value in
                print(lastTransform.scaleX * value.magnification)
                if lastTransform.scaleX * value.magnification < maximumScale {
                    let newTransform = CGAffineTransform.anchoredScale(
                        scale: value.magnification,
                        anchor: value.startAnchor.scaledBy(contentSize)
                    )

                    withAnimation(.interactiveSpring) {
                        transform = lastTransform.concatenating(newTransform)
                    }
                }
                
            }
            .onEnded { _ in
                onEndGesture()
            }
    }

    private var doubleTapGesture: some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                let newTransform: CGAffineTransform =
                if transform.isIdentity {
                    .anchoredScale(scale: doubleTapZoomScale, anchor: value.location)
                } else {
                    .identity
                }
                
                withAnimation(.linear(duration: 0.15)) {
                    transform = newTransform
                    lastTransform = newTransform
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                withAnimation(.interactiveSpring) {
                    transform = lastTransform.translatedBy(
                        x: value.translation.width / transform.scaleX,
                        y: value.translation.height / transform.scaleY
                    )
                }
            }
            .onEnded { _ in
                onEndGesture()
            }
    }

    private func onEndGesture() {
        let newTransform = limitTransform(transform)

        withAnimation(.snappy(duration: 0.1)) {
            transform = newTransform
            lastTransform = newTransform
        }
    }

    private func limitTransform(_ transform: CGAffineTransform) -> CGAffineTransform {
        let scaleX = transform.scaleX
        let scaleY = transform.scaleY

        if scaleX < minZoomScale
            || scaleY < minZoomScale
        {
            return .identity
        }

        let maxX = contentSize.width * (scaleX - 1)
        let maxY = contentSize.height * (scaleY - 1)

        if transform.tx > 0
            || transform.tx < -maxX
            || transform.ty > 0
            || transform.ty < -maxY
        {
            let tx = min(max(transform.tx, -maxX), 0)
            let ty = min(max(transform.ty, -maxY), 0)
            var transform = transform
            transform.tx = tx
            transform.ty = ty
            return transform
        }

        return transform
    }
}

public extension View {
    @ViewBuilder
    func zoomable(
        minZoomScale: CGFloat = 1,
        maximumScale: CGFloat = 5,
        doubleTapZoomScale: CGFloat = 3,
        canDragDismiss: Binding<Bool>
    ) -> some View {
        modifier(ZoomableModifier(
            minZoomScale: minZoomScale,
            maximumScale: maximumScale,
            doubleTapZoomScale: doubleTapZoomScale,
            canDragDismiss: canDragDismiss
        ))
    }
}

extension View {
    @ViewBuilder
    func modify(@ViewBuilder _ fn: (Self) -> some View) -> some View {
        fn(self)
    }

    @ViewBuilder
    func animatableTransformEffect(_ transform: CGAffineTransform) -> some View {
        scaleEffect(
            x: transform.scaleX,
            y: transform.scaleY,
            anchor: .zero
        )
        .offset(x: transform.tx, y: transform.ty)
    }
}

private extension UnitPoint {
    func scaledBy(_ size: CGSize) -> CGPoint {
        .init(
            x: x * size.width,
            y: y * size.height
        )
    }
}

private extension CGAffineTransform {
    static func anchoredScale(scale: CGFloat, anchor: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: anchor.x, y: anchor.y)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -anchor.x, y: -anchor.y)
    }

    var scaleX: CGFloat {
        sqrt(a * a + c * c)
    }

    var scaleY: CGFloat {
        sqrt(b * b + d * d)
    }
    
    var isScaleIdentity: Bool {
        scaleX == 1 && scaleY == 1
    }
}

#endif
