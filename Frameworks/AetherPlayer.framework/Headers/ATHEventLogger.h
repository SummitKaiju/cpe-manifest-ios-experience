//
//  ATHEventLogger.h
//  AetherPlayer
//
//  Provides interface for logging AetherPlayer events and persisting them to the remote storage
//  Events are periodically synchronized in batches
//
//  Created by Stefan Vukanić on 6/5/18.
//

#import <Foundation/Foundation.h>
#import "ATHEvent.h"

@interface ATHEventLogger : NSObject

+ (ATHEventLogger*)sharedInstance;

// Logs an event
+ (void)logEvent: (ATHEvent*)event;

// Persists events immediatelly to remote storage provider
- (void)persist;

//Flushes the events queue without event persisting
- (void)flush;
@end
