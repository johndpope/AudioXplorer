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

#import "CAConstants.h"
#import "CADataSourceObject.h"
#import "CADeviceObject.h"
#import "CADeviceManager.h"

static NSString *dataSourceNameForID ( AudioDeviceID theDeviceID, UInt32 theDirection, UInt32 theChannel, UInt32 theDataSourceID )
{
    OSStatus theStatus;
    UInt32 theSize;
    AudioValueTranslation theTranslation;
    CFStringRef theCFString;
    
    theTranslation.mInputData = &theDataSourceID;
    theTranslation.mInputDataSize = sizeof(UInt32);
    theTranslation.mOutputData = &theCFString;
    theTranslation.mOutputDataSize = sizeof ( CFStringRef );
    theSize = sizeof(AudioValueTranslation);
    theStatus = AudioDeviceGetProperty ( theDeviceID, theChannel, theDirection, kAudioDevicePropertyDataSourceNameForIDCFString, &theSize, &theTranslation );
    if (theStatus == noErr)
    {
        NSString *rv = [NSString stringWithString:(NSString *)theCFString];
        CFRelease ( theCFString );
        return rv;
    }
    
    return nil;
}

@implementation AudioDataSourceObject

+ (AudioDataSourceObject*)dataSourceWithType:(OSType)typeID direction:(short)direction
                                            parentDevice:(AudioDeviceObject*)parent
{
    AudioDataSourceObject *obj = [[AudioDataSourceObject alloc] init];
    [obj setType:typeID];
    [obj setDirection:direction];
    [obj setDeviceParent:parent];
    [obj update];
    return [obj autorelease];
}

- (id)init
{
    if(self = [super init])
    {
        mDeviceParent = NULL;
        mType = 0;
        mDirection = DIRECTION_NONE;
        mTitle = NULL;
    }
    return self;
}

- (void)dealloc
{
    [mDeviceParent release];
    [mTitle release];
    [super dealloc];
}

- (void)setType:(OSType)typeID
{
    mType = typeID;
}

- (void)setDirection:(short)direction
{
    mDirection = direction;
}

- (void)setDeviceParent:(AudioDeviceObject*)deviceParent
{
    [mDeviceParent autorelease];
    mDeviceParent = [deviceParent retain];
}

- (void)setAsCurrent
{
    UInt32 theSize;
    Boolean isWritable;
    OSStatus theStatus = AudioDeviceGetPropertyInfo([mDeviceParent deviceID], 0, mDirection,
                                    kAudioDevicePropertyDataSource, &theSize, &isWritable);
    if(theStatus != noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceGetPropertyInfo(kAudioDevicePropertyDataSource)" withOSStatus:theStatus];
        return;
    }

    if(isWritable == NO)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceGetPropertyInfo(kAudioDevicePropertyDataSource) not writable" withOSStatus:0];
        return;
    }

    theSize = sizeof(OSType);
    theStatus = AudioDeviceSetProperty([mDeviceParent deviceID], 0, 0, mDirection,
                                    kAudioDevicePropertyDataSource, theSize, &mType);
    if(theStatus != noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceSetProperty(kAudioDevicePropertyDataSource)" withOSStatus:theStatus];
        return;
    }
}

- (NSString*)title
{
    return mTitle;
}

- (void)update
{
    [mTitle autorelease];
    mTitle = dataSourceNameForID([mDeviceParent deviceID], mDirection,
                                [mDeviceParent channel], mType);
    [mTitle retain];
}

@end
