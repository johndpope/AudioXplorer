
/*
 
 [The "BSD licence"]
 Copyright (c) 2003-2006 Arizona Software
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
														   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
														   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import <Foundation/Foundation.h>
#import "AudioDataStruct.h"
#import "AudioDataTrigger.h"

@interface AudioDataAmplitude : NSObject <NSCoding>
{
    AudioDataStruct mData;
    FLOAT mYFullScaleFactor;
    FLOAT mGain;
    BOOL mReverseXAxis;

    // Status flag (thread safe)
    NSLock *mLock;
    SHORT mStatusFlag;
    
    // Trigger
    AudioDataTrigger *mTrigger[MAX_CHANNEL];
    BOOL mTriggerState;
    BOOL mOldTriggerState;
    BOOL mDisplayWindowMode;
    FLOAT mDisplayWindowDuration;
    USHORT mTriggerMethod;
}

- (void)initTriggers;
- (void)initChannels;
- (void)defaultValues;

- (void)setReverseXAxis:(BOOL)flag;
- (BOOL)reverseXAxis;

- (void)setLoopBuffer:(BOOL)flag timeFollow:(BOOL)follow;

- (void)setDisplayWindowMode:(BOOL)flag;
- (BOOL)displayWindowMode;
- (void)setDisplayWindowDuration:(FLOAT)duration;
- (FLOAT)displayWindowDuration;
- (void)setTriggerState:(BOOL)flag;
- (BOOL)triggerState;
- (void)setTriggerSlope:(USHORT)slope;
- (USHORT)triggerSlope;
- (void)setTriggerOffset:(FLOAT)offset;
- (FLOAT)triggerOffset;

- (void)setDuration:(FLOAT)inDuration rate:(FLOAT)inRate channel:(SHORT)inChannel;
- (void)setDataBuffer:(SOUND_DATA_PTR)buffer size:(ULONG)size channel:(SHORT)channel;

- (void)setGain:(FLOAT)gain;

- (void)setStatusFlag:(SHORT)status;
- (SHORT)statusFlag;

@end

@interface AudioDataAmplitude (Data)

- (AudioDataBuffer)dataBufferOfChannel:(SHORT)channel;
- (SOUND_DATA_PTR)dataBasePtrOfChannel:(SHORT)channel;
- (BOOL)dataExistsForChannel:(SHORT)channel;

- (void)optimizeSize;
- (void)findMinMaxValuesOfChannel:(SHORT)channel;

- (void)addDataValue:(SOUND_DATA_TYPE)value inChannel:(SHORT)channel;
- (BOOL)addMonoRawDataPtr:(SOUND_DATA_PTR)inPtr ofSize:(ULONG)inSize toChannel:(SHORT)inChannel;
- (BOOL)addStereoRawDataPtr:(SOUND_DATA_PTR)inPtr ofSize:(ULONG)inSize inChannel:(SHORT)channel;
- (BOOL)readStereoRawDataInBuffer:(SOUND_DATA_PTR)buffer from:(FLOAT*)from size:(ULONG)size;

@end

@interface AudioDataAmplitude (Position)

- (BOOL)positionInRange:(FLOAT)position channel:(SHORT)channel;
- (FLOAT)currentPositionOfChannel:(SHORT)channel;
- (FLOAT)currentAbsolutePositionOfChannel:(SHORT)channel;
- (ULONG)currentIndexOfChannel:(SHORT)inChannel;
- (ULONG)maxIndex;

@end

@interface AudioDataAmplitude (Value)

- (FLOAT)yValueAtIndex:(ULONG)index channel:(SHORT)channel;
- (FLOAT)yValueAtX:(FLOAT)x channel:(SHORT)channel;
- (ULONG)indexOfXValue:(FLOAT)value channel:(SHORT)channel;
- (FLOAT)xValueAtIndex:(ULONG)index channel:(SHORT)channel;
- (FLOAT)instantLevelOfChannel:(SHORT)channel;

- (FLOAT)minXOfChannel:(SHORT)channel;
- (FLOAT)maxXOfChannel:(SHORT)channel;
- (FLOAT)minYOfChannel:(SHORT)channel;
- (FLOAT)maxYOfChannel:(SHORT)channel;

@end

@interface AudioDataAmplitude (Parameters)

- (ULONG)dataRate;

- (NSString*)name;

- (NSString*)xAxisUnitForRange:(FLOAT)range;
- (FLOAT)xAxisUnitFactorForRange:(FLOAT)range;

- (NSString*)yAxisUnitForRange:(FLOAT)range;
- (FLOAT)yAxisUnitFactorForRange:(FLOAT)range;

- (NSString*)xAxisUnit;
- (NSString*)yAxisUnit;

@end

@interface AudioDataAmplitude (Export)
- (BOOL)supportRawDataExport;
- (NSString*)stringOfRawDataFromIndex:(ULONG)from to:(ULONG)to channel:(USHORT)channel delimiter:(NSString*)delimiter;
@end
