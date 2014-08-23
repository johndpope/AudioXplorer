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

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>

#import "CADeviceObject.h"
#import "CAClientObject.h"

@interface AudioDeviceManager : NSObject {
    NSTimer *mListenerTimer;
    BOOL mDirty;
    
    NSMutableArray *mClientArray;
    
    NSMutableArray *mDeviceArray;
    
    AudioDeviceObject *mCurrentInputDeviceObject;
    AudioDeviceObject *mCurrentOutputDeviceObject;
    
    BOOL mInputDeviceAvailable;    
}

+ (AudioDeviceManager*)shared;
+ (void)log:(NSString*)log;
+ (void)displayCoreAudioMessage:(NSString*)message withOSStatus:(OSStatus)status;

+ (void)setLogDelegate:(id)delegate;
- (void)setDirty:(BOOL)flag;

@end

@interface AudioDeviceManager (Device)

- (void)addListener;
- (void)removeListener;

- (void)checkForDiedDevices;
- (void)refreshDevices;
- (void)initDevices;

- (BOOL)inputDeviceAvailable;
- (BOOL)outputDeviceAvailable;

- (AudioDeviceObject*)deviceObjectForDeviceID:(AudioDeviceID)deviceID;

- (void)setCurrentInputDeviceAtIndex:(short)index;
- (void)setCurrentOutputDeviceAtIndex:(short)index;

- (NSString*)currentInputDeviceTitle;
- (NSString*)currentOutputDeviceTitle;

- (void)setCurrentInputDataSourceAtIndex:(short)index;
- (void)setCurrentOutputDataSourceAtIndex:(short)index;

- (NSString*)currentInputDataSourceTitle;
- (NSString*)currentOutputDataSourceTitle;

- (AudioStreamBasicDescription)currentInputStreamDescription;
- (AudioStreamBasicDescription)currentOutputStreamDescription;

- (int)numberOfInputChannels;
- (int)numberOfOutputChannels;

- (AudioDeviceObject*)queryCurrentInputDevice;
- (AudioDeviceObject*)queryCurrentOutputDevice;

- (NSArray*)arrayOfArray:(NSArray*)array direction:(short)direction;
- (NSArray*)titlesArrayFromArray:(NSArray*)array direction:(short)direction;

- (NSArray*)inputDeviceTitlesArray;
- (NSArray*)outputDeviceTitlesArray;

- (NSArray*)inputStreamTitlesArray;
- (NSArray*)outputStreamTitlesArray;

- (NSArray*)inputDataSourceTitlesArray;
- (NSArray*)outputDataSourceTitlesArray;

- (NSString*)inputRequestedQuality;
- (NSString*)inputObtainedQuality;
- (NSString*)outputRequestedQuality;
- (NSString*)outputObtainedQuality;

- (AudioDeviceID)currentInputDeviceID;
- (AudioDeviceID)currentOutputDeviceID;

@end

@interface AudioDeviceManager (Clients)

- (id)registerClient:(id)client deviceID:(AudioDeviceID)deviceID ioProc:(AudioDeviceIOProc)ioProc
            userData:(id)userData notifySelector:(SEL)notifySel;
- (void)removeClient:(id)ticket;

- (BOOL)addAndStartIOProc:(id)ticket;
- (BOOL)stopAndRemoveIOProc:(id)ticket;

- (BOOL)isRunningClient:(id)ticket;

@end
