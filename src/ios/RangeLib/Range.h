//
//  Range.h
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

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@class RangeDataManager;

// These headers are included as a convenience so that SDK users
// can just import "Range.h" and get everything they need.
#import "RangeTrigger.h"
#import "RangeDataManager.h"
#import "RangeAudioManager.h"
#import "RangeTemperatureTranslator.h"

// General SDK information :
//
// NOTE: This library currently only compiles to ARM architectures.
// This means that using x86 based processors (Simulator) will cause linker errors.
// You will need to have physical Range hardware to test the SDK. Luckily they are easy to get!
// http://supermechanical.com/range
//
//
// Currently this code takes control of the audio system of the iOS device.
// It does this by creating an AVAudio session and making it a "PlayAndRecord" category session.
// You should setup your project to allow background processing of audio to get the full Range library functionality.
// The library watches for a headphone jack being plugged in and starts playing special audio when it is.
// No other sounds should be playing while the Range is plugged in.
// Any other source of sound can cause the Range to not work properly.
// If you want to play a short sound through the iOS device's internal speaker we have made accommodations for that.


// I have attempted to keep all of the iOS-device-subsystem-controlling code as open source
// as possible. I want you to understand what we are doing so we don't step on each other's toes.
// If you find a better way to achieve what we are doing then please contact us and let us know.

/*!
 Singleton class for interacting with Range hardware.
 */
@NativeStorage : CDVPlugin

/*!
 Convenience property to access the temperature translator singleton.
 This is used to convert raw stored temperatures into any arbitrary scale.
 */
@property (strong, readonly) RangeTemperatureTranslator* temperatureTranslator;

/*!
    This is now the object in which all audio functions should be called on.
    Most functions should only be called if the enableAudio function has been called first
    and disableAudio has not been called.
 */
@property (strong, readonly) RangeAudioManager* audioManager;

/*!
 There should only ever exist a single instance of Range.
 This function provides a reference to that singleton.
 Never call alloc/init/new on Range.
 @return Reference to the only instance of this class.
 */
+ (Range *)sharedInstance;

/*!
 This invalidates all previous pointers to range_sample_t. Those should never be stored between calls to this function.
 Use @synchronized(range) to keep this function from be called when you are accessing the Range object from other threads.
 */
- (void) refreshRangeDataManager;

/*!
 Call this function to get a pointer to all the data currently seen by the Range object.
 If you want to update the data in the RangeDataManager with the latest data then call refreshRangeDataManager
 
 @return Reference to the RangeDataManager.
 */
- (RangeDataManager*) allRangeData;

/*!
 This function allows us to clean up some things when the app exits.
 Mostly this has to do with returning various volumes to their original values.
 Not calling this on exit will cause volumes to be left in a max volume state.
 */
- (void) prepareForAppQuitting;

@end
