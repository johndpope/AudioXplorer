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

#import "AudioEffectController.h"
#import "AudioPlugInsController.h"
#import "AudioDialogPrefs.h"
#import "AXAUManager.h"
#import "ARDynamicMenu.h"

#define AU_TAG_OFFSET 1000	// Tag below this value are reserved for AX plug-ins
                                // Tag abov this value are reserved for AU component

#define AU_TAG_ALTERNATE_OFFSET 10000 // Offset when the item is in alternate state (dynamic item)

@implementation AudioEffectController

+ (AudioEffectController*)shared
{
    static AudioEffectController* _AudioEffectController = NULL;
    if(_AudioEffectController == NULL)
        _AudioEffectController = [[AudioEffectController alloc] init];
    return _AudioEffectController;
}

- (id)init
{
    if(self = [super init])
    {
        mAlternateKeyPressed = NO;
        mLastEffectTag = -1;
    }
    return self;
}

- (void)setEffectsMenu:(NSMenu*)menu
{
    mEffectsMenu = menu;
}

- (void)setAboutMenu:(NSMenu*)menu
{
    mAboutMenu = menu;
}

- (void)loadPlugInsController
{
    [[AudioPlugInsController shared] setEffectsMenu:mEffectsMenu useSubmenu:YES];
    [[AudioPlugInsController shared] setAboutMenu:mAboutMenu];
    [[AudioPlugInsController shared] load];
}

- (void)addSubmenu:(NSMenu*)subMenu toMenu:(NSMenu*)mainMenu withTitle:(NSString*)title
{
    NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:title
                                                        action:NULL
                                                        keyEquivalent:@""];
    [mainMenu addItem:subMenuItem];
    [mainMenu setSubmenu:subMenu forItem:subMenuItem];
    [[ARDynamicMenu shared] addDynamicMenuItem:subMenuItem delegate:self];

    int item;
    for(item=0; item<[subMenu numberOfItems]; item++) {
        [[ARDynamicMenu shared] addDynamicMenuItem:(NSMenuItem*)[subMenu itemAtIndex:item] delegate:self];		
	}
        
    [subMenuItem release];
}

- (void)buildAudioUnitsMenu
{
    NSArray *titles = [[AXAUManager shared] componentTitles];

    if([titles count]>0)
    {
        NSMenu *subMenu = NULL;
        BOOL useSubmenu = [[AudioDialogPrefs shared] effectsAsSubmenu];

        if(useSubmenu)
            subMenu = [[NSMenu alloc] initWithTitle:@""];
        else
            [mEffectsMenu addItem:[NSMenuItem separatorItem]];

        ARDynamicMenu *dynamicMenu = [ARDynamicMenu shared];

        NSString *lastTitle = NULL;
        short index;
        for(index=0; index<[titles count]; index++)
        {
            NSString *title = [titles objectAtIndex:index];			
			NSArray *components = [title componentsSeparatedByString:@":"];
						
            if(lastTitle != NULL && [[components objectAtIndex:0] isEqualToString:lastTitle] == NO)
            {
                if(useSubmenu)
                {
                    [self addSubmenu:subMenu toMenu:mEffectsMenu withTitle:lastTitle];
                    [subMenu release];
                    subMenu = [[NSMenu alloc] initWithTitle:@""];
                } else
                    [mEffectsMenu addItem:[NSMenuItem separatorItem]];
                lastTitle = [components objectAtIndex:0];                
            } else if(lastTitle == NULL)
                lastTitle = [components objectAtIndex:0];                

            NSString *shortTitle = [components count]>1?[components objectAtIndex:1]:title;
                        
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:shortTitle
                            action:@selector(performEffect:) keyEquivalent:@""];
            [item setTag:AU_TAG_OFFSET+index];
            if(useSubmenu)
                [subMenu addItem:item];
            else
            {
                [mEffectsMenu addItem:item];
                [dynamicMenu addDynamicMenuItem:item delegate:self];
            }
            [item release];
        }
        
        if(useSubmenu)
        {
            [self addSubmenu:subMenu toMenu:mEffectsMenu withTitle:lastTitle];
            [subMenu release];
        }
    }
}

- (void)preloadAudioUnits
{
    if([[AudioDialogPrefs shared] preloadAudioUnits])
        [[AXAUManager shared] preload];
}

- (void)load
{
	@try {
		[mEffectsMenu addItem:[NSMenuItem separatorItem]];
		[self loadPlugInsController];
		[self buildAudioUnitsMenu];
		[self preloadAudioUnits];
	} @catch(id exception) {
		NSLog(@"Exception while loading effects: %@", exception);
	}
}

- (BOOL)dynamicMenuChangedForMenuItem:(NSMenuItem*)menuItem modifiersFlags:(unsigned int)flags
{
    int tag = [menuItem tag]-AU_TAG_OFFSET;
    if(tag>=AU_TAG_ALTERNATE_OFFSET)
        tag -= AU_TAG_ALTERNATE_OFFSET;
    else if(tag<0)
        return NO;
    
    NSString *title = [[AXAUManager shared] componentTitleAtIndex:tag];
	NSArray *components = [title componentsSeparatedByString:@":"];
    NSString *shortTitle = [components count]>1?[components objectAtIndex:1]:title; 
    shortTitle = [shortTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if((flags & NSAlternateKeyMask)>0)
    {
        [menuItem setTitle:[NSString stringWithFormat:@"%@...", shortTitle]];
        [menuItem setTag:tag+AU_TAG_OFFSET+AU_TAG_ALTERNATE_OFFSET];
    } else
    {
        [menuItem setTitle:shortTitle];
        [menuItem setTag:tag+AU_TAG_OFFSET];
    }
    
    return YES;
}

- (BOOL)willPerformEffectOnTag:(int)tag
{
	return tag<AU_TAG_OFFSET || (tag>=AU_TAG_OFFSET && (tag-AU_TAG_OFFSET)<AU_TAG_ALTERNATE_OFFSET);
}

- (BOOL)willPerformEffect:(NSMenuItem*)sender
{
	return [self willPerformEffectOnTag:[sender tag]];
}

- (BOOL)willRedoEffect
{
	return [self willPerformEffectOnTag:mLastEffectTag];
}

- (BOOL)performEffectTag:(int)tag onData:(id)data channel:(unsigned short)channel parentWindow:(NSWindow*)parentWindow
{
    mLastEffectTag = tag;
    if(tag>=AU_TAG_OFFSET)
    {
        // AudioUnit
        int index = tag-AU_TAG_OFFSET;
        if(index>=AU_TAG_ALTERNATE_OFFSET)
        {
            [[AXAUManager shared] openEffectUIAtIndex:index-AU_TAG_ALTERNATE_OFFSET parentWindow:parentWindow];
            return NO;
        } else
            return [[AXAUManager shared] performEffectAtIndex:index
                                        onData:data
                                        channel:channel
                                parentWindow:parentWindow];
    } else
    {
        // AX plug-ins
        return [[AudioPlugInsController shared] performEffectAtIndex:tag
                                              onData:data
                                             channel:channel
                                        parentWindow:parentWindow];
    }
}

- (BOOL)performEffect:(NSMenuItem*)sender onData:(id)data channel:(unsigned short)channel parentWindow:(NSWindow*)parentWindow
{
    return [self performEffectTag:[sender tag] onData:data channel:channel parentWindow:parentWindow];
}

- (BOOL)redoLastEffectOnData:(id)data channel:(unsigned short)channel parentWindow:(NSWindow*)parentWindow
{
    return [self performEffectTag:mLastEffectTag onData:data channel:channel parentWindow:parentWindow];
}

- (BOOL)canRedoLastEffect
{
    return mLastEffectTag>-1;
}

- (void)modifierChanged:(unsigned int)flags
{
    mAlternateKeyPressed = (flags & NSAlternateKeyMask)>0;
}

- (void)aboutEffect:(id)sender
{
    if([sender tag]<AU_TAG_OFFSET)
        [[AudioPlugInsController shared] aboutEffectAtIndex:[sender tag]];
}

@end
