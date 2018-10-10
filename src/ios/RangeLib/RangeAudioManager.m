//
//  RangeAudioManager.m
//
//  Created by David Clift-Reaves.
//
// Copyright 2014 Supermechanical
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

#import "RangeAudioManager_internal.h"

static NSString * const kRHeadphoneInsertion = @"insertion";
static NSString * const kRHeadphoneRemoval = @"removal";

NSString * const kRSpeaker = @"Speaker";
NSString * const kRSpeakerAndMicrophone = @"SpeakerAndMicrophone";

const float maxVolume = 1.0f;
const float defaultAlertVolume = maxVolume;

// SDK user - I STRONGLY suggest you do not touch this constant
const float targetMicGain = 0.2f;

#if (TARGET_IPHONE_SIMULATOR)

@implementation RangeAudioManager

+ (void) requestMicrophonePermission: (MicPermissionHandler_t) handler
{
    handler(YES);
}


+ (RangeAudioManager *)sharedInstance
{
    static RangeAudioManager *sharedSingleton;
    
    @synchronized(self)
    {
        if (!sharedSingleton)
            sharedSingleton = [[RangeAudioManager alloc] init];
        
        return sharedSingleton;
    }
}

- (void) prepareForAppQuitting
{
    return;
}

- (RangeDataManager*) allTemperatures
{
    if(self.audioInput == nil)
    {
        self.audioInput = [[RangeAudioInput alloc] init];
    }
    
    return [self.audioInput allTemperatures];
}

#pragma mark - member functions

- (BOOL) checkAndFixPowerVolume
{
    return NO;
}

- (BOOL) isHeadsetPluggedIn
{
    return YES;
}

- (void)registerForHeadsetCallbacksOnObject:(id)object withSelector:(SEL)selector
{
    self->headsetCallbackId = object;
    self->headsetCallbackSelector = selector;
}


- (void) callCallbackWithString: (NSString*) callbackInput
{
    if( self->headsetCallbackSelector && self->headsetCallbackId)
    {
        // The code below is equivalent to :
        // [self->headsetCallbackId performSelector:self->headsetCallbackSelector withObject:callbackInput ];
        // but in an ARC approved way
        SEL selector = self->headsetCallbackSelector;
        IMP imp = [self->headsetCallbackId methodForSelector:selector];
        void (*func)(id, SEL, NSString*) = (void *)imp;
        func(self->headsetCallbackId, selector, callbackInput);
    }
}

- (void) returnToUserVolume
{
    return;
}

- (BOOL) prepareForAudioNotification
{
    return YES;
}

- (void) cleanUpAfterAudioNotification
{
    return;
}

-(BOOL) isAudioEnabled
{
    return YES;
}

-(void) enableAllAudio
{
    [self callCallbackWithString:kRHeadphoneInsertion];
    return;
}

-(void) disableAllAudio
{
    [self callCallbackWithString:kRHeadphoneRemoval];
    return;
}

@end

#else //#if (TARGET_IPHONE_SIMULATOR)

@implementation RangeAudioManager

#pragma mark - global functions

+ (void) requestMicrophonePermission: (MicPermissionHandler_t) handler
{
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:handler];
    } else {
        handler(YES);
    }
}

//+ (void) requestMicrophonePermission
//{
//    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
//    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
//        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
//            if (granted)
//            {
//                // Microphone enabled code
//                //                NSLog(@"Microphone is enabled..");
//                g_isPermissionForMicrophone = [NSNumber numberWithBool:YES];
//            }
//            else
//            {
//                // Microphone disabled code
//                //                NSLog(@"Microphone is disabled..");
//                g_isPermissionForMicrophone = [NSNumber numberWithBool:NO];
//            }
//        }];
//    } else {
//        g_isPermissionForMicrophone = [NSNumber numberWithBool:YES];
//    }
//}
//
//+ (BOOL) isMicrophonePermissionGivenAndIsResponse: (BOOL*) isResponse
//{
//    if(isResponse != NULL)
//    {
//        *isResponse = g_isPermissionForMicrophone != NULL;
//    }
//
//    return g_isPermissionForMicrophone != NULL &&
//    [g_isPermissionForMicrophone boolValue] == YES;
//}

+ (float) getCurrentVolume
{
    return [MPMusicPlayerController applicationMusicPlayer].volume;
}

+ (void) setCurrentVolume: (float) inputVolume
{
    [MPMusicPlayerController applicationMusicPlayer].volume = inputVolume;
}

#pragma mark - callbacks

- (NSString*) getFirstAudioSessionRouteOut
{
    NSString* output = @"None";
    if(is_ios_6)
    {
        AVAudioSession* audioSession = self->_audioSession;
        
        AVAudioSessionRouteDescription * currentRouteDescription = audioSession.currentRoute;
        if([currentRouteDescription.outputs count] > 0)
        {
            AVAudioSessionPortDescription* firstOutput = currentRouteDescription.outputs[0];
            output = firstOutput.portType;
        }
    } else {
#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        /*
         returns the current session route:
         * ReceiverAndMicrophone
         * HeadsetInOut
         * Headset
         * HeadphonesAndMicrophone
         * Headphone
         * SpeakerAndMicrophone
         * Speaker
         * HeadsetBT
         * LineInOut
         * Lineout
         * Default
         */
        
        UInt32 rSize = sizeof (CFStringRef);
        CFStringRef route;
        AudioSessionGetProperty (kAudioSessionProperty_AudioRoute, &rSize, &route);
        
        // This trick shouldn't be relied on. It only worked in old iOS versions.
        // I am keeping it here so that we don't ever return NULL.
        if (route != NULL) {
            output = [NSString stringWithFormat:@"%@", route];
        }
#pragma clang diagnostic pop
#endif //MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
    }
    return output;
}

static bool shouldProcessCallback(RangeAudioManager *manager)
{
    return manager.audioState == kRangeAudioStateStarted ||
    manager.audioState == kRangeAudioStateStopped ||
    manager.audioState == kRangeAudioStatePaused ||
    manager.audioState == kRangeAudioStateUninit ||
    manager.audioState == kRangeAudioStateEnabledNotStarted ||
    manager.audioState == kRangeAudioStateDestroyed
    ;
}


#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
// pre-ios6 callback function
static void audioRouteChangeListenerCallback (
                                              void                      *inUserData,
                                              AudioSessionPropertyID    inPropertyID,
                                              UInt32                    inPropertyValueSize,
                                              const void                *inPropertyValue)
{
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;
    RangeAudioManager *manager = CFBridgingRelease(CFBridgingRetain((__bridge RangeAudioManager *) inUserData));
    
    if(shouldProcessCallback(manager))
    {
        CFDictionaryRef routeChangeDictionary = inPropertyValue;
        
        CFNumberRef routeChangeReasonRef =
        CFDictionaryGetValue (
                              routeChangeDictionary,
                              CFSTR (kAudioSession_AudioRouteChangeKey_Reason));
        
        SInt32 routeChangeReason;
        
        CFNumberGetValue (
                          routeChangeReasonRef,
                          kCFNumberSInt32Type,
                          &routeChangeReason);
        
        CFDictionaryRef newRouteRef = CFDictionaryGetValue(routeChangeDictionary, kAudioSession_AudioRouteChangeKey_CurrentRouteDescription);
        NSDictionary *newRouteDict = (__bridge NSDictionary *)newRouteRef;
        
        CFDictionaryRef oldRoute = CFDictionaryGetValue(routeChangeDictionary, kAudioSession_AudioRouteChangeKey_PreviousRouteDescription);
        
        NSArray * paths = [[newRouteDict objectForKey: @"RouteDetailedDescription_Outputs"] count] ? [newRouteDict objectForKey: @"RouteDetailedDescription_Outputs"] : [newRouteDict objectForKey: @"RouteDetailedDescription_Inputs"];
        
        NSString * newRouteString = [[paths objectAtIndex: 0] objectForKey: @"RouteDetailedDescription_PortType"];
        
        NSString * oldRouteString = [[[((__bridge NSDictionary *)oldRoute) objectForKey: @"RouteDetailedDescription_Outputs"]objectAtIndex: 0] objectForKey: @"RouteDetailedDescription_PortType"];
        
        if(manager.audioState == kRangeAudioStateEnabledNotStarted)
        {
            if (routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable && ![newRouteString isEqualToString: oldRouteString])
            {
                // Headset is plugged in..
                if ([manager isHeadsetRoute: newRouteString])
                {
                    [manager rangeStartAllWithCallback];
                }
            }
        } else {
            if (routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable && ![newRouteString isEqualToString: oldRouteString])
            {
                // Headset is plugged in..
                if ([manager isHeadsetRoute: newRouteString])
                {
                    [manager rangeStartAllWithCallback];
                }
            } else if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable)
            {
                // Headset is unplugged..
                if ([manager isHeadsetRoute: oldRouteString])
                {
                    [manager rangeStopAllWithCallback];
                }
            } else if(routeChangeReason == kAudioSessionRouteChangeReason_NoSuitableRouteForCategory)
            {
                [manager destroyTransitionWithDisable:NO];
            }
        }
    }
}
#pragma clang diagnostic pop
#endif //MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6

// equivalent callback as audioRouteChangeListenerCallback for ios7
- (void)routeChange:(NSNotification *)notification
{
    AVAudioSessionRouteDescription * newRouteDescription = _audioSession.currentRoute;
    NSDictionary *routeChangeDict = notification.userInfo;
    NSUInteger routeChangeType = [[routeChangeDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    AVAudioSessionRouteDescription * oldRouteDescription = [routeChangeDict valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSString * newRouteString = ((AVAudioSessionPortDescription*)[newRouteDescription.outputs objectAtIndex: 0]).portType;
    NSString * oldRouteString = ((AVAudioSessionPortDescription*)[oldRouteDescription.outputs objectAtIndex: 0]).portType;
    
    //    NSLog(@"%@ newRoute: %@ oldRoute: %@", notification, newRouteString, oldRouteString);
    
    if(shouldProcessCallback(self))
    {
        if(self.audioState == kRangeAudioStateEnabledNotStarted)
        {
            if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == routeChangeType && ![newRouteString isEqualToString: oldRouteString])
            {
                // Headset is plugged in..
                if ( [self isHeadsetRoute: newRouteString] )
                {
                    [self rangeStartAllWithCallback];
                }
            }
        } else {
            if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == routeChangeType && ![newRouteString isEqualToString: oldRouteString])
            {
                // Headset is plugged in..
                if ( [self isHeadsetRoute: newRouteString] )
                {
                    [self rangeStartAllWithCallback];
                }
            }
            else if (AVAudioSessionRouteChangeReasonOldDeviceUnavailable == routeChangeType)
            {
                // Headset is unplugged..
                if ( [self isHeadsetRoute: oldRouteString] )
                {
                    [self rangeStopAllWithCallback];
                }
            }
            else if (AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory == routeChangeType)
            {
                [self destroyTransitionWithDisable:NO];
            }
        }
    }
}

static void audioInterruptionListener (
                                       void     *inUserData,
                                       UInt32   inInterruptionState
                                       )
{
    RangeAudioManager *manager = CFBridgingRelease(CFBridgingRetain((__bridge RangeAudioManager *) inUserData));
    if(manager.audioState == kRangeAudioStateStarted ||
       manager.audioState == kRangeAudioStateStopped ||
       manager.audioState == kRangeAudioStatePaused)
    {
        if( inInterruptionState == kAudioSessionBeginInterruption ) {
            //NSLog( @"Audio interruption begin\n" );
            [manager stoppedTransition];
        }
        else if( inInterruptionState == kAudioSessionEndInterruption ) {
            //NSLog( @"Audio interruption over\n" );
            // reactivate session
            [manager startedTransition];
        }
    }
}

// ios7 requires this type of callback for interruption notification
// for now we will just translate the information to work with our old callback.
- (void)interruption:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    NSUInteger interuptionType = [[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    UInt32   tempInterruptionState = 0;
    
    if(AVAudioSessionInterruptionTypeBegan == interuptionType)
    {
        tempInterruptionState = kAudioSessionBeginInterruption;
    }
    else if (AVAudioSessionInterruptionTypeEnded == interuptionType)
    {
        tempInterruptionState = kAudioSessionEndInterruption;
    }
    
    audioInterruptionListener (
                               (__bridge void *)(self),
                               tempInterruptionState
                               );
}

#pragma mark - member functions

-(void) captureAudioCategoryAndMode
{
    self.originalCategory = [_audioSession category];
    self.originalMode = [_audioSession mode];
    
    if(is_ios_6)
    {
        self.originalOptions = [_audioSession categoryOptions];
    }
}

-(void) returnAudioCategoryAndMode
{
    if(self.originalCategory)
    {
        [self setAudioCategory:self.originalCategory
                   withOptions:self.originalOptions
                       andMode:self.originalMode];
        
        self.originalCategory = nil;
        self.originalOptions = 0;
        self.originalMode = nil;
    } else {
        NSLog(@"returnAudioCategoryAndMode called but category never captured.");
    }
}

-(void) setDefaultAudioCategoryAndMode
{
    [self setAudioCategory:AVAudioSessionCategoryPlayAndRecord
               withOptions:0
                   andMode:AVAudioSessionModeMeasurement];
}

-(void) setAudioCategory: (NSString*) category withOptions: (AVAudioSessionCategoryOptions) options andMode: (NSString *) mode
{
    NSError* error = nil;
    
    if(options)
    {
        if (![_audioSession setCategory:category
                            withOptions:options
                                  error:&error]) {
            NSLog(@"AVAudioSession setCategory failed: %@", [error localizedDescription]);
        }
    } else {
        if (![_audioSession setCategory:category
                                  error:&error]) {
            NSLog(@"AVAudioSession setCategory failed: %@", [error localizedDescription]);
        }
    }
    
    if (![_audioSession setMode: mode
                          error:&error]) {
        NSLog(@"AVAudioSession setMode failed: %@", [error localizedDescription]);
    }
}

-(void) disableMicGain
{
    NSError* error = nil;
    
    // Turn off mic auto gain and force it to the lowest gain setting.
    // This just adds consistency to things. Shouldn't really matter.
    if(is_ios_6)
    {
        if(_audioSession.isInputGainSettable == YES)
        {
            if (![_audioSession setInputGain:targetMicGain error:&error])
            {
                NSLog(@"AVAudioSession setInputGain failed: %@", [error localizedDescription]);
            }
        } else {
            NSLog(@"ios6+ - cannot set input gain");
        }
        
        float inputGain = _audioSession.inputGain;
        if(!(inputGain < targetMicGain + 0.01f && inputGain > targetMicGain - 0.01f))
        {
            NSLog(@"Mic gain not set as expected. Target: %f Actual: %f", targetMicGain, inputGain);
        }
        //        NSLog(@"inputGain: %0.2f",_audioSession.inputGain);
    } else {
#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UInt32 ui32propSize = sizeof(UInt32);
        UInt32 f32propSize = sizeof(Float32);
        UInt32 inputGainAvailable = 0;
        Float32 inputGain = targetMicGain;
        
        OSStatus status =
        AudioSessionGetProperty(kAudioSessionProperty_InputGainAvailable
                                , &ui32propSize
                                , &inputGainAvailable);
        
        if (status != kAudioSessionNoError) {
            NSLog(@"AudioSessionGetProperty... failed: %d", (int)status);
        }
        
        if (inputGainAvailable) {
            status =
            AudioSessionSetProperty(kAudioSessionProperty_InputGainScalar
                                    , sizeof(inputGain)
                                    , &inputGain);
            if (status != kAudioSessionNoError) {
                NSLog(@"AudioSessionSetProperty... failed: %d", (int)status);
            }
        } else {
            NSLog(@"ios5 - cannot set input gain");
        }
        status =
        AudioSessionGetProperty(kAudioSessionProperty_InputGainScalar
                                , &f32propSize
                                , &inputGain);
        
        if (status != kAudioSessionNoError) {
            NSLog(@"AudioSessionGetProperty... failed: %d", (int)status);
        }
        
        if(!(inputGain < targetMicGain + 0.01f && inputGain > targetMicGain - 0.01f))
        {
            NSLog(@"Mic gain not set as expected. Target: %f Actual: %f", targetMicGain, inputGain);
        }
        //        NSLog(@"inputGain: %0.2f",inputGain);
#pragma clang diagnostic pop
#endif //#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
    }
}

+ (RangeAudioManager *)sharedInstance
{
    static RangeAudioManager *sharedSingleton;
    
    @synchronized(self)
    {
        if (!sharedSingleton)
            sharedSingleton = [[RangeAudioManager alloc] init];
        
        return sharedSingleton;
    }
}

- (instancetype) init
{
    if (self = [super init])
    {
        self.originalCategory = nil;
        self.originalOptions = 0;
        self.originalMode = nil;
        
        self.volumeManager = [NSMutableDictionary dictionary];
        audioNotificationCount = 0;
        self.audioState = kRangeAudioStateUninit;
        
        is_ios_6 = [[[UIDevice currentDevice] systemVersion] compare:@"6.0.0" options:NSNumericSearch] != NSOrderedAscending;
        
        _audioSession = [AVAudioSession sharedInstance];
        
#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
        OSStatus status;
#endif //#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
        
        if(is_ios_6)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(interruption:)
                                                         name:AVAudioSessionInterruptionNotification object:nil];
        } else {
#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            status = AudioSessionInitialize( NULL,
                                            NULL,
                                            audioInterruptionListener,
                                            (__bridge void *)(self) );
#pragma clang diagnostic pop
            if (status != kAudioSessionNoError) {
                NSLog(@"AudioSessionInitialize... failed: %d", (int)status);
            }
#endif //#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
        }
        
        // Configure it so that we will recieve notifications about interruptions from our audio session.
        if(is_ios_6)
        {
            // AVAudioSessionInterruptionNotification
            // Already set above.
        } else {
#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [_audioSession setDelegate: (id<AVAudioSessionDelegate>)self];
#pragma clang diagnostic pop
#endif //#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
        }
        
        if(is_ios_6)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(routeChange:)
                                                         name:AVAudioSessionRouteChangeNotification
                                                       object:nil];
        } else {
#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
            status = AudioSessionAddPropertyListener (
                                                      kAudioSessionProperty_AudioRouteChange,
                                                      audioRouteChangeListenerCallback,
                                                      (__bridge void *)(self));
            if (status != kAudioSessionNoError) {
                NSLog(@"AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange... failed: %d", (int)status);
            }
#endif //#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
        }
        
        return self;
    } else {
        return nil;
    }
}

-(BOOL) isAudioEnabled
{
    return
    self.audioState == kRangeAudioStateEnabledNotStarted ||
    self.audioState == kRangeAudioStateStarted ||
    self.audioState == kRangeAudioStateStopped ||
    self.audioState == kRangeAudioStateDestroyed ||
    self.audioState == kRangeAudioStatePaused;
}

-(void) enableAllAudio
{
    if(! [self isAudioEnabled])
    {
        if([self isHeadsetPluggedIn])
        {
            [self rangeStartAllWithCallback];
        } else {
            // A sanity check to make sure we transition from the proper state.
            if(!(self.audioState == kRangeAudioStateDestroyed ||
                 self.audioState == kRangeAudioStateUninit ||
                 self.audioState == kRangeAudioStateDestroyedAndDisabled))
            {
                NSLog(@"Range SDK - transitioning to kRangeAudioStateEnabledNotStarted from unexpected state: %ld ", (long)self.audioState);
            }
            
            self.audioState = kRangeAudioStateEnabledNotStarted;
        }
    } else {
        NSLog(@"Range SDK user is trying to enable audio when it is already enabled!");
    }
}

-(void) disableAllAudio
{
    if([self isAudioEnabled])
    {
        [self destroyTransitionWithDisable:YES];
    } else {
        NSLog(@"Range SDK user is trying to disable audio when it is already disabled!");
    }
}

#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
// pre-ios6 property setter
-(void) oldIosPropertySetterWithRoute: (UInt32) audioRouteOverride
{
    OSStatus status = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    if (status != kAudioSessionNoError) {
        NSLog(@"AudioSessionSetProperty... failed: %d", (int)status);
    }
}
#endif //#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6


- (BOOL) checkAndFixPowerVolume {
    BOOL output = NO;
    // check our
    if( [RangeAudioManager getCurrentVolume] != maxVolume && [self isHeadsetPluggedIn])
    {
        [RangeAudioManager setCurrentVolume: maxVolume];
        output = YES;
    }
    return output;
}

- (BOOL) isSpeakerOutput {
    NSString* audioRoute = [self getFirstAudioSessionRouteOut];
    BOOL output = false;
    if( is_ios_6)
    {
        output = [audioRoute isEqualToString:AVAudioSessionPortBuiltInSpeaker];
    } else {
#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
        output = [audioRoute isEqualToString:kRSpeaker] || [audioRoute isEqualToString:kRSpeakerAndMicrophone];
#endif //#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
    }
    return output;
}

- (BOOL) isHeadsetRoute: (NSString*) routeStr
{
    BOOL output = NO;
    if( is_ios_6)
    {
        output = [routeStr isEqualToString:AVAudioSessionPortHeadphones] ||
        [routeStr isEqualToString:AVAudioSessionPortHeadsetMic];
    } else {
#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
        /* Known values of route:
         * "Headset"
         * "Headphone"
         * "Speaker"
         * "SpeakerAndMicrophone"
         * "HeadphonesAndMicrophone"
         * "HeadsetInOut"
         * "ReceiverAndMicrophone"
         * "Lineout"
         */
        NSRange headphoneRange = [routeStr rangeOfString : @"Head"];
        output = (headphoneRange.location != NSNotFound);
#endif //#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
    }
    return output;
}

- (BOOL)isHeadsetPluggedIn
{
    NSString* audioRoute = [self getFirstAudioSessionRouteOut];
    return [self isHeadsetRoute: audioRoute];
}

- (void)registerForHeadsetCallbacksOnObject:(id)object withSelector:(SEL)selector
{
    headsetCallbackId = object;
    headsetCallbackSelector = selector;
}


- (void) callCallbackWithString: (NSString*) callbackInput
{
    if( self->headsetCallbackSelector && self->headsetCallbackId)
    {
        // The code below is equivalent to :
        // [self->headsetCallbackId performSelector:self->headsetCallbackSelector withObject:callbackInput ];
        // but in an ARC approved way
        SEL selector = self->headsetCallbackSelector;
        IMP imp = [self->headsetCallbackId methodForSelector:selector];
        void (*func)(id, SEL, NSString*) = (void *)imp;
        func(self->headsetCallbackId, selector, callbackInput);
    }
}


-(void) enableSpeakerOverride
{
    if (is_ios_6)
    {
        //running on iOS 6.0.0 or higher
        [_audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    } else {
#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        [self oldIosPropertySetterWithRoute:audioRouteOverride];
#endif //#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
    }
}

-(void) disableSpeakerOverride
{
    if (is_ios_6)
    {
        //running on iOS 6.0.0 or higher
        [_audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    } else {
#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
        [self oldIosPropertySetterWithRoute:audioRouteOverride];
#endif //#if MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6
    }
}

#pragma mark - Volume functions

-(void) setSpeakerVolume: (float) volume
{
    if([self isSpeakerOutput])
    {
        float currentVolume = [RangeAudioManager getCurrentVolume];
        NSString* audioRoute = [self getFirstAudioSessionRouteOut];
        NSNumber* volumeOriginallyRead = self.volumeManager[audioRoute];
        if(volumeOriginallyRead == NULL)
        {
            self.volumeManager[audioRoute] = [NSNumber numberWithFloat:currentVolume];
        }
        
        if(currentVolume != volume)
        {
            [RangeAudioManager setCurrentVolume:volume];
        }
    } else {
        NSLog(@"setSpeakerVolume called without route being speaker.");
    }
}

-(void) captureVolume
{
    NSString* audioRoute = [self getFirstAudioSessionRouteOut];
    self.volumeManager[audioRoute] = [NSNumber numberWithFloat:[RangeAudioManager getCurrentVolume]];
}

-(void) returnToUserVolume
{
    NSString* audioRoute = [self getFirstAudioSessionRouteOut];
    NSNumber* volumeOriginallyRead = self.volumeManager[audioRoute];
    if(volumeOriginallyRead != NULL)
    {
        //returns volume to original setting
        [RangeAudioManager setCurrentVolume:[volumeOriginallyRead floatValue]];
    }
}

-(void) returnSpeakerVolume
{
    NSString* speakerRoute = kRSpeakerAndMicrophone;
    NSNumber* volumeOriginallyRead = self.volumeManager[speakerRoute];
    
    if(volumeOriginallyRead == NULL)
    {
        speakerRoute = kRSpeaker;
        volumeOriginallyRead = self.volumeManager[speakerRoute];
    }
    
    if(volumeOriginallyRead != NULL)
    {
        if([self prepareForAudioNotification] == YES)
        {
            //returns volume to original setting for this route
            [RangeAudioManager setCurrentVolume:[volumeOriginallyRead floatValue]];
            [self cleanUpAfterAudioNotification];
        }
        [self.volumeManager removeObjectForKey:kRSpeakerAndMicrophone];
        [self.volumeManager removeObjectForKey:kRSpeaker];
    }
}

#pragma mark - state transitions

-(void) destroyTransitionWithDisable: (BOOL) disable
{
    //    NSLog(@"destroyTransition state:%ld", self.audioState);
    
    if(self.audioState == kRangeAudioStateStarted ||
       self.audioState == kRangeAudioStateStopped ||
       self.audioState == kRangeAudioStatePaused
       )
    {
        bool destroyed_properly = false;
        NSError* error = nil;
        
        [self returnSpeakerVolume];
        // This must come after the returnSpeaker function
        [self stopWatchdog];
        [self returnToUserVolume];
        
        if(self.audioInput)
        {
            [self.audioInput immediateDestroyState];
        }
        self.audioInput = nil;
        
        if(self.audioOutput)
        {
            [self.audioOutput immediateDestroyState];
        }
        self.audioOutput = nil;
        
        // I may need to register callbacks to clean up all possible external audio structures
        // to break them down if we are in this function? Seems a bit extreme.
        
        if (![_audioSession setActive:NO error:&error]) {
            NSLog(@"AVAudioSession setActive:NO failed: %@", [error localizedDescription]);
        } else {
            destroyed_properly = true;
        }
        
        [self returnAudioCategoryAndMode];
        
        if(destroyed_properly)
        {
            if(disable == YES)
            {
                self.audioState = kRangeAudioStateDestroyedAndDisabled;
            } else {
                self.audioState = kRangeAudioStateDestroyed;
            }
        } else {
            NSLog(@"ERROR - audio not destroyed properly!");
        }
    } else if(self.audioState == kRangeAudioStateEnabledNotStarted) {
        if(disable == YES)
        {
            self.audioState = kRangeAudioStateDestroyedAndDisabled;
        } else {
            self.audioState = kRangeAudioStateDestroyed;
        }
    } else {
        NSLog(@"Trying to destroy audio from the wrong state: %ld", (long)self.audioState);
    }
}

// This gets called when we play an audio alert
- (void) pauseTransition
{
    //    NSLog(@"pauseTransition state:%ld", self.audioState);
    if(self.audioState == kRangeAudioStateStarted )
    {
        [self stopWatchdog];
        // If the sound effect doesn't clean up fast enough then burn it all down and rebuild.
        [self oneTimeWatchdog];
        
        [self.audioInput pauseRec];
        [self.audioOutput pause];
        
        self.audioState = kRangeAudioStatePaused;
    } else {
        NSLog(@"Trying to pause audio from the wrong state: %ld", (long)self.audioState);
    }
}

// This gets called when the Range is unplugged
-(void) stoppedTransition
{
    //    NSLog(@"stoppedTransition state:%ld", self.audioState);
    
    if(self.audioState == kRangeAudioStateStarted ||
       self.audioState == kRangeAudioStatePaused
       )
    {
        [self stopWatchdog];
        [self returnToUserVolume];
        
        [self.audioInput pauseRec];
        [self.audioOutput pause];
        
        self.audioState = kRangeAudioStateStopped;
    } else {
        NSLog(@"Trying to stop audio from the wrong state: %ld", (long)self.audioState);
    }
}

// The assumption is that this function only gets called if we know headphones are plugged in.
-(void) startedTransition
{
    //    NSLog(@"startedTransition state:%ld", self.audioState);
    
    if([self isHeadsetPluggedIn] == NO)
    {
        NSLog(@"We shouldn't be trying to transition to a start state if no headphones are plugged in.");
    }
    
    if(self.audioState == kRangeAudioStateUninit  ||
       self.audioState == kRangeAudioStateStopped ||
       self.audioState == kRangeAudioStateDestroyed ||
       self.audioState == kRangeAudioStateDestroyedAndDisabled ||
       self.audioState == kRangeAudioStateEnabledNotStarted
       )
    {
        NSError* error = nil;
        bool setup_properly = false;
        
        if( self.audioState == kRangeAudioStateUninit ||
           self.audioState == kRangeAudioStateDestroyed ||
           self.audioState == kRangeAudioStateDestroyedAndDisabled ||
           self.audioState == kRangeAudioStateEnabledNotStarted)
        {
            [self captureAudioCategoryAndMode];
        }
        
        [self setDefaultAudioCategoryAndMode];
        
        // Activate the audio session
        error = nil;
        if (![_audioSession setActive:YES error:&error]) {
            NSLog(@"AVAudioSession setActive:YES failed: %@", [error localizedDescription]);
        } else {
            setup_properly = true;
        }
        
        if(setup_properly)
        {
            if( self.audioState == kRangeAudioStateUninit ||
               self.audioState == kRangeAudioStateDestroyed ||
               self.audioState == kRangeAudioStateDestroyedAndDisabled ||
               self.audioState == kRangeAudioStateEnabledNotStarted)
            {
                // grab the volume
                [self captureVolume];
                
                // Set the alert volume now.
                [self enableSpeakerOverride];
                // wait until we are sure we are set to speaker output
                // We use a for loop because a while loop here is not worth an infinite hang
                for (int i =0; i < 100 && ![self isSpeakerOutput]; i++);
                [self setSpeakerVolume:defaultAlertVolume];
                [self disableSpeakerOverride];
            }
            
            if(self.audioOutput == nil)
            {
                self.audioOutput = [[RangeAudioOutput alloc] init];
            }
            
            if(self.audioInput == nil)
            {
                self.audioInput = [[RangeAudioInput alloc] init];
            }
            
            //set headphone volume to max. (This is required.)
            [RangeAudioManager setCurrentVolume: maxVolume];
            [self disableMicGain];
            
            [self.audioOutput play];
            [self.audioInput startRec];
            [self startWatchdog];
            
            self.audioState = kRangeAudioStateStarted;
        } else {
            NSLog(@"ERROR - audio not started properly!");
        }
    } else if (self.audioState == kRangeAudioStatePaused) {
        NSError* error = nil;
        bool setup_properly = false;
        
        [self setDefaultAudioCategoryAndMode];
        
        // Activate the audio session
        error = nil;
        if (![_audioSession setActive:YES error:&error]) {
            NSLog(@"AVAudioSession setActive:YES failed: %@", [error localizedDescription]);
        } else {
            setup_properly = true;
        }
        
        if(setup_properly)
        {
            [self disableMicGain];
            
            [self.audioOutput play];
            [self.audioInput startRec];
            [self startWatchdog];
            
            self.audioState = kRangeAudioStateStarted;
        } else {
            NSLog(@"ERROR - audio not started properly!");
        }
    } else {
        NSLog(@"Trying to start audio from the wrong state: %ld", (long)self.audioState);
    }
}

#pragma mark -
#pragma mark watchdog

-(void) startWatchdog
{
    if(self.watchdogTimer == nil)
    {
        self.watchdogTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                              target:self
                                                            selector:@selector(watchdogCheck)
                                                            userInfo:nil
                                                             repeats:YES];
    }
}

-(void) oneTimeWatchdog
{
    if(self.watchdogTimer == nil)
    {
        self.watchdogTimer = [NSTimer scheduledTimerWithTimeInterval:45
                                                              target:self
                                                            selector:@selector(watchdogCheck)
                                                            userInfo:nil
                                                             repeats:NO];
    } else {
        NSLog(@"oneTimeWatchdog not created because there the Timer is already non-nil");
    }
}

-(void) stopWatchdog
{
    [self.watchdogTimer invalidate];
    self.watchdogTimer = nil;
}

-(void) watchdogCheck
{
    if([self isHeadsetPluggedIn])
    {
        NSDate* now = [NSDate date];
        if(self.audioInput.lastParsedDataRead == nil || [now timeIntervalSinceDate:self.audioInput.lastParsedDataRead] > 5)
        {
            NSLog(@"Not seeing data produced. Trying to restart everything.");
            // Do a software reset if we are not getting any data.
            [self destroyTransitionWithDisable:NO];
            [self startedTransition];
        }
    }
}

#pragma mark -

- (BOOL) prepareForAudioNotification
{
    //    NSLog(@"prepare - NotificaionsCount: %d", audioNotificationCount);
    BOOL output = YES;
    if(self.audioState == kRangeAudioStateStarted ||
       self.audioState == kRangeAudioStateStopped ||
       self.audioState == kRangeAudioStatePaused ||
       self.audioState == kRangeAudioStateEnabledNotStarted )
    {
        if(audioNotificationCount < 0)
        {
            NSLog(@"audioNotificationCount is not balanced. Check that you are calling prepare and cleanup at the right times.");
        }
        
        if(audioNotificationCount == 0)
        {
            if(self.audioState == kRangeAudioStateStarted)
            {
                [self pauseTransition];
            }
            
            [self enableSpeakerOverride];
            // Wait until we are sure we are set to speaker output.
            // We use a for loop because a while loop here is not worth an infinite hang.
            for (int i =0; i < 100 && ![self isSpeakerOutput]; i++);
            
            output = [self isSpeakerOutput];
            
            if(output)
            {
                [self setSpeakerVolume:defaultAlertVolume];
            } else {
                NSLog(@"We are not setting the speaker volume as we were expecting. If this is an iPod (3rd gen) then this is expected.");
            }
        }
        
        audioNotificationCount++;
    } else {
        NSLog(@"prepareForAudioNotification called in wrong AudioState. In state: %ld", (long)self.audioState);
    }
    
    return output;
}

- (void) cleanUpAfterAudioNotification
{
    //    NSLog(@"clean - NotificaionsCount: %d", audioNotificationCount);
    if(self.audioState == kRangeAudioStateStarted ||
       self.audioState == kRangeAudioStateStopped ||
       self.audioState == kRangeAudioStatePaused ||
       self.audioState == kRangeAudioStateEnabledNotStarted)
    {
        audioNotificationCount--;
        if(audioNotificationCount == 0)
        {
            [self disableSpeakerOverride];
            if(self.audioState == kRangeAudioStatePaused)
            {
                [self startedTransition];
            } else if(self.audioState == kRangeAudioStateStopped) {
                NSLog(@"Error - cleanUpAfterAudioNotification supposed to be in a paused state.");
                // Try to start anyway
                [self startedTransition];
            } else if(self.audioState == kRangeAudioStateStarted) {
                NSLog(@"Error - cleanUpAfterAudioNotification supposed to not be started already.");
            }
        }
        
        if(audioNotificationCount < 0)
        {
            NSLog(@"audioNotificationCount is not balanced. Check that you are calling prepare and cleanup at the right times.");
        }
    } else{
        NSLog(@"cleanUpAfterAudioNotification called in wrong AudioState. In state: %ld", (long)self.audioState);
    }
}

- (void) prepareForAppQuitting
{
    [self returnToUserVolume];
    [self returnSpeakerVolume];
    
    [self destroyTransitionWithDisable:NO];
}

- (void) rangeStartAllWithCallback
{
    [self startedTransition];
    [self callCallbackWithString:kRHeadphoneInsertion];
}

- (void) rangeStopAllWithCallback
{
    if(self.audioState == kRangeAudioStateStarted ||
       self.audioState == kRangeAudioStateStopped ||
       self.audioState == kRangeAudioStatePaused)
    {
        [self stoppedTransition];
    }
    [self callCallbackWithString:kRHeadphoneRemoval];
}

- (RangeDataManager*) allTemperatures
{
    if(self.audioInput)
    {
        return [self.audioInput allTemperatures];
    } else {
        return nil;
    }
}

@end

#endif //!(TARGET_IPHONE_SIMULATOR)
