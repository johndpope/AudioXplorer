
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

#import "AudioOpFFT.h"
#import "AudioOperator.h"

@implementation AudioOpFFT

+ (AudioDataFFT*)computeWrapper:(AudioDataWrapper*)wrapper selection:(BOOL)flag
{
    return [self computeWrapper:wrapper withFFTData:NULL selection:flag];
}

+ (AudioDataFFT*)computeWrapper:(AudioDataWrapper*)wrapper withFFTData:(AudioDataFFT*)data selection:(BOOL)flag
{
    if(flag)
        data = [self computeData:[wrapper data] from:[wrapper selMinX] to:[wrapper selMaxX]
                                size:[wrapper fftSize] audioDataFFT:data
                                windowParametersArray:[wrapper fftWindowParametersArray]];
    else
        data = [self computeData:[wrapper data] from:[wrapper cursorX] to:[wrapper cursorX]
                                size:[wrapper fftSize] audioDataFFT:data
                                windowParametersArray:[wrapper fftWindowParametersArray]];
                                
    [data applyParametersFromWrapper:wrapper];

    return data;
}

+ (AudioDataFFT*)computeData:(AudioDataAmplitude*)data from:(FLOAT)from to:(FLOAT)to size:(ULONG)size audioDataFFT:(AudioDataFFT*)audioDataFFT windowParametersArray:(NSArray*)windowParametersArray
{
    ULONG theFFT_N = size;
    ULONG theFFT_N2 = theFFT_N*0.5;
    ULONG theFFT_log2 = log(theFFT_N)/log(2);
        
    // Buffer to hold audio data for the FFT (because we must sample
    // the original audio buffer)
    SOUND_DATA_PTR temporaryAudioData;
    temporaryAudioData = (SOUND_DATA_PTR)calloc(theFFT_N, SOUND_DATA_SIZE);
    if(temporaryAudioData==NULL)
    {
        NSLog(@"Error while allocating temporaryAudioData");
        return NULL;
    }

    // Buffer for complex split array (used to compute the FFT)    
    COMPLEX_SPLIT complexSplit;    
    complexSplit.realp = (SOUND_DATA_PTR)calloc(theFFT_N2, SOUND_DATA_SIZE);    
    if(complexSplit.realp==NULL)
    {
        NSLog(@"Error while allocating complexSplit.realp");
        return NULL;
    }
    complexSplit.imagp = (SOUND_DATA_PTR)calloc(theFFT_N2, SOUND_DATA_SIZE);
    if(complexSplit.imagp==NULL)
    {
        NSLog(@"Error while allocating complexSplit.imagp");
        return NULL;
    }

    // Create the module array buffer
    if(audioDataFFT == NULL)
        audioDataFFT = [[[AudioDataFFT alloc] init] autorelease];

    // Step of sampling
    FLOAT step = 1.0;
    if(from<to)
        step = ((to-from)*[data dataRate])/theFFT_N;

    [audioDataFFT setFFTSize:theFFT_N];
    [audioDataFFT setDeltaT:(FLOAT)(theFFT_N*step)/[data dataRate]];

    // Prepare the windowing function
    AudioOperator *operator = [AudioOperator shared];
    [operator prepareWindowingParameters:windowParametersArray];

    // Compute the FFT for all available channel
    SHORT channel;
    for(channel=0; channel<MAX_CHANNEL; channel++)
    {
        if([data dataExistsForChannel:channel])
        {
            // Sample audio data into the buffer
            ULONG index;
            ULONG offset = [data indexOfXValue:from channel:channel];
            for(index=0; index<theFFT_N; index++)
            {
                ULONG audioIndex = offset+index*step;
                FLOAT value = [data yValueAtIndex:audioIndex channel:channel];
                temporaryAudioData[index] = [operator yValueAfterWindowing:value
                                                atIndex:index maxIndex:theFFT_N];
            }
                        
            // Prepare the odd-even array from temporal data
            ctoz((COMPLEX*)temporaryAudioData, 2, &complexSplit, 1, theFFT_N2);
            
            // FFT of the temporal data
            fft_zrip([operator weightBufferForLog2:theFFT_log2],
                        &complexSplit, 1, theFFT_log2, FFT_FORWARD);
            
            // Scale
            FLOAT scale = 1.0/theFFT_N2;
            
            vsmul(complexSplit.realp, 1, &scale, complexSplit.realp, 1, theFFT_N2);
            vsmul(complexSplit.imagp, 1, &scale, complexSplit.imagp, 1, theFFT_N2);
            
            if([audioDataFFT allocateBufferForChannel:channel])
            {        
                FLOAT maxValue = 0;  
                                
                for(index=0; index<theFFT_N2; index++)
                {
                    FLOAT value = sqrt(complexSplit.realp[index]*complexSplit.realp[index]+
                        complexSplit.imagp[index]*complexSplit.imagp[index]);   
                                    
                    if(index==0)
                        value = sqrt(complexSplit.realp[1]*complexSplit.realp[1]+
                        complexSplit.imagp[1]*complexSplit.imagp[1]);
                        
                    maxValue = MAX(value, maxValue);
                }
        
                for(index=0; index<theFFT_N2; index++)
                {
                    if(index==0)
                        [audioDataFFT setRpart:complexSplit.realp[1] ipart:complexSplit.imagp[1]
                                    atIndex:index channel:channel];                        
                    else
                        [audioDataFFT setRpart:complexSplit.realp[index] ipart:complexSplit.imagp[index]
                                    atIndex:index channel:channel];
                }
            } else
            {
                audioDataFFT = NULL;
                break;
            }
        } // If channel available
    }

    [audioDataFFT update];
    
    // Free all buffers
    free(complexSplit.realp);
    free(complexSplit.imagp);
    free(temporaryAudioData);

    return audioDataFFT;
}

@end
