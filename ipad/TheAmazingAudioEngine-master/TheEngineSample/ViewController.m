//
//  ViewController.m
//  Audio Controller Test Suite
//
//  Created by Michael Tyson on 13/02/2012.
//  Copyright (c) 2012 A Tasty Pixel. All rights reserved.
//

#import "ViewController.h"
#import "TheAmazingAudioEngine.h"
#import "GCDAsyncUdpSocket.h"
#import <QuartzCore/QuartzCore.h>

#define checkResult(result,operation) (_checkResult((result),(operation),strrchr(__FILE__, '/')+1,__LINE__))
//static inline BOOL _checkResult(OSStatus result, const char *operation, const char* file, int line) {
//    if ( result != noErr ) {
//        int fourCC = CFSwapInt32HostToBig(result);
//        NSLog(@"%s:%d: %s result %d %08X %4.4s\n", file, line, operation, (int)result, (int)result, (char*)&fourCC);
//        return NO;
//    }
//    return YES;
//}


#define kAuxiliaryViewTag 251


@interface ViewController () {
    AudioFileID _audioUnitFile;
    AEChannelGroupRef _group;
    GCDAsyncUdpSocket *udpSocket;
    NSString *messageIn;
    UISlider *trackingS;
}
@property (nonatomic, retain) AEAudioController *audioController;
@property (nonatomic, retain) AEAudioFilePlayer *loop1;
@property (nonatomic, retain) AEAudioFilePlayer *loop2;
@property (nonatomic, retain) AEAudioFilePlayer *loop3;
@property (retain) UIButton *oneshotAudioUnitButton;
@end

@implementation ViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {        
        // Setup our socket.
        // The socket will invoke our delegate methods using the usual delegate paradigm.
        // However, it will invoke the delegate methods on a specified GCD delegate dispatch queue.
        //
        // Now we can configure the delegate dispatch queues however we want.
        // We could simply use the main dispatch queue, so the delegate methods are invoked on the main thread.
        // Or we could use a dedicated dispatch queue, which could be helpful if we were doing a lot of processing.
        //
        // The best approach for your application will depend upon convenience, requirements and performance.
        //
        // For this simple example, we're just going to use the main thread.
        
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (id)initWithAudioController:(AEAudioController*)audioController {
    if ( !(self = [super initWithStyle:UITableViewStyleGrouped]) ) return nil;
    
    self.audioController = audioController;
    
    // Create the first loop player
    self.loop1 = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle]
                                                            URLForResource:@"Southern Rock Organ" withExtension:@"m4a"]
                                           audioController:_audioController
                                                     error:NULL];
    _loop1.volume = 1.0;
    _loop1.channelIsMuted = YES;
    _loop1.loop = YES;
    
    // Create the second loop player
    self.loop2 = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"Southern Rock Drums" withExtension:@"m4a"]
                                           audioController:_audioController
                                                     error:NULL];
    _loop2.volume = 1.0;
    _loop2.channelIsMuted = YES;
    _loop2.loop = YES;
    
    // Create the third loop player
    self.loop3 = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"Southern Rock Drums" withExtension:@"m4a"]
                                           audioController:_audioController
                                                     error:NULL];
    _loop3.volume = 1.0;
    _loop3.channelIsMuted = YES;
    _loop3.loop = YES;
    
    // Create a group for loop1, loop2, loop3 and oscillator
    _group = [_audioController createChannelGroup];
    [_audioController addChannels:[NSArray arrayWithObjects:_loop1, _loop2, _loop3, nil] toChannelGroup:_group];
    
    return self;
}

-(void)dealloc {
    [_audioController removeObserver:self forKeyPath:@"numberOfInputChannels"];
    

    NSMutableArray *channelsToRemove = [NSMutableArray arrayWithObjects:_loop1, _loop2, _loop3, nil];
    
    self.loop1 = nil;
    self.loop2 = nil;
    self.loop3 = nil;
    
    self.audioController = nil;
    
    [super dealloc];
}


//*********************************
//*********************************
//********** UDP RECEIVE **********
//*********************************
//*********************************
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg)
    {
        /* If you want to get a display friendly version of the IPv4 or IPv6 address, you could do this:
         
         NSString *host = nil;
         uint16_t port = 0;
         [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
         
         */
        
        NSLog(@"received:");
        NSLog(msg);
        messageIn = msg;
        [self decodeAndRespond];
    }
    else
    {
        NSLog(@"Error converting received data into UTF-8 String");
    }
    
    //[udpSocket sendData:data toAddress:address withTimeout:-1 tag:0];
}

-(void)
decodeAndRespond
{
    NSString *message = messageIn;
    //receive message:
    //length = 4;
    //char 0: riff id, corresponding port;
    //char 1~3: volume value: 000~100;
//    if ([message length] < 2)
//    {
//        message = @"00";
//    }
    
    const char *command = [message UTF8String];
    
    
    int  riffId = 0;
    float  volume = 0;
    
    
    if ([message length] >= 2)
    {
        riffId = command[0]-(int)'0';
        volume = (float)(command[1]-(int)'0')/100;
    }
    
//for test
//    if([message length] >= 4)
//    {
//    riffId = [[message substringWithRange:NSMakeRange(0,1)] intValue];
//    volume = [[message substringWithRange:NSMakeRange(1,3)] intValue]/100;
//    }
    float equilizer[3] = {0.4, 0.5, 1.0};
    volume = volume * equilizer[riffId];
    volume = (volume - 0.1) * 3.5;
    
    NSLog(@"riffId:%i ,volume: %f ", riffId, volume);

    switch(riffId)
    {
        case 1:
            _loop1.volume = (float)volume;
            trackingS.value = _loop1.volume;
            break;
        case 2:
            _loop2.volume = (float)volume;
            break;
        case 3:
            _loop3.volume = (float)volume;
            break;
        case 4:
            [_audioController setVolume:(float)volume forChannelGroup:_group];
            break;
        default:
            break;
    }
}

- (void)loop1SwitchChanged:(UISwitch*)sender {
    _loop1.channelIsMuted = !sender.isOn;
}

- (void)loop2SwitchChanged:(UISwitch*)sender {
    _loop2.channelIsMuted = !sender.isOn;
}

- (void)loop3SwitchChanged:(UISwitch*)sender {
    _loop3.channelIsMuted = !sender.isOn;
}

- (void)channelGroupSwitchChanged:(UISwitch*)sender {
    [_audioController setMuted:!sender.isOn forChannelGroup:_group];
}

- (void)loop1VolumeChanged:(UISlider*)sender {
    _loop1.volume = sender.value;
}

- (void)loop2VolumeChanged:(UISlider*)sender {
    _loop2.volume = sender.value;
}

- (void)loop3VolumeChanged:(UISlider*)sender {
    _loop3.volume = sender.value;
}

- (void)channelGroupVolumeChanged:(UISlider*)sender {
    [_audioController setVolume:sender.value forChannelGroup:_group];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 100)] autorelease];
    headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    
    int port = 21368;

    NSError *error = nil;
    
    if (![udpSocket bindToPort:port error:&error])
    {
        NSLog(@"Error starting server (bind): %@", error);
        return;
    }
    if (![udpSocket beginReceiving:&error])
    {
        [udpSocket close];
        
        NSLog(@"Error starting server (recv): %@", error);
        return;
    }
}


-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isiPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    

    static NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    
    if ( !cell ) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [[cell viewWithTag:kAuxiliaryViewTag] removeFromSuperview];
    
    switch ( indexPath.section ) {
        case 0: {
            cell.accessoryView = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
            UISlider *slider = [[[UISlider alloc] initWithFrame:CGRectMake(cell.bounds.size.width - (isiPad ? 250 : 210), 0, 100, cell.bounds.size.height)] autorelease];
            slider.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            slider.tag = kAuxiliaryViewTag;
            slider.maximumValue = 1.0;
            slider.minimumValue = 0.0;
            [cell addSubview:slider];
            
            switch ( indexPath.row ) {
                case 0: {
                    cell.textLabel.text = @"Channel 1";
                    ((UISwitch*)cell.accessoryView).on = !_loop1.channelIsMuted;
                    slider.value = _loop1.volume;
                    trackingS = slider;
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(loop1SwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    [slider addTarget:self action:@selector(loop1VolumeChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 1: {
                    cell.textLabel.text = @"Channel 2";
                    ((UISwitch*)cell.accessoryView).on = !_loop2.channelIsMuted;
                    slider.value = _loop2.volume;
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(loop2SwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    [slider addTarget:self action:@selector(loop2VolumeChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 2: {
                    cell.textLabel.text = @"Channel 3";
                    ((UISwitch*)cell.accessoryView).on = !_loop3.channelIsMuted;
                    slider.value = _loop3.volume;
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(loop3SwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    [slider addTarget:self action:@selector(loop3VolumeChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 3: {
                    cell.textLabel.text = @"Master";
                    ((UISwitch*)cell.accessoryView).on = ![_audioController channelGroupIsMuted:_group];
                    slider.value = [_audioController volumeForChannelGroup:_group];
                    [((UISwitch*)cell.accessoryView) addTarget:self action:@selector(channelGroupSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    [slider addTarget:self action:@selector(channelGroupVolumeChanged:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
            }
            break;
        }
    }
    
    return cell;
}


@end
