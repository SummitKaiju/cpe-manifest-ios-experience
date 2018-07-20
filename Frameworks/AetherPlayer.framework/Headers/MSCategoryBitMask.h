//
//  MSCategoryBitMask.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/15/18.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MSCategoryBitMask) {
    MSCategoryBitMaskAll = INT_MAX,
    MSCategoryBitMaskLeftEye = 1 << 21,
    MSCategoryBitMaskRightEye = 1 << 22
};
