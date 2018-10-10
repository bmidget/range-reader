//
//  RangeTrigger.h
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
#import "RangeData.h"

//==================================================================================================
#pragma mark   RangeTriggerDirection options

/*!
 @enum           RangeTriggerDirection options
 @abstract       These are the directions that the temperature can travel to generate a trigger.
 
 @constant       kRangeTriggerDirectionUnset
 The default constant. It is the same as null.
 @constant       kRangeTriggerDirectionRising
 The constant for setting a trigger that occurs when a series of temperatures is increasing.
 @constant       kRangeTriggerDirectionFalling
 The constant for setting a trigger that occurs when a series of temperatures is decreasing.
 @constant       kRangeTriggerDirectionBidirectional
 The constant for setting a trigger that occurs when a series of temperatures is either increasing or decreasing.
 */
typedef NS_ENUM(UInt32, RangeTriggerDirection) {
    kRangeTriggerDirectionUnset,
    kRangeTriggerDirectionRising,
    kRangeTriggerDirectionFalling,
    kRangeTriggerDirectionBidirectional,
};

//==================================================================================================
#pragma mark -
#pragma mark RangeTrigger class
/*!
 One of the most common things to do with temperature data is to set actions based on temperature thresholds.
 This class helps the SDK-user to create these triggering behaviors properly.
 */
@interface RangeTrigger : NSObject <NSCoding>

#pragma mark - Properties
@property (nonatomic, readonly) float triggerTemperature;
@property (nonatomic, readonly) RangeTriggerDirection direction;

#pragma mark - Class functions
/*!
 This function allows you to toggle through all the RangeTriggerDirection directions
 without hitting the uninit state.

 @return The next toggled direction in the set.
 */
+ (RangeTriggerDirection) toggleDirection: (RangeTriggerDirection) direction;

#pragma mark - Member functions
/*!
 This should be the only way you init this object.
 Don't translate the temperature to a different scale. Only use raw temperatures as input.
 
 @param rawTemperature
 The trigger set point given in the raw temperature scale.
 
 @param direction
 The enum describing which direction the temperature has to change to generate a trigger.
 
 @return a new object with the set point and trigger direction set.
 */
- (instancetype) initTriggerWithTemperature: (float) rawTemperature andDirection: (RangeTriggerDirection) direction;

/*!
 Check the supplied raw data point to see if a trigger has occured.
 This is the main function that should be called on this class. All 
 (or an appropriate subset) of the raw data should be fed into this 
 function to determine if it satisfies the trigger.
 
 @return YES if a trigger occured based on the current input data point. NO otherwise.
 */
- (BOOL) isTriggerForRawData: (const range_sample_t*) rawData;

/*!
 This function allows you to change the properties of the trigger.
 It resets the inner state machine of the trigger.
 NOTE: Do not call this in function if you want to use this class in a multi-threaded environment.
 (or if you do then lock the object on trigger checks and this function call.)
 
 @param rawTemperature
 The trigger set point given in the raw temperature scale.
 
 @param direction
 The enum describing which direction the temperature has to change to generate a trigger.
 */
- (void) changeTriggerTemperature: (float) rawTemperature andDirection: (RangeTriggerDirection) direction;

@end
