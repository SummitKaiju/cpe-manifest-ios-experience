//
//  UnboundedBlockingQueue.h
//  Pods
//
//  Created by Stefan Vukanić on 6/5/18.
//

#import <Foundation/Foundation.h>

@interface UnboundedBlockingQueue : NSObject

- (UnboundedBlockingQueue*)initUnbound;
- (UnboundedBlockingQueue*)initWithCapacity:(NSInteger)capacity;

- (void)offer:(id)data;

- (id)take;
- (NSArray*)takeN:(NSInteger)count;

- (NSInteger)count;
- (BOOL)isEmpty;
- (void) purge;
@end
