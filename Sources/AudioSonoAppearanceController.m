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

#import "AudioSonoAppearanceController.h"


@implementation AudioSonoAppearanceController

- (id)init
{
    self = [super initWithWindowNibName:@"AudioSonoAppearance"];
    if(self)
    {
        [self window];

        [AudioSonoAppearanceController fillSonoColorModePopUp:mColorsPopUp];
    }
    return self;
}

- (void)setContainerBox:(NSBox*)box
{
    [box setContentView:mAppearanceView];
}

- (void)setSonoData:(AudioDataSono*)data
{
    [mSonoData autorelease];
    mSonoData = [data retain];
    
    if(mSonoData)
    {
        [mContrastSlider setDoubleValue:[mSonoData imageContrast]];
        [mGainSlider setDoubleValue:[mSonoData imageGain]];
        [mInverseButton setState:[mSonoData inverseVideo]];
        [mColorsPopUp selectItemAtIndex:[AudioSonoAppearanceController itemIndexOfColorMode:[mSonoData colorMode]]];
    }
}

- (void)setDelegate:(id)delegate
{
    mDelegate = delegate;
}

- (NSView*)view
{
    return mAppearanceView;
}

- (IBAction)contrastSliderAction:(id)sender
{
    [mSonoData setImageContrast:[sender floatValue]];
    if([mDelegate respondsToSelector:@selector(sonoDataAppearanceHasChanged)])
        [mDelegate performSelector:@selector(sonoDataAppearanceHasChanged)];
}

- (IBAction)gainSliderAction:(id)sender
{
    [mSonoData setImageGain:[sender floatValue]];
    if([mDelegate respondsToSelector:@selector(sonoDataAppearanceHasChanged)])
        [mDelegate performSelector:@selector(sonoDataAppearanceHasChanged)];
}

- (IBAction)inverseButtonAction:(id)sender
{
    [mSonoData setInverseVideo:[sender state] == NSOnState];
    if([mDelegate respondsToSelector:@selector(sonoDataAppearanceHasChanged)])
        [mDelegate performSelector:@selector(sonoDataAppearanceHasChanged)];
}

- (IBAction)colorsPopUpAction:(id)sender
{
    [mSonoData setColorMode:[AudioSonoAppearanceController colorModeOfPopUp:sender]];
    if([mDelegate respondsToSelector:@selector(sonoDataAppearanceHasChanged)])
        [mDelegate performSelector:@selector(sonoDataAppearanceHasChanged)];
}

@end

@implementation AudioSonoAppearanceController (ColorModePopUp)

+ (void)fillSonoColorModePopUp:(NSPopUpButton*)popUp
{
    [popUp removeAllItems];
    [popUp addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"Grayscale", NULL),
                                                        NSLocalizedString(@"Fire", NULL),
                                                        NSLocalizedString(@"Cold", NULL),
                                                        NSLocalizedString(@"Chromatic", NULL),
                                                        NULL]];
}

+ (USHORT)colorModeOfPopUp:(NSPopUpButton*)popUp
{
    switch([popUp indexOfSelectedItem]) {
        case 0:
            return IMAGE_COLOR_GRAYSCALE;
        case 1:
            return IMAGE_COLOR_HOT;
        case 2:
            return IMAGE_COLOR_COLD;
        case 3:
            return IMAGE_COLOR_CHROMATIC;
    }
    return IMAGE_COLOR_HOT;
}

+ (USHORT)itemIndexOfColorMode:(USHORT)mode
{
    switch(mode) {
        case IMAGE_COLOR_GRAYSCALE:
            return 0;
        case IMAGE_COLOR_HOT:
            return 1;
        case IMAGE_COLOR_COLD:
            return 2;
        case IMAGE_COLOR_CHROMATIC:
            return 3;
    }
    return 1;
}

@end
