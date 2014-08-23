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

#import "AudioDialogFFTParameters.h"
#import "AudioConstants.h"
#import "AudioUtilities.h"

@implementation AudioDialogFFTParameters

- (id)init
{
    if(self = [super initWithWindowNibName:@"AudioFFTParameters"])
    {
        mWrapper = NULL;
        mRTDisplayer = NULL;
        mSharedOperator = [AudioOperator shared];
        [self window];
    }
    return self;
}

- (void)preparePanel
{
    [AudioUtilities setFFTSizePopUp:mFFTSizePopUp];
    [mSharedOperator fillPopUpButtonWithWindowFunctionTitles:mFFTWindowTypePopUp];
}

- (void)updateWindowParameterTitle
{
    SHORT funcID = mWrapper ? [mWrapper fftWindowFunctionID]:[mRTDisplayer fftWindowFunctionID];
    NSString *paramTitle = [mSharedOperator windowFunctionParameterTitleForID:funcID];
    [mFFTWindowParameterTitle setStringValue:paramTitle];
    [mFFTWindowParameterTextField setEnabled:![paramTitle isEqualToString:@""]];
}

- (void)updateFromWrapper
{
    [mFFTSizeDisplayButton setEnabled:YES];
    [mFFTSizeColorWell setEnabled:YES];
    
    [AudioUtilities selectFFTSizePopUp:mFFTSizePopUp withSize:[mWrapper fftSizeForUnit:UNIT_POINTS]];
    [mFFTSizeColorWell setColor:[mWrapper fftSizeColor]];
    [mFFTSizeDisplayButton setFloatValue:[mWrapper allowsFFTSize]];
    
    [mSharedOperator selectPopUp:mFFTWindowTypePopUp forWindowFunctionID:[mWrapper fftWindowFunctionID]];
    [mFFTWindowParameterTextField setFloatValue:[mWrapper fftWindowFunctionParameterValue]];
    [self updateWindowParameterTitle];
}

- (void)updateToWrapper
{
    [mWrapper setFFTWindowFunctionParameterValue:[mFFTWindowParameterTextField floatValue]];
}

- (void)updateFromRTDisplayer
{
    [mFFTSizeDisplayButton setEnabled:NO];
    [mFFTSizeColorWell setEnabled:NO];
    
    [AudioUtilities selectFFTSizePopUp:mFFTSizePopUp withSize:[mRTDisplayer fftSize]];
    
    [mSharedOperator selectPopUp:mFFTWindowTypePopUp forWindowFunctionID:[mRTDisplayer fftWindowFunctionID]];
    [mFFTWindowParameterTextField setFloatValue:[mRTDisplayer fftWindowFunctionParameterValue]];
    [self updateWindowParameterTitle];
}

- (void)updateToRTDisplayer
{
    [mRTDisplayer setFFTWindowFunctionParameterValue:[mFFTWindowParameterTextField floatValue]];
}

- (void)openPanelForWrapper:(AudioDataWrapper*)wrapper parentWindow:(NSWindow*)parent
{
    mWrapper = wrapper;
    mRTDisplayer = NULL;
    [self preparePanel];
    [self updateFromWrapper];
    [NSApp beginSheet:[self window] modalForWindow:parent
        modalDelegate:self didEndSelector:NULL contextInfo:NULL];
}

- (void)openPanelForRTDisplayer:(AudioRTDisplayer*)rtDisplayer parentWindow:(NSWindow*)parent
{
    mWrapper = NULL;
    mRTDisplayer = rtDisplayer;
    [self preparePanel];
    [self updateFromRTDisplayer];
    [NSApp beginSheet:[self window] modalForWindow:parent
        modalDelegate:self didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)closePanel:(id)sender
{
    [self updateToWrapper];
    [[self window] orderOut:self];
    [NSApp endSheet:[self window] returnCode:0];
}

- (IBAction)fftSizePopUpAction:(id)sender
{
    if(mWrapper)
    {
        [mWrapper setFFTSize:[AudioUtilities fftSizePopUp:mFFTSizePopUp] fromUnit:UNIT_POINTS];
        [[mWrapper view] setNeedsDisplay:YES];
    } else
        [mRTDisplayer setFFTSize:[AudioUtilities fftSizePopUp:mFFTSizePopUp]];
}

- (IBAction)displayFFTSizeButtonAction:(id)sender
{
    [mWrapper setAllowsFFTSize:[sender state]];
    [[mWrapper view] setNeedsDisplay:YES];
}

- (IBAction)fftSizeColorWellAction:(id)sender
{
    [mWrapper setFFTSizeColor:[sender color]];
    [[mWrapper view] setNeedsDisplay:YES];
}

- (IBAction)fftWindowFunctionTypePopUpAction:(id)sender
{
    if(mWrapper)
        [mWrapper setFFTWindowFunctionID:[mSharedOperator windowFunctionIDSelected:mFFTWindowTypePopUp]];
    else
        [mRTDisplayer setFFTWindowFunctionID:[mSharedOperator windowFunctionIDSelected:mFFTWindowTypePopUp]];
    [self updateWindowParameterTitle];
}

- (IBAction)fftWindowFunctionParameterTextFieldAction:(id)sender
{
    if(mWrapper)
        [mWrapper setFFTWindowFunctionParameterValue:[sender floatValue]];
    else
        [mRTDisplayer setFFTWindowFunctionParameterValue:[sender floatValue]];
}

@end
