
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
#import "AudioView.h"
#import "AudioDataWrapper.h"

@interface AudioOperator : NSObject {
    FFTSetup mFFTWeightBuffer;
    SHORT mFFTWeightBufferLog2;
    
    // Windowing
    NSArray *mWindowFunctionTitleArray;
    NSArray *mWindowFunctionIDArray;
    NSArray *mWindowFunctionParameterTitleArray;
    
    SHORT mWindowID;
    FLOAT mWindowParameter;
    
    // Operations
    
    NSArray *mOperationTitleArray;
    NSArray *mOperationIDArray;
}

+ (id)shared;

@end

@interface AudioOperator (Analyze)
- (FFTSetup)weightBufferForLog2:(SHORT)log2;
- (AudioDataWrapper*)computeOperation:(SHORT)op withWrapper:(AudioDataWrapper*)wrapper;
@end

@interface AudioOperator (Windowing)
- (void)prepareWindowingParameters:(NSArray*)windowParametersArray;
- (FLOAT)yValueAfterWindowing:(FLOAT)value atIndex:(ULONG)index maxIndex:(ULONG)maxIndex;

- (void)fillPopUpButtonWithWindowFunctionTitles:(NSPopUpButton*)popUp;
- (SHORT)windowFunctionIDSelected:(NSPopUpButton*)popUp;
- (void)selectPopUp:(NSPopUpButton*)popUp forWindowFunctionID:(SHORT)windowID;
- (NSString*)windowFunctionParameterTitleForID:(SHORT)windowID;
@end

@interface AudioOperator (Operations)
- (NSArray*)operationTitles;
- (NSArray*)operationID;
+ (AudioDataWrapper*)computeWrapperFromWrapperSourceA:(AudioDataWrapper*)sourceA sourceB:(AudioDataWrapper*)sourceB operation:(SHORT)opID;
@end
