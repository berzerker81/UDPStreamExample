#include <objc/NSObject.h>

@interface VideoPacket : NSObject

@property (nonatomic)uint8_t* buffer;
@property NSInteger size;
-(id)initWithData:(NSData*)data;
@end

@interface VideoFileParser : NSObject
-(BOOL)open:(NSString*)fileName;
-(VideoPacket *)nextPacket;
-(void)close;

@end
