//
//  ATHDataTypes.h
//  ATHVideo
//
//  Created by Jared Sinclair on 7/27/16.
//  Copyright © 2016 The New York Times Company. All rights reserved.
//

@import Foundation;

typedef NS_OPTIONS(NSInteger, ATHPanningAxis) {
    ATHPanningAxisHorizontal = 1 << 0,
    ATHPanningAxisVertical   = 1 << 1,
};

typedef NS_ENUM(NSInteger, ATHUserInteractionMethod) {
    ATHUserInteractionMethodGyroscope = 0,
    ATHUserInteractionMethodTouch,
};
