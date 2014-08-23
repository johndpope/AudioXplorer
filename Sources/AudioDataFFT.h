
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
#import <vecLib/vDSP.h>

#import "AudioConstants.h"
#import "AudioDataWrapper.h"

@class AudioDataController;
@class AudioDataSono;

@interface AudioDataFFT : NSObject <NSCoding>
{
    COMPLEX_SPLIT mFFTData[MAX_CHANNEL];
    ULONG mFFTDataBufferSize[MAX_CHANNEL];

    ULONG mFFT_N, mFFT_N2, mFFT_log2;

    FLOAT mMinY[MAX_CHANNEL], mMaxY[MAX_CHANNEL];
    FLOAT mDeltaT;    
    
    SHORT mXAxisScale;
    SHORT mYAxisScale;
}
- (void)setFFTSize:(ULONG)size;
- (void)setDeltaT:(FLOAT)deltaT;

- (void)setXAxisScale:(SHORT)scale;
- (SHORT)xAxisScale;

- (void)setYAxisScale:(SHORT)scale;
- (SHORT)yAxisScale;

- (void)applyParametersFromWrapper:(AudioDataWrapper*)wrapper;
- (void)copyFFTDataFromSonoData:(AudioDataSono*)data atX:(FLOAT)x channel:(SHORT)channel;
- (BOOL)allocateBufferForChannel:(SHORT)channel;
- (void)setRpart:(FLOAT)rpart ipart:(FLOAT)ipart atIndex:(ULONG)index channel:(SHORT)channel;
- (void)update;

- (FLOAT)yValueNaturalAtIndex:(ULONG)index channel:(SHORT)channel;
- (FLOAT)yValueAtIndex:(ULONG)index channel:(SHORT)channel;
- (FLOAT)yValueNormalizedAtX:(FLOAT)x channel:(SHORT)channel;
- (BOOL)dataExistsForChannel:(SHORT)channel;
- (COMPLEX_SPLIT)dataForChannel:(SHORT)channel;

- (FLOAT)minXOfChannel:(SHORT)channel;
- (FLOAT)maxXOfChannel:(SHORT)channel;
- (FLOAT)minYOfChannel:(SHORT)channel;
- (FLOAT)maxYOfChannel:(SHORT)channel;

- (NSString*)name;

- (NSString*)xAxisUnitForRange:(FLOAT)range;
- (FLOAT)xAxisUnitFactorForRange:(FLOAT)range;

- (NSString*)yAxisUnitForRange:(FLOAT)range;
- (FLOAT)yAxisUnitFactorForRange:(FLOAT)range;

@end
