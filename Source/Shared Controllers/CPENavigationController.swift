//
//  CPENavigationController.swift
//

import UIKit

class CPENavigationController: UINavigationController {
    
    public var supportsPortrait = false
    public var supportsLandscape = true
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if supportsPortrait && supportsLandscape {
            return .all
        }
        
        return (supportsPortrait ? .portrait : .landscape)
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if supportsPortrait && supportsLandscape {
            return .portrait
        }
        
        return (supportsPortrait ? .portrait : .landscapeLeft)
    }
    
    override open var shouldAutorotate: Bool {
        return true
    }

}
