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

#import "AudioDialogOperations.h"
#import "AudioUtilities.h"
#import "AudioSTWindowController.h"

@implementation AudioDialogOperations

- (id)init
{
    if(self = [super initWithWindowNibName:@"AudioOperations"])
    {
        mWindowController = NULL;
        mAmplitudeWrapperArray = NULL;
        mOperator = [[AudioOperator alloc] init];
        mIndexOfViewA = 0;
        mIndexOfViewB = 0;
        mIndexOfOperator = 0;
        [self window];
    }
    return self;
}

- (void)dealloc
{
    [mOperator release];
    [mAmplitudeWrapperArray release];
    [super dealloc];
}

- (BOOL)preparePanel
{
    [mAmplitudeWrapperArray autorelease];
    mAmplitudeWrapperArray = [[(AudioSTWindowController*)mWindowController amplitudeWrapperArray] retain];
    if(mAmplitudeWrapperArray == NULL || [mAmplitudeWrapperArray count]<2)
    {
        NSBeginAlertSheet(NSLocalizedString(@"Unable to perform operation.", NULL), NSLocalizedString(@"OK", NULL), NULL, NULL, [mWindowController window], self, NULL, NULL, NULL, NSLocalizedString(@"There must be at least 2 amplitude views to open the operation panel.", NULL));    
        return NO;
    }
    
    [mViewAPopUp removeAllItems];
    [mViewBPopUp removeAllItems];
    
    SHORT index;
    for(index=0; index<[mAmplitudeWrapperArray count]; index++)
    {
        NSString *title = [NSString stringWithFormat:@"%d - %@", index+1, [[mAmplitudeWrapperArray objectAtIndex:index] viewName]];
        [mViewAPopUp addItemWithTitle:title];
        [mViewBPopUp addItemWithTitle:title];
    }

    mIndexOfViewA = 0;
    mIndexOfViewB = 1;
    
    [mViewBPopUp selectItemAtIndex:mIndexOfViewB];

    [mOperationPopUp removeAllItems];
    [mOperationPopUp addItemsWithTitles:[mOperator operationTitles]];
    
    mIndexOfOperator = 0;
    [mOperationPopUp selectItemAtIndex:mIndexOfOperator];
    
    return YES;
}

- (void)openPanelForWindow:(id)parent
{
    mWindowController = parent;
    if([self preparePanel])
        [NSApp beginSheet:[self window] modalForWindow:[mWindowController window]
            modalDelegate:self didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)popUpAction:(id)sender
{
    switch([sender tag]) {
        case 0: // Amplitude source A
            mIndexOfViewA = [mViewAPopUp indexOfSelectedItem];
            break;
        case 1: // Amplitude source B
            mIndexOfViewB = [mViewBPopUp indexOfSelectedItem];
            break;
        case 2: // Operation
            mIndexOfOperator = [mOperationPopUp indexOfSelectedItem];
            break;
    }
}

- (IBAction)cancelPanel:(id)sender
{
    [[self window] orderOut:self];
    [NSApp endSheet:[self window] returnCode:0];
}

- (IBAction)closeAndPerformPanel:(id)sender
{
    AudioDataWrapper *sourceA = [mAmplitudeWrapperArray objectAtIndex:mIndexOfViewA];
    AudioDataWrapper *sourceB = [mAmplitudeWrapperArray objectAtIndex:mIndexOfViewB];
    SHORT operationID = [[[mOperator operationID] objectAtIndex:mIndexOfOperator] intValue];
    
    AudioDataWrapper *wrapper = [AudioOperator computeWrapperFromWrapperSourceA:sourceA
                                            sourceB:sourceB operation:operationID];

    [wrapper setViewName:[mViewResultNameTextField stringValue] always:YES];
    
    [mWindowController addAudioDataWrapper:wrapper parentWrapper:NULL];

    [[self window] orderOut:self];
    [NSApp endSheet:[self window] returnCode:0];
}

@end
