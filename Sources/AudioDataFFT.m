
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

#import "AudioDataFFT.h"
#import "AudioDataSono.h"
#import "AudioDataWrapper.h"

#define FFT_VERSION_10b12 1	// Version 1.0b12 and before
#define FFT_VERSION_CURRENT 2

#define CHANNEL(channel) (channel == STEREO_CHANNEL)?LEFT_CHANNEL:channel

@implementation AudioDataFFT

- (id)init
{
    if(self = [super init])
    {
        SHORT channel;
        for(channel=0; channel<MAX_CHANNEL; channel++)
        {
            mFFTData[channel].realp = NULL;
            mFFTData[channel].imagp = NULL;
            mFFTDataBufferSize[channel] = 0;
            mMinY[channel] = 0;
            mMaxY[channel] = 0;
        }
        
        mFFT_N = DEFAULT_FFT_SIZE;
        mFFT_N2 = mFFT_N*0.5;
        mFFT_log2 = log(mFFT_N)/log(2);
        
        mDeltaT = 0;

        mXAxisScale = XAxisLinearScale;
        mYAxisScale = YAxisLinearScale;
    }
    return self;
}

- (void)dealloc
{    
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {
        if(mFFTData[channel].realp)
            free(mFFTData[channel].realp);
        if(mFFTData[channel].imagp)
            free(mFFTData[channel].imagp);
    }
    [super dealloc];
}

- (void)initWithCoderVersionCurrent:(NSCoder*)coder
{
    [coder decodeArrayOfObjCType:@encode(ULONG) count:MAX_CHANNEL at:&mFFTDataBufferSize];

    [coder decodeArrayOfObjCType:@encode(FLOAT) count:MAX_CHANNEL at:&mMinY];
    [coder decodeArrayOfObjCType:@encode(FLOAT) count:MAX_CHANNEL at:&mMaxY];
    
    [coder decodeValueOfObjCType:@encode(ULONG) at:&mFFT_N];
    [coder decodeValueOfObjCType:@encode(ULONG) at:&mFFT_N2];
    [coder decodeValueOfObjCType:@encode(ULONG) at:&mFFT_log2];
    [coder decodeValueOfObjCType:@encode(SHORT) at:&mYAxisScale];
    [coder decodeValueOfObjCType:@encode(FLOAT) at:&mDeltaT];

    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {
        BOOL hasData = NO;
        [coder decodeValueOfObjCType:@encode(BOOL) at:&hasData];
        if(hasData)
        {
            if([self allocateBufferForChannel:channel])
            {
                [coder decodeArrayOfObjCType:@encode(FLOAT) count:mFFT_N2 at:mFFTData[channel].realp];
                [coder decodeArrayOfObjCType:@encode(FLOAT) count:mFFT_N2 at:mFFTData[channel].imagp];
            } else
                [NSException raise:AXExceptionName format:NSLocalizedString(@"Unable to allocate the buffer to hold the spectrum data.", NULL)];
        }
    }
}

- (id)initWithCoder:(NSCoder*)coder
{
    if(self = [super init])
    {
        long version = [[coder decodeObject] longValue];

        switch(version) {
            case FFT_VERSION_10b12:
                [NSException raise:AXExceptionName format:NSLocalizedString(@"Cannot read file saved from a previous beta version.", NULL)];
                break;
            case FFT_VERSION_CURRENT:
                [self initWithCoderVersionCurrent:coder];
                break;
        }    
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:[NSNumber numberWithLong:FFT_VERSION_CURRENT]];

    [coder encodeArrayOfObjCType:@encode(ULONG) count:MAX_CHANNEL at:&mFFTDataBufferSize];

    [coder encodeArrayOfObjCType:@encode(FLOAT) count:MAX_CHANNEL at:&mMinY];
    [coder encodeArrayOfObjCType:@encode(FLOAT) count:MAX_CHANNEL at:&mMaxY];
    
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mFFT_N];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mFFT_N2];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mFFT_log2];
    [coder encodeValueOfObjCType:@encode(SHORT) at:&mYAxisScale];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mDeltaT];

    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {
        BOOL hasData = [self dataExistsForChannel:channel];
        [coder encodeValueOfObjCType:@encode(BOOL) at:&hasData];
        if(hasData)
        {
            [coder encodeArrayOfObjCType:@encode(FLOAT) count:mFFT_N2 at:mFFTData[channel].realp];
            [coder encodeArrayOfObjCType:@encode(FLOAT) count:mFFT_N2 at:mFFTData[channel].imagp];
        }
    }
}

- (void)setFFTSize:(ULONG)size
{
    mFFT_N = size;
    mFFT_N2 = mFFT_N*0.5;
    mFFT_log2 = log(size)/log(2);
}

- (void)setDeltaT:(FLOAT)deltaT
{
    mDeltaT = deltaT;
}

- (void)setXAxisScale:(SHORT)scale
{
    mXAxisScale = scale;
}

- (SHORT)xAxisScale
{
    return mXAxisScale;
}

- (void)setYAxisScale:(SHORT)scale
{
    mYAxisScale = scale;
}

- (SHORT)yAxisScale
{
    return mYAxisScale;
}

- (void)applyParametersFromWrapper:(AudioDataWrapper*)wrapper
{
    mFFT_N = [wrapper fftSize];
    mFFT_N2 = [wrapper fftSize2];
    mFFT_log2 = [wrapper fftLog2];
    mDeltaT = [wrapper deltaT];
    if(mDeltaT==0)
        mDeltaT = (FLOAT)mFFT_N/[wrapper dataRate];
}

- (void)copyFFTDataFromSonoData:(AudioDataSono*)data atX:(FLOAT)x channel:(SHORT)channel
{
    COMPLEX_SPLIT buffer = [data fftBufferAtX:x];

    if([self dataExistsForChannel:channel] == NO)
    {	
        mFFT_N = [data fftWindowWidth];
        mFFT_N2 = mFFT_N*0.5;
    	mFFT_log2 = log(mFFT_N)/log(2);
        mDeltaT = (FLOAT)mFFT_N/[data dataRate];
        [self allocateBufferForChannel:channel];
    }
    
    memcpy(mFFTData[channel].realp, buffer.realp, mFFT_N2*sizeof(float));
    memcpy(mFFTData[channel].imagp, buffer.imagp, mFFT_N2*sizeof(float));
    
    [self update];
}

- (BOOL)allocateBufferForChannel:(SHORT)channel
{
    if(mFFTData[channel].realp && mFFTDataBufferSize[channel] != mFFT_N2*SOUND_DATA_SIZE)
    {
        free(mFFTData[channel].realp);
        free(mFFTData[channel].imagp);
        mFFTData[channel].realp = NULL;
        mFFTData[channel].imagp = NULL;
        mFFTDataBufferSize[channel] = 0;
    }
    
    if(mFFTData[channel].realp == NULL)
    {
        mFFTDataBufferSize[channel] = mFFT_N2*SOUND_DATA_SIZE;

        mFFTData[channel].realp = (float*)malloc(mFFTDataBufferSize[channel]);
        mFFTData[channel].imagp = (float*)malloc(mFFTDataBufferSize[channel]);
    }
    
    return (mFFTData[channel].realp!=NULL);
}

- (void)setRpart:(FLOAT)rpart ipart:(FLOAT)ipart atIndex:(ULONG)index channel:(SHORT)channel
{
    if(index<0 || index*SOUND_DATA_SIZE>=mFFTDataBufferSize[channel])
        NSLog(@"Index problem in setRPart (%d)", index);
        
    mFFTData[channel].realp[index] = rpart;
    mFFTData[channel].imagp[index] = ipart;
}

- (FLOAT)yValue:(FLOAT)value channel:(SHORT)channel
{
    if(mYAxisScale == YAxisLinearScale)
        return value;
    else
    {
        if(value==0)
            return -200;
        else
        {
            if(value <= 0)
                return 0;
            else
                return 20*log10(value/mMaxY[CHANNEL(channel)]);
        }
    }
}

- (void)updateChannel:(SHORT)channel
{
    ULONG maxIndex = 0;
    ULONG minIndex = 0;
    
    mMinY[channel] = MIN(0, [self yValueNaturalAtIndex:0 channel:channel]); // Always start at 0
    mMaxY[channel] = [self yValueNaturalAtIndex:0 channel:channel];
        
    ULONG index;
    for(index=0; index<mFFT_N2; index++)
    {
        FLOAT module = [self yValueNaturalAtIndex:index channel:channel];
        
        if(module<mMinY[channel])
        {
            mMinY[channel] = module;
            minIndex = index;
        }
        if(module>mMaxY[channel])
        {
           /* meanF[0] = index-3;
            meanF[1] = index-2;
            meanF[2] = index-1;
            meanF[3] = index+1;
            meanF[4] = index+2;
            meanF[5] = index+3;
            
            meanM[0] = [self yValueAtIndex:index-3 channel:channel];
            meanM[1] = [self yValueAtIndex:index-2 channel:channel];
            meanM[2] = [self yValueAtIndex:index-1 channel:channel];
            meanM[3] = [self yValueAtIndex:index+1 channel:channel];
            meanM[4] = [self yValueAtIndex:index+2 channel:channel];
            meanM[5] = [self yValueAtIndex:index+3 channel:channel];*/
            
            mMaxY[channel] = module;
            maxIndex = index;
        }        
    } 
    
    // Calcul de la fréquence exacte
    
  /*  FLOAT s, m;
    s = maxIndex/mDeltaT*mMaxY;
    m = mMaxY;
    
    long i;
    for(i=0; i<6; i++)
    {
        s += meanF[i]/mDeltaT*meanM[i];
        m += meanM[i];
    }*/
    
    //NSLog(@"Max %f at %f", maxIndex/mDeltaT, s/m);
}

- (void)update
{
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {
        if([self dataExistsForChannel:channel])
            [self updateChannel:channel];
    }
}

- (ULONG)dataSize { return mFFT_N2*SOUND_DATA_SIZE; }

- (ULONG)maxIndex { return mFFT_N2; }

- (DOUBLE)deltaT { return mDeltaT; }

- (FLOAT)yValueNaturalAtIndex:(ULONG)index channel:(SHORT)channel
{
    ULONG idx = MIN(index, [self maxIndex]-1);
    return sqrt(mFFTData[CHANNEL(channel)].realp[idx]*mFFTData[CHANNEL(channel)].realp[idx]
                +mFFTData[CHANNEL(channel)].imagp[idx]*mFFTData[CHANNEL(channel)].imagp[idx]);
}

- (FLOAT)yValueAtIndex:(ULONG)index channel:(SHORT)channel
{
    return [self yValue:[self yValueNaturalAtIndex:index channel:channel] channel:channel];
}

- (FLOAT)yValueAtX:(FLOAT)x channel:(SHORT)channel
{
    return [self yValueAtIndex:x*mDeltaT channel:channel];
}

- (FLOAT)yValueNormalizedAtX:(FLOAT)x channel:(SHORT)channel
{
	return [self yValueAtX:x channel:channel]/[self maxYOfChannel:channel];
}

- (FLOAT)minXOfChannel:(SHORT)channel { return 0; }
- (FLOAT)maxXOfChannel:(SHORT)channel
{
    if(mDeltaT!=0)
        return mFFT_N2/mDeltaT;
    else
        return 0;
}
- (FLOAT)minYOfChannel:(SHORT)channel
{
    return [self yValue:mMinY[CHANNEL(channel)] channel:channel];
}
- (FLOAT)maxYOfChannel:(SHORT)channel
{
    return [self yValue:mMaxY[CHANNEL(channel)] channel:channel];
}

- (ULONG)indexOfXValue:(FLOAT)value channel:(SHORT)channel
{
    ULONG index = value*mDeltaT;
    index = MAX(0, index);
    index = MIN(index, mFFT_N2-1);
    
    return index;
}

- (BOOL)dataExistsForChannel:(SHORT)channel
{
    return mFFTData[CHANNEL(channel)].realp != NULL;
}

- (COMPLEX_SPLIT)dataForChannel:(SHORT)channel
{
    return mFFTData[CHANNEL(channel)];
}

- (SHORT)kind { return KIND_FFT; }
- (BOOL)supportTrigger { return NO; }
- (BOOL)supportPlayback { return NO; }
- (BOOL)supportHarmonicCursor { return YES; }

- (NSString*)name { return NSLocalizedString(@"Spectrum", NULL); }
- (NSString*)xAxisUnit { return @"Hz"; }
- (NSString*)yAxisUnit
{
    if(mYAxisScale == YAxisLogScale)
        return @"dB";
    else
        return @"V";
}
- (NSString*)xAxisName { return NSLocalizedString(@"Frequency", NULL); }
- (NSString*)yAxisName { return NSLocalizedString(@"Module", NULL); } // Module

- (NSString*)xAxisUnitForRange:(FLOAT)range
{
    if(range>=1000)
        return @"kHz";
    else
        return @"Hz";
}

- (FLOAT)xAxisUnitFactorForRange:(FLOAT)range
{
    if(range>=1000)
        return 0.001;
    else
        return 1;
}

- (NSString*)yAxisUnitForRange:(FLOAT)range
{
    if(mYAxisScale == YAxisLinearScale)
    {
        if(range<1 && range>1e-3)
            return @"mV";
        else if(range<1e-3)
            return @"µV";
        else
            return @"V";
    } else
        return @"dB";
}

- (FLOAT)yAxisUnitFactorForRange:(FLOAT)range
{
    if(mYAxisScale == YAxisLinearScale)
    {
        if(range<1 && range>1e-3)
            return 1e3;
        else if(range<1e-3)
            return 1e6;
        else
            return 1;
    } else
        return 1;
}

@end

@implementation AudioDataFFT (Export)

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
            size += mFFTDataBufferSize[channel];
    }

    return size;
}

- (NSString*)stringOfRawDataFromIndex:(ULONG)from to:(ULONG)to channel:(USHORT)channel delimiter:(NSString*)delimiter
{
    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:[self sizeOfData]];
    
    if(channel == STEREO_CHANNEL)
        [s appendFormat:@"%@%@ %@", NSLocalizedString(@"Left", NULL), delimiter,
                                    NSLocalizedString(@"Right", NULL)];
    else if(channel == LEFT_CHANNEL)
        [s appendString:NSLocalizedString(@"Left", NULL)];
    else if(channel == RIGHT_CHANNEL)
        [s appendString:NSLocalizedString(@"Right", NULL)];
    
    ULONG index;
    for(index=from; index<to; index++)
    {
        if(channel == STEREO_CHANNEL)
            [s appendFormat:@"\r%f%@ %f", [self yValueNaturalAtIndex:index channel:LEFT_CHANNEL],
                                        delimiter,
                                         [self yValueNaturalAtIndex:index channel:RIGHT_CHANNEL]];
        else if(channel == LEFT_CHANNEL)
            [s appendFormat:@"\r%f", [self yValueNaturalAtIndex:index channel:LEFT_CHANNEL]];
        else if(channel == RIGHT_CHANNEL)
            [s appendFormat:@"\r%f", [self yValueNaturalAtIndex:index channel:RIGHT_CHANNEL]];
    }
        
    return [s autorelease];
}

@end

