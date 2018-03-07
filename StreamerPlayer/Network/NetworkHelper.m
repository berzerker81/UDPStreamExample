//
//  NetworkHelper.m
//  StreamerPlayer
//
//  Created by 장웅 on 2017. 9. 29..
//  Copyright © 2017년 장웅. All rights reserved.
//

#import "NetworkHelper.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
//#define IOS_VPN       @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

@implementation NetworkHelper
+(NetworkHelper*)getSharedInstance
{
    static NetworkHelper * sInstance = nil;
    if(sInstance == nil)
    {
        sInstance = [[NetworkHelper alloc] init];
    }
    return sInstance;
}

+ (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ /*IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6,*/ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ /*IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4,*/ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

+ (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}
#pragma mark udp

+ (void)udpSetting
{
    [[NetworkHelper getSharedInstance] udpInit];
}

+ (void)startUDPServer
{
    [[NetworkHelper getSharedInstance] udpInit];
}

+ (void)closeUDP
{
    [[NetworkHelper getSharedInstance] closeUdp];
}

+ (void)connectToAddress:(NSString*)addr
{
    [[NetworkHelper getSharedInstance] connectToAddress:addr];
}
- (void)connectToAddress:(NSString*)addr
{
    NSError * error = nil;
    [udpSocket connectToHost:addr onPort:7777 error:nil];
    connectedIPAddress = addr;
    if(error)
    {
        NSLog(@"%@",error.localizedDescription);
    }
}

-(void)udpInit
{
    
    NSError * error = nil;
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [udpSocket setIPv4Enabled:YES];
    [udpSocket bindToPort:7777 error:&error];
    [udpSocket beginReceiving:&error];
    if(error)
    {
        NSLog(@"%@",error.localizedDescription);
    }
    
    
}

-(void)closeUdp
{
    [udpSocket close];
    udpSocket = nil;
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    

    NSString * addrString = [[NSString alloc] initWithData:address encoding:NSUTF8StringEncoding];
    
    NSLog(@"udpSocketdidConnectToAddress:%@",address);
    //접속했다고 호스트에 통지함.
    
    
    NSString * strData = [NSString stringWithFormat:@"Test"];
    
    [self sendData:[strData dataUsingEncoding:NSUTF8StringEncoding]];
    
}



/**
 * By design, UDP is a connectionless protocol, and connecting is not needed.
 * However, you may optionally choose to connect to a particular host for reasons
 * outlined in the documentation for the various connect methods listed above.
 *
 * This method is called if one of the connect methods are invoked, and the connection fails.
 * This may happen, for example, if a domain name is given for the host and the domain name is unable to be resolved.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error
{
    NSLog(@"NotConnect");
}

/**
 * Called when the datagram with the given tag has been sent.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"send");
}

/**
 * Called if an error occurs while trying to send a datagram.
 * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error
{
    NSLog(@"error %@",error.localizedDescription);
}

/**
 * Called when the socket has received the requested datagram.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext
{
    NSLog(@"udpSocket ReceiveData :%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

+ (void)sendData:(NSData*)data
{
    [[NetworkHelper getSharedInstance] sendData:data];
}

-(void)sendData:(NSData*)data
{
//    [udpSocket sendData:data toAddress:<#(nonnull NSData *)#> withTimeout:<#(NSTimeInterval)#> tag:<#(long)#>]
}

+ (void)sendData:(NSData*)data toAddress:(NSString*)addr
{
    [[NetworkHelper getSharedInstance] sendData:data toAddress:addr];
}

-(void)sendData:(NSData*)data toAddress:(NSString*)addr
{
    [udpSocket sendData:data
              toAddress:[addr dataUsingEncoding:NSUTF8StringEncoding]
            withTimeout:10
                    tag:1];
}

/**
 * Called when the socket is closed.
 **/
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error
{
    
}




@end
