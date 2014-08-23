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

#import "AudioPlugInsController.h"
#import "AudioPlugInItem.h"
#import "AXPlugInHeader.h"

@implementation AudioPlugInsController

NSString *appSupportSubpath = @"Application Support/AudioXplorer/PlugIn";

+ (AudioPlugInsController*)shared
{
    static AudioPlugInsController *_plugInsController = NULL;
    if(_plugInsController == NULL)
        _plugInsController = [[AudioPlugInsController alloc] init];
    
    return _plugInsController;
}

- (id)init
{
    self = [super initWithWindowNibName:@"AudioPlugIns"];
    if(self)
    {
        mParentEffectsMenu = NULL;
        mEffectsMenu = NULL;
        mAboutMenu = NULL;
        mEffectsItemArray = [[NSMutableArray alloc] init];
        mPlugInInstances = [[NSMutableArray alloc] init];

        mLastEffectItem = -1;
        mUseSubmenu = NO;
        
        [self window];
    }
    return self;
}

- (void)dealloc
{
    [mEffectsItemArray release];
    [mPlugInInstances release];
    [super dealloc];
}

- (void)setEffectsMenu:(NSMenu*)menu useSubmenu:(BOOL)useSubmenu
{
    mUseSubmenu = useSubmenu;
    if(mUseSubmenu)
    {
        mEffectsMenu = [[NSMenu alloc] initWithTitle:@"AudioXplorer"];
        mParentEffectsMenu = menu;
    } else
    {
        mParentEffectsMenu = NULL;
        mEffectsMenu = menu;
    }
}

- (void)setAboutMenu:(NSMenu*)menu
{
    mAboutMenu = menu;
}

- (NSMutableArray *)allBundles
{
    NSArray *librarySearchPaths;
    NSEnumerator *searchPathEnum;
    NSString *currPath;
    NSMutableArray *bundleSearchPaths = [NSMutableArray array];
    NSMutableArray *allBundles = [NSMutableArray array];
    
    librarySearchPaths = NSSearchPathForDirectoriesInDomains(
        NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
    
    searchPathEnum = [librarySearchPaths objectEnumerator];
    while(currPath = [searchPathEnum nextObject])
    {
        [bundleSearchPaths addObject:
            [currPath stringByAppendingPathComponent:appSupportSubpath]];
    }
    [bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]];
    
    searchPathEnum = [bundleSearchPaths objectEnumerator];
    while(currPath = [searchPathEnum nextObject])
    {
        NSDirectoryEnumerator *bundleEnum;
        NSString *currBundlePath;
        bundleEnum = [[NSFileManager defaultManager]
            enumeratorAtPath:currPath];
        if(bundleEnum)
        {
            while(currBundlePath = [bundleEnum nextObject])
            {
                if([[currBundlePath pathExtension] isEqualToString:@"bundle"])
                {
                    [allBundles addObject:[currPath
                            stringByAppendingPathComponent:currBundlePath]];
                }
            }
        }
    }
    
    return allBundles;
} 

- (BOOL)respondsToSelector:(NSString*)selector plugInInstance:(id)instance
{
    if([instance respondsToSelector:NSSelectorFromString(selector)] == NO)
    {
        [self badPlugInInstance:instance
            reason:[NSString stringWithFormat:@"Plug-in doesn't respond to method %@", selector]];
        return NO;
    } else
        return YES;
}

- (void)badPlugInAtPath:(NSString*)path reason:(NSString*)reason
{
    [mVariableATextField setStringValue:NSLocalizedString(@"Path:", NULL)];
    [mParameterATextField setStringValue:path];
    [mParameterBTextField setStringValue:reason];
    [NSApp runModalForWindow:mPlugInProblemPanel];
}

- (void)badPlugInInstance:(id)instance reason:(NSString*)reason
{
    [mVariableATextField setStringValue:NSLocalizedString(@"Class:", NULL)];
    [mParameterATextField setStringValue:[instance className]];
    [mParameterBTextField setStringValue:reason];
    [NSApp runModalForWindow:mPlugInProblemPanel];
}

- (BOOL)plugInClassIsValid:(Class)plugInClass
{
    if([plugInClass conformsToProtocol:@protocol(AXPlugInRequiredProtocol)])
    {
        if([plugInClass conformsToProtocol:@protocol(AXPlugInSingleProtocol)])
            return YES;
        if([plugInClass conformsToProtocol:@protocol(AXPlugInMultipleProtocol)])
            return YES;
        [self badPlugInInstance:plugInClass reason:NSLocalizedString(@"Bad plug in reason F", NULL)];
    } else
        [self badPlugInInstance:plugInClass reason:NSLocalizedString(@"Bad plug in reason G", NULL)];
    
    return NO;
}

- (void)loadPlugIn
{        
    [mPlugInInstances removeAllObjects];
    
    NSMutableArray *bundlePaths = [self allBundles];
    NSEnumerator *pathEnum = [bundlePaths objectEnumerator];
    NSString *path = NULL;
    while(path = [pathEnum nextObject])
    {
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        if(bundle)
        {
            Class principalClass = [bundle principalClass];
            if(principalClass)
            {
                if([self plugInClassIsValid:principalClass])
                {
                    id instance = [[principalClass alloc] init];
                    if(instance)
                        [mPlugInInstances addObject:[instance autorelease]];
                }
            }
        }
    }
}

- (void)registerSinglePlugInInstance:(id)instance
{
    NSString *methodTitle = [instance methodTitle];
    NSString *methodName = [instance methodName];
    
    if(methodTitle == NULL)
    {
        [self badPlugInInstance:instance reason:NSLocalizedString(@"Bad plug in reason A", NULL)];
        return;
    }
    if(methodName == NULL)
    {
        [self badPlugInInstance:instance reason:NSLocalizedString(@"Bad plug in reason B", NULL)];
        return;
    }
    
    [mEffectsItemArray addObject:[AudioPlugInItem itemWithMethodName:methodName instance:instance]];
    
    NSMenuItem *item = [mEffectsMenu addItemWithTitle:methodTitle
                    action:@selector(performEffect:)
                    keyEquivalent:@""];          
    [item setTag:[mEffectsItemArray count]-1];
    
    NSString *titleString = methodTitle;
    if([titleString characterAtIndex:[titleString length]-1] != '.')
        titleString = [titleString stringByAppendingString:@"..."];
        
    item = [mAboutMenu addItemWithTitle:titleString
                    action:@selector(aboutEffect:)
                    keyEquivalent:@""];          
    [item setTag:[mEffectsItemArray count]-1];
}

- (void)registerMultiplePlugInInstance:(id)instance
{
    NSArray *methodTitles = [instance methodTitles];
    NSArray *methodNames = [instance methodNames];

    if(methodTitles == NULL)
    {
        [self badPlugInInstance:instance reason:NSLocalizedString(@"Bad plug in reason C", NULL)];
        return;
    }
    if(methodNames == NULL)
    {
        [self badPlugInInstance:instance reason:NSLocalizedString(@"Bad plug in reason D", NULL)];
        return;
    }
    
    unsigned short title;
    for(title=0; title<[methodTitles count]; title++)
    {
        [mEffectsItemArray addObject:[AudioPlugInItem itemWithMethodName:[methodNames objectAtIndex:title] instance:instance]];
        
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[methodTitles objectAtIndex:title]
                        action:@selector(performEffect:)
                        keyEquivalent:@""];          
        [item setTag:[mEffectsItemArray count]-1];
        [mEffectsMenu addItem:item];
        [item release];
        
        NSString *titleString = [methodTitles objectAtIndex:title];
        if([titleString characterAtIndex:[titleString length]-1] != '.')
            titleString = [titleString stringByAppendingString:@"..."];
            
        item = [mAboutMenu addItemWithTitle:titleString
                        action:@selector(aboutEffect:)
                        keyEquivalent:@""];          
        [item setTag:[mEffectsItemArray count]-1];
    }
}

- (void)registerPlugInInstance:(id)instance
{
    switch([instance plugInType]) {
        case AXPLUGIN_TYPE_SINGLE:
            [self registerSinglePlugInInstance:instance];
            break;
        case AXPLUGIN_TYPE_MULTIPLE:
            [self registerMultiplePlugInInstance:instance];
            break;
        default:
            [self badPlugInInstance:instance reason:NSLocalizedString(@"Bad plug in reason E", NULL)];
            return;
    }
}

- (void)registerPlugIn
{
    if([mPlugInInstances count]>0)
    {
        [mAboutMenu addItem:[NSMenuItem separatorItem]];
    }

    NSEnumerator *plugInsEnum = [mPlugInInstances objectEnumerator];
    id instance = NULL;
    while(instance = [plugInsEnum nextObject])
        [self registerPlugInInstance:instance];
}

- (void)buildEffectsMenu
{
    if(mUseSubmenu == NO) return;
    
    NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:@"AudioXplorer"
                                                        action:NULL
                                                        keyEquivalent:@""];
    [mParentEffectsMenu addItem:subMenuItem];
    [mParentEffectsMenu setSubmenu:mEffectsMenu forItem:subMenuItem];
	[mEffectsMenu autorelease];
}

- (void)load
{
    [self loadPlugIn];
    [self registerPlugIn];
    [self buildEffectsMenu];
}

- (BOOL)canRedoLastEffect
{
    return mLastEffectItem != -1;
}

- (BOOL)redoLastEffectOnData:(id)data channel:(USHORT)channel parentWindow:(NSWindow*)parentWindow
{
    return [[mEffectsItemArray objectAtIndex:mLastEffectItem] performEffectOnData:data channel:channel
                                                        parentWindow:parentWindow];
}

- (BOOL)performEffectAtIndex:(unsigned short)index onData:(id)data channel:(USHORT)channel parentWindow:(NSWindow*)parentWindow
{    
    mLastEffectItem = index;
    
    return [[mEffectsItemArray objectAtIndex:index] performEffectOnData:data channel:channel
                                                        parentWindow:parentWindow];
}

- (void)aboutEffectAtIndex:(unsigned short)index
{
    AudioPlugInItem *mPlugInItem = [mEffectsItemArray objectAtIndex:index];
    if([mPlugInItem about] == NO)
    {
        [mTitleTextField setStringValue:[mPlugInItem aboutTitleField]];
        [mVersionTextField setStringValue:[mPlugInItem versionTitleField]];
        [mAuthorsTextField setStringValue:[mPlugInItem authorsTitleField]];
        [mDescriptionTextField setStringValue:[mPlugInItem descriptionTitleField]];
        [NSApp runModalForWindow:mAboutPlugInPanel];
    }
}

- (IBAction)closeAboutPlugInPanel:(id)sender
{
    [mAboutPlugInPanel orderOut:self];
    [NSApp endSheet:mAboutPlugInPanel returnCode:0];
}

- (IBAction)closePlugInProblemPanel:(id)sender
{
    [mPlugInProblemPanel orderOut:self];
    [NSApp endSheet:mPlugInProblemPanel returnCode:0];
}

@end
