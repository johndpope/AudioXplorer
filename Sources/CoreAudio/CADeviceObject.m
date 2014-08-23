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

#import "CADeviceObject.h"
#import "CADeviceManager.h"

@implementation AudioDeviceObject

+ (AudioDeviceObject*)deviceWithID:(AudioDeviceID)deviceID
{
    AudioDeviceObject *obj = [[AudioDeviceObject alloc] init];
    [obj setDeviceID:deviceID];
    [obj update];
    return [obj autorelease];
}

- (id)init
{
    if(self = [super init])
    {
        mDeviceUID = NULL;
        
        mDeviceInputIsAlive = YES;
        mDeviceOutputIsAlive = YES;
        
        short direction;
        for(direction=0; direction<DIRECTION_COUNT; direction++)
        {
            mCurrentDeviceStreamObject[direction] = NULL;
            mStreamArray[direction] = NULL;
            
            mCurrentDataSourceObject[direction] = NULL;
            mDataSourceArray[direction] = NULL;
        }        
    }
    return self;
}

- (void)dealloc
{
    [self removeListener];
    
    [mDeviceUID release];
    
    short direction;
    for(direction=0; direction<DIRECTION_COUNT; direction++)
    {
        [mCurrentDeviceStreamObject[direction] release];
        [mStreamArray[direction] release];
        [mCurrentDataSourceObject[direction] release];
        [mDataSourceArray[direction] release];
    }
    
    [super dealloc];
}

- (void)setDeviceID:(AudioDeviceID)deviceID
{
    mDeviceID = deviceID;
    [self removeListener];
    [self addListener];
}

- (AudioDeviceID)deviceID
{
    return mDeviceID;
}

- (void)setTitle:(NSString*)title
{
    [mTitle autorelease];
    mTitle = [title retain];
}

- (NSString*)title
{
    return mTitle;
}

- (BOOL)isAlive:(short)direction
{
    UInt32 theSize;
    Boolean isWritable;
	UInt32	isAlive;
    OSStatus theStatus;

    theStatus = AudioDeviceGetPropertyInfo(mDeviceID, 0, direction,
                kAudioDevicePropertyDeviceIsAlive, &theSize, &isWritable);
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceGetPropertyInfo(kAudioDevicePropertyDeviceIsAlive)" withOSStatus:theStatus];
        return NO;
    }

    theStatus = AudioDeviceGetProperty(mDeviceID, 0, direction,
                kAudioDevicePropertyDeviceIsAlive, &theSize, &isAlive);
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceGetProperty(kAudioDevicePropertyDeviceIsAlive)" withOSStatus:theStatus];
        return NO;
    }

    return (BOOL)(isAlive != 0);
}

- (BOOL)isInputAlive
{
    return mDeviceInputIsAlive;
    //return [self isAlive:DIRECTION_INPUT];
}

- (BOOL)isOutputAlive
{
    return mDeviceOutputIsAlive;
  //  return [self isAlive:DIRECTION_OUTPUT];
}

- (void)inputPropertyDeviceIsAliveHasChanged
{
    AudioDeviceStop(mDeviceID, mIOProc);
    AudioDeviceRemoveIOProc(mDeviceID, mIOProc);
    mDeviceInputIsAlive = NO;
}

- (void)outputPropertyDeviceIsAliveHasChanged
{
    AudioDeviceStop(mDeviceID, mIOProc);
    AudioDeviceRemoveIOProc(mDeviceID, mIOProc);
    mDeviceOutputIsAlive = NO;
}

static OSStatus inputDevicePropertyListener(AudioDeviceID inDevice, UInt32 inChannel, Boolean isInput,
                                        AudioDevicePropertyID inPropertyID, void *inClientData)
{
    AudioDeviceObject *theDeviceObject = (AudioDeviceObject*)inClientData;
    
    if(inPropertyID == kAudioDevicePropertyDeviceIsAlive
        && [theDeviceObject deviceID] == inDevice)
        [theDeviceObject inputPropertyDeviceIsAliveHasChanged];

    return noErr;
}

static OSStatus outputDevicePropertyListener(AudioDeviceID inDevice, UInt32 inChannel, Boolean isInput,
                                        AudioDevicePropertyID inPropertyID, void *inClientData)
{
    AudioDeviceObject *theDeviceObject = (AudioDeviceObject*)inClientData;
    
    if(inPropertyID == kAudioDevicePropertyDeviceIsAlive
        && [theDeviceObject deviceID] == inDevice)
        [theDeviceObject outputPropertyDeviceIsAliveHasChanged];

    return noErr;
}

- (void)addListener
{
    AudioDeviceAddPropertyListener(mDeviceID, 0, DIRECTION_INPUT, kAudioDevicePropertyDeviceIsAlive, 
                                    inputDevicePropertyListener, self);
    AudioDeviceAddPropertyListener(mDeviceID, 0, DIRECTION_OUTPUT, kAudioDevicePropertyDeviceIsAlive, 
                                    outputDevicePropertyListener, self);
}

- (void)removeListener
{
    AudioDeviceRemovePropertyListener(mDeviceID, 0, DIRECTION_INPUT, kAudioDevicePropertyDeviceIsAlive, 
                                    inputDevicePropertyListener);
    AudioDeviceRemovePropertyListener(mDeviceID, 0, DIRECTION_OUTPUT, kAudioDevicePropertyDeviceIsAlive, 
                                    outputDevicePropertyListener);    
}

- (void)setCurrentInputDataSourceAtIndex:(short)index
{
	NSArray *array = mDataSourceArray[DIRECTION_INPUT];
	if(index >=0 && index < [array count]) {
		mCurrentDataSourceObject[DIRECTION_INPUT] = [array objectAtIndex:index];
		[mCurrentDataSourceObject[DIRECTION_INPUT] setAsCurrent];    		
	}
}

- (void)setCurrentOutputDataSourceAtIndex:(short)index
{
	NSArray *array = mDataSourceArray[DIRECTION_OUTPUT];
	if(index >=0 && index < [array count]) {
		mCurrentDataSourceObject[DIRECTION_OUTPUT] = [array objectAtIndex:index];
		[mCurrentDataSourceObject[DIRECTION_OUTPUT] setAsCurrent];
	}
}

- (NSString*)currentInputDataSourceTitle
{
    return [mCurrentDataSourceObject[DIRECTION_INPUT] title];
}

- (NSString*)currentOutputDataSourceTitle
{
    return [mCurrentDataSourceObject[DIRECTION_OUTPUT] title];
}

- (BOOL)hasDirection:(short)direction
{
    return (mStreamArray[direction] != NULL && [mStreamArray[direction] count]>0)
            || (mDataSourceArray[direction] != NULL && [mDataSourceArray[direction] count]>0);
}

- (short)channel
{
    return 0;
}

- (NSArray*)titlesArrayFromArray:(NSArray*)array
{
    NSMutableArray *titles = [NSMutableArray arrayWithCapacity:[array count]];
    
    int index;
    for(index=0; index<[array count]; index++)
        [titles addObject:[[array objectAtIndex:index] title]];
    
    return titles;
}

- (NSArray*)streamTitlesArrayForDirection:(short)direction
{
    return [self titlesArrayFromArray:mStreamArray[direction]];
}

- (NSArray*)dataSourceTitlesArrayForDirection:(short)direction
{
    return [self titlesArrayFromArray:mDataSourceArray[direction]];
}

- (NSString*)queryTitle
{
    UInt32 theSize;
    Boolean isWritable;
    OSStatus theStatus;
	NSString *title = NULL;
	
    theStatus = AudioDeviceGetPropertyInfo(mDeviceID, 0, DIRECTION_INPUT,
                kAudioDevicePropertyDeviceNameCFString, &theSize, &isWritable);
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceGetPropertyInfo(kAudioDevicePropertyDeviceNameCFString)" withOSStatus:theStatus];
        return NULL;
    }

    theStatus = AudioDeviceGetProperty(mDeviceID, 0, DIRECTION_INPUT,
                kAudioDevicePropertyDeviceNameCFString, &theSize, &title);
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceGetProperty(kAudioDevicePropertyDeviceNameCFString)" withOSStatus:theStatus];
        return NULL;
    }
    
    return title;
}

- (void)update
{
    [self queryStreamList];
    [self queryDataSourceList];
    
    [self setTitle:[self queryTitle]];
}

- (void)setAsCurrentInput
{
    [AudioDeviceManager log:[NSString stringWithFormat:@"Set device %d as current input", mDeviceID]];
    [self queryInputStreamList];
    [mCurrentDeviceStreamObject[DIRECTION_INPUT] findBestPhysicalFormatNeeded];
}

- (void)setAsCurrentOutput
{
    [AudioDeviceManager log:[NSString stringWithFormat:@"Set device %d as current output", mDeviceID]];
    [self queryOutputStreamList];
    [mCurrentDeviceStreamObject[DIRECTION_OUTPUT] findBestPhysicalFormatNeeded];
}

- (AudioStreamObject*)currentInputStream
{
    return mCurrentDeviceStreamObject[DIRECTION_INPUT];
}

- (AudioStreamObject*)currentOutputStream
{
    return mCurrentDeviceStreamObject[DIRECTION_OUTPUT];
}

- (NSString*)inputRequestedQuality
{
    return [mCurrentDeviceStreamObject[DIRECTION_INPUT] requestedQuality];
}

- (NSString*)inputObtainedQuality
{
    return [mCurrentDeviceStreamObject[DIRECTION_INPUT] obtainedQuality];
}

- (NSString*)outputRequestedQuality
{
    return [mCurrentDeviceStreamObject[DIRECTION_OUTPUT] requestedQuality];
}

- (NSString*)outputObtainedQuality
{
    return [mCurrentDeviceStreamObject[DIRECTION_OUTPUT] obtainedQuality];
}

@end

@implementation AudioDeviceObject (Stream)

- (void)queryStreamList
{
    [self queryInputStreamList];
    [self queryOutputStreamList];
}

- (void)queryInputStreamList
{
    [mCurrentDeviceStreamObject[DIRECTION_INPUT] release];
    mCurrentDeviceStreamObject[DIRECTION_INPUT] = [[self queryStreamListForDeviceID:mDeviceID
                                                                    direction:DIRECTION_INPUT] retain];
}

- (void)queryOutputStreamList
{
    [mCurrentDeviceStreamObject[DIRECTION_OUTPUT] release];
    mCurrentDeviceStreamObject[DIRECTION_OUTPUT] = [[self queryStreamListForDeviceID:mDeviceID
                                                                    direction:DIRECTION_OUTPUT] retain];
}

- (AudioStreamObject*)queryStreamListForDeviceID:(UInt32)deviceID direction:(short)direction
{
    OSStatus theStatus = noErr;
    UInt32 theSize;
    int theCount = 0;

    [mStreamArray[direction] release];
    mStreamArray[direction] = NULL;
    
    // Get the number of streams
    
    theStatus =  AudioDeviceGetPropertyInfo(deviceID, 0, direction, kAudioDevicePropertyStreams,
                                            &theSize, NULL);
    if(theStatus!=noErr)
    {
        return NULL;
    }
    
    // Get the stream list
    
    theCount = theSize/sizeof(AudioStreamID);
        
    AudioStreamID *theStreamList = (AudioStreamID*)malloc(theSize);
    
    theStatus = AudioDeviceGetProperty(deviceID, 0, direction, kAudioDevicePropertyStreams,
                                        &theSize, theStreamList);
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceGetProperty(kAudioDevicePropertyStreams)" withOSStatus:theStatus];
        return NULL;
    }
    
    // Store the stream list

    [mStreamArray[direction] release];
    mStreamArray[direction] = [[NSMutableArray arrayWithCapacity:theCount] retain];
    
    int index;
    for(index=0; index<theCount; index++)
        [mStreamArray[direction] addObject:[AudioStreamObject streamWithID:theStreamList[index]
                                                                direction:direction
                                                                deviceParent:self]];
    free(theStreamList);
    
    return theCount>0?[mStreamArray[direction] objectAtIndex:0]:NULL;
}

@end

@implementation AudioDeviceObject (DataSource)

- (void)queryDataSourceList
{
    [mCurrentDataSourceObject[DIRECTION_INPUT] release];
    [mCurrentDataSourceObject[DIRECTION_OUTPUT] release];
    
    mCurrentDataSourceObject[DIRECTION_INPUT] = [[self queryDataSourceListForChannel:[self channel]
                                                                    direction:DIRECTION_INPUT] retain];
    mCurrentDataSourceObject[DIRECTION_OUTPUT] = [[self queryDataSourceListForChannel:[self channel]
                                                                    direction:DIRECTION_OUTPUT] retain];
}

- (AudioDataSourceObject*)queryDataSourceListForChannel:(UInt32)theChannel direction:(short)direction
{
    OSStatus theStatus = noErr;
    UInt32 theDeviceID = mDeviceID;
    UInt32 theSize;

    [mDataSourceArray[direction] release];
    mDataSourceArray[direction] = NULL;
    
    // Get the number of data source available
    
    theStatus = AudioDeviceGetPropertyInfo(theDeviceID, theChannel, direction,
                                    kAudioDevicePropertyDataSources, &theSize, NULL);
    if(theStatus!=noErr)
    {
        return NULL;
    }

    // Get the data source list
    
    int theCount = theSize / sizeof(OSType);
    OSType *typeList = (OSType *) malloc(theSize);

    theStatus = AudioDeviceGetProperty (theDeviceID, theChannel, direction, 
                                kAudioDevicePropertyDataSources, &theSize, typeList);
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceGetProperty(kAudioDevicePropertyDataSources)" withOSStatus:theStatus];
        free(typeList);
        return NULL;
    }

    // Store the data source list

    [mDataSourceArray[direction] release];
    mDataSourceArray[direction] = [[NSMutableArray arrayWithCapacity:theCount] retain];

    int index;
    for(index=0; index<theCount; index++)
        [mDataSourceArray[direction] addObject:[AudioDataSourceObject dataSourceWithType:typeList[index]
                                                            direction:direction
                                                            parentDevice:self]];

    free(typeList);
    
    return theCount>0?[mDataSourceArray[direction] objectAtIndex:0]:NULL;
}

@end

@implementation AudioDeviceObject (IOProc)

- (void)setIOProc:(AudioDeviceIOProc)ioProc
{
    mIOProc = ioProc;
}

@end
