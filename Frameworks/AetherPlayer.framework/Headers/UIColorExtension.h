//
//  UIColorExtension.h
//  AetherPlayer-iOS
//
//  Created by Stefan Vukanić on 3/26/18.
//

#import <UIKit/UIColor.h>

@interface UIColor(UIColorExtension)
+ (instancetype)colorWithHexString:(NSString *)hexStr  andAlpha:(CGFloat)alphaRange;
+ (instancetype)colorWithHexString:(NSString *)hexStr;
@end
