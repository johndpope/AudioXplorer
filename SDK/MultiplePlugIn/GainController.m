//
//  AXPlugInsGainController.m
//  AXPlugIns
//
//  Created by bovet on Fri May 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GainController.h"

#define PERCENT 0
#define DB 1

@implementation GainController

- (id)init
{
    self = [super initWithWindowNibName:@"Gain"];
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
    GainController *panel = [[GainController alloc] init];
    int code = [NSApp runModalForWindow:[panel window]];
    if(code == 1)
        *gain = [panel gain];
    [panel release];
    return code == 1;
}

@end
