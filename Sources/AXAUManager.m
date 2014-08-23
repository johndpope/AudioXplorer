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

#import "AXAUManager.h"
#import "AXAUComponent.h"

@implementation AXAUManager

+ (AXAUManager*)shared
{
    static AXAUManager *sharedAXAUManager = NULL;
    if(sharedAXAUManager == NULL)
        sharedAXAUManager = [[AXAUManager alloc] init];
    return sharedAXAUManager;
}

- (id)init
{
    if(self = [super init])
    {
        mComponentArray = [[NSMutableArray alloc] init];
        mComponentTitles = [[NSMutableArray alloc] init];
        [self findComponents];
    }
    return self;
}

- (void)dealloc
{
    [mComponentArray release];
    [mComponentTitles release];
    [super dealloc];
}

- (void)findComponentsOfType:(OSType)type
{    
    ComponentDescription desc;
    desc.componentType = type;
    desc.componentSubType = 0;
    desc.componentManufacturer = 0;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    Component theComponent = FindNextComponent (NULL, &desc);
    while (theComponent != NULL)
    {
        ComponentDescription found;
        Handle hdl = NewHandle(10);
        GetComponentInfo(theComponent, &found, hdl, 0, 0);
        
        char * c = *hdl;
        c++;
        NSString *name = [NSString stringWithCString:c length:GetHandleSize(hdl)-1];
        DisposeHandle(hdl);
        
        AXAUComponent *component = [AXAUComponent componentWithDescription:found name:name];
        [mComponentArray addObject:component];
            
        theComponent = FindNextComponent(theComponent, &desc);
    }    
}

- (void)updateComponentTitles
{
    [mComponentTitles removeAllObjects];

    NSEnumerator *enumerator = [mComponentArray objectEnumerator];
    AXAUComponent *component = NULL;
    while(component = [enumerator nextObject])
        [mComponentTitles addObject:[component title]];
}

- (NSString*)componentTitleAtIndex:(int)index
{
    return [mComponentTitles objectAtIndex:index];
}

- (NSArray*)componentTitles
{
    return mComponentTitles;
}

- (void)preload
{
    NSEnumerator *enumerator = [mComponentArray objectEnumerator];
    AXAUComponent *component = NULL;
    while(component = [enumerator nextObject])
        [component open];
}

- (void)findComponents
{
    [mComponentArray removeAllObjects];
    
    [self findComponentsOfType:kAudioUnitType_Effect];
    [self findComponentsOfType:'aumf'];
    
    [mComponentArray sortUsingSelector:@selector(componentCompare:)];
    
    [self updateComponentTitles];
}

- (void)openComponentUIAtIndex:(short)index
{
    AXAUComponent *component = [mComponentArray objectAtIndex:index];
    [component openUI];
}

- (BOOL)performEffectAtIndex:(unsigned short)index onData:(id)data channel:(unsigned short)channel parentWindow:(NSWindow*)parentWindow
{    
    return [(AXAUComponent*)[mComponentArray objectAtIndex:index] performEffectOnData:data channel:channel
                                                        parentWindow:parentWindow];
}

- (BOOL)openEffectUIAtIndex:(unsigned short)index parentWindow:(NSWindow*)parentWindow
{
    return [(AXAUComponent*)[mComponentArray objectAtIndex:index] openUI];
}

@end
