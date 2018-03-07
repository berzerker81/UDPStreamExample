//
//  StreameVC.m
//  StreamerPlayer
//
//  Created by 장웅 on 2017. 9. 29..
//  Copyright © 2017년 장웅. All rights reserved.
//

#import "StreameVC.h"
#import <VideoToolbox/VideoToolbox.h>


//https://mobisoftinfotech.com/resources/mguide/h264-encode-decode-using-videotoolbox/

@interface StreameVC ()

@end

@implementation StreameVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    //인코더를 아래 경로에서 가져옴.
    //https://github.com/LevyGG/iOS-H.264-hareware-encode-and-decode
    h264Encoder = [H264HwEncoderImpl alloc];
    [h264Encoder initWithConfiguration];
    [h264Encoder initEncode:self.videoContainer.frame.size.width
                     height:self.videoContainer.frame.size.height];
    h264Encoder.delegate = self;

    
    [self.ipaddrlabel setText:[NetworkHelper getIPAddress:YES]];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startStream:(id)sender {
    
    [self setCaptureDevice];
}

- (void)setCaptureDevice
{
    NSError *deviceError;
    
    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&deviceError];
    
    // make output device
    
    AVCaptureVideoDataOutput *outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    
    [outputDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    // initialize capture session
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    
    [captureSession addInput:inputDevice];
    
    [captureSession addOutput:outputDevice];
    
    // make preview layer and add so that camera's view is displayed on screen
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer    layerWithSession:captureSession];
    previewLayer.frame = self.videoContainer.bounds;
    [self.videoContainer.layer addSublayer:previewLayer];
    
    // go!
    [captureSession startRunning];
}


-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection

{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );
    CGSize imageSize = CVImageBufferGetEncodedSize( imageBuffer );
    // also in the 'mediaSpecific' dict of the sampleBuffer
//    NSLog( @"frame captured at %.fx%.f", imageSize.width, imageSize.height );
    
    [h264Encoder encode:sampleBuffer];
}

#pragma mark - Encoder Delegate

#pragma mark - H264HwEncoderImplDelegate delegate 解码代理
- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
{
//    NSLog(@"gotSpsPps %d %d", (int)[sps length], (int)[pps length]);
    //[sps writeToFile:h264FileSavePath atomically:YES];
    //[pps writeToFile:h264FileSavePath atomically:YES];
    // write(fd, [sps bytes], [sps length]);
    //write(fd, [pps bytes], [pps length]);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];

    
}
- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
//    NSLog(@"gotEncodedData %d", (int)[data length]);
    //    static int framecount = 1;
    
    // [data writeToFile:h264FileSavePath atomically:YES];
    //write(fd, [data bytes], [data length]);
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    
    if(targetIP)
    {
        [socket sendData:ByteHeader toHost:targetIP port:7777 withTimeout:10 tag:2];
    }
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext
{
//    [super udpSocket:sock didReceiveData:data fromAddress:address withFilterContext:filterContext];
    NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString * tag = dict[@"tag"];
    if(tag)
    {
        switch ([tag intValue])
        {
            case 1: //영상 요청
            {
                targetIP = dict[@"content"];
                
            }
                break;
                
            default:
                break;
        }
        
    }
    
    NSLog(@"DataReceived %@",dict);
    
}



@end
