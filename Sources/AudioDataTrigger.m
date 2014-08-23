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

#import "AudioDataTrigger.h"
#import "AudioConstants.h"
#import "AudioUtilities.h"

#define DATA_TRIGGER_VERSION_CURRENT 0

#define POSITIVE_SLOPE 0
#define NEGATIVE_SLOPE 1

@implementation AudioDataTrigger

- (id)init
{
    if(self = [super init])
    {
        [self defaultValues];
    }
    return self;
}

- (void)defaultValues
{
    mTriggerBufferTemp = NULL;
    mTriggerBuffer = NULL;
    mTriggerBufferDuration = 0;
    mTriggerBufferSize = 0;
    mTriggerBufferTempPtr = -1;
    mTriggerDataRate = 0;
    
    mTriggerStartTime = 0;
    mTriggerCurrentTime = 0;
    mTriggerLastTime = 0;
    mTriggerLastValue = 0;
    
    mTriggerRaised = NO;
    mTriggerOffset = 0;
    mTriggerSlope = POSITIVE_SLOPE;
    
    mTriggerTempMinY = mTriggerTempMaxY = 0;
    mTriggerMinY = mTriggerMaxY = 0;
}

- (void)dealloc
{
    if(mTriggerBufferTemp)
        free(mTriggerBufferTemp);

    if(mTriggerBuffer)
        free(mTriggerBuffer);

    [super dealloc];
}

- (id)initWithCoder:(NSCoder*)coder
{
    if(self = [super init])
    {
        [self defaultValues];
        
        /*long version = */[[coder decodeObject] longValue];
    
        mTriggerBufferTemp = [AudioUtilities decodeBufferFromCoder:coder];
        mTriggerBuffer = [AudioUtilities decodeBufferFromCoder:coder];
    
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mTriggerBufferDuration];
        [coder decodeValueOfObjCType:@encode(SLONG) at:&mTriggerBufferSize];
        [coder decodeValueOfObjCType:@encode(SLONG) at:&mTriggerBufferTempPtr];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mTriggerDataRate];
    
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mTriggerStartTime];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mTriggerCurrentTime];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mTriggerLastTime];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mTriggerLastValue];
        
        [coder decodeValueOfObjCType:@encode(BOOL) at:&mTriggerRaised];
        [coder decodeValueOfObjCType:@encode(USHORT) at:&mTriggerSlope];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mTriggerOffset];
    
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mTriggerTempMinY];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mTriggerTempMaxY];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mTriggerMinY];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mTriggerMaxY];    
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:[NSNumber numberWithLong:DATA_TRIGGER_VERSION_CURRENT]];

    [AudioUtilities encodeBufferAt:mTriggerBufferTemp size:mTriggerBufferSize coder:coder];
    [AudioUtilities encodeBufferAt:mTriggerBuffer size:mTriggerBufferSize coder:coder];

    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mTriggerBufferDuration];
    [coder encodeValueOfObjCType:@encode(SLONG) at:&mTriggerBufferSize];
    [coder encodeValueOfObjCType:@encode(SLONG) at:&mTriggerBufferTempPtr];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mTriggerDataRate];

    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mTriggerStartTime];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mTriggerCurrentTime];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mTriggerLastTime];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mTriggerLastValue];
    
    [coder encodeValueOfObjCType:@encode(BOOL) at:&mTriggerRaised];
    [coder encodeValueOfObjCType:@encode(USHORT) at:&mTriggerSlope];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mTriggerOffset];

    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mTriggerTempMinY];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mTriggerTempMaxY];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mTriggerMinY];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mTriggerMaxY];    
}

- (void)setTriggerSlope:(USHORT)slope
{
    mTriggerSlope = slope;
}

- (USHORT)triggerSlope
{
    return mTriggerSlope;
}

- (void)setTriggerOffset:(FLOAT)offset
{
    mTriggerOffset = offset;
}

- (FLOAT)triggerOffset
{
    return mTriggerOffset;
}

- (void)setTriggerBufferDuration:(FLOAT)duration rate:(ULONG)rate
{
    mTriggerDataRate = rate;
    mTriggerBufferSize = duration*rate*SOUND_DATA_SIZE;
    
    if(mTriggerBufferTemp)
        free(mTriggerBufferTemp);

    mTriggerBufferTemp = (FLOAT*)malloc(mTriggerBufferSize);
    if(mTriggerBufferTemp == NULL)
        NSLog(@"Unable to malloc the trigger temp buffer");
        
    mTriggerBufferTempPtr = -1;

    if(mTriggerBuffer)
        free(mTriggerBuffer);
    
    mTriggerBuffer = (FLOAT*)malloc(mTriggerBufferSize);
    if(mTriggerBuffer == NULL)
        NSLog(@"Unable to malloc the trigger buffer");
    mTriggerBufferDuration = duration;
    
    mTriggerLastTime = mTriggerCurrentTime = 0;
    mTriggerRaised = NO;
}

- (BOOL)bufferTempAddValue:(FLOAT)value
{
    mTriggerBufferTempPtr++;
    if(mTriggerBufferTempPtr*SOUND_DATA_SIZE>=mTriggerBufferSize)
    {
        mTriggerBufferTempPtr = -1;
        return NO;
    } else
    {
        if(mTriggerBufferTempPtr==0)
        {
            mTriggerTempMinY = mTriggerTempMaxY = value;
        } else
        {
            mTriggerTempMinY = MIN(mTriggerTempMinY, value);
            mTriggerTempMaxY = MAX(mTriggerTempMaxY, value);
        }
        mTriggerBufferTemp[mTriggerBufferTempPtr] = value;
        return YES;
    }
}

- (void)triggerValue:(FLOAT)value atTime:(FLOAT)time
{
    mTriggerCurrentTime = time;
        
    if(mTriggerCurrentTime>mTriggerLastTime)
    {

        // The current trigger buffer window is now behind, begin to fill the temporary buffer.
        
        if((mTriggerSlope == POSITIVE_SLOPE && mTriggerLastValue<=mTriggerOffset && value>mTriggerOffset ||
            mTriggerSlope == NEGATIVE_SLOPE && mTriggerLastValue>=mTriggerOffset && value<mTriggerOffset)
            && mTriggerRaised == NO)
        {
            // Trigger condition raised. Begin to fill the temporary buffer.
            mTriggerLastTime = mTriggerCurrentTime;
            mTriggerBufferTempPtr = -1;
            mTriggerRaised = YES;
            [self bufferTempAddValue:value];
        } else
        {
            // No trigger condition raised or condition already raised.
            // Continue to fill the temporary buffer.
            if([self bufferTempAddValue:value] == NO)
            {                
                // Temporary buffer full. Copy to the real buffer for display.
                memcpy(mTriggerBuffer, mTriggerBufferTemp, mTriggerBufferSize);
                
                // Set the min/max value of y-axis
                mTriggerMinY = mTriggerTempMinY;
                mTriggerMaxY = mTriggerTempMaxY;
                
                // Set the last trigger time (so the trigger is ignored during one duration)
                mTriggerLastTime = mTriggerCurrentTime + mTriggerBufferDuration;
                
                // Reset the raised flag
                mTriggerRaised = NO;
            }
        }
    }
    
    // Remember last value
    mTriggerLastValue = value;
}

- (void)reset
{
    mTriggerLastTime = mTriggerCurrentTime = 0;
    mTriggerRaised = NO;
}

- (FLOAT)minX
{
    return 0;
}

- (FLOAT)maxX
{
    return mTriggerBufferDuration;
}

- (FLOAT)minY
{
    return mTriggerMinY;
}

- (FLOAT)maxY
{
    return mTriggerMaxY;
}

- (FLOAT)valueAtX:(FLOAT)x
{
    ULONG index = x*mTriggerDataRate;
    if(x>mTriggerBufferDuration)
    {
        NSLog(@"Try to get value over trigger buffer");
        return 0;
    } else
        return mTriggerBuffer[index];
}

@end
