//
//  MSViewerModel.h
//  AetherPlayer
//
//  Created by Stefan Vukanić on 3/15/18.
//

#import <Foundation/Foundation.h>
#import "MSViewerParameters.h"

//TODO: implement

@interface MSViewerModel : NSObject
@property(nonatomic, strong) MSViewerParameters *parameters;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) Lenses *lenses;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) Distortion *distortion;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) FieldOfView *maximumFieldOfView;
@end
