//
//  ATHEvent.h
//  Pods
//
//  Created by Stefan Vukanić on 6/5/18.
//

#import <Foundation/Foundation.h>
#import "ATHEventType.h"
#import "AWSDynamoDB.h"

NS_ASSUME_NONNULL_BEGIN
@interface ATHEvent : NSObject
@property (readonly, nonatomic) ATHEventTypeAlias type;
@property (readonly, nonatomic) NSString *eventId;
@property (readonly, nonatomic) NSString *content;
@property (readonly, nonatomic) NSString *track;
@property (readonly, nonatomic, nullable) NSMutableDictionary *attributes;
@property (readonly, nonatomic) NSInteger timestamp;

- (instancetype)initWithType:(ATHEventTypeAlias)type andContent:(NSURL*)content andTrack:(NSString*)track;
- (instancetype)initWithType:(ATHEventTypeAlias)type andContent:(NSURL*)content andTrack:(NSString*)track andAttributes:(NSDictionary*)attributes;

+ (ATHEvent*)withType:(ATHEventTypeAlias)type andContent:(NSURL*)content andTrack:(NSString*)track;
+ (ATHEvent*)withType:(ATHEventTypeAlias)type andContent:(NSURL*)content andTrack:(NSString*)track andAttributes:(NSDictionary*)attributes;

- (void)putAttribute:(NSString*)key andValue:(NSObject*)value;
-(AWSDynamoDBWriteRequest*)getDynamoItemWithSession:(NSString*)session andDevice:(NSString*)device andPlatform:(NSString*)platform;
@end
NS_ASSUME_NONNULL_END
