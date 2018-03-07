//
//  UDPTestVC.m
//  StreamerPlayer
//
//  Created by 장웅 on 2017. 10. 2..
//  Copyright © 2017년 장웅. All rights reserved.
//

#import "UDPTestVC.h"
#define LOGTEXT(str) [self loggerText:str]
@interface UDPTestVC ()

@end

@implementation UDPTestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    LOGTEXT([NetworkHelper getIPAddress:YES]);
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
//    [NetworkHelper udpSetting];
    socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError * error;
    [socket bindToPort:7777 error:&error];
    [socket setIPv4Enabled:YES];
    
    if(error)
    {
        LOGTEXT(@"PortError");
    }
    
    
    [socket beginReceiving:&error];
    if(error)
    {
        LOGTEXT(@"beginReceiving");
    }
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
//    [NetworkHelper closeUDP];
    [socket close];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loggerText:(NSString*)logStr
{
    NSString * appendedString = [self.logger.text stringByAppendingString:[NSString stringWithFormat:@"\n%@",logStr]];
    [self.logger setText:appendedString];
    
    [self.logger scrollRectToVisible:CGRectMake(0, self.logger.contentSize.height - self.logger.bounds.size.height, self.logger.bounds.size.width,
                                                self.logger.bounds.size.height) animated:YES];
}
- (IBAction)send:(id)sender {

    NSData * dat = [[self.dataField text] dataUsingEncoding:NSUTF8StringEncoding];
    
    [socket sendData:dat
              toHost:self.ipField.text
                port:7777
         withTimeout:10
                 tag:1];
}


-(void)textFieldDidEndEditing:(UITextField *)textField
{
    
}

-(bool)textFieldShouldReturn:(UITextField *)textField
{
    
    [textField resignFirstResponder];
    return YES;
}



#pragma mark - GCDDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    NSString * logstr = [NSString stringWithFormat:@"didConnectToAddress %@",address];
    LOGTEXT(logstr);
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
    LOGTEXT(logstr);
}

/**
 * Called when the datagram with the given tag has been sent.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSString * logstr = [NSString stringWithFormat:@"didSendDataWithTag %d",tag];
    LOGTEXT(logstr);

}

/**
 * Called if an error occurs while trying to send a datagram.
 * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error
{
    NSString * logstr = [NSString stringWithFormat:@"didNotSendDataWithTag %@",error.localizedDescription];
    LOGTEXT(logstr);

}

/**
 * Called when the socket has received the requested datagram.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext
{
    
    NSString * stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString * asciiData  = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    NSString * logstr = [NSString stringWithFormat:@"didReceiveData %@ , %@",
                         stringData,asciiData];
    LOGTEXT(logstr);
}

/**
 * Called when the socket is closed.
 **/
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error
{
    LOGTEXT(@"socketClose");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
