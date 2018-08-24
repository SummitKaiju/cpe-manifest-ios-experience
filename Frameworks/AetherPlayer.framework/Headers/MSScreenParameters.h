//
//  MSScreenParametersProtocol.h
//  AetherPlayer
//
//  Created by Stefan Vukanić on 3/15/18.
//

#import <Foundation/Foundation.h>

@interface MSScreenParameters : NSObject
@property (nonatomic, assign) float width;
@property (nonatomic, assign) float height;
@property (nonatomic, assign) float border;
@property (nonatomic, assign) float aspectRatio;

-(instancetype)initWithWidth:(float)width andHeight:(float)height andBorder:(float)border NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithParameters:(MSScreenParameters*)parameters NS_DESIGNATED_INITIALIZER;
@end
