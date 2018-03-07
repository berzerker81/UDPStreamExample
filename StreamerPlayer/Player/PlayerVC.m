//
//  PlayerVC.m
//  StreamerPlayer
//
//  Created by 장웅 on 2017. 9. 29..
//  Copyright © 2017년 장웅. All rights reserved.
//
#import "StreameVC.h"
#import "PlayerVC.h"
#import "VideoFileParser.h"

@implementation PlayerVC

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.ipaddrlabel setText:[NetworkHelper getIPAddress:YES]];
    
    _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, (self.view.frame.size.width * 9)/16 )] ;
    [self.videoContainer.layer addSublayer:_glLayer];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError * error;
    [socket bindToPort:7777 error:&error];
    [socket setIPv4Enabled:YES];
    
    if(error)
    {
        NSLog(@"PortError");
    }
    
    
    [socket beginReceiving:&error];
    if(error)
    {
        NSLog(@"beginReceiving");
    }
    
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [socket close];
    
}
- (IBAction)connect:(id)sender {
    
    NSDictionary * payload =@{
                              @"tag":@"1",
                              @"content":self.ipaddrlabel.text
                              };
    NSData* kData = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingPrettyPrinted error:nil];
    
    
    [socket sendData:kData toHost:self.textfield.text port:7777 withTimeout:30 tag:1];
    
}

-(bool)textFieldShouldReturn:(UITextField *)textField
{
    [self connect:nil];
    return [textField resignFirstResponder];
}


#pragma mark - GCDDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    NSString * logstr = [NSString stringWithFormat:@"didConnectToAddress %@",address];
    NSLog(@"%@",logstr);
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
    NSString * logstr = [NSString stringWithFormat:@"didNotConnect %@",error.localizedDescription];
    NSLog(@"%@",logstr);
}

/**
 * Called when the datagram with the given tag has been sent.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSString * logstr = [NSString stringWithFormat:@"didSendDataWithTag %d",tag];
    NSLog(@"%@",logstr);
    
}

/**
 * Called if an error occurs while trying to send a datagram.
 * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error
{
    NSString * logstr = [NSString stringWithFormat:@"didNotSendDataWithTag %@",error.localizedDescription];
    NSLog(@"%@",logstr);
    
}

/**
 * Called when the socket has received the requested datagram.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext
{
    
    NSString * stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self decodePacket:data];
}

-(CVPixelBufferRef)decode:(VideoPacket*)vp {
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)vp.buffer, vp.size,
                                                          kCFAllocatorNull,
                                                          NULL, 0, vp.size,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {vp.size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", (int)decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", (int)decodeStatus);
            }
            
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    
    return outputPixelBuffer;
}


- (void)decodePacket:(NSData*)data
{
    VideoPacket * vp = [[VideoPacket alloc] initWithData:data];
    
    uint32_t nalSize = (uint32_t)(vp.size - 4);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    
    vp.buffer[0] = *(pNalSize + 3);
    vp.buffer[1] = *(pNalSize + 2);
    vp.buffer[2] = *(pNalSize + 1);
    vp.buffer[3] = *(pNalSize);
    
    CVPixelBufferRef pixelBuffer = NULL;
    int nalType = vp.buffer[4] & 0x1F;
    switch (nalType) {
        case 0x05:
            NSLog(@"Nal type is IDR frame");
            if([self initH264Decoder]) {
                pixelBuffer = [self decode:vp];
            }
            break;
        case 0x07:
            NSLog(@"Nal type is SPS");
            _spsSize = vp.size - 4;
            _sps = malloc(_spsSize);
            memcpy(_sps, vp.buffer + 4, _spsSize);
            break;
        case 0x08:
            NSLog(@"Nal type is PPS");
            _ppsSize = vp.size - 4;
            _pps = malloc(_ppsSize);
            memcpy(_pps, vp.buffer + 4, _ppsSize);
            break;
            
        default:
            NSLog(@"Nal type is B/P frame");
            pixelBuffer = [self decode:vp];
            break;
    }
    
    if(pixelBuffer) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            _glLayer.pixelBuffer = pixelBuffer;
        });
        
        CVPixelBufferRelease(pixelBuffer);
    }
    
    NSLog(@"Read Nalu size %ld", (long)vp.size);
}

/**
 * Called when the socket is closed.
 **/
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error
{
    NSLog(@"socketClose");
}


#pragma mark Decode


static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}


-(BOOL)initH264Decoder {
    if(_deocderSession) {
        return YES;
    }
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &_deocderSession);
        CFRelease(attrs);
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", (int)status);
    }
    
    return YES;
}



-(void)clearH264Deocder {
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    free(_sps);
    free(_pps);
    _spsSize = _ppsSize = 0;
}



@end
