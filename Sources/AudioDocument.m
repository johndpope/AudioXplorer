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

#import "AudioDocument.h"
#import "AudioDataWrapper.h"
#import "AudioDialogPrefs.h"

@implementation AudioDocument

- (id)init
{
    self = [super init];
    if (self) {
        mDocumentModel = [[AudioDocumentModel alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self removeWindowController:mAudioSTWindowController];
    [mAudioSTWindowController release];
    [mDocumentModel release];
    
    [super dealloc];
}

- (void)makeWindowControllers
{    
    mAudioSTWindowController= [[AudioSTWindowController alloc] init];
    [self addWindowController:mAudioSTWindowController];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];    
}

/*- (IBAction)saveDocument:(id)sender
{
    if([[ARRegManager sharedRegManager] isRegistered])
        [super saveDocument:sender];
    else
        NSRunAlertPanel(NSLocalizedString(@"Save feature disabled", NULL), NSLocalizedString(@"Register AudioXplorer to remove this limitation.", NULL), NSLocalizedString(@"OK", NULL), NULL, NULL, NULL);    
}*/

/*- (IBAction)saveDocumentAs:(id)sender
{
    if([[ARRegManager sharedRegManager] isRegistered])
        [super saveDocumentAs:sender];
    else
        NSRunAlertPanel(NSLocalizedString(@"Save feature disabled", NULL), NSLocalizedString(@"Register AudioXplorer to remove this limitation.", NULL), NSLocalizedString(@"OK", NULL), NULL, NULL, NULL);    
}*/

/*- (IBAction)saveDocumentTo:(id)sender
{
    if([[ARRegManager sharedRegManager] isRegistered])
        [super saveDocumentTo:sender];
    else
        NSRunAlertPanel(NSLocalizedString(@"Save feature disabled", NULL), NSLocalizedString(@"Register AudioXplorer to remove this limitation.", NULL), NSLocalizedString(@"OK", NULL), NULL, NULL, NULL);    
}*/

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    [mDocumentModel setStaticWindowPersistentData:[mAudioSTWindowController persistentData]];
    return [NSArchiver archivedDataWithRootObject:mDocumentModel];
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    [mDocumentModel release];
        
    NS_DURING
        mDocumentModel = [[NSUnarchiver unarchiveObjectWithData:data] retain];
    NS_HANDLER
        if ([[localException name] isEqualToString:AXExceptionName]) {
            NSRunAlertPanel(NSLocalizedString(@"Unable to load the file", NULL), @"%@", @"OK", nil, nil, 
                    localException);
        }
        NSAssert(NO, @"loadDataRepresentation failed");
    NS_ENDHANDLER
    
    return YES;    
}

- (AudioDocumentModel*)documentModel
{
    return mDocumentModel;
}

- (AudioSTWindowController*)documentStaticWindow
{
    return mAudioSTWindowController;
}

@end
