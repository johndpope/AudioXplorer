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

#import "AudioPlugInItem.h"
#import "AudioPlugInParameter.h"
#import "AudioPlugInsController.h"
#import "AXPlugInHeader.h"
#import "AudioConstants.h"

@implementation AudioPlugInItem

+ (AudioPlugInItem*)itemWithMethodName:(NSString*)name instance:(id)instance
{
    AudioPlugInItem *item = [[AudioPlugInItem alloc] init];
    [item setPlugInInstance:instance];
    [item setPlugInMethodName:name];
    return [item autorelease];
}

- (id)init
{
    if(self = [super init])
    {
        mPlugInInstance = NULL;
        mMethodName = NULL;
        mMethodSelector = NULL;
        mType = -1;
    }
    return self;
}

- (void)dealloc
{
    [mPlugInInstance release];
    [mMethodName release];
    [super dealloc];
}

- (void)setPlugInInstance:(id)instance
{
    [mPlugInInstance autorelease];
    mPlugInInstance = [instance retain];
    mType = [mPlugInInstance plugInType];
}

- (void)setPlugInMethodName:(NSString*)name
{	
    [mMethodName autorelease];
    mMethodName = [name retain];  
    mMethodSelector = NSSelectorFromString(mMethodName);  
}

- (BOOL)performEffectOnData:(id)data channel:(USHORT)channel parentWindow:(NSWindow*)parentWindow;
{
    AudioPlugInParameter *param = [[AudioPlugInParameter alloc] init];

    [param setParentWindow:parentWindow];
    [param setData:data];
    [param setChannelCount:channel==STEREO_CHANNEL?2:1];

    BOOL success = NO;
    
    if(mType == AXPLUGIN_TYPE_SINGLE)
    {
        if([[AudioPlugInsController shared] respondsToSelector:@"plugInWillBeCalled"
                                            plugInInstance:mPlugInInstance])
        {
            if([mPlugInInstance plugInWillBeCalled])
                [mPlugInInstance performSelector:mMethodSelector withObject:param];
            success = YES;
        }
    } else
    {
        if([[AudioPlugInsController shared] respondsToSelector:@"plugInWillBeCalledWithMethod:"
                                            plugInInstance:mPlugInInstance])
        {
            if([mPlugInInstance plugInWillBeCalledWithMethod:mMethodName])
                [mPlugInInstance performSelector:mMethodSelector withObject:param];
            
            success = YES;
        }
    }
    
    [param release];
    
    return success;
}

@end

@implementation AudioPlugInItem (About)

- (BOOL)about
{
    return NO;
}

- (NSString*)aboutTitleField
{
    if([[AudioPlugInsController shared] respondsToSelector:
    mType == AXPLUGIN_TYPE_SINGLE?@"aboutString":@"aboutStringOfMethod:"
                                        plugInInstance:mPlugInInstance])
    {
        if(mType == AXPLUGIN_TYPE_SINGLE)
            return [mPlugInInstance aboutString];
        else
            return [mPlugInInstance aboutStringOfMethod:mMethodName];
    } else
        return @"";
}

- (NSString*)versionTitleField
{
    if([[AudioPlugInsController shared] respondsToSelector:
    mType == AXPLUGIN_TYPE_SINGLE?@"versionString":@"versionStringOfMethod:"
                                        plugInInstance:mPlugInInstance])
    {
        if(mType == AXPLUGIN_TYPE_SINGLE)
            return [mPlugInInstance versionString];
        else
            return [mPlugInInstance versionStringOfMethod:mMethodName];
    } else
        return @"";
}

- (NSString*)authorsTitleField;
{
    if([[AudioPlugInsController shared] respondsToSelector:
    mType == AXPLUGIN_TYPE_SINGLE?@"authorsString":@"authorsStringOfMethod:"
                                        plugInInstance:mPlugInInstance])
    {
        if(mType == AXPLUGIN_TYPE_SINGLE)
            return [mPlugInInstance authorsString];
        else
            return [mPlugInInstance authorsStringOfMethod:mMethodName];
    } else
        return @"";
}

- (NSString*)descriptionTitleField;
{
    if([[AudioPlugInsController shared] respondsToSelector:
    mType == AXPLUGIN_TYPE_SINGLE?@"authorsString":@"authorsStringOfMethod:"
                                        plugInInstance:mPlugInInstance])
    {
        if(mType == AXPLUGIN_TYPE_SINGLE)
            return [mPlugInInstance descriptionString];
        else
            return [mPlugInInstance descriptionStringOfMethod:mMethodName];
    } else
        return @"";
}

@end
