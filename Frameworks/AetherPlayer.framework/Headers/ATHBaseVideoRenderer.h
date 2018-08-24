//
//  ATHBaseVideoRenderer.h
//  AetherPlayer-iOS
//
//  Created by Miloš Žikić on 3/30/18.
//

#import "ATHRenderer.h"
#import "ATHVideoLayerCues.h"
#import "SyncedAVPlayers.h"

@interface ATHBaseVideoRenderer : ATHRenderer
@property (nonatomic, strong) ATHVideoLayerCues *cues;
@property (nonatomic, strong) SyncedAVPlayers *players;
@property (nonatomic, weak) AVPlayer *player;
@end
