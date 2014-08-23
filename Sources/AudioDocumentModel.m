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

#import "AudioDocumentModel.h"
#import "AudioVersions.h"
#import "AudioUtilities.h"
#import "AudioConstants.h"

@implementation AudioDocumentModel

- (id)init
{
    self = [super init];
    if (self) {
        mAudioDataArray = [[NSMutableArray alloc] init];
        mAudioStaticWindowPersistentData = NULL;
    }
    return self;
}

- (void)dealloc
{
    [mAudioDataArray release];
    [mAudioStaticWindowPersistentData release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder*)coder
{
    if(self = [super init])
    {
        long version = [[coder decodeObject] longValue];
        if(version>MODEL_VERSION_CURRENT)
        {
            [NSException raise:AXExceptionName format:NSLocalizedString(@"The file cannot be read because it has been saved with a newer version of AudioXplorer.", NULL)];
        } else if(version<MODEL_VERSION_CURRENT)
        {
            [NSException raise:AXExceptionName format:NSLocalizedString(@"Cannot read file saved from a previous beta version.", NULL)];
        } else
        {
            mAudioDataArray = [[coder decodeObject] retain];
            mAudioStaticWindowPersistentData = [[coder decodeObject] retain];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:[NSNumber numberWithLong:MODEL_VERSION_CURRENT]];
    [coder encodeObject:mAudioDataArray];
    [coder encodeObject:mAudioStaticWindowPersistentData];
}

- (void)setStaticWindowPersistentData:(id)data
{
    [mAudioStaticWindowPersistentData autorelease];
    mAudioStaticWindowPersistentData = [data retain];
}

- (id)staticWindowPersistentData
{
    return mAudioStaticWindowPersistentData;
}

- (NSMutableArray*)dataWrappers
{
    return mAudioDataArray;
}

@end
