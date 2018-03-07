//
//  PlayerVC.h
//  StreamerPlayer
//
//  Created by 장웅 on 2017. 9. 29..
//  Copyright © 2017년 장웅. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GCDAsyncUdpSocket.h>
#import "AAPLEAGLLayer.h"
#import <VideoToolbox/VideoToolbox.h>

@interface PlayerVC : UIViewController<UITextFieldDelegate,GCDAsyncUdpSocketDelegate>
{
    @protected
    GCDAsyncUdpSocket * socket;
    
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    AAPLEAGLLayer *_glLayer; // player
    
}
@property (weak, nonatomic) IBOutlet UILabel *ipaddrlabel;
@property (weak, nonatomic) IBOutlet UIView *videoContainer;
@property (weak, nonatomic) IBOutlet UITextField *textfield;
- (IBAction)connect:(id)sender;

@end
