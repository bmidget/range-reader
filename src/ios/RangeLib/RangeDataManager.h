//
//  RangeDataManager.h
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

/*!
 This class contains a set of RangeDatas and allows for easy searching of datapoints and datapoint ranges.
 */
@interface RangeDataManager : NSObject

/*! 
 Add the entries from another RangeDataManager to this one.
 @return YES if everything was added correctly.
 */
-(BOOL) addRangeManager:(RangeDataManager*) rManager;

/*!
 Get the uids of all Ranges that are in this RangeDataManager.
 @return An array of NSString* that are all the uids
 */
-(NSArray*) rangeIdsWithData;

/*!
 Get a reference to the data contained for a certain uid
 @return The pointer to the RangeData. NULL if there is no data for the provided uid.
 */
-(RangeData*) getDataByRange:(NSString*) uid;

/*!
 Sums up the number of data points in all of the contained RangeDatas
 @return The number of all data points in this RangeDataManager
 */
-(int) totalLength;

/*!
 Get the most recent (latest time) sample in this RangeDataManger. By any Range uid.
 @param outUid returns the uid of the Range with the latest sample
 @return Reference to the sample with the greatest time that was read. NULL if there are no samples for this manager.
 */
- (const range_sample_t *) latestSample: (NSString **) outUid;

/*!
 Get the earliest (by time) sample read. By any Range uid.
 @param outUid returns the uid of the Range with the earliest sample
 @return Reference to the sample with the earliest time that was read. NULL if there are no samples for this manager.
 */
- (const range_sample_t *) earliestSample: (NSString **) outUid;

/*!
 Change the gap length used to get the last gap seen.
 @param thresholdInSeconds Sets the gap size to look for when filtering out data that is unwanted.
 */
- (void) gapThreshold:(double) thresholdInSeconds;

/*!
 Get the first sample after the last "long" gap seen.
 This should be used when graphing data when you don't want to show all data but 
 instead the most recent data that the user likely wants to see.
 @param outUid returns the uid of the Range with the sample after the latest gap seen. Returns kRDIllegalUid if there is no gap.
 @return Reference to the sample after the latest gap. NULL if there are no gaps seen for this manager.
 */
- (const range_sample_t *)  endOfLatestGap: (NSString **) outUid;

@end
