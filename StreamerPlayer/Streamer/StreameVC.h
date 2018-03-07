//
//  StreameVC.h
//  StreamerPlayer
//
//  Created by 장웅 on 2017. 9. 29..
//  Copyright © 2017년 장웅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NetworkHelper.h"
#import "H264HwEncoderImpl.h"
#import <GCDAsyncUdpSocket.h>
#import "PlayerVC.h"

@interface StreameVC : PlayerVC<AVCaptureVideoDataOutputSampleBufferDelegate,
                                        GCDAsyncUdpSocketDelegate,
                                        H264HwEncoderImplDelegate>

{
    @private
    H264HwEncoderImpl * h264Encoder;
    NSString * targetIP;
    
}
@property (weak, nonatomic) IBOutlet UILabel *ipaddrlabel;
@property (weak, nonatomic) IBOutlet UIView *videoContainer;

@end
