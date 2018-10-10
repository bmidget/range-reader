//
//  RangeTrigger.m
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

#import "RangeTrigger.h"

@interface RangeTrigger()
{
}

#pragma mark - persisted properties
@property (nonatomic) float triggerTemperature;
@property (nonatomic) RangeTriggerDirection direction;

#pragma mark - transient properties
@property (nonatomic) BOOL isDataEverRead;
@property (nonatomic) float lastTemperatureRead;
@property (nonatomic) float hysteresisOffset;
@property (nonatomic) BOOL isHysteresisEnabled;

@end


@implementation RangeTrigger

+ (RangeTriggerDirection) toggleDirection: (RangeTriggerDirection) direction
{
    NSUInteger tempInt = direction;
    const NSUInteger numberOfTriggerDirections = 4;
    tempInt = (tempInt + 1) % numberOfTriggerDirections;
    // the first enum is just a defualt value that is not valid for normal use.
    if(tempInt == 0) tempInt++;
    return (RangeTriggerDirection) tempInt;
}

- (instancetype) initTriggerWithTemperature: (float) rawTemperature andDirection: (RangeTriggerDirection) direction
{
    if ( self = [super init] ) {
        [self changeTriggerTemperature:rawTemperature andDirection:direction];

        return self;
    } else {
        return nil;
    }
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    float rawTemperature = [decoder decodeDoubleForKey:@"rawTriggerTemperature"];
    RangeTriggerDirection direction = [decoder decodeInt32ForKey:@"direction"];

    [self changeTriggerTemperature:rawTemperature andDirection:direction];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeDouble:self.triggerTemperature forKey:@"rawTriggerTemperature"];
    [encoder encodeInt32:self.direction forKey:@"direction"];
}

#pragma mark - Member functions

- (void) changeTriggerTemperature: (float) rawTemperature andDirection: (RangeTriggerDirection) direction
{
    self.isDataEverRead = NO;
    self.lastTemperatureRead = 0.0f;
    self.triggerTemperature = rawTemperature;
    self.hysteresisOffset = [RangeTrigger hysOffsetBasedOnTemp:rawTemperature];
    self.direction = direction;
    self.isHysteresisEnabled = NO;
}

- (BOOL) isTriggerForRawData: (const range_sample_t*) rawData
{
    float currentTemperature = rawData->temperature;
    BOOL output = NO;
    if(self.isDataEverRead == NO)
    {
        self.isDataEverRead = YES;
        self.lastTemperatureRead = currentTemperature;
    }
    else
    {
        RangeTriggerDirection outputDirection = kRangeTriggerDirectionUnset;
        
        // Check for crossings across an alert’s boundary, and in which direction, gated with hysteresis
        if((self.lastTemperatureRead < self.triggerTemperature) && (currentTemperature >= self.triggerTemperature))
        {
            if(self.isHysteresisEnabled == NO)
            {
                outputDirection = kRangeTriggerDirectionRising;
                self.isHysteresisEnabled = YES;
            }
        }
        else if ((self.lastTemperatureRead > self.triggerTemperature) && (currentTemperature <= self.triggerTemperature))
        {
            if(self.isHysteresisEnabled == NO)
            {
                outputDirection = kRangeTriggerDirectionFalling;
                self.isHysteresisEnabled = YES;
            }
        }
        
        // State machine for resetting the hysteresis gating of a given alert
        if((self.direction == kRangeTriggerDirectionRising) &&
           (currentTemperature < (self.triggerTemperature - self.hysteresisOffset)))
        {
            self.isHysteresisEnabled = NO;
        }
        else if((self.direction == kRangeTriggerDirectionFalling) &&
                (currentTemperature > (self.triggerTemperature + self.hysteresisOffset)))
        {
            self.isHysteresisEnabled = NO;
        }
        else if((self.direction == kRangeTriggerDirectionBidirectional) &&
                (fabsf(currentTemperature - self.triggerTemperature) > self.hysteresisOffset))
        {
            self.isHysteresisEnabled = NO;
        }
        
        // Check if there was a crossing that matches the polarity setting of a given alert
        if(self.direction == outputDirection)
        {
            output = YES;
        }
        else if((self.direction == kRangeTriggerDirectionBidirectional) &&
                (outputDirection != kRangeTriggerDirectionUnset ) )
        {
            output = YES;
        }
    }
    
    self.lastTemperatureRead = currentTemperature;
    return output;
}


// Function for determining the hysteresis range appropriate for a given alert temperature
+ (float) hysOffsetBasedOnTemp: (float) alertTemp
{
    float offset = 0.0f;
    // Piecewise linear function that takes alertTemp and
    // generates offset based on these (alertTemp, offset) pairs, in degrees F:
    // (-40, 10) (75, 2) (450, 10)
    if( alertTemp > 75.0f)
    {
        offset = (8.0f/375.0f) * alertTemp + (2.0f/5.0f);
    } else {
        offset = (-8.0f/115.0f) * alertTemp + (166.0f/23.0f);
    }
    
    return offset;
}

//// A very simple quick unit test for sanity checking things.
//
//#define LOG_HYS(var) NSLog(@"%s = %f", #var, var)
//#define LOG_TRIG(var) if([var isTriggerForRawData:sample]) NSLog(@"%s: triggered at time: %f on temp: %f", #var, sample->unix_time, sample->temperature)
//
//+ (void) simpleUnitTest
//{
//
//    float hyst_neg_60 = [RangeTrigger hysOffsetBasedOnTemp:-60];
//    float hyst_neg_40 = [RangeTrigger hysOffsetBasedOnTemp:-40];
//    float hyst_neg_10 = [RangeTrigger hysOffsetBasedOnTemp:-10];
//    float hyst_0 = [RangeTrigger hysOffsetBasedOnTemp:0];
//    float hyst_10 = [RangeTrigger hysOffsetBasedOnTemp:10];
//    float hyst_40 = [RangeTrigger hysOffsetBasedOnTemp:40];
//    float hyst_60 = [RangeTrigger hysOffsetBasedOnTemp:60];
//    float hyst_75 = [RangeTrigger hysOffsetBasedOnTemp:75];
//    float hyst_90 = [RangeTrigger hysOffsetBasedOnTemp:90];
//    float hyst_120 = [RangeTrigger hysOffsetBasedOnTemp:120];
//    float hyst_150 = [RangeTrigger hysOffsetBasedOnTemp:150];
//    float hyst_200 = [RangeTrigger hysOffsetBasedOnTemp:200];
//    float hyst_300 = [RangeTrigger hysOffsetBasedOnTemp:300];
//    float hyst_350 = [RangeTrigger hysOffsetBasedOnTemp:350];
//    float hyst_400 = [RangeTrigger hysOffsetBasedOnTemp:400];
//    float hyst_500 = [RangeTrigger hysOffsetBasedOnTemp:500];
//    
//    LOG_HYS(hyst_neg_60);
//    LOG_HYS(hyst_neg_40);
//    LOG_HYS(hyst_neg_10);
//    LOG_HYS(hyst_0);
//    LOG_HYS(hyst_10);
//    LOG_HYS(hyst_40);
//    LOG_HYS(hyst_60);
//    LOG_HYS(hyst_75);
//    LOG_HYS(hyst_90);
//    LOG_HYS(hyst_120);
//    LOG_HYS(hyst_150);
//    LOG_HYS(hyst_200);
//    LOG_HYS(hyst_300);
//    LOG_HYS(hyst_350);
//    LOG_HYS(hyst_400);
//    LOG_HYS(hyst_500);
//    
//    RangeTrigger* risingTrigger = [[RangeTrigger alloc] initTriggerWithTemperature:135 andDirection:RangeTriggerDirectionRising];
//    RangeTrigger* risingHighTrigger = [[RangeTrigger alloc] initTriggerWithTemperature:350 andDirection:RangeTriggerDirectionRising];
//    RangeTrigger* fallingTrigger = [[RangeTrigger alloc] initTriggerWithTemperature:34 andDirection:RangeTriggerDirectionFalling];
//    RangeTrigger* biTrigger = [[RangeTrigger alloc] initTriggerWithTemperature:60 andDirection:RangeTriggerDirectionBidirectional];
//    
//    range_sample_t fakeData[] = {
//        { 200, 0},
//        { 300, 1},
//        { 350, 2},
//        { 351, 3},
//        { 349, 4},
//        { 351, 5},
//        { 120, 6},
//        { 380, 7},
//        { 30, 8},
//        { 70, 9},
//    };
//    
//    for(int i =0 ; i < (sizeof(fakeData)/ sizeof(range_sample_t)); i++)
//    {
//        const range_sample_t * sample = &(fakeData[i]);
//        LOG_TRIG(risingTrigger);
//        LOG_TRIG(risingHighTrigger);
//        LOG_TRIG(fallingTrigger);
//        LOG_TRIG(biTrigger);
//    }
//    
////    2014-03-17 16:54:12.228 Range[6707:907] risingHighTrigger: triggered at time: 2.000000 on temp: 350.000000
////    2014-03-17 16:54:12.229 Range[6707:907] risingTrigger: triggered at time: 7.000000 on temp: 380.000000
////    2014-03-17 16:54:12.230 Range[6707:907] risingHighTrigger: triggered at time: 7.000000 on temp: 380.000000
////    2014-03-17 16:54:12.230 Range[6707:907] fallingTrigger: triggered at time: 8.000000 on temp: 30.000000
////    2014-03-17 16:54:12.231 Range[6707:907] biTrigger: triggered at time: 8.000000 on temp: 30.000000
////    2014-03-17 16:54:12.232 Range[6707:907] biTrigger: triggered at time: 9.000000 on temp: 70.000000
//    
//}


@end
