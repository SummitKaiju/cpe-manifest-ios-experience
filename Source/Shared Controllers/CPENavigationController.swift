//
//  CPENavigationController.swift
//

import UIKit

class CPENavigationController: UINavigationController {
    
    @objc public var supportsPortrait = false
    @objc public var supportsLandscape = true
    private weak var lastPresentedController : UIViewController?
    
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
    
    /* Resolution to issue where WKActionSheet (save image, copy, cancel on long press)
     * causes presenting view controller to be dismissed.
     * @see : https://stackoverflow.com/questions/49856616/wkwebview-action-sheet-dismisses-the-presenting-view-controller-after-being-dism
     */
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        // WKWebView actions sheets workaround
        if presentedViewController != nil && lastPresentedController != presentedViewController  {
            lastPresentedController = presentedViewController;
            presentedViewController?.dismiss(animated: flag, completion: {
                completion?();
                self.lastPresentedController = nil;
            });
            
        } else if( nil == lastPresentedController) {
            super.dismiss(animated: flag, completion: completion);
        }
    }

}
