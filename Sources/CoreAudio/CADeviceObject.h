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

#import "CAConstants.h"
#import "CAStreamObject.h"
#import "CADataSourceObject.h"

@class CAStreamObject;

@interface AudioDeviceObject : NSObject
{
    NSString 	*mDeviceUID;		// Universal ID
    UInt32 	mDeviceID;		// Local ID
    NSString 	*mTitle;		// Device title
    BOOL	mDeviceInputIsAlive;
    BOOL	mDeviceOutputIsAlive;
    
    // Available streams
    
    AudioStreamObject 	*mCurrentDeviceStreamObject[DIRECTION_COUNT];
    NSMutableArray	*mStreamArray[DIRECTION_COUNT];
    
    // Available data source
    
    AudioDataSourceObject	*mCurrentDataSourceObject[DIRECTION_COUNT];
    NSMutableArray		*mDataSourceArray[DIRECTION_COUNT];
    
    // IOProc
    
    AudioDeviceIOProc 		mIOProc;
}

+ (AudioDeviceObject*)deviceWithID:(AudioDeviceID)deviceID;

- (void)setDeviceID:(AudioDeviceID)deviceID;
- (AudioDeviceID)deviceID;

- (void)setTitle:(NSString*)title;
- (NSString*)title;

- (BOOL)isInputAlive;
- (BOOL)isOutputAlive;

- (void)addListener;
- (void)removeListener;

- (void)setCurrentInputDataSourceAtIndex:(short)index;
- (void)setCurrentOutputDataSourceAtIndex:(short)index;

- (NSString*)currentInputDataSourceTitle;
- (NSString*)currentOutputDataSourceTitle;

- (BOOL)hasDirection:(short)direction;
- (short)channel;

- (NSArray*)streamTitlesArrayForDirection:(short)direction;
- (NSArray*)dataSourceTitlesArrayForDirection:(short)direction;

- (void)update;

- (void)setAsCurrentInput;
- (void)setAsCurrentOutput;

- (AudioStreamObject*)currentInputStream;
- (AudioStreamObject*)currentOutputStream;

- (NSString*)inputRequestedQuality;
- (NSString*)inputObtainedQuality;
- (NSString*)outputRequestedQuality;
- (NSString*)outputObtainedQuality;

@end

@interface AudioDeviceObject (Stream)
- (void)queryStreamList;
- (void)queryInputStreamList;
- (void)queryOutputStreamList;
- (AudioStreamObject*)queryStreamListForDeviceID:(UInt32)deviceID direction:(short)direction;
@end

@interface AudioDeviceObject (DataSource)
- (void)queryDataSourceList;
- (AudioDataSourceObject*)queryDataSourceListForChannel:(UInt32)theChannel direction:(short)direction;
@end

@interface AudioDeviceObject (IOProc)
- (void)setIOProc:(AudioDeviceIOProc)ioProc;
@end
