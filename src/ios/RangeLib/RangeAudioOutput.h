//
//  RangeAudioOutput.h
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

/*!
 Range requires a special sound to be playing at all times when it is plugged in
 to generate its power. This class generates that sound.
 
 It is unnecessary for the SDK end-user to directly use this class.
 */
@interface RangeAudioOutput : NSObject

/*!
 Pauses the sound that acts as the power to the Range.
 This effectively removes power from the Range.
 */
- (void) pause;

/*!
 Starts (or resumes) the sound that acts as the power to the Range.
 This effectively turns the Range on.
 @return YES if the audio was able to start playing.
 */
- (BOOL) play;

/*!
 Destroys all state related to this object. The underlying AudioQueues require us to use global resources.
 We can't rely on dealloc to do things in the proper order.
 */
-(void) immediateDestroyState;

@end
