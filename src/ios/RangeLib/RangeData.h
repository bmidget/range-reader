//
//  RangeData.h
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

static NSString * const kRDIllegalUid;

/*!
 This is the value (returned from functions
 that return indicies) if an index was not found.
 */
static const int kRangeIndexNotFound;

typedef struct  {
    /*!
     Temperature (in F) of the sample.
     */
    float temperature;
    /*!
     Time since 1970 for sample.
     Is the equivalent of what [[NSDate date] timeIntervalSince1970] 
     would return at the moment the sample was taken.
     */
    double unix_time;
} range_sample_t;

/*!
 The most important assumption of the RangeData is that all the data comes from a single unique device.
 There is also an assumption that there is a guaranteed order to the samples contained within this object.
 All samples are in ascending order based on timestamp.
 
 Pointers are only valid until another RangeData is merged with this one.
 Practically, for use in this library, this means that if the Range object is refreshed in another thread
 you will need to ensure that things are locked appropriately.
 Also, it is good practice to never hold onto a range_sample_t pointer for any extended period of time.
 */
@interface RangeData : NSObject

/*!
 This is the unique identifier associated with all samples in this object.
 */
@property (nonatomic, readonly) NSString* rangeUid;

/*!
 Returns the maximum sample rate for the data.
 */
@property (nonatomic, readonly) NSNumber* sampleRateInHz;

/*!
 Get the pointer to the sample at an index.
 @return pointer to a range_sample_t struct. If index is invalid then returns NULL.
 */
- (const range_sample_t *) sampleAt: (int) index;

/*!
 Current length of the sample data.
 @return number of range_sample_t in the backing store
 */
- (int) length;

/*!
 Gets the last sample which is the latest sample in time.
 @return pointer to a range_sample_t struct. If length is 0 then it returns NULL.
 */
- (const range_sample_t *) latestSample;

/*!
 Returns a linear interpolated temperature for the given time.
 
 @param time
 The arbitrary time reqested for a temperature to be given at. (If no actual data point is there then we interpolate.)
 
 @param intevalInterpolatedOver
 Returns the inteval between the two datapoints used to interpolate.
 Returns -1.0 if the time requested did not have a datapoint on either side so that it could be interpolated. (The time was outside of the range of the data.)
 Returns 0.0 if there was no interpolation done.
 
 @return Returns a linear interpolated temperature for the given time. One of the endpoints if outside of bounds. Zero if there are no datapoints.
 */
- (float) interpolateTemperatureAtTime: (double) time outIntervalInterpolated: (double*) intevalInterpolatedOver;

/*!
 Gets a pointer to the sample that is closest to the given time.
 @return pointer to a range_sample_t struct. If length is 0 then it returns NULL.
 */
- (const range_sample_t *) findClosestSampleAtTime: (double) time;

/*!
 Gets the index for the sample that is closest to the given time.
 @return index for a sample. If length is 0 then it returns RDC_NOT_FOUND.
 */
- (int) findClosestSampleIndexAtTime: (double) time;

/*!
 This function gives you a pointer to the starting struct and the length of the data described by the time window provided.
 
 Please be aware that both start/stop times are INCLUSIVE.
 
 @param startTime
 The starting time (inclusive) for the returned samples.
 
 @param stopTime
 The ending time (inclusive) for the returned samples.
 
 @param lengthOut
 The number of samples that fall within the time window.
 
 @return The pointer to the first range_sample_t in the RangeData's internal array of samples that is within the time window. NULL if there are no items that match the request.
 */
- (const range_sample_t *) findSamplesFromStart: (double) startTime toStop: (double) stopTime withOutputLength:(int*) lengthOut;

/*!
 This function gives you an index to the starting struct and the length of the data described by the time window provided.
 
 Please be aware that both start/stop times are INCLUSIVE.
 
 @param startTime
 The starting time (inclusive) for the returned samples.
 
 @param stopTime
 The ending time (inclusive) for the returned samples.
 
 @param lengthOut
 The number of samples that fall within the time window.
 
 @return The index to the first range_sample_t that is within the time window. RDC_NOT_FOUND if there are no items that match the request.
 */
- (int) findSamplesIndexFromStart: (double) startTime toStop: (double) stopTime withOutputLength:(int*) lengthOut;

@end
