
#import <Foundation/Foundation.h>
#import <GCDAsyncUdpSocket.h>

@interface NetworkHelper : NSObject<GCDAsyncUdpSocketDelegate>
{
    @private
    GCDAsyncUdpSocket * udpSocket;
    NSString * connectedIPAddress;
}
+ (NSString *)getIPAddress:(BOOL)preferIPv4;
+ (NSDictionary *)getIPAddresses;
+ (void)startUDPServer;
+ (void)udpSetting;
+ (void)closeUDP;
+ (void)connectToAddress:(NSString*)addr;
+ (void)sendData:(NSData*)data;
+ (void)sendData:(NSData*)data toAddress:(NSString*)addr;
@end


