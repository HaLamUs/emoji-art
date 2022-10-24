//
//  iOS.swift
//  LHEmojiArt
//
//  Created by lamha on 20/10/2022.
//

import SwiftUI

extension UIImage {
    var imageData: Data? { jpegData(compressionQuality: 1.0) }
}

struct Pasteboard {
    static var imageData: Data? {
        UIPasteboard.general.image?.imageData
    }
    
    static var imageURL: URL? {
        UIPasteboard.general.url?.imageURL
    }
}

extension View {
    // why using ViewBuilder? because if return some View but has if, else diff View
    // it just coding style make thing small
    @ViewBuilder
    func wrappedInNavigationViewToMakeDissmissable(_ dismiss: (()-> Void)?) -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            // ko cẩn thận xoay ngang nó sẽ ra 2 view 2 bên dù là iphone
            NavigationView {
                self
                    .navigationBarTitleDisplayMode(.inline)
                    .dismissable(dismiss)
            }
            .navigationViewStyle(StackNavigationViewStyle()) // stack instead of side by side
        } else {
            self
        }
    }
    
    @ViewBuilder
    func dismissable(_ dismiss: (()-> Void)?) -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            self.toolbar {
                // use cancel can work on mac os, tv os, iphone
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        else {
            self
        }
    }
    
    func paletteControlButtonStyle() -> some View {
        self
    }
    
    func popoverPadding() -> some View {
        self
    }
    
}
