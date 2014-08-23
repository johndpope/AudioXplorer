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
#import "AudioTypes.h"

@interface AudioDataTrigger : NSObject <NSCoding>
{
    FLOAT *mTriggerBufferTemp;
    FLOAT *mTriggerBuffer;
    FLOAT mTriggerBufferDuration;
    SLONG mTriggerBufferSize;
    SLONG mTriggerBufferTempPtr;
    ULONG mTriggerDataRate;
    
    FLOAT mTriggerStartTime;
    FLOAT mTriggerCurrentTime;
    FLOAT mTriggerLastTime;
    FLOAT mTriggerLastValue;
    
    BOOL mTriggerRaised;
    USHORT mTriggerSlope;
    FLOAT mTriggerOffset;
    
    FLOAT mTriggerTempMinY;
    FLOAT mTriggerTempMaxY;
    FLOAT mTriggerMinY;
    FLOAT mTriggerMaxY;
}

- (void)defaultValues;

- (void)setTriggerSlope:(USHORT)slope;
- (USHORT)triggerSlope;
- (void)setTriggerOffset:(FLOAT)offset;
- (FLOAT)triggerOffset;

- (void)setTriggerBufferDuration:(FLOAT)duration rate:(ULONG)rate;
- (void)triggerValue:(FLOAT)value atTime:(FLOAT)time;
- (void)reset;

- (FLOAT)minX;
- (FLOAT)maxX;
- (FLOAT)minY;
- (FLOAT)maxY;

- (FLOAT)valueAtX:(FLOAT)x;

@end
