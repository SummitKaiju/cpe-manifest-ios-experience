//
//  AetherContentManager.swift
//

import Foundation

import AetherPlayer

class AetherContentManager {
    
    static let shared = AetherContentManager()
    
    private var imfs = [URL: ATHContent]()
    
    private init() {
    }
    
    public func preload(imfURL: URL) {
        guard imfs[imfURL] != nil else {
            if let imf = ATHContent(from: imfURL) {
                imfs[imfURL] = imf
                imf.whenReady({ content in })
            }
            return
        }
    }
    
    public func get(imfURL: URL) -> ATHContent {
        if let imf = imfs[imfURL] {
            return imf
        } else {
            let imf = ATHContent(from: imfURL)!
            imfs[imfURL] = imf
            return imf
        }
    }
    
}
