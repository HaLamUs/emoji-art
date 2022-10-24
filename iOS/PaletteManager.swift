//
//  PaletteManager.swift
//  LHEmojiArt
//
//  Created by lamha on 14/10/2022.
//

import SwiftUI

struct PaletteManager: View {
    @EnvironmentObject var store: PaletteStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.palettes) {
                    palette in
                    NavigationLink(destination: PaletteEditor(palette: $store.palettes[palette])) {
                        VStack(alignment: .leading) {
//                            Text(palette.name).font(colorScheme == .dark ? .largeTitle : .caption)
                            Text(palette.name).font(editMode == .active ? .largeTitle : .caption)
                            Text(palette.emojis)
                        }
                        .gesture(editMode == .active ? tap : nil)
                    }
                }
                .onDelete {
                    indexSet in
                    store.palettes.remove(atOffsets: indexSet)
                }
                .onMove {
                    indexSet, newOffset in
                    store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
                }
            }
            .navigationTitle("Manage Palettes")
            .navigationBarTitleDisplayMode(.inline)
            .dismissable{ presentationMode.wrappedValue.dismiss() }
//            .toolbar {
//                ToolbarItem { EditButton() }
//                ToolbarItem(placement: .navigationBarLeading) {
//                    //wrappedValue là mình đang đọc giá trị thực chứ ko phải access binding gì hết
//                    if presentationMode.wrappedValue.isPresented,
//                       UIDevice.current.userInterfaceIdiom != .phone {
//                        Button("Close") {
//                            presentationMode.wrappedValue.dismiss()
//                        }
//                    }
//                }
////                EditButton() // this will toggle the edit value
//            }
//            .environment(\.colorScheme, .dark)
            .environment(\.editMode, $editMode) // #bind env editMode to local @state var
        }
    }
    
    var tap: some Gesture {
        TapGesture().onEnded {
            
        }
    }
    
}

struct PaletteManager_Previews: PreviewProvider {
    static var previews: some View {
        PaletteManager()
            .environmentObject(PaletteStore(name: "Preview"))
    }
}
