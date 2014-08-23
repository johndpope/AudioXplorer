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

#import "ARDynamicMenu.h"
#import <Carbon/Carbon.h>

@interface ARDynamicMenu (Declaration)
- (BOOL)dynamicMenuChangedForMenuItem:(NSMenuItem*)item modifiersFlags:(unsigned int)flags;
@end

@implementation ARDynamicMenu

extern MenuRef _NSGetCarbonMenu(NSMenu *);

OSStatus carbonMenuOpeningEventCallback(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData)
{
    // Distribute the information
    [(ARDynamicMenu*)inUserData notifyDelegateWithModifiers:GetCurrentEventKeyModifiers()];

    return noErr;
}

OSStatus carbonMenuKeyModifiersChangedEventCallback(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData)
{
    EventParamType actualType;
    UInt32 outSize;
    UInt32 modifiers;
    
    // Get the modifiers state
    GetEventParameter(inEvent, kEventParamKeyModifiers, typeUInt32 , &actualType,
        sizeof(typeUInt32), &outSize, &modifiers);
    
    // Distribute the information
    [(ARDynamicMenu*)inUserData notifyDelegateWithModifiers:modifiers];
    
    return noErr;
}

+ (ARDynamicMenu*)shared
{
    static ARDynamicMenu *_ARDynamicMenu = NULL;
    if(_ARDynamicMenu == NULL)
        _ARDynamicMenu = [[ARDynamicMenu alloc] init];
    return _ARDynamicMenu;
}

- (id)init
{
    if(self = [super init])
    {
        mItemDelegateArray = [[NSMutableArray alloc] init];
        mMenuCallbackArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [mMenuCallbackArray release];
    [mItemDelegateArray release];
    [super dealloc];
}

- (BOOL)addCarbonCallbackForMenu:(NSMenu*)menu
{
    if([mMenuCallbackArray indexOfObject:menu]==NSNotFound)
    {
        // Callback has not been yet installed
        [mMenuCallbackArray addObject:menu];

        // Install the menu carbon callback when key are pressed
        EventTypeSpec theEvent;
        theEvent.eventClass = kEventClassKeyboard;
        theEvent.eventKind = kEventRawKeyModifiersChanged;
    
        OSStatus status = InstallMenuEventHandler(_NSGetCarbonMenu(menu),
                                NewEventHandlerUPP(carbonMenuKeyModifiersChangedEventCallback),
                                1,
                                &theEvent,
                                self,
                                NULL);
        if(status != noErr)
        {
            NSLog(@"Error %d with InstallMenuEventHandler (key modifiers)", status);
            return NO;
        }
            
        // Install the menu carbon callback when menu is opened
        theEvent.eventClass = kEventClassMenu;
        theEvent.eventKind = kEventMenuOpening;
    
        InstallMenuEventHandler(_NSGetCarbonMenu(menu),
                                NewEventHandlerUPP(carbonMenuOpeningEventCallback),
                                1,
                                &theEvent,
                                self,
                                NULL);
        if(status != noErr)
        {
            NSLog(@"Error %d with InstallMenuEventHandler (menu opening)", status);
            return NO;
        }
    }
    return YES;
}

- (BOOL)addDynamicMenuItem:(NSMenuItem*)item delegate:(id)delegate
{
    if([self addCarbonCallbackForMenu:[item menu]])
    {
        [mItemDelegateArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:item, @"Item", delegate, @"Delegate", NULL]];
        return YES;
    } else
        return NO;
}

- (void)removeDynamicMenuItem:(NSMenuItem*)item
{
	NSEnumerator *enumerator = [mItemDelegateArray reverseObjectEnumerator];
	NSDictionary *dic = nil;
	while(dic = [enumerator nextObject]) {
		if([dic objectForKey:@"Item"] == item)
			[mItemDelegateArray removeObject:dic];
	}
}

- (void)removeDynamicMenuDelegate:(id)delegate
{
	NSEnumerator *enumerator = [mItemDelegateArray reverseObjectEnumerator];
	NSDictionary *dic = nil;
	while(dic = [enumerator nextObject]) {
		if([dic objectForKey:@"Delegate"] == delegate)
			[mItemDelegateArray removeObject:dic];
	}
}

- (void)notifyDelegateWithModifiers:(UInt32)modifiers
{
    // Get the modifiers flags
    BOOL optionKeyPressed = (modifiers & 1 << optionKeyBit) > 0;
    BOOL controlKeyPressed = (modifiers & 1 << controlKeyBit) > 0;
    BOOL shiftKeyPressed = (modifiers & 1 << shiftKeyBit) > 0;
    
    unsigned int flags = optionKeyPressed?NSAlternateKeyMask:0;
    flags = flags + (controlKeyPressed?NSControlKeyMask:0);
    flags = flags + (shiftKeyPressed?NSShiftKeyMask:0);
        
    NSEnumerator *enumerator = [mItemDelegateArray objectEnumerator];
    NSDictionary *dic = NULL;
    while(dic = [enumerator nextObject])
    {
        NSMenuItem *menuItem = [dic objectForKey:@"Item"];
        id delegate = [dic objectForKey:@"Delegate"];
        
        // Call the delegate
        BOOL modified = [delegate dynamicMenuChangedForMenuItem:menuItem
                                modifiersFlags:flags];
        
        // Invalidate the menu item
        if(modified)
        {
            NSMenu *menu = [menuItem menu];
			if(menu)
				InvalidateMenuItems(_NSGetCarbonMenu(menu), [menu indexOfItem:menuItem]+1, 1);
        }
    }
    
    // Update all registered menu
    enumerator = [mMenuCallbackArray objectEnumerator];
    NSMenu *menu = NULL;
    while(menu = [enumerator nextObject])
        UpdateInvalidMenuItems(_NSGetCarbonMenu(menu));
}

@end
