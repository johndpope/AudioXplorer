
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

#import "AudioDataAmplitude.h"
#import "AudioDialogPrefs.h"

#define AMPLITUDE_VERSION_10b12 1	// Version 1.0b12 and before
#define AMPLITUDE_VERSION_CURRENT 2

#define TRIGGER_POSITIVE_SLOPE 0
#define TRIGGER_NEGATIVE_SLOPE 1

#define CHANNEL(channel) (channel == STEREO_CHANNEL)?LEFT_CHANNEL:channel

@implementation AudioDataAmplitude

- (id)init
{
    if(self = [super init])
    {        
        [self initTriggers];
        [self initChannels];
        [self defaultValues];
    }
    
    return self;
}

- (void)dealloc
{    
    [mLock release];
    
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {
        if(mData.data[channel].dataBasePtr)
            free(mData.data[channel].dataBasePtr);
        [mTrigger[channel] release];
    }
    [super dealloc];
}

- (void)initWithCoderVersionCurrent:(NSCoder*)coder
{
    [coder decodeValueOfObjCType:@encode(BOOL) at:&mTriggerState];
    [coder decodeValueOfObjCType:@encode(BOOL) at:&mOldTriggerState];
    [coder decodeValueOfObjCType:@encode(BOOL) at:&mDisplayWindowMode];
    [coder decodeValueOfObjCType:@encode(FLOAT) at:&mDisplayWindowDuration];
    [coder decodeValueOfObjCType:@encode(USHORT) at:&mTriggerMethod];

    [coder decodeValueOfObjCType:@encode(FLOAT) at:&mYFullScaleFactor];
    [coder decodeValueOfObjCType:@encode(FLOAT) at:&mGain];
    [coder decodeValueOfObjCType:@encode(BOOL) at:&mReverseXAxis];

    [coder decodeValueOfObjCType:@encode(ULONG) at:&mData.dataRate];
    [coder decodeValueOfObjCType:@encode(ULONG) at:&mData.maxIndex];

    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {
        mTrigger[channel] = [[coder decodeObject] retain];

        AudioDataBufferPtr buffer = &mData.data[channel];            
        [coder decodeValueOfObjCType:@encode(ULONG) at:&buffer->startIndex];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&buffer->stopIndex];
        [coder decodeValueOfObjCType:@encode(DOUBLE) at:&buffer->startTime];
        [coder decodeValueOfObjCType:@encode(DOUBLE) at:&buffer->stopTime];
        [coder decodeValueOfObjCType:@encode(DOUBLE) at:&buffer->absoluteTime];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&buffer->dataMaxSize];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&buffer->dataCurSize];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&buffer->minY];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&buffer->maxY];
    
        BOOL hasData = NO;
        [coder decodeValueOfObjCType:@encode(BOOL) at:&hasData];
        if(hasData)
        {
            buffer->dataBasePtr = (SOUND_DATA_PTR)malloc(buffer->dataMaxSize);
            long size = buffer->dataMaxSize/SOUND_DATA_SIZE;
            [coder decodeArrayOfObjCType:@encode(FLOAT) count:size at:buffer->dataBasePtr];        
        }
    }
}

- (id)initWithCoder:(NSCoder*)coder
{
    if(self = [super init])
    {
        [self defaultValues];
        
        long version = [[coder decodeObject] longValue];

        switch(version) {
            case AMPLITUDE_VERSION_10b12:
                [NSException raise:AXExceptionName format:NSLocalizedString(@"Cannot read file saved from a previous beta version.", NULL)];
                break;
            case AMPLITUDE_VERSION_CURRENT:
                [self initWithCoderVersionCurrent:coder];
                break;
        }    
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:[NSNumber numberWithLong:AMPLITUDE_VERSION_CURRENT]];

    [coder encodeValueOfObjCType:@encode(BOOL) at:&mTriggerState];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&mOldTriggerState];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&mDisplayWindowMode];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mDisplayWindowDuration];
    [coder encodeValueOfObjCType:@encode(USHORT) at:&mTriggerMethod];

    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mYFullScaleFactor];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mGain];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&mReverseXAxis];
    
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mData.dataRate];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mData.maxIndex];

    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {
        [coder encodeObject:mTrigger[channel]];
    
        AudioDataBuffer buffer = mData.data[channel];
        long size = buffer.dataMaxSize/SOUND_DATA_SIZE;        
        [coder encodeValueOfObjCType:@encode(ULONG) at:&buffer.startIndex];
        [coder encodeValueOfObjCType:@encode(ULONG) at:&buffer.stopIndex];
        [coder encodeValueOfObjCType:@encode(DOUBLE) at:&buffer.startTime];
        [coder encodeValueOfObjCType:@encode(DOUBLE) at:&buffer.stopTime];
        [coder encodeValueOfObjCType:@encode(DOUBLE) at:&buffer.absoluteTime];
        [coder encodeValueOfObjCType:@encode(ULONG) at:&buffer.dataMaxSize];
        [coder encodeValueOfObjCType:@encode(ULONG) at:&buffer.dataCurSize];
        [coder encodeValueOfObjCType:@encode(FLOAT) at:&buffer.minY];
        [coder encodeValueOfObjCType:@encode(FLOAT) at:&buffer.maxY];
        BOOL hasData = buffer.dataBasePtr != NULL;
        [coder encodeValueOfObjCType:@encode(BOOL) at:&hasData];
        if(hasData)
            [coder encodeArrayOfObjCType:@encode(FLOAT) count:size at:buffer.dataBasePtr];
    }
}

- (void)initTriggers
{
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
        mTrigger[channel] = [[AudioDataTrigger alloc] init];
}

- (void)initChannels
{
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {            
        mData.data[channel].dataBasePtr = NULL;
        mData.data[channel].startTime = 0;
        mData.data[channel].stopTime = 0;
        mData.data[channel].absoluteTime = 0;
        mData.data[channel].startIndex = 0;
        mData.data[channel].stopIndex = 0;
        mData.data[channel].dataMaxSize = 0;
        mData.data[channel].dataCurSize = 0;
    }
    mData.dataRate = 0;
    mData.maxIndex = 0;
    mData.loopBuffer = NO;
    mData.timeFollow = NO;
    [self setGain:1.0];
}

- (void)defaultValues
{
    mLock = [[NSLock alloc] init];

    mStatusFlag = NONE;
    mYFullScaleFactor = [[AudioDialogPrefs shared] fullScaleVoltage]*0.5;
    mGain = 0;
    mReverseXAxis = NO;

    mOldTriggerState = mTriggerState = NO;
    mDisplayWindowMode = NO;
    mDisplayWindowDuration = 0.01;

    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
        [mTrigger[channel] setTriggerBufferDuration:mDisplayWindowDuration rate:SOUND_DEFAULT_RATE];

    mTriggerMethod = TRIGGER_POSITIVE_SLOPE;
}

- (void)setReverseXAxis:(BOOL)flag
{
    mReverseXAxis = flag;

    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {                      
        FLOAT min = mData.data[channel].startTime;
        FLOAT max = mData.data[channel].stopTime;

        mData.data[channel].startTime = -max;
        mData.data[channel].stopTime = -min;
    }

}

- (BOOL)reverseXAxis
{
    return mReverseXAxis;
}

- (void)setLoopBuffer:(BOOL)flag timeFollow:(BOOL)follow
{
    mData.loopBuffer = flag;
    mData.timeFollow = follow;
}

- (void)setDisplayWindowMode:(BOOL)flag
{
    mDisplayWindowMode = flag;
    [self setReverseXAxis:flag == NO];
    if(flag == NO)
    {
        mOldTriggerState = mTriggerState;
        mTriggerState = NO;
    } else
        mTriggerState = mOldTriggerState;
}

- (BOOL)displayWindowMode
{
    return mDisplayWindowMode;
}

- (void)setDisplayWindowDuration:(FLOAT)duration
{
    mDisplayWindowDuration = duration;
    
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
        [mTrigger[channel] setTriggerBufferDuration:duration rate:mData.dataRate];
}

- (FLOAT)displayWindowDuration
{
    return mDisplayWindowDuration;
}

- (void)setTriggerState:(BOOL)flag
{
    mTriggerState = flag;
    mOldTriggerState = flag;
}

- (BOOL)triggerState
{
    return mTriggerState;
}

- (void)setTriggerSlope:(USHORT)slope
{
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
        [mTrigger[channel] setTriggerSlope:slope];
}

- (USHORT)triggerSlope
{
    return [mTrigger[LEFT_CHANNEL] triggerSlope];
}

- (void)setTriggerOffset:(FLOAT)offset
{	
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
        [mTrigger[channel] setTriggerOffset:offset];
}

- (FLOAT)triggerOffset
{
    return [mTrigger[LEFT_CHANNEL] triggerOffset];
}

- (void)setDuration:(FLOAT)inDuration rate:(FLOAT)inRate channel:(SHORT)inChannel
{
    ULONG size = inDuration*inRate*SOUND_DATA_SIZE;
    
    mData.dataRate = inRate;
    mData.maxIndex = inDuration*inRate;

    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {                                    
        if(mData.data[channel].dataBasePtr)
        {
            free(mData.data[channel].dataBasePtr);
            mData.data[channel].dataBasePtr = NULL;
        }
        
        if(channel == inChannel || inChannel == STEREO_CHANNEL)
            mData.data[channel].dataBasePtr = (SOUND_DATA_PTR)malloc(size);
        
        mData.data[channel].startIndex = 0;
        mData.data[channel].stopIndex = 0;

        mData.data[channel].startTime = 0;
        mData.data[channel].stopTime = 0;
        mData.data[channel].absoluteTime = 0;
        
        mData.data[channel].dataMaxSize = size;
        mData.data[channel].dataCurSize = 0;

        mData.data[channel].minY = 0;
        mData.data[channel].maxY = 0;
        
        [mTrigger[channel] reset];
    }    
}

- (void)setDataBuffer:(SOUND_DATA_PTR)buffer size:(ULONG)size channel:(SHORT)channel_
{
    SHORT channel = CHANNEL(channel_);
    
    mData.data[channel].dataBasePtr = buffer;
    mData.data[channel].dataMaxSize = size;

    mData.dataRate = SOUND_DEFAULT_RATE;
    mData.maxIndex = size/SOUND_DATA_SIZE;
    
    mData.data[channel].startIndex = 0;
    mData.data[channel].stopIndex = 0;

    if(mReverseXAxis)
    {
        mData.data[channel].startTime = -(DOUBLE)mData.maxIndex/mData.dataRate;
        mData.data[channel].stopTime = 0;
        mData.data[channel].absoluteTime = mData.data[channel].startTime;
    } else
    {
        mData.data[channel].startTime = 0;
        mData.data[channel].stopTime = (DOUBLE)mData.maxIndex/mData.dataRate;
        mData.data[channel].absoluteTime = mData.data[channel].stopTime;
    }
    
    mData.data[channel].dataMaxSize = size;
    mData.data[channel].dataCurSize = size;

    [self findMinMaxValuesOfChannel:channel];
}

- (void)setGain:(FLOAT)gain
{
    mGain = gain;
}

- (void)setStatusFlag:(SHORT)status
{
    [mLock lock];
    mStatusFlag = status;
    [mLock unlock];
}

- (SHORT)statusFlag
{
    BOOL status;
    [mLock lock];
    status = mStatusFlag;
    [mLock unlock];
    return status;
}

@end

@implementation AudioDataAmplitude (Data)

- (AudioDataBuffer)dataBufferOfChannel:(SHORT)channel
{
    return mData.data[CHANNEL(channel)];
}

- (SOUND_DATA_PTR)dataBasePtrOfChannel:(SHORT)channel
{
    return mData.data[CHANNEL(channel)].dataBasePtr;
}

- (BOOL)dataExistsForChannel:(SHORT)channel
{
    return mData.data[CHANNEL(channel)].dataBasePtr != NULL;
}

- (void)optimizeSize
{
    ULONG maxSize = 0;
    
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {
        if([self dataExistsForChannel:channel])
        {
            mData.data[channel].dataMaxSize = mData.data[channel].dataCurSize+SOUND_DATA_SIZE;
            mData.data[channel].dataBasePtr = realloc(mData.data[channel].dataBasePtr, mData.data[channel].dataMaxSize);
            maxSize = MAX(maxSize, mData.data[channel].dataMaxSize);
        }
    }

    mData.maxIndex = (FLOAT)maxSize/SOUND_DATA_SIZE;
}

- (void)flattenBuffer
{
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {
        if([self dataExistsForChannel:channel])
        {
            FLOAT_PTR basePtr = mData.data[channel].dataBasePtr;
            ULONG startIndex = mData.data[channel].startIndex;
            ULONG stopIndex = mData.data[channel].stopIndex;
            ULONG maxIndex = mData.maxIndex;
            if(stopIndex<startIndex)
            {
                // Buffer is rotated. Flatten it.
                // Choose the smallest part to copy it to a temporary buffer.
                if(stopIndex<=(maxIndex-startIndex))
                {
                    ULONG tempSize = (stopIndex+1)*SOUND_DATA_SIZE;
                    FLOAT_PTR temp = malloc(tempSize);
                    
                    // Copy to temp
                    memcpy(temp, basePtr, tempSize);
                    
                    // Shift
                    memcpy(basePtr, basePtr+startIndex, (maxIndex-startIndex)*SOUND_DATA_SIZE);
                    
                    // Copy back from temp
                    memcpy(basePtr+(maxIndex-startIndex), temp, tempSize);
                    
                    free(temp);
                } else
                {
                    ULONG tempSize = (maxIndex-startIndex)*SOUND_DATA_SIZE;
                    FLOAT_PTR temp = malloc(tempSize);
                    
                    // Copy to temp
                    memcpy(temp, basePtr+startIndex, tempSize);
                    
                    // Shift
                    memcpy(basePtr+(maxIndex-startIndex), basePtr, (stopIndex+1)*SOUND_DATA_SIZE);
                    
                    // Copy back from temp
                    memcpy(basePtr, temp, tempSize);
                    
                    free(temp);
                }
                mData.data[channel].startIndex = 0;
                mData.data[channel].stopIndex = maxIndex-1;
            }
        }
    }
}

// Called to optimize the size, flatten the rotate buffer and perform other clean-up process
- (void)optimize
{
    // Optimize the size
    [self optimizeSize];
    
    // Flatten the rotating buffer is needed
    [self flattenBuffer];
}

- (void)findMinMaxValuesOfChannel:(SHORT)channel
{    
    SOUND_DATA_PTR data = mData.data[CHANNEL(channel)].dataBasePtr;
        
    FLOAT minY = data[0];
    FLOAT maxY = data[0];
 
    ULONG index;
    for(index=0; index<mData.maxIndex; index++)   
    {
        FLOAT value = data[index];

        if(value<minY)
            minY = value;
        
        if(value>maxY)
            maxY = value;
    }
    mData.data[CHANNEL(channel)].minY = minY;
    mData.data[CHANNEL(channel)].maxY = maxY;    
}

- (ULONG)incrementIndexOfChannel:(SHORT)channel_ by:(ULONG)inc
{
    SHORT channel = CHANNEL(channel_);
    
    BOOL linked = (mData.data[channel].stopIndex==mData.data[channel].startIndex-1) ||
                    (mData.data[channel].stopIndex==(mData.maxIndex-1) && mData.data[channel].startIndex==0);
    
    if(mData.data[channel].stopIndex>=(mData.maxIndex-1) && !mData.loopBuffer)
        return 0;
    
    if(mData.data[channel].dataCurSize > 0)
        mData.data[channel].stopIndex += inc;			// Adjust index
    mData.data[channel].absoluteTime += (DOUBLE)inc/mData.dataRate;
    
    if(mReverseXAxis)
    {
        mData.data[channel].startTime -= (DOUBLE)inc/mData.dataRate;	// Adjust time stamp
        if(mData.timeFollow == NO)
            mData.data[channel].startTime = MAX(mData.data[channel].startTime,
                                        -(DOUBLE)mData.maxIndex/mData.dataRate);
    } else
    {
        mData.data[channel].stopTime += (DOUBLE)inc/mData.dataRate;	// Adjust time stamp
        if(mData.timeFollow == NO)
            mData.data[channel].stopTime = MIN(mData.data[channel].stopTime,
                                                (DOUBLE)mData.maxIndex/mData.dataRate);
    }
    
    mData.data[channel].dataCurSize += inc * SOUND_DATA_SIZE;
    if(mData.data[channel].dataCurSize>mData.data[channel].dataMaxSize)
        mData.data[channel].dataCurSize = mData.data[channel].dataMaxSize;
        
    if(linked)
    {
        mData.data[channel].startIndex += inc;				// Adjust index
        // Ne pas ajouter le mme incrŽment que pour stopTime -> erreur d'arrondi!
        mData.data[channel].startTime = mData.data[channel].stopTime-(DOUBLE)mData.maxIndex/mData.dataRate;
    }

    if(mData.data[channel].startIndex>=mData.maxIndex)
    {
        if(!mData.loopBuffer)
            return 0;
        ULONG delta = mData.data[channel].startIndex-(mData.maxIndex-1);
        mData.data[channel].startIndex = delta-1;
    }
    
    if(mData.data[channel].stopIndex>=mData.maxIndex)
    {
        if(!mData.loopBuffer)
            return 0;
        ULONG delta = mData.data[channel].stopIndex-(mData.maxIndex-1);
        mData.data[channel].stopIndex = delta-1;
    }
    
    return mData.data[channel].stopIndex;
}

- (void)_addDataValue:(FLOAT)value inChannel:(SHORT)channel_ atIndex:(ULONG)index
{
    SHORT channel = CHANNEL(channel_);
    
    // Compute displayed value
        
    FLOAT _value = value*pow(10, mGain*0.1);	// Gain is in [dB]
    if(index>=mData.maxIndex || index<0)
    {
        NSLog(@"Index overflow in _addDataValue (%d>=%d)", index, mData.maxIndex);
    } else
        mData.data[channel].dataBasePtr[index] = _value;

    // Trigger detection
    
    if(mTriggerState)
        [mTrigger[channel] triggerValue:_value atTime:mData.data[channel].absoluteTime];
    
    // Min/max detection
    
    if(index==0)
    {
        mData.data[channel].minY = _value;
        mData.data[channel].maxY = _value;
    } else
    {
        if(_value<mData.data[channel].minY)
            mData.data[channel].minY = _value;
        if(_value>mData.data[channel].maxY)
            mData.data[channel].maxY = _value;
    }
}

- (void)addDataValue:(FLOAT)value inChannel:(SHORT)channel
{
    ULONG index = [self incrementIndexOfChannel:CHANNEL(channel) by:1];
    [self _addDataValue:value inChannel:CHANNEL(channel) atIndex:index];
}

- (BOOL)addMonoRawDataPtr:(SOUND_DATA_PTR)inPtr ofSize:(ULONG)inSize toChannel:(SHORT)inChannel
{   
    ULONG index;
    for(index=0; index*SOUND_DATA_SIZE<inSize; index++)
    {
        ULONG dataIndex = [self incrementIndexOfChannel:inChannel by:1];
        if(dataIndex==-1)
            return NO;
        [self _addDataValue:inPtr[index] inChannel:inChannel atIndex:dataIndex];
    }
    
    return YES;    
}

- (BOOL)addStereoRawDataPtr:(SOUND_DATA_PTR)inPtr ofSize:(ULONG)inSize inChannel:(SHORT)channel
{    
    ULONG index;
    for(index=0; index*SOUND_DATA_SIZE<inSize; index++)
    {
        if(channel == LEFT_CHANNEL || channel == STEREO_CHANNEL)
        {
            ULONG leftIndex = [self incrementIndexOfChannel:LEFT_CHANNEL by:1];
            if(leftIndex==-1)
                return NO;
                
            [self _addDataValue:inPtr[index] inChannel:LEFT_CHANNEL atIndex:leftIndex];
        }
        
        index++;
        
        if(channel == RIGHT_CHANNEL || channel == STEREO_CHANNEL)
        {
            ULONG rightIndex = [self incrementIndexOfChannel:RIGHT_CHANNEL by:1];
            if(rightIndex==-1)
                return NO;
    
            [self _addDataValue:inPtr[index] inChannel:RIGHT_CHANNEL atIndex:rightIndex]; 
        }
    }
    return YES;
}

- (BOOL)readStereoRawDataInBuffer:(SOUND_DATA_PTR)buffer from:(FLOAT*)from size:(ULONG)size
{    
    FLOAT fromTime = *from;
    FLOAT maxTime = MAX([self maxXOfChannel:LEFT_CHANNEL], [self maxXOfChannel:RIGHT_CHANNEL]);
    ULONG indexCount = size*0.5/SOUND_DATA_SIZE;
    
    if(fromTime+(FLOAT)indexCount/mData.dataRate>maxTime)
    {
        *from = maxTime;
        return NO;
    }
    
    // Create a stereo buffer to hold the data
    
    SOUND_DATA_PTR targetPtr = buffer;
    SOUND_DATA_PTR leftPtr = mData.data[LEFT_CHANNEL].dataBasePtr;
    SOUND_DATA_PTR rightPtr = mData.data[RIGHT_CHANNEL].dataBasePtr;
    
    if(leftPtr && rightPtr)
    {
        // Stereo
        
        leftPtr += [self indexOfXValue:*from channel:LEFT_CHANNEL];
        rightPtr += [self indexOfXValue:*from channel:RIGHT_CHANNEL];

        ULONG index;
        for(index=0; index<indexCount; index++)
        {
            *targetPtr++ = *leftPtr++;
            *targetPtr++ = *rightPtr++;
        }
            
    } else if(leftPtr && rightPtr == NULL)
    {
        // Mono (LEFT)
        
        leftPtr += [self indexOfXValue:*from channel:LEFT_CHANNEL];
        
        ULONG index;
        for(index=0; index<indexCount; index++)
        {
            *targetPtr++ = *leftPtr;
            *targetPtr++ = *leftPtr++;
        }
    } else if(leftPtr == NULL && rightPtr)
    {
        // Mono (RIGHT)
        
        rightPtr += [self indexOfXValue:*from channel:RIGHT_CHANNEL];
        
        ULONG index;
        for(index=0; index<indexCount; index++)
        {
            *targetPtr++ = *rightPtr;
            *targetPtr++ = *rightPtr++;
        }
    }
    
    *from += (FLOAT)indexCount/mData.dataRate;

    return YES;
}

@end

@implementation AudioDataAmplitude (Position)

- (BOOL)positionInRange:(FLOAT)position channel:(SHORT)channel
{
    return (position>=mData.data[CHANNEL(channel)].startTime) && (position<=mData.data[CHANNEL(channel)].stopTime);
}

- (FLOAT)currentPositionOfChannel:(SHORT)channel
{
    return mData.data[CHANNEL(channel)].stopTime;
}

- (FLOAT)currentAbsolutePositionOfChannel:(SHORT)channel
{
    return mData.data[CHANNEL(channel)].absoluteTime;
}

- (ULONG)currentIndexOfChannel:(SHORT)channel
{
    return mData.data[CHANNEL(channel)].stopIndex;
}

- (ULONG)maxIndex { return mData.maxIndex; }

@end

@implementation AudioDataAmplitude (Value)

- (FLOAT)yValueAtIndex:(ULONG)index channel:(SHORT)channel
{
    if(mData.data[CHANNEL(channel)].dataBasePtr)
    {
        ULONG start = mData.data[CHANNEL(channel)].startIndex;
        ULONG stop = mData.data[CHANNEL(channel)].stopIndex;
            
        if(index>=mData.maxIndex)
        {
            index = index-mData.maxIndex;
            if(index>=mData.maxIndex)
            {
                NSLog(@"Index too big in AudioDataAmplitude.m:yValueAtIndex:channel %d (max >= %d)", index, mData.maxIndex);
                index = mData.maxIndex-1;
            }
        }
    
        if(index>stop && stop>start)
            index = stop;
                        
        return mData.data[CHANNEL(channel)].dataBasePtr[index]*mYFullScaleFactor;
    } else
        return 0;
}

- (FLOAT)yValueAtX:(FLOAT)x channel:(SHORT)channel_
{
    SHORT channel = CHANNEL(channel_);
    
    if(mTriggerState)
        return [mTrigger[channel] valueAtX:x]*mYFullScaleFactor;
    else
    {
        if(mDisplayWindowMode)
            x += mData.data[channel].stopTime-mDisplayWindowDuration;
            
        if(mData.data[channel].dataBasePtr)
        {
            ULONG offset = 0;
            
            if(x<mData.data[channel].startTime)
                offset = mData.data[channel].startIndex;
            else
                offset = (x-mData.data[channel].startTime)*mData.dataRate+
                                                        mData.data[channel].startIndex;
            
            if(offset>=mData.maxIndex)
                offset = offset-mData.maxIndex;
                
            return mData.data[channel].dataBasePtr[offset]*mYFullScaleFactor;
        } else
            return 0;
    }
}

- (ULONG)indexOfXValue:(FLOAT)value channel:(SHORT)channel
{
    // -1 pour delta puisque les index vont de 0 ˆ indexMax-1
    SLONG delta = (value-mData.data[CHANNEL(channel)].startTime)*mData.dataRate-1;
    SLONG index = mData.data[CHANNEL(channel)].startIndex+delta;
    if(index>=mData.maxIndex)
        index = index-mData.maxIndex;
    if(index<0)
        index = 0;
    return index;
}

- (FLOAT)xValueAtIndex:(ULONG)index channel:(SHORT)channel_
{
    USHORT channel = CHANNEL(channel_);
    ULONG delta = 0;
    if(index>=mData.data[channel].startIndex)
        delta = index - mData.data[channel].startIndex;
    else
        delta = index + mData.maxIndex - mData.data[channel].startIndex;
        
    return (FLOAT)delta/mData.dataRate;
}

- (FLOAT)instantLevelOfChannel:(SHORT)channel
{
    ULONG stop = mData.data[CHANNEL(channel)].stopIndex;
    ULONG delta = mData.dataRate*0.1;
    
    FLOAT total = 0;
    
    ULONG index;
    for(index=stop; index>stop-delta; index--)
    {
        FLOAT value = [self yValueAtIndex:index channel:CHANNEL(channel)];
        total += value>0 ? value:-value;
    }
    
    return total/delta;
}

- (FLOAT)minXOfChannel:(SHORT)channel
{
    if(mTriggerState)
        return [mTrigger[CHANNEL(channel)] minX];
    else if(mDisplayWindowMode)
        return 0;
    else
        return mData.data[CHANNEL(channel)].startTime;
}

- (FLOAT)maxXOfChannel:(SHORT)channel
{
    if(mTriggerState)
        return [mTrigger[CHANNEL(channel)] maxX];
    else if(mDisplayWindowMode)
        return mDisplayWindowDuration;
    else
        return mData.data[CHANNEL(channel)].stopTime;
}
- (FLOAT)minYOfChannel:(SHORT)channel
{
    if(mTriggerState)
        return [mTrigger[CHANNEL(channel)] minY]*mYFullScaleFactor;
    else
        return mData.data[CHANNEL(channel)].minY*mYFullScaleFactor;
}

- (FLOAT)maxYOfChannel:(SHORT)channel
{
    if(mTriggerState)
        return [mTrigger[CHANNEL(channel)] maxY]*mYFullScaleFactor;
    else
        return mData.data[CHANNEL(channel)].maxY*mYFullScaleFactor;
}

@end

@implementation AudioDataAmplitude (Parameters)

- (ULONG)dataRate
{
    return mData.dataRate;
}

- (SHORT)kind { return KIND_AMPLITUDE; }

- (NSString*)name
{
    return NSLocalizedString(@"Sound", NULL);
}

- (NSString*)xAxisUnit
{
    return @"s";
}

- (NSString*)xAxisUnitForRange:(FLOAT)range
{
    if(range<1e-3)
        return @"µs";
    else if(range<1)
        return @"ms";
    else
        return @"s";
}

- (FLOAT)xAxisUnitFactorForRange:(FLOAT)range
{
    if(range<1e-3)
        return 1e6;
    else if(range<1)
        return 1e3;
    else
        return 1;
}

- (NSString*)yAxisUnitForRange:(FLOAT)range
{
    if(range<1 && range>1e-3)
        return @"mV";
    else if(range<1e-3)
        return @"µV";
    else
        return @"V";
}

- (FLOAT)yAxisUnitFactorForRange:(FLOAT)range
{
    if(range<1 && range>1e-3)
        return 1e3;
    else if(range<1e-3)
        return 1e6;
    else
        return 1;
}

- (NSString*)yAxisUnit { return @"V"; }
- (NSString*)xAxisName { return NSLocalizedString(@"Time", NULL); }
- (NSString*)yAxisName { return NSLocalizedString(@"Sound", NULL); }

- (BOOL)supportTrigger { return [self triggerState]; }
- (BOOL)supportPlayback { return YES; }
- (BOOL)supportHarmonicCursor { return NO; }

@end

@implementation AudioDataAmplitude (Export)

- (BOOL)supportRawDataExport
{
    return YES;
}

- (ULONG)sizeOfData
{
    long size = 0;
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {
        if([self dataExistsForChannel:channel])
            size += mData.data[channel].dataMaxSize*SOUND_DATA_SIZE;
    }

    return size;
}

- (NSString*)stringOfRawDataFromIndex:(ULONG)from to:(ULONG)to channel:(USHORT)channel delimiter:(NSString*)delimiter
{
    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:[self sizeOfData]];
    
    if(channel == STEREO_CHANNEL)
        [s appendFormat:@"%@ [%@]%@ %@ [%@]%@ %@ [%@]", NSLocalizedString(@"Time", NULL),
                                    [self xAxisUnit], delimiter,
                                    NSLocalizedString(@"Left", NULL), [self yAxisUnit], delimiter,
                                    NSLocalizedString(@"Right", NULL), [self yAxisUnit]];
    else if(channel == LEFT_CHANNEL)
        [s appendFormat:@"%@ [%@]%@ %@ [%@]", NSLocalizedString(@"Time", NULL),
                                    [self xAxisUnit], delimiter,
                                    NSLocalizedString(@"Left", NULL), [self yAxisUnit]];
    else if(channel == RIGHT_CHANNEL)
        [s appendFormat:@"%@ [%@]%@ %@ [%@]", NSLocalizedString(@"Time", NULL),
                                    [self xAxisUnit], delimiter,
                                    NSLocalizedString(@"Right", NULL), [self yAxisUnit]];
        
    ULONG index = from;
    while(index != to)
    {
        float x = [self xValueAtIndex:index channel:LEFT_CHANNEL];
        float yLeft = [self yValueAtIndex:index channel:LEFT_CHANNEL];
        float yRight = [self yValueAtIndex:index channel:RIGHT_CHANNEL];
        
        if(channel == STEREO_CHANNEL)
            [s appendFormat:@"\r%f%@ %f%@ %f", x,
                                        delimiter,
                                        yLeft,
                                        delimiter,
                                        yRight];
        else if(channel == LEFT_CHANNEL)
            [s appendFormat:@"\r%f%@ %f", x, delimiter, yLeft];
        else if(channel == RIGHT_CHANNEL)
            [s appendFormat:@"\r%f%@ %f", x, delimiter, yRight];
            
        index++;
        if(index==to)
            break;
        if(index>=mData.maxIndex)
            index = 0;
    }
        
    return [s autorelease];
}

@end
