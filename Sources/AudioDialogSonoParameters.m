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

#import "AudioDialogSonoParameters.h"
#import "AudioConstants.h"
#import "AudioUtilities.h"

#define WINDOW_OFFSET_TAG 0

@implementation AudioDialogSonoParameters

- (id)init
{
    if(self = [super initWithWindowNibName:@"AudioSonoParameters"])
    {
        mWrapper = NULL;
        mSharedOperator = [AudioOperator shared];
        [self window];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    mUnitPopUp[WINDOW_OFFSET_TAG] = UNIT_POINTS;

    [AudioUtilities setFFTSizePopUp:mWindowSizePopUp];
    [mSharedOperator fillPopUpButtonWithWindowFunctionTitles:mWindowTypePopUp];
}

- (void)updateWindowParameterTitle
{
    NSString *paramTitle = [mSharedOperator windowFunctionParameterTitleForID:[mWrapper sonoWindowFunctionID]];
    [mWindowParameterTitle setStringValue:paramTitle];
    [mWindowParameterTextField setEnabled:![paramTitle isEqualToString:@""]];
}

- (void)updateFromWrapper
{
    [AudioUtilities selectFFTSizePopUp:mWindowSizePopUp withSize:[mWrapper windowSizeForUnit:UNIT_POINTS]];
    [mWindowOffsetTextField setFloatValue:[mWrapper windowOffsetForUnit:mUnitPopUp[WINDOW_OFFSET_TAG]]];

    [mSharedOperator selectPopUp:mWindowTypePopUp forWindowFunctionID:[mWrapper sonoWindowFunctionID]];
    [mWindowParameterTextField setFloatValue:[mWrapper sonoWindowFunctionParameterValue]];
    [self updateWindowParameterTitle];
}

- (void)updateToWrapper
{
    [mWrapper setWindowOffset:[mWindowOffsetTextField floatValue] fromUnit:mUnitPopUp[WINDOW_OFFSET_TAG]];
}

- (void)openPanelForWrapper:(AudioDataWrapper*)wrapper parentWindow:(NSWindow*)parent
{
    mWrapper = wrapper;
    [self updateFromWrapper];
    [NSApp beginSheet:[self window] modalForWindow:parent
        modalDelegate:self didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)closePanel:(id)sender
{
    [self updateToWrapper];
    [[self window] orderOut:self];
    [NSApp endSheet:[self window] returnCode:0];
}

- (IBAction)windowSizeTextFieldAction:(id)sender
{
}

- (IBAction)windowOffsetTextFieldAction:(id)sender
{
}

- (IBAction)windowSizePopUpAction:(id)sender
{
    [mWrapper setWindowSize:[AudioUtilities fftSizePopUp:mWindowSizePopUp] fromUnit:UNIT_POINTS];
}

- (IBAction)windowOffsetDividerButton:(id)sender
{
    FLOAT factor = [mWrapper convertFactorFromUnit:UNIT_POINTS toUnit:mUnitPopUp[WINDOW_OFFSET_TAG]];
    FLOAT offset = 0;
    
    switch([sender tag]) {
        case 0:
            offset = [AudioUtilities fftSizePopUp:mWindowSizePopUp]*factor*0.5;
            break; 
        case 1:
            offset = [AudioUtilities fftSizePopUp:mWindowSizePopUp]*factor*0.25;
            break; 
        case 2:
            offset = [AudioUtilities fftSizePopUp:mWindowSizePopUp]*factor*0.125;
            break; 
    }
    [mWindowOffsetTextField setFloatValue:offset];
}

- (IBAction)windowOffsetUnitPopUpAction:(id)sender
{
    SHORT newUnit = [sender indexOfSelectedItem]+1;
    FLOAT factor = [mWrapper convertFactorFromUnit:mUnitPopUp[WINDOW_OFFSET_TAG] toUnit:newUnit];
    
    mUnitPopUp[WINDOW_OFFSET_TAG] = newUnit;
    
    [mWindowOffsetTextField setFloatValue:[mWindowOffsetTextField floatValue]*factor];
}

- (IBAction)windowFunctionTypePopUpAction:(id)sender
{
    [mWrapper setSonoWindowFunctionID:[mSharedOperator windowFunctionIDSelected:mWindowTypePopUp]];
    [self updateWindowParameterTitle];
}

- (IBAction)windowFunctionParameterTextFieldAction:(id)sender
{
    [mWrapper setSonoWindowFunctionParameterValue:[sender floatValue]];
}

@end
