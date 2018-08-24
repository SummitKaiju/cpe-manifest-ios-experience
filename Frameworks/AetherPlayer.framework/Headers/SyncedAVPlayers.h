//
//  SyncedAVPLayers.h
//
//  Created by Miloš Žikić on 3/23/18.
//  Copyright © 2018 Aether. All rights reserved.
//

@import AVKit;

@interface SyncedAVPlayers : NSObject
@property (readonly) BOOL isReady;
- (instancetype _Nullable )initWithPlayers:(NSArray<AVPlayer *> * _Nonnull)players;
- (void)playSegment:(CMTime)start andStop:(CMTime)stop andReverse:(BOOL)reverse completionHandler:(void (^ _Nullable)(BOOL finished))completition;
- (AVPlayer *_Nullable)getPlayerAtIndex:(NSUInteger)index;
@end




