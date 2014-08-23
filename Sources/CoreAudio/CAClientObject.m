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

#import "CAClientObject.h"
#import "CADeviceManager.h"

@implementation CAClientObject

- (id)init
{
    if(self = [super init])
    {
        mIOProc = NULL;
        mDeviceID = kAudioDeviceUnknown;
        mUserData = NULL;
        mClient = NULL;
        mAdded = NO;
        mRunning = NO;
    }
    return self;
}

- (void)setClient:(id)client
{
    mClient = client;
}

- (void)setIOProc:(AudioDeviceIOProc)ioProc
{
    mIOProc = ioProc;
}

- (void)setDeviceID:(AudioDeviceID)deviceID
{
    mDeviceID = deviceID;
}

- (void)setUserData:(id)userData
{
    mUserData = userData;
}

- (void)setNotifySelector:(SEL)selector
{
    mNotifySelector = selector;
}

- (id)client
{	
    return mClient;
}

- (AudioDeviceIOProc)ioProc
{
    return mIOProc;
}

- (AudioDeviceID)deviceID
{
    return mDeviceID;
}

- (void)setIsRunning:(BOOL)flag
{
    mRunning = flag;
}

- (BOOL)isRunning
{
    return mRunning;
}

- (void)setAdded:(BOOL)flag
{
    mAdded = flag;
}

- (BOOL)startIOProc
{
    if(mRunning) return YES;
    
    OSStatus err = AudioDeviceStart(mDeviceID, mIOProc);
    if(err == noErr)
    {
        mRunning = YES;
        return YES;
    } else
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceStart error" withOSStatus:err];
        return NO;
    }
}

- (BOOL)stopIOProc
{
    if(mRunning == NO) return YES;
    
    OSStatus err = AudioDeviceStop(mDeviceID, mIOProc);
    if(err == noErr)
    {
        mRunning = NO;
        return YES;
    } else
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceStop error" withOSStatus:err];
        return NO;
    }
}

- (BOOL)addIOProc
{
    if(mAdded) return YES;
 
    OSStatus err = AudioDeviceAddIOProc(mDeviceID, mIOProc, mUserData);
    if(err == noErr)
    {
        mAdded = YES;
        return YES;
    } else
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceAddIOProc error" withOSStatus:err];
        return NO;
    }
}

- (BOOL)removeIOProc
{
    if(mAdded == NO) return YES;
    
    OSStatus err = AudioDeviceRemoveIOProc(mDeviceID, mIOProc);
    if(err == noErr)
    {
        mAdded = NO;
        return YES;
    } else
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceRemoveIOProc error" withOSStatus:err];
        return NO;
    }
}

- (void)notifyClient
{
    // WARNING : this method can be called from another thread !
    [mClient performSelector:mNotifySelector withObject:self];
}

@end
