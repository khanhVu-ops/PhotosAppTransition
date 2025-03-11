//
//  Detail.swift
//  Photos App Transition
//
//  Created by User on 08/05/24.
//

import SwiftUI
import SwiftUIIntrospect

struct Detail: View {
    @EnvironmentObject private var coordinator: UICoordinator
    var body: some View {
        VStack(spacing: 0){
            NavigationBar()
            GeometryReader{
                let size =  $0.size
                
                ScrollView(.horizontal){
                    ScrollViewReader { proxy in
                        LazyHStack(spacing: 0){
                            ForEach(coordinator.items){
                                 item in
                                ImageView(item, size: size)
                                    .id(item.id)
                            }
                        }
                        .onAppear {
                            proxy.scrollTo(coordinator.selectedItem?.id)
                        }
                    }
                    
                    
//                    .scrollTargetLayout()
                }
                .introspect(.scrollView, on: .iOS(.v16, .v17, .v18), customize: { scrollView in
                    scrollView.isPagingEnabled = true
                    scrollView.showsHorizontalScrollIndicator = false
                    scrollView.contentInsetAdjustmentBehavior = .never
                })
                .background {
                    if let selectedItem = coordinator.selectedItem{
                        Rectangle()
                            .fill(.clear)
                            .anchorPreference(key: HeroKey.self, value: .bounds, transform: { anchor in
                                return [selectedItem.id + "DEST": anchor]
                            })
                    }
                }
                .offset(coordinator.offset)
                
                Rectangle()
                    .foregroundStyle(.clear)
//                    .frame(width: 10)
                    .contentShape(.rect)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ value in
                                let translation = value.translation
                                coordinator.offset = value.translation
                                let heightProcess = max(min(translation.height / 200, 1), 0)
                                coordinator.dragProcess = heightProcess
                            })
                            .onEnded({ value in
                                let translation = value.translation
                                let velocity = value.velocity
                                let height = translation.height + (velocity.height / 5)
                                if height > (size.height * 0.5) {
                                    coordinator.toogleView(show: false)
                                } else {
                                    withAnimation(.easeIn(duration: 0.2)) {
                                        coordinator.offset = .zero
                                        coordinator.dragProcess = 0
                                    }
                                }
                            })
                    )
            }
            .opacity(coordinator.showDetailView ? 1 : 0)
            BottomIndicatorView()
                .offset(y: coordinator.showDetailView ? 0 : 120)
                .animation(.easeInOut(duration: 0.15), value: coordinator.showDetailView)
        }
        
        .onAppear{
            coordinator.toogleView(show: true)
        }
    }
    
  
    @ViewBuilder
    func NavigationBar() -> some View {
        HStack{
            Button(action: {coordinator.toogleView(show: false)}, label: {
                HStack(spacing: 2){
                    Image(systemName: "chevron.left")
                        .font(.title3)
                    Text ("Regresar")
                    
                }
            })
            Spacer()
        }
        .padding([.top, .horizontal], 15)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .offset(y: coordinator.showDetailView ? 0 : -120)
        .animation(.easeInOut(duration: 0.15), value: coordinator.showDetailView)
    }
    
    @ViewBuilder
    func ImageView(_ item: Item, size: CGSize) -> some View {
        if let image = item.image{
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.width, height: size.height)
                .clipped()
                .contentShape(.rect)
        }
    }
    
    @ViewBuilder
    func BottomIndicatorView() -> some View {
        GeometryReader {
            let size = $0.size
            ScrollView(.horizontal) {
                LazyHStack(spacing: 5) {
                    ForEach(coordinator.items) { item in
                        if let image = item.previewImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(.rect(cornerRadius: 10))
                        }
                    }
                }
                .padding(.bottom, 10)
                .scrollIndicators(.hidden)
            }
        }
       
        .frame(height: 70)
    }
}

#Preview {
    ContentView()
}
