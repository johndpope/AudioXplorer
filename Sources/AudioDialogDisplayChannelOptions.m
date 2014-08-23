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

#import "AudioDialogDisplayChannelOptions.h"
#import "AudioConstants.h"

@implementation AudioDialogDisplayChannelOptions

- (id)init
{
    if(self = [super initWithWindowNibName:@"AudioDisplayChannelOptions"])
    {
        mWrapper = NULL;
        mView = NULL;
        mParentWindow = NULL;
        mPanelEndedSelector = NULL;
        [self window];
    }
    return self;
}

- (void)lissajousSheetEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode==OK)
    {
        [mView setLissajousFrom:[mLissajousFromTextField floatValue]];
        [mView setLissajousTo:[mLissajousToTextField floatValue]];
        [mView setLissajousQuality:[mLissajousQualitySlider floatValue]];
        [mView refresh];
    }
    
    [mParentWindow performSelector:mPanelEndedSelector withObject:[NSNumber numberWithBool:returnCode==CANCEL]];
}

- (IBAction)lissajousPanelCancel:(id)sender
{
    [mLissajousPanel orderOut:self];
    [NSApp endSheet:mLissajousPanel returnCode:CANCEL];
}

- (IBAction)lissajousPanelOK:(id)sender
{
    [mLissajousPanel orderOut:self];
    [NSApp endSheet:mLissajousPanel returnCode:OK];
}

- (IBAction)lissajousQualitySliderAction:(id)sender
{
    [mLissajousQualityTextField setStringValue:[NSString stringWithFormat:@"%d%%", [sender intValue]]];
}

- (void)openLissajousPanel
{
    [mLissajousFromTextField setFloatValue:[mView lissajousFrom]];
    [mLissajousToTextField setFloatValue:[mView lissajousTo]];
    [mLissajousQualityTextField setStringValue:[NSString stringWithFormat:@"%d%%", (SHORT)[mView lissajousQuality]]];
    [mLissajousQualitySlider setDoubleValue:[mView lissajousQuality]];
    
    [NSApp beginSheet:mLissajousPanel modalForWindow:[mParentWindow window]
        modalDelegate:self didEndSelector:@selector(lissajousSheetEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)openPanelForWrapper:(AudioDataWrapper*)wrapper parentWindow:(id)parent endSelector:(SEL)endSelector
{
    mWrapper = wrapper;
    mView = [wrapper view];
    mParentWindow = parent;
    mPanelEndedSelector = endSelector;

    switch([wrapper displayedChannel]) {
        case LISSAJOUS_CHANNEL:
            [self openLissajousPanel];
            break;
        default:
            [mParentWindow performSelector:mPanelEndedSelector withObject:[NSNumber numberWithBool:YES]];
            break;
    }
}

@end
