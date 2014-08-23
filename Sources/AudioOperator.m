
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

#import "AudioOperator.h"
#import "AudioConstants.h"
#import "AudioOpFFT.h"
#import "AudioOpSono.h"
#import "AudioApp.h"

#define RECT_ID 0
#define BARTLETT_ID 100
#define WELCH_ID 101
#define HANN_ID 102
#define HAMMING_ID 103
#define BLACKMAN_ID 104
#define GAUSSIAN_ID 105
#define KAISER_ID 106

#define OP_ADD 0
#define OP_SUB 1
#define OP_MUL 2
#define OP_DIV 3
#define OP_SMM 4 // Stereo = Mono(+)Mono
#define OP_SLL 5 // Stereo = Left(+)Left
#define OP_SLR 6 // Stereo = Left(+)Right
#define OP_SRR 7 // Stereo = Right(+)Right

FFTSetup gFFTWeightBuffer = NULL;
SHORT gFFTWeightBufferLog2 = 0;

@implementation AudioOperator

+ (id)shared
{
    static AudioOperator *sharedOperator = NULL;
    
    if(!sharedOperator)
    {
        sharedOperator = [[AudioOperator alloc] init];
        [AudioApp addStaticObject:sharedOperator];
    }
    
    return sharedOperator;
}

- (id)init
{
    if(self = [super init])
    {
        mFFTWeightBuffer = NULL;
        mFFTWeightBufferLog2 = 0;
        
        mWindowID = 0;
        mWindowParameter = 1.0;

        mWindowFunctionTitleArray = [[NSArray arrayWithObjects:NSLocalizedString(@"Rectangular", NULL),
                                                                @"Bartlett",
                                                                @"Welch",
                                                                @"Hann",
                                                                @"Hamming",
                                                                @"Blackman",
                                                                @"Gaussian",
                                                                @"Kaiser",
                                                                NULL] retain];

        mWindowFunctionParameterTitleArray = [[NSArray arrayWithObjects:@"",
                                                                @"",
                                                                @"",
                                                                @"",
                                                                @"",
                                                                @"",
                                                                [NSString stringWithFormat:@"%C =", 0x03C3],
                                                                [NSString stringWithFormat:@"%C =", 0x03B1],
                                                                NULL] retain];

        mWindowFunctionIDArray = [[NSArray arrayWithObjects:[NSNumber numberWithInt:RECT_ID],
                                                        [NSNumber numberWithInt:BARTLETT_ID],
                                                        [NSNumber numberWithInt:WELCH_ID],
                                                        [NSNumber numberWithInt:HANN_ID],
                                                        [NSNumber numberWithInt:HAMMING_ID],
                                                        [NSNumber numberWithInt:BLACKMAN_ID],
                                                        [NSNumber numberWithInt:GAUSSIAN_ID],
                                                        [NSNumber numberWithInt:KAISER_ID],
                                                        NULL] retain];
    
        mOperationTitleArray = [[NSArray arrayWithObjects:@"+",
                                                            @"-",
                                                            @"*",
                                                            @"/",
                                                    NSLocalizedString(@"Stereo = Mono(+)Mono", NULL),
                                                    NSLocalizedString(@"Stereo = Left(+)Left", NULL),
                                                    NSLocalizedString(@"Stereo = Left(+)Right", NULL),
                                                    NSLocalizedString(@"Stereo = Right(+)Right", NULL),
                                                            NULL] retain];
                                                            
        mOperationIDArray = [[NSArray arrayWithObjects:[NSNumber numberWithInt:OP_ADD],
                                                        [NSNumber numberWithInt:OP_SUB],
                                                        [NSNumber numberWithInt:OP_MUL],
                                                        [NSNumber numberWithInt:OP_DIV],
                                                        [NSNumber numberWithInt:OP_SMM],
                                                        [NSNumber numberWithInt:OP_SLL],
                                                        [NSNumber numberWithInt:OP_SLR],
                                                        [NSNumber numberWithInt:OP_SRR],
                                                        NULL] retain];
    }
    return self;
}

- (void)dealloc
{
    if(mFFTWeightBuffer) destroy_fftsetup(mFFTWeightBuffer);

    [mWindowFunctionTitleArray release];
    [mWindowFunctionIDArray release];
    [mWindowFunctionParameterTitleArray release];

    [mOperationTitleArray release];
    [mOperationIDArray release];
    
    [super dealloc];
}

@end

@implementation AudioOperator (Analyze)

- (FFTSetup)weightBufferForLog2:(SHORT)log2
{
    if(log2!=mFFTWeightBufferLog2)
    {
        mFFTWeightBufferLog2 = log2;
        
        if(mFFTWeightBuffer)
            free(mFFTWeightBuffer);
            
        mFFTWeightBuffer = create_fftsetup(mFFTWeightBufferLog2, FFT_RADIX2);
    }
    
    return mFFTWeightBuffer;
}

- (AudioDataWrapper*)computeOperation:(SHORT)op withWrapper:(AudioDataWrapper*)wrapper
{
    AudioDataWrapper* theComputedWrapper = NULL;
    NSString *viewName = @"";
    
    switch(op) {
        case OPERATION_AMPLITUDE:
            theComputedWrapper = wrapper;
            viewName = [NSString stringWithFormat:@"%@", [wrapper viewName]];
            break;
        
        case OPERATION_FFT_CURSOR:
            theComputedWrapper = [AudioDataWrapper initWithAudioData:[AudioOpFFT computeWrapper:wrapper selection:NO]];
            viewName = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Spectrum", NULL),
                                                            [wrapper viewName]];
            break;
            
        case OPERATION_FFT_SELECTION:
            theComputedWrapper = [AudioDataWrapper initWithAudioData:[AudioOpFFT computeWrapper:wrapper selection:YES]];
            viewName = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Spectrum", NULL),
                                                            [wrapper viewName]];
            break;
        
        case OPERATION_SONO:
            theComputedWrapper = [AudioDataWrapper initWithAudioData:[AudioOpSono computeWrapper:wrapper selection:NO]];
            viewName = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Sonogram", NULL),
                                                             [wrapper viewName]];
            break;

        case OPERATION_SONO_SELECTION:
            theComputedWrapper = [AudioDataWrapper initWithAudioData:[AudioOpSono computeWrapper:wrapper selection:YES]];
            viewName = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Sonogram", NULL),
                                                             [wrapper viewName]];
            break;
        
        case OPERATION_COPY:
            theComputedWrapper = [AudioDataWrapper copyFromAudioDataWrapper:wrapper];
            viewName = [wrapper viewName];
            break;
        
        case OPERATION_LINKED_FFT:	// Linked to sonogram view always
            theComputedWrapper = [AudioDataWrapper wrapperLinkedToWrapper:wrapper];
            viewName = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Spectrum", NULL),
                                                             [wrapper viewName]];
            break;
    }
    
    [theComputedWrapper setViewName:viewName always:NO];
    return theComputedWrapper;
}

@end

@implementation AudioOperator (Windowing)

- (FLOAT)besselI0:(FLOAT)x
{
    FLOAT ax, ans, y;
    
    ax = fabs(x);
    if(ax<3.75)
    {
        y = x/3.75;
        y *= y;
        ans = 1.0+y*(3.5156229+y*(3.0899424+y*(1.2067492+y*(0.2659732+y*(0.360768e-1+y*0.45813e-2)))));
    } else
    {
        y = 3.75/ax;
        ans = (exp(ax)/sqrt(ax))*(0.39894228+y*(0.132859e-1
                        +y*(0.225319e-2+y*(-0.157565e-2+y*(0.916281e-2
                        +y*(-0.2057706e-1+y*(0.2635537e-1+y*(-0.1647633e-1
                        +y*0.392377e-2))))))));
    }
    return ans;
}

- (void)prepareWindowingParameters:(NSArray*)windowParametersArray
{
    mWindowID = 0;
    mWindowParameter = 1.0;
    
    if(windowParametersArray)
    {
        mWindowID = [[windowParametersArray objectAtIndex:0] intValue];
        mWindowParameter = [[windowParametersArray objectAtIndex:1] floatValue];
    }    
}

- (FLOAT)yValueAfterWindowing:(FLOAT)value atIndex:(ULONG)index maxIndex:(ULONG)maxIndex
{
    FLOAT tau = maxIndex*0.5;
    FLOAT x = index-tau;
    FLOAT sigma = mWindowParameter;	// GAUSSIAN_ID
    FLOAT alpha = mWindowParameter; 	// KAISER_ID
        
    switch(mWindowID) {
        case RECT_ID:
            return value;
            break;
        case BARTLETT_ID:
            return value*(1.0-fabs(x)/tau);
            break;
        case WELCH_ID:
            return value*(1.0-pow(x/tau,2));
            break;
        case HANN_ID:
            return value*(0.5+(1-0.5)*cos(pi*x/tau));
            break;
        case HAMMING_ID:
            return value*(0.54+(1-0.54)*cos(pi*x/tau));
            break;
        case BLACKMAN_ID:
            return value*(0.42+0.5*cos(pi*x/tau)+0.08*cos(2*pi*x/tau));
            break;
        case GAUSSIAN_ID:
            return value*exp(-pow(x/sigma,2));
            break;
        case KAISER_ID:
            return value*([self besselI0:alpha*sqrt(1-pow(x/tau,2))]/[self besselI0:alpha]);
            break;
   }
    return value;
}

- (void)fillPopUpButtonWithWindowFunctionTitles:(NSPopUpButton*)popUp
{
    [popUp removeAllItems];
    [popUp addItemsWithTitles:mWindowFunctionTitleArray];
}

- (SHORT)windowFunctionIDSelected:(NSPopUpButton*)popUp
{
    return [[mWindowFunctionIDArray objectAtIndex:[popUp indexOfSelectedItem]] intValue];
}

- (void)selectPopUp:(NSPopUpButton*)popUp forWindowFunctionID:(SHORT)windowID
{
    [popUp selectItemAtIndex:[mWindowFunctionIDArray indexOfObject:[NSNumber numberWithInt:windowID]]];
}

- (NSString*)windowFunctionParameterTitleForID:(SHORT)windowID
{
    return [mWindowFunctionParameterTitleArray objectAtIndex:[mWindowFunctionIDArray indexOfObject:[NSNumber numberWithInt:windowID]]];
}

@end

@implementation AudioOperator (Operations)

- (NSArray*)operationTitles
{
    return mOperationTitleArray;
}

- (NSArray*)operationID
{
    return mOperationIDArray;
}

+ (FLOAT)computeValueA:(FLOAT)a valueB:(FLOAT)b operation:(SHORT)opID
{
    FLOAT result = 0;
    
    switch(opID) {
        case OP_ADD:
            result = a+b;
            break;
        case OP_SUB:
            result = a-b;
            break;
        case OP_MUL:
            result = a*b;
            break;
        case OP_DIV:
            result = a/b;
            break;
        default:
            NSLog(@"Invalid operator %d", opID);
    }
    return result;
}

+ (AudioDataWrapper*)computeWrapperFromWrapperSourceA:(AudioDataWrapper*)sourceA sourceB:(AudioDataWrapper*)sourceB operation:(SHORT)opID
{
    AudioDataAmplitude *dataA = [sourceA data];
    AudioDataAmplitude *dataB = [sourceB data];
    
    AudioDataAmplitude *result = [[AudioDataAmplitude alloc] init];

    FLOAT rate = [dataA dataRate];
    ULONG maxIndexA = [dataA maxIndex];
    ULONG maxIndexB = [dataB maxIndex];
    ULONG maxIndex = MIN(maxIndexA, maxIndexB);
        
    [result setDuration:(FLOAT)maxIndex/rate rate:rate channel:STEREO_CHANNEL];

    ULONG index;
    for(index=0; index<maxIndex; index++)
    {
        switch(opID) {
            case OP_SMM: // Stereo = Mono(+)Mono
            {
                SHORT ca = [dataA dataExistsForChannel:LEFT_CHANNEL] ? LEFT_CHANNEL:RIGHT_CHANNEL;
                SHORT cb = [dataB dataExistsForChannel:LEFT_CHANNEL] ? LEFT_CHANNEL:RIGHT_CHANNEL;
                
                [result addDataValue:[dataA yValueAtIndex:index channel:ca]
                                    inChannel:LEFT_CHANNEL];
                [result addDataValue:[dataB yValueAtIndex:index channel:cb]
                                    inChannel:RIGHT_CHANNEL];
                break;
            }
            case OP_SLL: // Stereo = Left(+)Left
                [result addDataValue:[dataA yValueAtIndex:index channel:LEFT_CHANNEL]
                                    inChannel:LEFT_CHANNEL];
                [result addDataValue:[dataB yValueAtIndex:index channel:LEFT_CHANNEL]
                                    inChannel:RIGHT_CHANNEL];
                break;
            case OP_SLR: // Stereo = Left(+)Right
                [result addDataValue:[dataA yValueAtIndex:index channel:LEFT_CHANNEL]
                                    inChannel:LEFT_CHANNEL];
                [result addDataValue:[dataB yValueAtIndex:index channel:RIGHT_CHANNEL]
                                    inChannel:RIGHT_CHANNEL];
                break;
            case OP_SRR: // Stereo = Right(+)Right
                [result addDataValue:[dataA yValueAtIndex:index channel:RIGHT_CHANNEL]
                                    inChannel:LEFT_CHANNEL];
                [result addDataValue:[dataB yValueAtIndex:index channel:RIGHT_CHANNEL]
                                    inChannel:RIGHT_CHANNEL];
                break;
            default:
            {
                FLOAT value = [self computeValueA:[dataA yValueAtIndex:index channel:LEFT_CHANNEL] 
                                valueB:[dataB yValueAtIndex:index channel:LEFT_CHANNEL]
                                operation:opID];
                [result addDataValue:value inChannel:LEFT_CHANNEL];
                break;
            }
        }
    }

    AudioDataWrapper *wrapper = [AudioDataWrapper initWithAudioData:[result autorelease]];
    
    return wrapper;
}

@end
