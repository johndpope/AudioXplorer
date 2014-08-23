
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

#import "AudioInspectorController.h"
#import "AudioApp.h"
#import "AudioRTWindowController.h"
#import "AudioDialogPrefs.h"
#import "AudioUtilities.h"

@implementation AudioInspectorController

+ (id)shared
{
    static AudioInspectorController *_sharedInspectorController = NULL;
    
    if(_sharedInspectorController == NULL)
    {
        _sharedInspectorController = [[AudioInspectorController allocWithZone:[self zone]] init];
        [AudioApp addStaticObject:_sharedInspectorController];
    }
    
    return _sharedInspectorController;
}

- (id)init
{
    self = [self initWithWindowNibName:@"AudioInspector"];
    if(self)
    {
		mMainWindow = nil;
        [self setWindowFrameAutosaveName:@""];
        [self setShouldCascadeWindows:NO];        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
        
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [mAudioInspectorST windowDidLoad];
    [mAudioInspectorRT windowDidLoad];
    
    [[self window] setAlphaValue:[[AudioDialogPrefs shared] inspectorTransparency]];

    // Set the window size by hands (is there a bug ? because without this, the window doesn't have
    // the correct size)
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *rect = [defaults objectForKey:@"AXInspectorFrame"];
    if(rect)
    {
        NSRect r = NSRectFromString(rect);
        [[self window] setFrame:r display:YES animate:NO];
    }

    [self setMainWindow:[NSApp mainWindow]];
    
    // Register notification
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) 
                                    name:NSWindowDidBecomeMainNotification object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) 
                                    name:NSWindowDidResignMainNotification object:NULL];
}

- (void)registerInspectorFrame
{
    // Save the inspector frame for later use (bug in windowDidLoad)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[self window] stringWithSavedFrame] forKey:@"AXInspectorFrame"];
}

+ (void)setContentView:(NSView*)view resize:(BOOL)resize
{
    NSWindow *inspectorWindow = [[AudioInspectorController shared] window];
    NSBox *inspectorBox = [[AudioInspectorController shared] box];

    float deltaWidth = 0;
    float deltaHeight = 0;
    
    NSRect boxFrame;
    
    if(resize)
    {
        // Resize the box
    
        NSRect oldBoxContentFrame = [[inspectorBox contentView] frame];
        NSRect newBoxContentFrame = [view frame];
        
        deltaWidth = newBoxContentFrame.size.width-oldBoxContentFrame.size.width;
        deltaHeight = newBoxContentFrame.size.height-oldBoxContentFrame.size.height;
            
        boxFrame = [inspectorBox frame];
        boxFrame.size.width += deltaWidth;
        boxFrame.size.height += deltaHeight;
    
        boxFrame.origin.y -= deltaHeight;        
    }

    [inspectorBox setContentView:view];

    // Resize the window
    
    if(resize && (deltaWidth !=0 || deltaHeight != 0))
    {
        NSRect contentRect = [NSWindow contentRectForFrameRect:[inspectorWindow frame]
                                styleMask:[inspectorWindow styleMask]];

        contentRect.size.width += deltaWidth;
        contentRect.size.height += deltaHeight;
                    
        NSRect newFrame = [NSWindow frameRectForContentRect:contentRect
                                    styleMask:[inspectorWindow styleMask]];
    
        newFrame.origin.y -= deltaHeight;
        
        [inspectorWindow setFrame:newFrame display:YES
                animate:[[AudioDialogPrefs shared] useVisualAnimation]];
    }
}

- (void)setContentViewAndResize:(NSView*)view
{    
    if(view == NULL)
        view = mAudioInspectorNotApplicable;
        
    if(view != mAudioInspectorNotApplicable && view != mAudioInspectorNoAudioView)
    {
        [AudioInspectorController setContentView:view resize:YES];
        [self registerInspectorFrame];
    } else
        [AudioInspectorController setContentView:view resize:NO];
}

- (void)setMainWindow:(NSWindow*)mainWindow
{
	mMainWindow = mainWindow;
	
    NSWindowController *controller = [mainWindow windowController];
    NSView *contentView = mAudioInspectorNotApplicable;
    
    [mAudioInspectorST setMainWindow:mainWindow];
    [mAudioInspectorRT setMainWindow:mainWindow];
    
    if([controller isKindOfClass:[AudioSTWindowController class]])
    {
        if([(AudioSTWindowController*)[mainWindow windowController] viewCount]>0)
            contentView = [mAudioInspectorST view];
        else
            contentView = mAudioInspectorNoAudioView;
    } else if([controller isKindOfClass:[AudioRTWindowController class]])
        contentView = [mAudioInspectorRT view];
        
    [self setContentViewAndResize:contentView];
}

- (void)resignMainWindow:(NSWindow*)mainWindow
{
    [mAudioInspectorST resignMainWindow:mainWindow];
    [mAudioInspectorRT resignMainWindow:mainWindow];
    [self setContentViewAndResize:mAudioInspectorNotApplicable];
	mMainWindow = nil;
}

- (void)windowControllerWillClose:(NSWindowController*)controller
{
	if([controller window] == mMainWindow) {
		[self resignMainWindow:mMainWindow];
	}
}

// Notifications

- (void)mainWindowChanged:(NSNotification*)notification
{
    [self setMainWindow:[notification object]];
}

- (void)mainWindowResigned:(NSNotification*)notification
{
	[self resignMainWindow:[notification object]];
}

- (void)windowDidMove:(NSNotification *)aNotification
{
    [self registerInspectorFrame];
}

- (NSBox*)box
{
    return mInspectorBox;
}

- (void)toggleRTMonitoring
{
    [mAudioInspectorRT toggleRTMonitoring];
}

- (void)rtLayoutChanged
{
    [mAudioInspectorRT rtLayoutChanged];
}

- (void)changeRTLayout:(USHORT)key
{
    [mAudioInspectorRT changeRTLayout:key];
}

@end
