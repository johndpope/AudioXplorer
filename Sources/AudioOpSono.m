
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

#import "AudioOpSono.h"
#import "AudioOperator.h"

@implementation AudioOpSono

- (id)initWithAudioDataSono:(AudioDataSono*)sono
{
    if(self = [super init])
    {
        mComplexSplitBufferFFT.realp = NULL;
        mComplexSplitBufferFFT.imagp = NULL;
        
        mAudioDataForFFT = NULL;

        mAudioDataSono = [sono retain];
    }
    return self;
}

- (void)dealloc
{
    [mAudioDataSono release];

    if(mComplexSplitBufferFFT.realp) free(mComplexSplitBufferFFT.realp);
    if(mComplexSplitBufferFFT.imagp) free(mComplexSplitBufferFFT.imagp);
    if(mAudioDataForFFT) free(mAudioDataForFFT);
        
    [super dealloc];
}

- (FLOAT)moduleAtIndex:(ULONG)index
{
    return sqrt(mComplexSplitBufferFFT.realp[index]*mComplexSplitBufferFFT.realp[index]+
            mComplexSplitBufferFFT.imagp[index]*mComplexSplitBufferFFT.imagp[index]);
}

- (void)prepareBuffer
{        
    ULONG fft_n = [mAudioDataSono fftWindowWidth];
    ULONG fft_n2 = fft_n * 0.5;
    
    // Buffer to hold the temporary audio data required for the FFT
    if(mAudioDataForFFT) free(mAudioDataForFFT);
    mAudioDataForFFT = (SOUND_DATA_PTR)calloc(fft_n, SOUND_DATA_SIZE);
    
    // Buffer to hold the result of one FFT at a time
    if(mComplexSplitBufferFFT.realp) free(mComplexSplitBufferFFT.realp);
    if(mComplexSplitBufferFFT.imagp) free(mComplexSplitBufferFFT.imagp);
    
    mComplexSplitBufferFFT.realp = (SOUND_DATA_PTR)calloc(fft_n2, SOUND_DATA_SIZE);
    mComplexSplitBufferFFT.imagp = (SOUND_DATA_PTR)calloc(fft_n2, SOUND_DATA_SIZE);        
}

// Compute the sonogram
- (void)computeSono:(AudioDataAmplitude*)amplitudeData channel:(USHORT)channel windowParametersArray:(NSArray*)windowParametersArray
{
    ULONG fft_offset = [mAudioDataSono fftWindowOffset];
    ULONG fft_n = [mAudioDataSono fftWindowWidth];
    ULONG fft_n2 = fft_n * 0.5;
    ULONG max_fft = [mAudioDataSono maxFFT];
    ULONG fft_log2 = log(fft_n)/log(2);

    AudioOperator *operator = [AudioOperator shared];
    [operator prepareWindowingParameters:windowParametersArray];

    // Let's compute every windows
    ULONG indexFFT;
    for(indexFFT=0; indexFFT<max_fft; indexFFT++)
    {
        // Sample the audio data
        ULONG offset = [amplitudeData indexOfXValue:[mAudioDataSono minXOfChannel:channel] channel:channel];
        ULONG index;
        for(index=0; index<fft_n; index++)
        {
            ULONG source = offset+indexFFT*fft_offset+index;
            FLOAT value = [amplitudeData yValueAtIndex:source channel:channel];
            mAudioDataForFFT[index] = [amplitudeData yValueAtIndex:source channel:channel];
            mAudioDataForFFT[index] = [operator yValueAfterWindowing:value atIndex:index maxIndex:fft_n];
        }

        // Prepare the odd-even array from temporal data
        ctoz((COMPLEX*)mAudioDataForFFT, 2, &mComplexSplitBufferFFT, 1, fft_n2);
        
        // Compute the FFT
        fft_zrip([[AudioOperator shared] weightBufferForLog2:fft_log2],
                    &mComplexSplitBufferFFT, 1, fft_log2, FFT_FORWARD);

        // Scale
        FLOAT scale = 1.0/fft_n2;
        
        vsmul(mComplexSplitBufferFFT.realp, 1, &scale, mComplexSplitBufferFFT.realp, 1, fft_n2);
        vsmul(mComplexSplitBufferFFT.imagp, 1, &scale, mComplexSplitBufferFFT.imagp, 1, fft_n2);

        // Copy the temporary buffer into the sonogram buffer        
        [mAudioDataSono addFFT:mComplexSplitBufferFFT];
    }    
}

+ (AudioDataSono*)computeWrapper:(AudioDataWrapper*)wrapper selection:(BOOL)selection;
{
    AudioDataSono *sonoData = [[AudioDataSono alloc] init];
    [sonoData applyWrapper:wrapper selection:selection];
    AudioOpSono *sono = [[AudioOpSono alloc] initWithAudioDataSono:sonoData];
    
    USHORT channel = [wrapper displayedChannel];
    if(channel != LEFT_CHANNEL && channel != RIGHT_CHANNEL)
        channel = LEFT_CHANNEL;
        
    [sono prepareBuffer];
    [sono computeSono:[wrapper data]
            channel:channel
            windowParametersArray:[wrapper sonoWindowParametersArray]];
    [sono release];

    [sonoData computeImage];   
    
    return [sonoData autorelease];
}

@end

@implementation AudioOpSono (SonoToAmplitude)
/*
- (void)computeAmplitudeSliceToBuffer:(SOUND_DATA_PTR)buffer atIndex:(ULONG)index
{
    ULONG fft_n = [mAudioDataSono fftWindowWidth];
    ULONG fft_n2 = fft_n*0.5;
    ULONG fft_log2 = log(fft_n)/log(2);

    
    // Copy the FFT data into the buffer
    FLOAT scale = 1.0/fft_n;
    
    ULONG i;
    for(i=0; i<fft_n2; i++)
    {
        mComplexSplitBufferFFT.realp[i] = [mAudioDataSono sonoBuffer]->realp[index*fft_n2+i];
        mComplexSplitBufferFFT.imagp[i] = [mAudioDataSono sonoBuffer]->imagp[index*fft_n2+i];
    }
        
    // Inverse FFT of the frequency data
    
    fft_zrip([[AudioOperator shared] weightBufferForLog2:fft_log2],
            &mComplexSplitBufferFFT, 1, fft_log2, FFT_INVERSE);
    
    // Scale the result

    vsmul( mComplexSplitBufferFFT.realp, 1, &scale, mComplexSplitBufferFFT.realp, 1, fft_n2 );
    vsmul( mComplexSplitBufferFFT.imagp, 1, &scale, mComplexSplitBufferFFT.imagp, 1, fft_n2 );

    // Result back to a real buffer
    
    ztoc ( &mComplexSplitBufferFFT, 1, ( COMPLEX * ) mAudioDataForFFT, 2, fft_n2 );

    // Copy result to buffer
    
    memcpy(buffer, mAudioDataForFFT, fft_n);
}

- (void)addBlock:(SOUND_DATA_PTR)block toAmplitude:(SOUND_DATA_PTR)amplitude fader:(BOOL)fade
{
    ULONG fft_n = [mAudioDataSono fftWindowWidth];
    
    // Copy the data without fading
    
    FLOAT deltaIndex = 1;//mFFTWindowWidth/fft_n*mRate;
    
    ULONG indexFFT;
    for(indexFFT=0; indexFFT<fft_n; indexFFT++)
    {
        // Copy amplitude from computed buffer to output buffer
        ULONG indexAmplitude = indexFFT*deltaIndex;
        amplitude[indexAmplitude] = mAudioDataForFFT[indexFFT];
        
        if(indexFFT<fft_n)
        {
            // Linear adjustment between two points
            FLOAT deltaAmplitude = mAudioDataForFFT[indexFFT+1]-mAudioDataForFFT[indexFFT];
            ULONG indexFit;
            for(indexFit=indexFFT*deltaIndex; indexFit<(indexFFT+1)*deltaIndex; indexFit++)
                amplitude[indexFit] = amplitude[indexAmplitude]+
                                        deltaAmplitude*(indexFit-indexFFT*deltaIndex)/deltaIndex;
        }
    }
}

- (FLOAT*)computeAmplitudeFrom:(FLOAT)from to:(FLOAT)to size:(ULONG*)outSize
{
    // from [s], to [s]

    ULONG rate = [mAudioDataSono rate];
    ULONG fft_n = [mAudioDataSono fftWindowWidth];
    
    ULONG indexFrom = (from*rate)/[mAudioDataSono fftWindowOffset];
    ULONG indexTo = (to*rate-fft_n)/[mAudioDataSono fftWindowOffset];
    ULONG size = (to-from)*rate*SOUND_DATA_SIZE;
    
    FLOAT *amplitude = (FLOAT*)malloc(size);
    FLOAT *block = (FLOAT*)malloc(fft_n*SOUND_DATA_SIZE);
    FLOAT *amplitudePtr = amplitude;
        
    ULONG index;
    for(index=indexFrom; index<indexTo; index++)
    {
        ULONG offset;
        [self computeAmplitudeSliceToBuffer:block atIndex:index];
        [self addBlock:block toAmplitude:amplitudePtr fader:NO];

        offset = [mAudioDataSono fftWindowOffset]*rate;
        amplitudePtr += offset;
    }
    
    free(block);
    
    *outSize = size;

    return amplitude;
}
*/
@end
