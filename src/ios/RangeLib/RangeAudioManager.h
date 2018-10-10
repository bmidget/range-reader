//
//  RangeAudioManager.h
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

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

static NSString * const kRHeadphoneInsertion;
static NSString * const kRHeadphoneRemoval;

// callback block type definition
typedef void (^MicPermissionHandler_t)(BOOL);

@interface RangeAudioManager : NSObject <AVAudioPlayerDelegate>

#pragma mark - class functions
/*!
 We use this function to request that our app be given microphone permissions.
 See the SDK example for usage.
 */
+ (void) requestMicrophonePermission: (MicPermissionHandler_t) handler;

/*!
 SDK user should not use this function directly!
 The Range class uses it.
 */
+ (RangeAudioManager *)sharedInstance;

#pragma mark - member functions

/*!
 Call this function periodically to verify that the user hasn't
 accidentally changed the volume and cut power to the Range.
 
 @return YES if the volume had to be fixed.
 */
- (BOOL) checkAndFixPowerVolume;

/*!
 Convenience function to easily determine if there is something plugged into the headset port.
 
 @return YES if headset is currently plugged in to the audio port. NO otherwise.
 */
- (BOOL) isHeadsetPluggedIn;

/*!
 Allows a user to process some data when we detect a headset insertion.
 @code
 // Example of callback selector.
 // direction should be cast to a NSString*
 -(void) func: (id) direction;
 @endcode
 
 @param object
 The object that the callback selector will be called on
 @param selector
 The selector that is called on the object parameter. See code example of callback selector type.
 */
- (void) registerForHeadsetCallbacksOnObject:(id)object withSelector:(SEL)selector;

/*!
 We should return the global volume back to whatever the user had it to before Range was started.
 Range requires the volume to be turned up to max to get the appropriate amount of power.
 */
- (void) returnToUserVolume;

// If you want to play your own sounds then call these functions
// before and after you play the sound, respectively.
// Because of how iOS routes audio, your sounds can only play via the iPhone/iPad internal speakers.
// The time between the calls should be very short. (No temperature data will be recorded during this time.)

/*!
 Call this function before playing a sound effect.
 Note: Do not call cleanUpAfterAudioNotification if this function returns NO.
 
 @return YES if preparation was successful and the speaker is set to output.
 */
- (BOOL) prepareForAudioNotification;

/*!
 Call this function after playing a sound effect.
 */
- (void) cleanUpAfterAudioNotification;


/*!
 Verifies if the RangeAudioManager thinks that it currently has control of the Audio.
 */
-(BOOL) isAudioEnabled;

/*!
 This enables the Range code to have full control of the iOS audio system.
 Other code should not try to generate any sounds when Range audio control is enabled.
 With the exception of short sound effects that can be played with prepare/cleanup functions provided.
 This function should be called after registering for "headset callbacks".
 It will trigger a headset callback if a headset is plugged in when enabling.
 
 */
-(void) enableAllAudio;

/*!
 This function tries to return the control of the audio system back to the SDK user's code.
 It puts the audio category and mode back in the state they were in when the audio was enabled.
 The user should call the audioSession "setActive" function after calling this function to re-enable their normal session.
 */
-(void) disableAllAudio;

@end
