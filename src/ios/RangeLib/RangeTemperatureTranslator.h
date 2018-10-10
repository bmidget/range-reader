//
//  RangeTemperatureTranslator.h
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

#import <Foundation/Foundation.h>

//==================================================================================================
#pragma mark    RangeTemperature Scales

/*!
 @enum           RangeTemperature scale types
 @abstract       These scales are used to describe which temperature scale is being used.
 @constant       kRangeTemperatureScaleKelvin
 The constant for the Kelvin temperature scale.
 @constant       kRangeTemperatureScaleCelcius
 The constant for the Celcius temperature scale.
 @constant       kRangeTemperatureScaleFahrenheit
 The constant for the Fahrenheit temperature scale.
 */
typedef NS_ENUM(UInt32, RangeTemperatureScale) {
    kRangeTemperatureScaleKelvin    = 2,
    kRangeTemperatureScaleCelcius  = 1,
    kRangeTemperatureScaleFahrenheit    = 0
};

//==================================================================================================
#pragma mark    Formats for printing a Temperature

/*!
 @enum           RangeTemperaturePrintFormat options
 @abstract       These are the choices for how to print temperatures based on various requirements.

 @constant       kRangeTemperaturePrintFormatHumanReadable
 The constant for printing the temperature in a human readable way.
 @constant       kRangeTemperaturePrintFormatRawData
 The constant for printing the temperature in a simple computer readable way.
 */
typedef NS_ENUM(UInt32, RangeTemperaturePrintFormat) {
    kRangeTemperaturePrintFormatHumanReadable  = 1,
    kRangeTemperaturePrintFormatRawData    = 0
};

//==================================================================================================
#pragma mark -
#pragma mark RangeTemperatureTranslator class

/*!
 This class contains a set of functions to help in translating from the raw data read into RangeData to data meaningful for the end user.
 */
@interface RangeTemperatureTranslator : NSObject

/*!
 There should only ever exist a single instance of RangeTemperatureTranslator.
 This function provides a reference to that singleton.
 Never call alloc/init/new on RangeTemperatureTranslator.
 @return Reference to the only instance of this class.
 */
+ (RangeTemperatureTranslator *)sharedInstance;

#pragma mark - Scale functions
/*!
 Read the currently set temperature scale.
 @return The currently set temperature scale that all raw samples will be translated to.
 */
- (RangeTemperatureScale) currentScale;

/*!
 Set the current temperature scale.
 
 @param scaleType
 The temperature scale that all future temperature translations should default to.
 */
- (void) setCurrentScale:(RangeTemperatureScale) scaleType;

#pragma mark - Translation functions

/*!
 Translate the raw temperature sample to the current temperature scale.
 
 @param rawSample
 The raw temperature value to be converted.
 
 @return The temperature when translated to the currentScale.
 */
- (float) translateSample: (float) rawSample;

/*!
 Translate the raw temperature sample to the specified temperature scale.
 
 @param rawSample
 The raw temperature value to be converted.
 
 @param scaleType
 The temperature scale to use in place of the default one.
 
 @return The temperature when the raw sample is translated to the supplied scaleType.
 */
- (float) translateSample: (float) rawSample toScale: (RangeTemperatureScale) scaleType;

/*!
 Translate a temperature between two arbitrary temperature scale types
 
 @param otherScaleSample
 The temperature value to be converted.
 
 @param startingScaleType
 The temperature scale that the otherScaleSample was input in.
 
 @param finalScaleType
 The temperature scale to output the sample to.
 
 @return The temperature when the input sample is translated from the starting temperature scale to the to the final scale.
 */
- (float) translateOtherSample: (float) otherScaleSample fromScale:(RangeTemperatureScale) startingScaleType toScale: (RangeTemperatureScale) finalScaleType;

/*!
 Translate a temperature from an arbitrary scale to the raw sample scale.
 
 @param otherScaleSample
 The temperature value to be converted.
 
 @param startingScaleType
 The temperature scale that the startingScaleType was input in.
 
 @return The temperature when the input sample is translated from the starting temperature scale to the to the raw sample scale.
 */
- (float) translateToRawSampleOtherSample: (float) otherScaleSample fromScale:(RangeTemperatureScale) startingScaleType;

#pragma mark - Rounding functions

/*!
 This provides a consistent scheme for rounding temperatures which is dependent on scale.
 
 @param rawSample
 The raw sample as provided by the Range functions.
 
 @param formatType
 The enum describing the end use for the output value of this function. It changes how things are rounded.
 
 @return The rounded sample translated to the default scale type.
 */
- (float) translateAndRoundSample: (float) rawSample withFormat: (RangeTemperaturePrintFormat) formatType;

/*!
 This provides a consistent scheme for rounding temperatures which is dependent on scale.
 
 @param rawSample
 The raw sample as provided by the Range functions.
 
 @param formatType
 The enum describing the end use for the output value of this function. It changes how things are rounded.
 
 @param scaleType
 The temperature scale to use in place of the default one.
 
 @return The rounded sample translated to scaleType.
 */
- (float) translateAndRoundSample: (float) rawSample withFormat: (RangeTemperaturePrintFormat) formatType toScale: (RangeTemperatureScale) scaleType;

#pragma mark - String output functions

/*!
 This provides a consistent way to convert raw temperatures to strings.
 
 @param rawSample
 The raw sample as provided by the Range functions.
 
 @param formatType
 The enum describing the end use for the output value of this function. It changes how things are printed.
 
 @return The raw sample translated to the default scale type and then turned into a string.
 */
- (NSString *) printSample:(float) rawSample withFormat: (RangeTemperaturePrintFormat) formatType;

/*!
 This provides a consistent way to convert raw temperatures to strings.
 
 @param rawSample
 The raw sample as provided by the Range functions.
 
 @param formatType
 The enum describing the end use for the output value of this function. It changes how things are printed.
 
 @param scaleType
 The temperature scale to use in place of the default one.
 
 @return The raw sample translated to the scaleType provided as a parameter and then turned into a string.
 */
- (NSString *) printSample:(float) rawSample withFormat: (RangeTemperaturePrintFormat) formatType withScale: (RangeTemperatureScale) scaleType;

@end
