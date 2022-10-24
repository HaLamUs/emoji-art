//
//  PaletteChooser.swift
//  LHEmojiArt
//
//  Created by lamha on 13/10/2022.
//

import SwiftUI

struct PaletteChooser: View {
    var emojiFontSize: CGFloat = 40
    var emojiFont: Font { .system(size: emojiFontSize) }
    
    @EnvironmentObject var store: PaletteStore
    
//    @State private var chosenPaletteIndex = 0 // this wont store
    @SceneStorage("PaletteChooser.chosenPaletteIndex") private var chosenPaletteIndex = 0
    
    var body: some View {
        HStack{
            paletteControlButton
            body(for: store.palette(at: chosenPaletteIndex))
        }
        .clipped()
    }
    
    var paletteControlButton: some View {
        Button {
            withAnimation {
                chosenPaletteIndex = (chosenPaletteIndex + 1) % store.palettes.count
            }
        } label: {
            Image(systemName: "paintpalette")
        }
        .font(emojiFont)
        .paletteControlButtonStyle()
        .contextMenu{ contextMenu }
    }
    
    @ViewBuilder
    var contextMenu: some View {
        AnimatedActionButton(title: "Edit", systemImage: "pencil") {
//            editing = true
            paletteToEdit = store.palette(at: chosenPaletteIndex)
        }
        AnimatedActionButton(title: "New", systemImage: "plus") {
            store.insertPalette(named: "New", emojis: "", at: chosenPaletteIndex)
//            editing = true
            paletteToEdit = store.palette(at: chosenPaletteIndex)
        }
        AnimatedActionButton(title: "Delete", systemImage: "minus.cirlce") {
            chosenPaletteIndex = store.removePalette(at: chosenPaletteIndex)
        }
        #if os(iOS)
        AnimatedActionButton(title: "Manager", systemImage: "slider.vertical.3") {
            managing = true
        }
        #endif
        gotoMenu
    }
    
    var gotoMenu: some View {
        Menu {
            ForEach(store.palettes) {
                palette in
                AnimatedActionButton(title: palette.name) {
//                    if let index = store.palettes.firstIndex(where: { $0.id == palette.id }) {
                    if let index = store.palettes.index(matching: palette) {
                        chosenPaletteIndex = index
                    }
                }
            }
        } label: {
            Label("Go To", systemImage: "text.insert")
        }
    }
    
    func body(for palette: Palette) -> some View {
        HStack {
            Text(palette.name)
            ScrollingEmojisView(emojis: palette.emojis)
                .font(emojiFont)
        }
        .id(palette.id) // this call tag, we use this trick to redraw the view will trigger the animation transition
        .transition(rollTransition)
//        .popover(isPresented: $editing) {
//            // we need dolar sign for binding (copy in out - exchange var b/w views)
//            PaletteEditor(palette: $store.palettes[chosenPaletteIndex])
//        }
        .popover(item: $paletteToEdit) {
            palette in
            PaletteEditor(palette: $store.palettes[palette])
                .popoverPadding()
                .wrappedInNavigationViewToMakeDissmissable { paletteToEdit = nil }
        }
        .sheet(isPresented: $managing) {
            PaletteManager()
        }
    }
    
//    @State private var editing = false
    @State private var managing = false
    @State private var paletteToEdit: Palette?
    
    var rollTransition: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .offset(x: 0, y: emojiFontSize),
            removal: .offset(x: 0, y: -emojiFontSize)
        )
    }
}

struct ScrollingEmojisView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.removingDuplicateCharacters.map {String($0)}, id: \.self) {
                    emoji in
                    Text(emoji)
                        .onDrag{ NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }
}

