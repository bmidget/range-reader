//
//  RangeSdkViewController.m
//  RangeSdk
//
//  Created by David Clift-Reaves.
//  Copyright (c) 2014 Supermechanical. All rights reserved.
//

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

#import "Range.h"
#import "RangeSdkViewController.h"

@interface RangeSdkViewController ()
{
    range_sample_t lastSampleSeen;
    BOOL dataWasStale;
    BOOL headsetPluggedIn;
    NSURL* _baseURL;
    NSURL* _templateURL;
    NSString* _replaceStr;
    NSString* _basicHtml;
    AVAudioPlayer* _alertPlayer;
}

@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic, strong) Range* range;
@property (nonatomic, strong) RangeTrigger* trigger;

@end

// By default, this sample app uses a WebView, so creating an iOS app is as simple as changing HTML and CSS
// in WebViewTemplate.html and WebViewStyle.css, in the Supporting Files folder. You should be able to do
// anything you can do in Safari here, except that {{temperature}} will be replaced with your Range's
// current temperature! Can it get any easier?
//
// If you're comfortable with Xcode and want to use storyboards for your UI, set useWebView = false.
//
const BOOL useWebView = true;

// These colors are a bit extreme but they help to visualize transitions in an obvious way.
const BOOL useBackgroundColors = true && !useWebView;


@implementation RangeSdkViewController

- (void) initRange
{
    // We have to request microphone permission before first requesting the Range sharedInstance.
    [RangeAudioManager requestMicrophonePermission:^(BOOL permissionGranted)
     {
         if(permissionGranted == YES)
         {
             // Do any additional setup after loading the view, typically from a nib.
             Range* tempRange = [Range sharedInstance];
             
             [tempRange.audioManager registerForHeadsetCallbacksOnObject:self withSelector:@selector(headsetCallback:)];
             [tempRange.audioManager enableAllAudio];
             self.range = tempRange;
             
             [self startClockUpdates: self];
         } else {
             dispatch_async(dispatch_get_main_queue(), ^{
                 UIAlertController *accessActionController = [UIAlertController alertControllerWithTitle:@"What's that? I can't hear you." message:@"This app needs access to your device's microphone so we can properly talk to the Range thermometer.\n\nPlease enable microphone access for this app in Settings / Privacy / Microphone" preferredStyle:UIAlertControllerStyleAlert];
                 
                 UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil];
                 [accessActionController addAction:action];

                 [self presentViewController:accessActionController animated:YES completion:nil];
             });
         }
     }];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(useWebView)
    {
        self.webView.hidden = false;
        self.mainLabel.hidden = true;
        self.headsetLabel.hidden = true;
        self.enableSwitch.hidden = true;
    } else {
        self.webView.hidden = true;
        self.mainLabel.hidden = false;
        self.headsetLabel.hidden = false;
        self.enableSwitch.hidden = false;
    }
    
    self.enableSwitch.on = true;
    
    lastSampleSeen.unix_time = 0;
    lastSampleSeen.temperature = 0;
    
    dataWasStale = NO;
    headsetPluggedIn = NO;
    NSError *templateError;
    
    NSString* path = [[NSBundle mainBundle] bundlePath];
    _baseURL = [NSURL fileURLWithPath:path];
    _templateURL = [NSURL fileURLWithPath:[path stringByAppendingString:@"/WebViewTemplate.html"]];
    
    _basicHtml = [[NSString alloc]
                  initWithContentsOfURL:_templateURL
                  encoding:NSUTF8StringEncoding
                  error:&templateError];
    if (_basicHtml == nil) {
        // an error occurred
        NSLog(@"Error reading file at %@\n%@", _templateURL, [templateError localizedFailureReason]);
        _basicHtml = @"<!DOCTYPE html>\
        <html>\
        <body> \
        \
        <h1>Temperature</h1>\
        \
        <h1>{{temperature}}</h1>\
        \
        </body>\
        </html>\
        ";
    }
    
    _replaceStr = @"{{temperature}}";
    
    if(useWebView)
    {
        NSString* updatedHtml = [_basicHtml stringByReplacingOccurrencesOfString:_replaceStr withString:@"Connect Range."];
        [self.webView loadHTMLString:updatedHtml baseURL:_baseURL];
    } else {
        [self.mainLabel setText:[NSString stringWithFormat:@"Connect Range!"]];
        [self.headsetLabel setText:@"Headphone Never Inserted"];
    }
    
    // temperatures should be input in F
    // use temperatureTranslator to translate from another scale to F
    float thresholdForTrigger = 85.0f;
    self.trigger = [[RangeTrigger alloc] initTriggerWithTemperature:thresholdForTrigger andDirection:kRangeTriggerDirectionRising];
    
    // This sound is a CC 0 sound. It is free to use. However, I suggest you change it with your own sound.
    // http://www.freesound.org/people/willy_ineedthatapp_com/sounds/167337/
    NSURL* url = [[NSBundle mainBundle] URLForResource:@"alert" withExtension:@"wav"];
    NSAssert(url, @"URL is valid.");
    
    NSError *error;
    _alertPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if(!_alertPlayer)
    {
        NSLog(@"Error creating _alertPlayer player: %@", error);
    }
    
    [self initRange];

}

- (IBAction)enableSwitchChanged:(id)sender {
    UISwitch* uiSwitch = sender;
    
    if(uiSwitch.on)
    {
        [self.range.audioManager enableAllAudio];
    } else {
        [self.range.audioManager disableAllAudio];
    }
}

- (void)didReceiveMemoryWarning
{
    // Release any retained subviews of the main view.
    if(self.range != nil)
    {
        [self.range.audioManager returnToUserVolume];
    }

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Timer
-(void)update
{
    if(self.range == nil)
    {
        return;
    }
    
    @synchronized(self.range)
    {
        // We periodically check the volume to make sure Range doesn't have its power cut.
        if([self.range.audioManager checkAndFixPowerVolume] )
        {
            // We had to fix the volume.
            // Notify the user that they are doing something wrong? (Up to you)
            NSLog(@"Volume fixed");
        }
        
        // By calling refreshRangeDataManager we have refreshed the storage.
        // all previous pointers are invalid. Use the new RangeDataManager to get current pointers.
        // We do all of this in a synchronized section to ensure that no other threads call "refreshRangeDataManager".
        // In this case we almost certainly don't need it but I wanted to show best practices.
        [self.range refreshRangeDataManager];
        
        RangeDataManager* rdm = [self.range allRangeData];
        const range_sample_t * latestSample = [rdm latestSample:NULL];
        //        range_sample_t previousSample = lastSampleSeen;
        if(latestSample != NULL)
        {
            lastSampleSeen = *latestSample;
        }
        
        BOOL isLastSampleSeenEverSet = lastSampleSeen.unix_time != 0;
        if( isLastSampleSeenEverSet == YES)
        {
            double secondsUntilStale = 5.0;
            
            if(useBackgroundColors)
            {
                // 5 seconds will produce good results in general and provides a good experience for end users.
                // 1 second response is helpful when using the background colors to see what is really happening.
                secondsUntilStale = 1.0;
            }
            
            NSString* temperatureStr = nil;
            
            BOOL isDataCurrentlyStale =
            (lastSampleSeen.unix_time + secondsUntilStale) < [[NSDate date] timeIntervalSince1970] ||
            headsetPluggedIn == NO;
            
            if(isDataCurrentlyStale)
            {
                // It has been more than seconds_till_stale since our code has seen a data point.
                // The data is considered to be stale at this point.
                if(dataWasStale == NO)
                {
                    // Data has become stale
                    temperatureStr = [NSString stringWithFormat:@"Disconnected"];
                    if(useBackgroundColors)
                    {
                        [self.mainView setBackgroundColor:[UIColor redColor]];
                    }
                    dataWasStale = YES;
                }
            } else {
                // We have active temperature data.
                if(dataWasStale == YES)
                {
                    // Valid data has been seen recently.
                    dataWasStale = NO;
                }
                
                temperatureStr =
                [self.range.temperatureTranslator printSample:lastSampleSeen.temperature
                                                   withFormat:kRangeTemperaturePrintFormatHumanReadable
                                                    withScale:kRangeTemperatureScaleFahrenheit];
                
                if(useBackgroundColors)
                {
                    if(lastSampleSeen.temperature < 60 || lastSampleSeen.temperature > 100)
                    {
                        [self.mainView setBackgroundColor:[UIColor purpleColor]];
                    } else {
                        [self.mainView setBackgroundColor:[UIColor greenColor]];
                    }
                } else {
                    // Just trying to show off a simple way of triggering an alert.
                    // Be careful using long sounds (over 5 seconds)
                    if([self.trigger isTriggerForRawData:&lastSampleSeen])
                    {
                        [self.range.audioManager prepareForAudioNotification];
                        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                        [_alertPlayer play];
                        while([_alertPlayer isPlaying]);
                        [self.range.audioManager cleanUpAfterAudioNotification];
                    }
                }
            }
            
            if(temperatureStr != nil)
            {
                if(useWebView)
                {
                    NSString* updatedHtml = [_basicHtml stringByReplacingOccurrencesOfString:_replaceStr
                                                                                  withString:temperatureStr];
                    [self.webView loadHTMLString:updatedHtml
                                         baseURL:_baseURL];
                } else {
                    [self.mainLabel setText:temperatureStr];
                }
            }
        }
    }
}

-(IBAction)startClockUpdates:(id)sender
{
    [self update];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:(1.0f/8.0f)
                                                  target:self
                                                selector:@selector(update)
                                                userInfo:nil
                                                 repeats:YES];
}


-(void) headsetCallback: (id)direction
{
    NSString * directionString = (NSString *) direction;
    
    // Note: This doesn't mean a Range was inserted. It just means that an audio jack was inserted.
    // Use the data from the rdm to determine if we have fresh data.
    
    if([directionString isEqualToString:kRHeadphoneInsertion])
    {
        // Your code here
        headsetPluggedIn = YES;
        if(useWebView)
        {
            // Nothing
        } else {
            [self.headsetLabel setText:@"Headphone Inserted"];
            if(useBackgroundColors)
            {
                [self.headsetLabel setBackgroundColor:[UIColor greenColor]];
            }
        }
    }
    else if([directionString isEqualToString:kRHeadphoneRemoval])
    {
        // Your code here
        headsetPluggedIn = NO;
        if(useWebView)
        {
            // Nothing
        } else {
            [self.headsetLabel setText:@"Headphone Removed"];
            if(useBackgroundColors)
            {
                [self.headsetLabel setBackgroundColor:[UIColor redColor]];
            }
        }
    }
}


@end
