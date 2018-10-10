//
//  RangeAudioInput.h
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

#import "RangeDataManager.h"

/*!
 Range reads audio information to convert to data.
 This class reads that sound and manages audio input.
 
 It is unnecessary for the SDK end-user to directly use this class.
 */
@interface RangeAudioInput : NSObject

/*!
 Get all the read RangeData objects.
 Hands control of object to caller.
 */
- (RangeDataManager*) allTemperatures;

/*!
 Start the audio data aquisition.
 */
- (void) startRec;

/*!
 Pause the audio data aquisition.
 */
- (void) pauseRec;

/*!
 Destroys all state related to this object. The underlying AudioQueues require us to use global resources.
 We can't rely on dealloc to do things in the proper order.
 */
-(void) immediateDestroyState;

/*!
 NSDate of the last time we have properly parsed any data.
 */
@property (strong, readonly) NSDate* lastParsedDataRead;

@end
