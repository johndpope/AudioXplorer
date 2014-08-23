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

#import "AXPlugInsGainController.h"

#define PERCENT 0
#define DB 1

@implementation AXPlugInsGainController

- (id)init
{
    self = [super initWithWindowNibName:@"AXPlugInsGain"];
    if(self)
    {	
        mLastUnit = PERCENT;
        [self loadWindow];
    }
    return self;
}

- (void)setGain:(float)gain
{
    [mGainTextField setFloatValue:gain];
}

- (float)gain
{
    float value = [mGainTextField floatValue];
    if(mLastUnit == DB)
        value = pow(10, value*0.05);
    else
        value *= 0.01;

    return value;
}

- (IBAction)gainUnitPopUpAction:(id)sender
{
    if(mLastUnit != [sender indexOfSelectedItem])
    {
        float value = [mGainTextField floatValue];
        switch(mLastUnit) {
            case PERCENT: 	// %->dB
                value = 20*log10(value*0.01);
                break;
            case DB:		// dB->%
                value = pow(10, value*0.05)*100;
                break;
        }
        [self setGain:value];
        mLastUnit = [sender indexOfSelectedItem];
    }
}

- (IBAction)cancelPanel:(id)sender
{
    [[self window] orderOut:self];
    if([[self window] isSheet])
        [NSApp endSheet:[self window] returnCode:0];
    else
        [NSApp stopModalWithCode:0];   
}

- (IBAction)okPanel:(id)sender
{
    [[self window] orderOut:self];
    if([[self window] isSheet])
        [NSApp endSheet:[self window] returnCode:1];
    else
        [NSApp stopModalWithCode:1];   
}

+ (BOOL)askUserForGain:(float*)gain
{
    AXPlugInsGainController *panel = [[AXPlugInsGainController alloc] init];
    int code = [NSApp runModalForWindow:[panel window]];
    if(code == 1)
        *gain = [panel gain];
    [panel release];
    return code == 1;
}

@end
