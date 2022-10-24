//
//  PaletteEditor.swift
//  LHEmojiArt
//
//  Created by lamha on 14/10/2022.
//

import SwiftUI

struct PaletteEditor: View {
//    @State private var palette: Palette = PaletteStore(name: "Test").palette(at: 2)
    @Binding var palette: Palette // this PaletteEditor doesnt need care how to store by binding it just know it from somewhere
    
    var body: some View {
        // textfield only received the binding and State we have projected value
        Form {
            nameSection
            addEmojisSection
            removeEmojiSection
        }
        .navigationTitle("Edit \(palette.name)")
        .frame(width: 300, height: 350)
    }
    
    var nameSection: some View {
        Section(header: Text("Name")) {
            TextField("Name", text: $palette.name)
        }
    }
    
    @State private var emojisToAdd = ""
    
    var addEmojisSection: some View {
        Section(header: Text("Add Emojis")) {
            TextField("", text: $emojisToAdd)
                .onChange(of: emojisToAdd) { // this will watch the value change
                    emojis in
                    addEmojis(emojis)
                }
        }
    }
    
    private func addEmojis(_ emojis: String) {
        withAnimation {
            palette.emojis = (emojis + palette.emojis)
                .filter { $0.isEmoji }
                .removingDuplicateCharacters
        }
    }
    
    var removeEmojiSection: some View {
        Section(header: Text("Remove Emoji")) {
            let emojis = palette.emojis.removingDuplicateCharacters.map { String($0) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                ForEach(emojis, id: \.self) {
                    emoji in
                    Text(emoji)
                        .onTapGesture {
                            withAnimation {
                                palette.emojis.removeAll(where: { String($0) == emoji })
                            }
                        }
                }
            }
            .font(.system(size: 40))
            
        }
    }
    
}

struct PaletteEditor_Previews: PreviewProvider {
    static var previews: some View {
        // constant binding
        PaletteEditor(palette: .constant(PaletteStore(name: "Preview").palette(at: 4)))
    }
}
