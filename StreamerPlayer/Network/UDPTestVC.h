//
//  UDPTestVC.h
//  StreamerPlayer
//
//  Created by 장웅 on 2017. 10. 2..
//  Copyright © 2017년 장웅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkHelper.h"
#import <GCDAsyncUdpSocket.h>


@interface UDPTestVC : UIViewController<UITextFieldDelegate,UITextViewDelegate,GCDAsyncUdpSocketDelegate>
{
    @private
    GCDAsyncUdpSocket * socket;
    
}
@property (weak, nonatomic) IBOutlet UITextView *logger;
@property (weak, nonatomic) IBOutlet UITextField *ipField;
@property (weak, nonatomic) IBOutlet UITextField *dataField;

@end
