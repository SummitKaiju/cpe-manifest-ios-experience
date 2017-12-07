//
//  SimpleImageIOCoder.swift
//

import Foundation
import SDWebImage

class SimpleImageIOCoder: SDWebImageImageIOCoder {
    
    override func decodedImage(with data: Data?) -> UIImage? {
        guard let data = data else {
            return nil
        }
        
        return UIImage(data: data)
    }
    
}
