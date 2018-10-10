//
//  RangeTemperatureTranslator.m
//
//  Created by David Clift-Reaves
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

#import "RangeTemperatureTranslator.h"

@interface RangeTemperatureTranslator()
{
    RangeTemperatureScale _currentScale;
}

@end


@implementation RangeTemperatureTranslator

+ (RangeTemperatureTranslator *)sharedInstance
{
    static RangeTemperatureTranslator *sharedSingleton;
    
    @synchronized(self)
    {
        if (!sharedSingleton)
            sharedSingleton = [[RangeTemperatureTranslator alloc] init];
        
        return sharedSingleton;
    }
}

- (instancetype)init
{
    if ( self = [super init] ) {
        _currentScale = kRangeTemperatureScaleFahrenheit;
        
        return self;
    } else {
        return nil;
    }
}

#pragma mark - Scale functions
- (RangeTemperatureScale) currentScale
{
    @synchronized(self)
    {
        return _currentScale;
    }
}

- (void) setCurrentScale:(RangeTemperatureScale) scaleType
{
    @synchronized(self)
    {
        _currentScale = scaleType;
    }
}

#pragma mark - Translation functions
- (float) translateSample: (float) rawSample
{
    return [self translateSample:rawSample toScale:_currentScale];
}

- (float) translateSample: (float) rawSample toScale: (RangeTemperatureScale) scaleType
{
    switch (scaleType) {
        case kRangeTemperatureScaleKelvin:
            return ((rawSample - 32.0f) * (5.0f/9.0f)) + 273.15f;
            break;
        case kRangeTemperatureScaleCelcius:
            return (rawSample - 32.0f) * 5.0f/9.0f;
            break;
        case kRangeTemperatureScaleFahrenheit:
            return rawSample;
            break;
        default:
            // ERROR
            return 0.0f;
            break;
    }
}

- (float) translateToRawSampleOtherSample: (float) otherScaleSample fromScale:(RangeTemperatureScale) startingScaleType
{
    switch (startingScaleType) {
        case kRangeTemperatureScaleKelvin:
            return (otherScaleSample - 274.15f) * (9.0f/5.0f) + 32.0f;
            break;
        case kRangeTemperatureScaleCelcius:
            return (otherScaleSample * (9.0f/5.0f)) + 32.0f;
            break;
        case kRangeTemperatureScaleFahrenheit:
            return otherScaleSample;
            break;
        default:
            // ERROR
            return 0.0f;
            break;
    }
}

- (float) translateOtherSample: (float) otherScaleSample fromScale:(RangeTemperatureScale) startingScaleType toScale: (RangeTemperatureScale) finalScaleType
{
    float rawEquivalent = [self translateToRawSampleOtherSample:otherScaleSample fromScale:startingScaleType];
    return [self translateSample:rawEquivalent toScale:finalScaleType];
}

#pragma mark - Rounding functions
- (float) translateAndRoundSample: (float) rawSample withFormat: (RangeTemperaturePrintFormat) formatType
{
    return [self translateAndRoundSample:rawSample withFormat:formatType toScale:_currentScale];
}

- (float) translateAndRoundSample: (float) rawSample withFormat: (RangeTemperaturePrintFormat) formatType toScale: (RangeTemperatureScale) scaleType
{
    float translatedSample = [self translateSample:rawSample toScale:scaleType];
    
    switch (formatType) {
        case kRangeTemperaturePrintFormatHumanReadable:
        {
            switch (scaleType) {
                case kRangeTemperatureScaleKelvin:
                case kRangeTemperatureScaleCelcius:
                    // round to the nearest tenth of a degree
//                    return roundf(translatedSample * 10.0f) / 10.0f;
                    return roundf(translatedSample);
                    break;
                case kRangeTemperatureScaleFahrenheit:
                    // round to the nearest degree
                    return roundf(translatedSample);
                    break;
                default:
                    // ERROR
                    return NAN;
                    break;
            }
        }
            break;
        case kRangeTemperaturePrintFormatRawData:
        {
            switch (scaleType) {
                case kRangeTemperatureScaleKelvin:
                case kRangeTemperatureScaleCelcius:
                    // round to the nearest hundreth of a degree
                    return roundf(translatedSample * 100.0f) / 100.0f;
                    break;
                case kRangeTemperatureScaleFahrenheit:
                    // round to the nearest tenth of a degree
                    return roundf(translatedSample * 10.0f) / 10.0f;
                    break;
                default:
                    // ERROR
                    return NAN;
                    break;
            }
        }
            break;
        default:
            // ERROR
            return NAN;
            break;
    }
}


#pragma mark - String output functions

- (NSString *) printSample:(float) rawSample withFormat: (RangeTemperaturePrintFormat) formatType
{
    return [self printSample:rawSample withFormat:formatType withScale:_currentScale];
}

- (NSString *) printSample:(float) rawSample withFormat: (RangeTemperaturePrintFormat) formatType withScale: (RangeTemperatureScale) scaleType
{
    float translatedSample = [self translateAndRoundSample:rawSample withFormat:formatType toScale:scaleType];
    
    switch (formatType) {
        case kRangeTemperaturePrintFormatHumanReadable:
        {
            switch (scaleType) {
                case kRangeTemperatureScaleKelvin:
                case kRangeTemperatureScaleCelcius:
//                    return [NSString stringWithFormat:@"%.1fº", translatedSample];
                    return [NSString stringWithFormat:@"%.0fº", translatedSample];
                    break;
                case kRangeTemperatureScaleFahrenheit:
                    return [NSString stringWithFormat:@"%.0fº", translatedSample];
                    break;
                default:
                    // ERROR
                    return @"ErrorTemperatureScale";
                    break;
            }
        }
            break;
        case kRangeTemperaturePrintFormatRawData:
        {
            switch (scaleType) {
                case kRangeTemperatureScaleKelvin:
                case kRangeTemperatureScaleCelcius:
                    return [NSString stringWithFormat:@"%.2f", translatedSample];
                    break;
                case kRangeTemperatureScaleFahrenheit:
                    return [NSString stringWithFormat:@"%.1f", translatedSample];
                    break;
                default:
                    // ERROR
                    return @"ErrorTemperatureScale";
                    break;
            }
        }
            break;
        default:
            // ERROR
            return @"ErrorTemperatureFormat";
            break;
    }
    
}

@end