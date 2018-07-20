//
//  MSViewerParameters.h
//  AetherPlayer
//
//  Created by Stefan Vukanić on 3/15/18.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, Alignment) {
    top=-1,
    center,
    bottom,
};

@interface Lenses : NSObject
@property(nonatomic, assign) float separation;
@property(nonatomic, assign) float offset;
@property(nonatomic, assign) float screenDistance;
@property(nonatomic, assign) Alignment alignment;
-(instancetype)initWithSeparation:(float)separation andOffset:(float)offset andAlignment:(Alignment)alignment andDistance:(float)screenDistance NS_DESIGNATED_INITIALIZER;
@end

@interface Distortion : NSObject
@property(nonatomic, assign) float k1;
@property(nonatomic, assign) float k2;
-(instancetype)init:(float)k1 andK2:(float)k2 NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithValues:(NSArray<NSNumber *>*)values NS_DESIGNATED_INITIALIZER;
-(float)distort:(float)r;
-(float)distortInv:(float)r;
@end

@interface FieldOfView : NSObject
@property(nonatomic, assign) float outer;
@property(nonatomic, assign) float inner;
@property(nonatomic, assign) float upper;
@property(nonatomic, assign) float lower;

-(instancetype)init:(float)outer inner:(float)inner upper:(float)upper lower:(float)lower NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithValues:(NSArray<NSNumber *>*)values NS_DESIGNATED_INITIALIZER;
@end

@interface MSViewerParameters : NSObject
@property(nonatomic, strong) Lenses *lenses;
@property(nonatomic, strong) Distortion *distortion;
@property(nonatomic, strong) FieldOfView *maximumFieldOfView;
-(instancetype)initWithLenses:(Lenses*)lenses andDistortion:(Distortion*)distortion andMaxFov:(FieldOfView*)maxFov NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithParameters:(MSViewerParameters*)parameters NS_DESIGNATED_INITIALIZER;
@end



