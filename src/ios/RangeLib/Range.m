//
//  Range.m
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

#if (TARGET_IPHONE_SIMULATOR)
// Feel free to comment this out if you want to compile your code
// for the simulator with the Range SDK calls ifdefed out.
#warning Range SDK is only somewhat supported on the iOS simulator. Make sure to test on actual hardware.
// What does somewhat supported mean? It means that you will get data if you are
// calling things correctly but the data will be based on the current time.
// Currently the behavior is that the raw temperatures (always in fahrenheit) are simply the unix time mod 90.
//
// You will also probably get data if you don't call things correctly.
// The simulation doesn't check to see if you call things in the right order
// or let you test insertion/removal callbacks. It is simply meant to be a way for the SDK user
// to get data in the proper format in the simulator for simple testing. It lets you
// test your temperature parsing/translation, UI behavior based on temperatures,
// or temperature triggering behavior.
//
// All of that to say that my suggested testing for an SDK user would be:
// * Start with simulator just to see what things should look like.
// * Immediately test on a real device to see what the real behavior is like.
// * Do the majority of your development interaction with the SDK on a real device.
// * Occasionally go back to the simulator to prototype or (sort of) unit test
//   either UI behavior or triggering behavior.
#endif

#import "Range.h"
#import "RangeTemperatureTranslator.h"
#import <MediaPlayer/MediaPlayer.h>
#import "RangeAudioManager_internal.h"
#import <Cordova/CDVPlugin.h>


@interface Range()

@property (strong, readwrite) RangeTemperatureTranslator* temperatureTranslator;
@property (strong, readwrite) RangeDataManager* rangeDataManager;
@property (strong, readwrite) RangeAudioManager* audioManager;

@end

@implementation Range

+ (Range *)sharedInstance
{
    static Range *sharedSingleton;
    
    @synchronized(self)
    {
        if (!sharedSingleton)
            sharedSingleton = [[Range alloc] init];
        
        return sharedSingleton;
    }
}

- (instancetype)init
{
    if (self = [super init])
    {    
        self.temperatureTranslator = [RangeTemperatureTranslator sharedInstance];
        self.rangeDataManager = [[RangeDataManager alloc] init];
        self.audioManager = [RangeAudioManager sharedInstance];
        
        return self;
    } else {
        return nil;
    }
}

- (void) prepareForAppQuitting
{
    [self.audioManager prepareForAppQuitting];
}

- (void) refreshRangeDataManager
{
#if (TARGET_IPHONE_SIMULATOR)
    BOOL addSuccess = [self.rangeDataManager addRangeManager:[self.audioManager allTemperatures]];
    if(!addSuccess)
    {
        NSLog(@"We were unable to merge our RangeManagers.");
    }
#else
    if(self.audioManager)
    {
        BOOL addSuccess = [self.rangeDataManager addRangeManager:[self.audioManager allTemperatures]];
        if(!addSuccess)
        {
            NSLog(@"We were unable to merge our RangeManagers.");
        }
    } else {
        NSLog(@"Can't refresh dataManager if Audio hasn't been initilized yet.");
    }
#endif // TARGET_IPHONE_SIMULATOR
    
}

- (RangeDataManager*) allRangeData
{
    return self.rangeDataManager;
}


@end