//
//  RangeAudioManager_internal.h
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

#import "RangeAudioManager.h"
#import "RangeAudioOutput.h"
#import "RangeAudioInput.h"
#import <MediaPlayer/MediaPlayer.h>

// SDK USER! - set this to 0 if your app doesn't run on any versions of iOS before 6
// It will get rid of a number of deprecation warnings.
#define MY_APP_DOES_RUN_ON_EARLIER_THAN_IOS_6 1


/*!
 It is unnecessary for the SDK end-user to directly use anything in this file.
 */

typedef NS_ENUM(NSInteger, RangeAudioState) {
    kRangeAudioStateUninit      = 0,
    kRangeAudioStateStarted     = 1,
    kRangeAudioStateStopped     = 2,
    kRangeAudioStatePaused      = 3,
    kRangeAudioStateDestroyed   = 4,
    kRangeAudioStateEnabledNotStarted = 5,
    kRangeAudioStateDestroyedAndDisabled   = 6,
};


@interface RangeAudioManager()
{
    AVAudioSession* _audioSession;
    id headsetCallbackId;
    SEL headsetCallbackSelector;
    bool is_ios_6;
    int audioNotificationCount;
}

@property (strong, readwrite) RangeAudioInput* audioInput;
@property (strong, readwrite) RangeAudioOutput* audioOutput;
@property (strong, readwrite) RangeDataManager* rangeDataManager;
// maps the route to its last read volume
@property (strong, readwrite) NSMutableDictionary* volumeManager;

@property (assign, readwrite) RangeAudioState audioState;

@property (strong, readwrite) NSString * originalCategory;
@property (assign, readwrite) AVAudioSessionCategoryOptions originalOptions;
@property (strong, readwrite) NSString * originalMode;

@property (strong, readwrite) NSTimer * watchdogTimer;

- (void) prepareForAppQuitting;
- (RangeDataManager*) allTemperatures;

@end
