//
//  ContentView.swift
//  LHEmojiArt
//
//  Created by lamha on 28/09/2022.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    // hold a view model
    @ObservedObject var document: EmojiArtDocument
    
    @Environment(\.undoManager) var undoManager
    //    let defaultEmojiFontSize: CGFloat = 40
    @ScaledMetric var defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack {
            documentBody
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
        }
    }
    
    var documentBody: some View {
        GeometryReader {
            geometry in
            ZStack {
                Color.white
                OptionalImage(uiImage: document.backgroundImage)
                    .scaleEffect(zoomScale)
                    .position(convertFromEmojiCoordinates((0, 0), in: geometry))
                
                    .gesture(doubleTapToZoom(in: geometry.size))
                //            ForEach(document.emojis) // dont need \.self cause we implement this Indentiable
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) {
                        emoji in
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale)
                            .position(position(for: emoji, in: geometry))
                    }
                }
            }
            // stay inside dont go outside
            .clipped()
            .onDrop(of: [.utf8PlainText, .url, .image], isTargeted: nil) {
                providers, location in
                //                return true
                return drop(providers: providers, at: location, in: geometry)
            }
            //            .gesture(zoomGesture())
            //            .gesture(panGesture()) // dont do this
            .gesture(panGesture().simultaneously(with: zoomGesture()))
            .alert(item: $alertToShow) {
                alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus) {
                status in
                switch status {
                case .failed(let url):
                    showBackgroundImageFetchFailedAlert(url)
                default:
                    break
                }
            }
            /*
             document.$backgroundImage: Publisher
             $document.backgroundImage: Binding
             */
            .onReceive(document.$backgroundImage) {
                image in
                if autoZoom {
                    zoomToFit(image, in: geometry.size)
                }
            }
            //            .toolbar {
            //                ToolbarItemGroup(placement: .bottomBar) {
            ////                    UndoButton(
            ////                        undo: undoManager?.optionalUndoMenuItemTitle,
            ////                        redo: undoManager?.optionalRedoMenuItemTitle
            ////                    )
            //                    AnimatedActionButton(title: "Paste Background", systemImage: "doc.on.clipboard") {
            //                        pasteBackground()
            //                    }
            //                    if let undoManager = undoManager {
            //                        if undoManager.canUndo {
            //                            AnimatedActionButton(title: undoManager.undoActionName, systemImage: "arrow.uturn.backward") {
            //                                undoManager.undo()
            //                            }
            //                        }
            //                        if undoManager.canRedo {
            //                            AnimatedActionButton(title: undoManager.redoActionName, systemImage: "arrow.uturn.forward") {
            //                                undoManager.redo()
            //                            }
            //                        }
            //                    }
            //                }
            //            }
            
            .compactableToolbar {
                AnimatedActionButton(title: "Paste Background", systemImage: "doc.on.clipboard") {
                    pasteBackground()
                }
                if Camera.isAvailable {
                    AnimatedActionButton(title: "Take photo", systemImage: "camera") {
                        backgroundPicker = .camera
                    }
                }
                if PhotoLibrary.isAvailable {
                    AnimatedActionButton(title: "Search photos", systemImage: "photo") {
                        backgroundPicker = .library
                    }
                }
                #if os(iOS)
                if let undoManager = undoManager {
                    if undoManager.canUndo {
                        AnimatedActionButton(title: undoManager.undoActionName, systemImage: "arrow.uturn.backward") {
                            undoManager.undo()
                        }
                    }
                    if undoManager.canRedo {
                        AnimatedActionButton(title: undoManager.redoActionName, systemImage: "arrow.uturn.forward") {
                            undoManager.redo()
                        }
                    }
                }
                #endif
                
            }
            .sheet(item: $backgroundPicker) {
                pickerType in
                switch pickerType {
                case .camera:
                    Camera(handlePickedImage: { image in handlePickedBackgroundImage(image) })
                case .library:
                    PhotoLibrary(handlePickedImage: { image in handlePickedBackgroundImage(image) })
                }
            }
            
        }
    }
    
    private func handlePickedBackgroundImage(_ image: UIImage?) {
        autoZoom = true
        if let imageData = image?.imageData {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        }
        backgroundPicker = nil
    }
    
    @State private var backgroundPicker: BackgroundPickerType?
    
    enum BackgroundPickerType: String, Identifiable {
        case camera
        case library
        //        var id: BackgroundPickerType { self }
        var id: String { rawValue }
    }
    
    private func pasteBackground() {
        autoZoom = true
        if let imageData = Pasteboard.imageData {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        }
        else if let url = Pasteboard.imageURL {
            document.setBackground(.url(url), undoManager: undoManager)
        }
        else {
            alertToShow = IdentifiableAlert(title: "Paste Background", message: "There is no image currentlt on the pasteboard.")
        }
    }
    
    @State private var autoZoom = false
    @State private var alertToShow: IdentifiableAlert?
    
    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "fetch failed: " + url.absoluteString, alert: {
            Alert(title: Text("Background Image Fetch"),
                  message: Text("Couldn't loadd image from \(url)."),
                  dismissButton: .default(Text("OK"))
            )
        })
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) {
            url in
            autoZoom = true
            document.setBackground(EmojiArtModel.Background.url(url.imageURL), undoManager: undoManager)
        }
        #if os(iOS)
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) {
                image in
                if let data = image.jpegData(compressionQuality: 0.1) {
                    autoZoom = true
                    document.setBackground(.imageData(data), undoManager: undoManager)
                }
            }
        }
        #endif
        if !found {
            found = providers.loadObjects(ofType: String.self) {
                string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(String(emoji),
                                      at: convertToEmojiCoordinates(location, in: geometry),
                                      size: defaultEmojiFontSize / zoomScale, undoManager: undoManager)
                }
            }
        }
        return found
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geomery: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geomery)
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    //    @State private var steadyStatePanOffset: CGSize = .zero
    @SceneStorage("EmojiArtDocument.steadyStatePanOffset") private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) {
                latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded {
                finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    //    @State private var steadyStateZoomScale: CGFloat = 1
    @SceneStorage("EmojiArtDocument.steadyStateZoomScale") private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) {
                latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { // đợi end mới vẽ thì anim rất xấu
                gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
}
