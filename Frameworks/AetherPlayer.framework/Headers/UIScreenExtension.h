//
//  UIScreenExtension.h
//  AetherPlayer-iOS
//
//  Created by Stefan Vukanić on 3/22/18.
//

#import <UIKit/UIKit.h>

@interface UIScreen (UIScreenExtension)
@property (NS_NONATOMIC_IOSONLY, readonly) CGRect landscapeBounds;
@property (NS_NONATOMIC_IOSONLY, readonly) CGRect nativeLandscapeBounds;
@end

