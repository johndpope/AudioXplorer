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

#import "ARProgressPanel.h"


@implementation ARProgressPanel

+ (ARProgressPanel*)progressPanelWithParentWindow:(NSWindow*)window delegate:(id)delegate
{
    ARProgressPanel *progress = [[ARProgressPanel alloc] init];
    
    [progress setParentWindow:window];
    [progress setDelegate:delegate];
    
    return [progress autorelease]; 
}

- (id)init
{
    if(self = [super initWithWindowNibName:@"ARProgressPanel"])
    {
        mParentWindow = NULL;
        mDelegate = NULL;
        [self window];
    }
    return self;
}

- (void)setParentWindow:(NSWindow*)window
{
    mParentWindow = window;
}

- (void)setDelegate:(id)delegate
{
    mDelegate = delegate;
}

- (void)setDeterminate:(BOOL)flag
{
    [mProgressIndicator setIndeterminate:!flag];
    [mProgressIndicator display];
}

- (void)setProgressValue:(float)value
{
    [mProgressIndicator setDoubleValue:value];
    [mProgressIndicator display];
}

- (void)setProgressPrompt:(NSString*)prompt
{
    [mProgressTextField setStringValue:prompt];
    [mProgressTextField display];
}

- (void)setCancelButtonEnabled:(BOOL)flag
{
    [mProgressCancelButton setEnabled:flag];
}

- (BOOL)open
{
    [mProgressIndicator setUsesThreadedAnimation:YES];
    [mProgressIndicator startAnimation:self];
    [self setCancelButtonEnabled:NO];
    
    [NSApp beginSheet:mProgressPanel modalForWindow:mParentWindow modalDelegate:self
                    didEndSelector:NULL contextInfo:NULL];

    return YES;
}

- (BOOL)close
{
    [mProgressIndicator stopAnimation:self];
    [mProgressPanel orderOut:self];
    [NSApp endSheet:mProgressPanel returnCode:0];

    return YES;
}

- (IBAction)cancel:(id)sender
{
    if([mDelegate respondsToSelector:@selector(progressPanelCancelled:)])
        [mDelegate performSelector:@selector(progressPanelCancelled:) withObject:self];
}

@end
