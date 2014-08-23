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

#import "AudioDialogPrefs.h"
#import "AudioDialogPrefs+Toolbar.h"

@implementation AudioDialogPrefs (Toolbar)

static NSString* 	PrefsToolbarIdentifier = @"PrefsToolbarIdentifier";
static NSString*	GeneralItemIdentifier = @"GeneralItemIdentifier";
static NSString*	ViewsItemIdentifier = @"ViewsItemIdentifier";
static NSString*	RTItemIdentifier = @"RTItemIdentifier";
static NSString*	EffectsItemIdentifier = @"EffectsItemIdentifier";
static NSString*	DevicesItemIdentifier = @"DevicesItemIdentifier";
static NSString*	UpdateItemIdentifier = @"UpdateItemIdentifier";

- (void)setupToolbar
{	
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:PrefsToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: allow customization, give a default display mode
    // and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
			
	// Select the first view
	
	if([toolbar respondsToSelector:@selector(setSelectedItemIdentifier:)])
		[toolbar setSelectedItemIdentifier:GeneralItemIdentifier];

	[self selectGeneralView];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method   Given an item identifier, self method returns an item 
    // The toolbar will use self method to obtain toolbar items that can be displayed
    // in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	NSSize itemSize = NSMakeSize(32, 32);

    if ([itemIdent isEqual: GeneralItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"PTBGeneral", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"PTBGeneral", nil)];
		
		// Use a custom view 
		[toolbarItem setImage:[NSImage imageNamed:@"tb_general"]];
		[toolbarItem setMinSize:itemSize];
		[toolbarItem setMaxSize:itemSize];
		
		// Action
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(selectGeneralView)];
    } else if ([itemIdent isEqual: ViewsItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"PTBViews", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"PTBViews", nil)];
		
		// Use a custom view 
		[toolbarItem setImage:[NSImage imageNamed:@"tb_views"]];
		[toolbarItem setMinSize:itemSize];
		[toolbarItem setMaxSize:itemSize];

		// Action
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(selectViewsView)];
    } else if ([itemIdent isEqual: RTItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"PTBRT", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"PTBRT", nil)];
		
		// Use a custom view 
		[toolbarItem setImage:[NSImage imageNamed:@"tb_rt"]];
		[toolbarItem setMinSize:itemSize];
		[toolbarItem setMaxSize:itemSize];

		// Action
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(selectRTView)];
    } else if ([itemIdent isEqual: EffectsItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"PTBEffects", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"PTBEffects", nil)];
		
		// Use a custom view 
		[toolbarItem setImage:[NSImage imageNamed:@"tb_effects"]];
		[toolbarItem setMinSize:itemSize];
		[toolbarItem setMaxSize:itemSize];
		
		// Action
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(selectEffectsView)];
    } else if ([itemIdent isEqual: DevicesItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"PTBDevices", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"PTBDevices", nil)];
		
		// Use a custom view 
		[toolbarItem setImage:[NSImage imageNamed:@"tb_devices"]];
		[toolbarItem setMinSize:itemSize];
		[toolbarItem setMaxSize:itemSize];
		
		// Action
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(selectDevicesView)];
    } else if ([itemIdent isEqual: UpdateItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"PTBUpdate", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"PTBUpdate", nil)];
		
		// Use a custom view 
		[toolbarItem setImage:[NSImage imageNamed:@"tb_update"]];
		[toolbarItem setMinSize:itemSize];
		[toolbarItem setMaxSize:itemSize];

		// Action
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(selectUpdateView)];
	} else {
		toolbarItem = nil;
    }
    
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:	GeneralItemIdentifier,
                                        NSToolbarSeparatorItemIdentifier, 
										ViewsItemIdentifier,
										RTItemIdentifier,
										EffectsItemIdentifier,
										DevicesItemIdentifier,
										UpdateItemIdentifier,
                                        NSToolbarFlexibleSpaceItemIdentifier,
                                        nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:	GeneralItemIdentifier,
										ViewsItemIdentifier,
										RTItemIdentifier,
										EffectsItemIdentifier,
										DevicesItemIdentifier,
										UpdateItemIdentifier,
                                        NSToolbarSeparatorItemIdentifier, 
                                        NSToolbarSpaceItemIdentifier,
                                        NSToolbarFlexibleSpaceItemIdentifier, nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:	GeneralItemIdentifier,
										ViewsItemIdentifier,
										RTItemIdentifier,
										EffectsItemIdentifier,
										DevicesItemIdentifier,
										UpdateItemIdentifier, nil];	
}

- (void)setContentView:(NSView*)view resize:(BOOL)resize
{
    float deltaWidth = 0;
    float deltaHeight = 0;
        
    if(resize)
    {
        NSRect oldFrame = [[[self window] contentView] frame];
        NSRect newFrame = [view frame];
        
        deltaWidth = newFrame.size.width-oldFrame.size.width;
        deltaHeight = newFrame.size.height-oldFrame.size.height;
    }

    [[self window] setContentView:view];

    // Resize the window
    
    if(resize && (deltaWidth !=0 || deltaHeight != 0))
    {
        NSRect contentRect = [NSWindow contentRectForFrameRect:[[self window] frame]
                                styleMask:[[self window] styleMask]];

        contentRect.size.width += deltaWidth;
        contentRect.size.height += deltaHeight;
                    
        NSRect newFrame = [NSWindow frameRectForContentRect:contentRect
                                    styleMask:[[self window] styleMask]];
    
        newFrame.origin.y -= deltaHeight;
        
        [[self window] setFrame:newFrame display:YES animate:NO];
    }
}

- (void)setWindowContentView:(NSView*)view
{
	[self setContentView:view resize:YES];
}

- (void)selectGeneralView
{
	[self setWindowContentView:mGeneralView];
}

- (void)selectViewsView
{
	[self setWindowContentView:mViewsView];
}

- (void)selectRTView
{
	[self setWindowContentView:mRTView];
}

- (void)selectEffectsView
{
	[self setWindowContentView:mEffectsView];
}

- (void)selectDevicesView
{
	[self setWindowContentView:mDevicesView];
}

- (void)selectUpdateView
{
	[self setWindowContentView:mUpdateView];
}

@end
