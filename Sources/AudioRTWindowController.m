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

#import "AudioRTWindowController.h"
#import "AudioRTDisplayer.h"
#import "AudioNotifications.h"
#import "AudioInspectorController.h"

@implementation AudioRTWindowController

- (id)init
{
    self = [self initWithWindowNibName:@"AudioRTWindow"];
    if(self)
    {
        [self setWindowFrameAutosaveName:@"AudioRTWindow"];
        [self setShouldCascadeWindows:NO];
        
        mAudioRTDisplayer = [[AudioRTDisplayer alloc] init];
        mFFTParametersPanel = [[AudioDialogFFTParameters alloc] init];
        
        mIntervalTitleArray = NULL;
        mIntervalNumberArray = NULL;

        mFullScreenWindow = NULL;
        mWindowDisplayedInFullScreen = NO;
    
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(windowWillClose:) 
                                                name:NSWindowWillCloseNotification
                                                object:NULL];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(audioRTMonitoringStatusChanged:)
                                                name:AudioRTMonitoringStatusChangedNotification
                                                object:NULL];
    }
    return self;
}

- (void)dealloc
{
	[[AudioInspectorController shared] windowControllerWillClose:self];
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [mFullScreenContentViewForWindow release];
    
    [mFFTParametersPanel release];
    [mAudioRTDisplayer release];

    [mIntervalTitleArray release];
    [mIntervalNumberArray release];

    [mResolutionTitleArray release];
    [mResolutionNumberArray release];

    [super dealloc];
}

- (FLOAT)valueForPopUpItem:(SHORT)item array:(NSArray*)array
{
    return [[array objectAtIndex:item] floatValue];
}

- (SHORT)popUpItemForValue:(FLOAT)interval array:(NSArray*)array
{
    return [array indexOfObject:[NSNumber numberWithFloat:interval]];
}

- (void)setupIntervalPopUp
{
    [mIntervalTitleArray release];
    [mIntervalNumberArray release];
    
    mIntervalTitleArray = [NSArray arrayWithObjects:@"50 ms",
                                                    @"100 ms",
                                                    @"500 ms",
                                                    @"1 s",
                                                    @"2 s",
                                                    @"5 s", NULL];
                                                    
    mIntervalNumberArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.05],
                                                    [NSNumber numberWithFloat:0.1],
                                                    [NSNumber numberWithFloat:0.5],
                                                    [NSNumber numberWithFloat:1],
                                                    [NSNumber numberWithFloat:2],
                                                    [NSNumber numberWithFloat:5], NULL];                                

    [mIntervalTitleArray retain];
    [mIntervalNumberArray retain];
    
    [mIntervalPopUp removeAllItems];
    [mIntervalPopUp addItemsWithTitles:mIntervalTitleArray];
}

- (void)setupResolutionPopUp
{
    [mResolutionTitleArray release];
    [mResolutionNumberArray release];
    
    mResolutionTitleArray = [NSArray arrayWithObjects:@"1 ms",
                                                    @"2 ms",
                                                    @"5 ms",
                                                    @"10 ms",
                                                    @"50 ms",
                                                    @"100 ms",
                                                    @"500 ms",
                                                    @"1 s",
                                                    @"2 s",
                                                    @"5 s", NULL];
                                                    
    mResolutionNumberArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.001],
                                                    [NSNumber numberWithFloat:0.002],
                                                    [NSNumber numberWithFloat:0.005],
                                                    [NSNumber numberWithFloat:0.01],
                                                    [NSNumber numberWithFloat:0.05],
                                                    [NSNumber numberWithFloat:0.1],
                                                    [NSNumber numberWithFloat:0.5],
                                                    [NSNumber numberWithFloat:1],
                                                    [NSNumber numberWithFloat:2],
                                                    [NSNumber numberWithFloat:5], NULL];                                

    [mResolutionTitleArray retain];
    [mResolutionNumberArray retain];
    
    [mResolutionPopUp removeAllItems];
    [mResolutionPopUp addItemsWithTitles:mResolutionTitleArray];
}

- (void)windowDidLoad
{
    [self setupIntervalPopUp];
    [self setupResolutionPopUp];
    [self setupToolbar];

    mFullScreenContentViewForWindow = [[mFullScreenPanelForWindow contentView] retain];

    [mIntervalPopUp selectItemAtIndex:[self popUpItemForValue:[mAudioRTDisplayer monitoringInterval]
                    array:mIntervalNumberArray]];
    [mResolutionPopUp selectItemAtIndex:[self popUpItemForValue:[mAudioRTDisplayer monitoringResolution]
                    array:mResolutionNumberArray]];
    [mChannelPopUp selectItemAtIndex:[mAudioRTDisplayer displayedChannel]];

    [mAudioRTDisplayer setRTWindow:[super window]];
    [mAudioRTDisplayer setRTWindowDelegate:self];
}

- (NSWindow*)window
{
    if(mWindowDisplayedInFullScreen)
        return mFullScreenWindow;
    else
        return [super window];
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    SEL action = [menuItem action];
    
    if(action == @selector(fftParameters:))
        return YES;
    if(action == @selector(intervalAction:))
        return YES;
    if(action == @selector(resolutionAction:))
        return YES;
    if(action == @selector(channelAction:))
        return YES;

    if(action == @selector(currentWindowFullScreen:))
        return mWindowDisplayedInFullScreen == NO;

    return NO;
}

- (void)keyDown:(NSEvent*)event
{
    NSString *c = [event charactersIgnoringModifiers];
    //unsigned int flags = [event modifierFlags];
    unsigned char c_ = [c characterAtIndex:0];
	
    switch(c_) {
        case 32:            
            [mEnableButton setIntValue:![mEnableButton state]];
            [self enableAction:mEnableButton];
            break;
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
            [[AudioInspectorController shared] changeRTLayout:c_];
            break;
		case '+':
		case '-':
			[mAudioRTDisplayer viewKeyDown:event];
			break;
			
    }
}

- (IBAction)showWindow:(id)sender
{
    [super showWindow:sender];
    [mAudioRTDisplayer startRTMonitoring:self];
}

- (IBAction)enableAction:(id)sender
{
   if([sender state] == NSOnState)
        [mAudioRTDisplayer resumeMonitoring];
    else
        [mAudioRTDisplayer pauseMonitoring];
}

- (IBAction)playthruAction:(id)sender
{
    [mAudioRTDisplayer setPlaythru:[sender state] == NSOnState];
}

- (IBAction)intervalAction:(id)sender
{
	SHORT item;
	if([sender isKindOfClass:[NSPopUpButton class]])
		item = [sender indexOfSelectedItem];
	else {
		item = [[[sender menu] itemArray] indexOfObject:sender];
		[mIntervalPopUp selectItemAtIndex:item];
	}
    
    [mAudioRTDisplayer setMonitoringInterval:[self valueForPopUpItem:item array:mIntervalNumberArray]];
}

- (IBAction)resolutionAction:(id)sender
{
	SHORT item;
	if([sender isKindOfClass:[NSPopUpButton class]])
		item = [sender indexOfSelectedItem];
	else {
		item = [[[sender menu] itemArray] indexOfObject:sender];
		[mResolutionPopUp selectItemAtIndex:item];
	}

    [mAudioRTDisplayer setMonitoringResolution:[self valueForPopUpItem:item array:mResolutionNumberArray]];
}

- (IBAction)channelAction:(id)sender
{
	if([sender isKindOfClass:[NSPopUpButton class]])
		[mAudioRTDisplayer setDisplayedChannel:[sender indexOfSelectedItem]];
	else {
		/* NOTE: bogue car le state ne change pas! NSMenu *menu = [sender menu];
		[sender setState:NSOnState];
		[menu itemChanged:sender];
		[menu update];*/
		[mAudioRTDisplayer setDisplayedChannel:[[[sender menu] itemArray] indexOfObject:sender]];
		[mChannelPopUp selectItemAtIndex:[[[sender menu] itemArray] indexOfObject:sender]];
	}
    [[mAudioRTDisplayer amplitudeView] setNeedsDisplay:YES];
    [[mAudioRTDisplayer fftView] setNeedsDisplay:YES];
    [[mAudioRTDisplayer sonoView] setNeedsDisplay:YES];
}

- (IBAction)fftParameters:(id)sender
{
    [mFFTParametersPanel openPanelForRTDisplayer:mAudioRTDisplayer parentWindow:[self window]];
}

- (void)windowWillClose:(NSNotification *)notification
{
    if([notification object] == [self window])
    {
        [mAudioRTDisplayer stopRTMonitoring:self];
        [self release];
    }
}

- (void)audioRTMonitoringStatusChanged:(NSNotification*)notification
{
    if([notification object] == mAudioRTDisplayer)
        [mEnableButton setIntValue:[[notification object] monitoring]];
}

- (AudioRTDisplayer*)audioRTDisplayer
{
    return mAudioRTDisplayer;
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
    return YES;
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
    return [sender isVertical]?200:100;
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
    return [sender isVertical]?proposedMax-200:proposedMax-100;
}

@end

@implementation AudioRTWindowController (WindowMenu)

#define FULL_SCREEN 1

- (IBAction)currentWindowFullScreen:(id)sender
{
    NSRect screenRect;
    int windowLevel;
    
    if(FULL_SCREEN)
    {
        if (CGDisplayCapture( kCGDirectMainDisplay ) != kCGErrorSuccess) {
            NSLog( @"Couldn't capture the main display!" );
            return;
        }
    
        windowLevel = CGShieldingWindowLevel();
    
        screenRect = [[NSScreen mainScreen] frame];
    } else
        screenRect = NSMakeRect(100,100,800,600);

    mFullScreenWindow = [[AudioFullScreenWindow alloc] initWithContentRect:screenRect
                                styleMask:NSBorderlessWindowMask | NSTexturedBackgroundWindowMask
                                backing:NSBackingStoreBuffered
                                defer:NO screen:[NSScreen mainScreen]];

    if(FULL_SCREEN)
        [mFullScreenWindow setLevel:windowLevel];
        
    [mFullScreenWindow setDelegate:self];
    [mFullScreenWindow setContentView:mFullScreenContentViewForWindow];
    [mFullScreenWindow setMovableByWindowBackground:NO];
    
    [mFullScreenBoxForWindow setContentView:[[self window] contentView]];
    
    mWindowDisplayedInFullScreen = YES;
    
    [mFullScreenWindow makeKeyAndOrderFront:nil];
    
//    [[[AudioInspectorController shared] window] setLevel:windowLevel];
}

- (IBAction)closeFullScreenForWindow:(id)sender
{
    mWindowDisplayedInFullScreen = NO;
    
    [mFullScreenWindow orderOut:self];
    [mFullScreenWindow close];
    
  //  [[[AudioInspectorController shared] window] setLevel:NSFloatingWindowLevel];

    [mAudioRTDisplayer applyLayout];

    if(FULL_SCREEN)
    {
        if (CGDisplayRelease( kCGDirectMainDisplay ) != kCGErrorSuccess) {
                NSLog( @"Couldn't release the display(s)!" );
                // Note: if you display an error dialog here, make sure you set
                // its window level to the same one as the shield window level,
                // or the user won't see anything.
        }
    }
}

@end

@implementation AudioRTWindowController (Toolbar)

static NSString* 	AudioRTWindowToolbarIdentifier = @"AudioRTWindow Toolbar Identifier";
static NSString*	EnableToolbarItemIdentifier = @"Enable Item Identifier";
static NSString*	PlaythruToolbarItemIdentifier = @"Playthru Item Identifier";
static NSString*	IntervalToolbarItemIdentifier = @"Interval Item Identifier";
static NSString*	ResolutionToolbarItemIdentifier = @"Resolution Item Identifier";
static NSString*	ChannelToolbarItemIdentifier = @"Channel Item Identifier";

- (void)setupToolbar
{
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: AudioRTWindowToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: allow customization, give a default display mode
    // and remember state in user defaults 
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method   Given an item identifier, self method returns an item 
    // The toolbar will use self method to obtain toolbar items that can be displayed
    // in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];

    if ([itemIdent isEqual: EnableToolbarItemIdentifier])
    {
        NSSize itemSize = [mEnableToolbarView frame].size;
        
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Enable Button", nil)];
		
		// Use a custom view 
		[toolbarItem setView:mEnableToolbarView];
		[toolbarItem setMinSize:itemSize];
		[toolbarItem setMaxSize:itemSize];
		} else if ([itemIdent isEqual: PlaythruToolbarItemIdentifier])
		{
			NSSize itemSize = [mPlaythruToolbarView frame].size;
			
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Playthru Button", nil)];
		
		// Use a custom view 
		[toolbarItem setView:mPlaythruToolbarView];
		[toolbarItem setMinSize:itemSize];
		[toolbarItem setMaxSize:itemSize];
    } else if ([itemIdent isEqual: IntervalToolbarItemIdentifier])
    {
        NSSize itemSize = [mIntervalToolbarView frame].size;
			
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Interval PopUp", nil)];
		
		// Use a custom view 
		[toolbarItem setView:mIntervalToolbarView];
		[toolbarItem setMinSize:itemSize];
		[toolbarItem setMaxSize:itemSize];

		// Create the custom menu 
		NSMenu *submenu=[[[NSMenu alloc] init] autorelease];
		NSArray *items = [[mIntervalPopUp menu] itemArray];
		NSEnumerator *enumerator = [items objectEnumerator];
		NSMenuItem *menuItem = nil;
		while(menuItem = [enumerator nextObject]) {
			NSMenuItem *submenuItem=[[[NSMenuItem alloc] initWithTitle: [menuItem title]
					action:@selector(intervalAction:)
					keyEquivalent: @""] autorelease];
			[submenu addItem: submenuItem];
			[submenuItem setTarget:self];
			[submenuItem setTag:[menuItem tag]];
		}
			
		NSMenuItem *menuFormRep=[[[NSMenuItem alloc] init] autorelease];
		[menuFormRep setTitle:NSLocalizedString(@"Interval", nil)];
		[menuFormRep setSubmenu:submenu];
		[toolbarItem setMenuFormRepresentation:menuFormRep];
    } else if ([itemIdent isEqual: ResolutionToolbarItemIdentifier])
    {
        NSSize itemSize = [mResolutionToolbarView frame].size;
			
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Resolution PopUp", nil)];
		
		// Use a custom view 
		[toolbarItem setView:mResolutionToolbarView];
		[toolbarItem setMinSize:itemSize];
		[toolbarItem setMaxSize:itemSize];
		
		// Create the custom menu 
		NSMenu *submenu=[[[NSMenu alloc] init] autorelease];
		NSArray *items = [[mResolutionPopUp menu] itemArray];
		NSEnumerator *enumerator = [items objectEnumerator];
		NSMenuItem *menuItem = nil;
		while(menuItem = [enumerator nextObject]) {
			NSMenuItem *submenuItem=[[[NSMenuItem alloc] initWithTitle: [menuItem title]
					action:@selector(resolutionAction:)
					keyEquivalent: @""] autorelease];
			[submenu addItem: submenuItem];
			[submenuItem setTarget:self];
			[submenuItem setTag:[menuItem tag]];
		}
			
		NSMenuItem *menuFormRep=[[[NSMenuItem alloc] init] autorelease];
		[menuFormRep setTitle:NSLocalizedString(@"Resolution", nil)];
		[menuFormRep setSubmenu:submenu];
		[toolbarItem setMenuFormRepresentation:menuFormRep];
    } else if ([itemIdent isEqual: ChannelToolbarItemIdentifier])
    {
        NSSize itemSize = [mChannelToolbarView frame].size;
        
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Channel PopUp", nil)];
		
		// Use a custom view 
		[toolbarItem setView:mChannelToolbarView];
		[toolbarItem setMinSize:itemSize];
		[toolbarItem setMaxSize:itemSize];

		// Create the custom menu 
		NSMenu *submenu=[[[NSMenu alloc] init] autorelease];
		NSArray *items = [[mChannelPopUp menu] itemArray];
		NSEnumerator *enumerator = [items objectEnumerator];
		NSMenuItem *menuItem = nil;
		while(menuItem = [enumerator nextObject]) {
			NSMenuItem *submenuItem=[[[NSMenuItem alloc] initWithTitle: [menuItem title]
					action:@selector(channelAction:)
					keyEquivalent: @""] autorelease];
			[submenu addItem: submenuItem];
			[submenuItem setTarget:self];
			[submenuItem setTag:[menuItem tag]];
		}
			
		NSMenuItem *menuFormRep=[[[NSMenuItem alloc] init] autorelease];
		[menuFormRep setTitle:NSLocalizedString(@"Channel", nil)];
		[menuFormRep setSubmenu:submenu];
		[toolbarItem setMenuFormRepresentation:menuFormRep];
    } else {
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
		// Returning nil will inform the toolbar self kind of item is not supported 
		toolbarItem = nil;
    }
    
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:
    // Returns the ordered list of items to be shown in the toolbar by default 
       
    // If during the toolbar's initialization, no overriding values are found in the user defaults,
    // or if the user chooses to revert to the default items self set will be used

    return [NSArray arrayWithObjects:	EnableToolbarItemIdentifier,
                                        PlaythruToolbarItemIdentifier,
                                        IntervalToolbarItemIdentifier,
                                        ResolutionToolbarItemIdentifier,
                                        ChannelToolbarItemIdentifier,
                                        nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:
    // Returns the list of all allowed items by identifier. By default, the toolbar 
    // does not assume any items are allowed, even the separator.
    // So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette

    return [NSArray arrayWithObjects:	EnableToolbarItemIdentifier,
                                        PlaythruToolbarItemIdentifier,
                                        IntervalToolbarItemIdentifier,
                                        ResolutionToolbarItemIdentifier,
                                        ChannelToolbarItemIdentifier,
                                        NSToolbarSeparatorItemIdentifier, 
                                        NSToolbarSpaceItemIdentifier,
                                        NSToolbarFlexibleSpaceItemIdentifier, nil];
}

@end