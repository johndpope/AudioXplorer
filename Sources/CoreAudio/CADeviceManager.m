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

#import "CADeviceManager.h"
#import "CAStreamObject.h"

@implementation AudioDeviceManager

static id mLogDelegate = NULL;
static BOOL mLogDisplay = NO;

+ (AudioDeviceManager*)shared
{
    static AudioDeviceManager *_deviceManager = NULL;
    if(_deviceManager == NULL)
    {
        _deviceManager = [[AudioDeviceManager alloc] init];
        [_deviceManager addListener];
        [_deviceManager initDevices];
    }
    return _deviceManager;
}

- (id)init
{
    if(self = [super init])
    {
        mClientArray = [[NSMutableArray alloc] init];
        mDeviceArray = NULL;
        mCurrentInputDeviceObject = NULL;
        mCurrentOutputDeviceObject = NULL;
        mInputDeviceAvailable = NO;
        
        mDirty = NO;
        
    	mListenerTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self
                            selector:@selector(listenerTimer:) userInfo:NULL repeats:YES] retain];
    }
    return self;
}

- (void)dealloc
{
    [self removeListener];

    [mLogDelegate release];
    
    [mListenerTimer release];
    
    [mClientArray release];
    [mDeviceArray release];
    [mCurrentInputDeviceObject release];
    [mCurrentOutputDeviceObject release];

    [super dealloc];
}

+ (void)log:(NSString*)log
{
    if(mLogDisplay)
    {
        if(mLogDelegate)
            [mLogDelegate performSelector:@selector(deviceManagerLog:) withObject:log];
        else
            NSLog(log);
    }
}

+ (void)displayCoreAudioMessage:(NSString*)message withOSStatus:(OSStatus)status
{
    NSString *err = NULL;
    
    switch(status) {
        case kAudioHardwareNoError:
            return;
            break;
        case kAudioHardwareNotRunningError:
            err = @"Hardware is not running";
            break;
        case kAudioHardwareUnspecifiedError:
            err = @"Unspecified";
            break;
        case kAudioHardwareUnknownPropertyError:
            err = @"Unknown property";
            break;
        case kAudioHardwareBadPropertySizeError:
            err = @"Bad property size";
            break;
        case kAudioHardwareIllegalOperationError:
            err = @"Illegal operation";
            break;
        case kAudioHardwareBadDeviceError:
            err = @"Bad device";
            break;
        case kAudioHardwareBadStreamError:
            err = @"Bad stream";
            break;
        case kAudioDeviceUnsupportedFormatError:
            err = @"Unsupported format";
            break;
        case kAudioDevicePermissionsError:
            err = @"Permissions";
            break;
        default:
            err =[NSString stringWithFormat:@"Unknown error number (%d)", status];
            break;
    }
    [AudioDeviceManager log:[NSString stringWithFormat:@"%@ [%@]", message, err]];
}

+ (void)setLogDelegate:(id)delegate
{
    [mLogDelegate autorelease];
    mLogDelegate = [delegate retain];
}

+ (void)setLogDisplay:(BOOL)flag
{
    mLogDisplay = flag;
}

- (void)setDirty:(BOOL)flag
{
    mDirty = flag;
}

@end

@implementation AudioDeviceManager (Device)

static OSStatus hardwarePropertyListener(AudioHardwarePropertyID inPropertyID, void *inClientData)
{
    if(inPropertyID == kAudioHardwarePropertyDevices)
        [[AudioDeviceManager shared] setDirty:YES];
    
    return noErr;
}

- (void)notifyDevicesChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CADeviceManagerDevicesChangedNotification
                                                        object:self];
}

- (void)addListener
{
    AudioHardwareAddPropertyListener(kAudioHardwarePropertyDevices, hardwarePropertyListener, NULL);
}

- (void)removeListener
{
    AudioHardwareRemovePropertyListener(kAudioHardwarePropertyDevices, hardwarePropertyListener);
}

- (void)listenerTimer:(NSTimer*)timer
{
    [self checkForDiedDevices];
    if(mDirty)
        [self refreshDevices];
}

- (void)notifyClientOfDeviceDead:(AudioDeviceObject*)device direction:(short)direction
{
    NSEnumerator *enumerator = [mClientArray objectEnumerator];
    CAClientObject *client = NULL;
    while(client = [enumerator nextObject])
    {
        if([client deviceID] == [device deviceID])
        {
            [client setIsRunning:NO];
            [client setAdded:NO];
            [client notifyClient];
        }
    }
}

- (void)checkForDiedDevices
{
    NSEnumerator *enumerator = [mDeviceArray objectEnumerator];
    AudioDeviceObject *device = NULL;
    while(device = [enumerator nextObject])
    {
        if([device isInputAlive] == NO)
            [self notifyClientOfDeviceDead:device direction:DIRECTION_INPUT];
        if([device isOutputAlive] == NO)
            [self notifyClientOfDeviceDead:device direction:DIRECTION_OUTPUT];			
    }
}

- (void)refreshDevices
{
    mDirty = NO;
    [self initDevices];
    [self notifyDevicesChanged];
}

- (void)initDevices
{
    OSStatus theStatus;
    UInt32 theSize;
    int theCount = 0;
    
    [mDeviceArray release];
    mDeviceArray = NULL;

    [mCurrentInputDeviceObject release];
    mCurrentInputDeviceObject = NULL;
    [mCurrentOutputDeviceObject release];
    mCurrentOutputDeviceObject = NULL;
        
    // Retreive the size of the device list
    
    theStatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices,
                                            &theSize, NULL);
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices)" withOSStatus:theStatus];
        return;
    }
    
    theCount = theSize / sizeof(AudioDeviceID);
    
    // Allocate enough space to hold the list
    
    AudioDeviceID* theDeviceList = (AudioDeviceID*)malloc(theCount*sizeof(AudioDeviceID));
    
    // Get the device list
    
    theSize = theCount*sizeof(AudioDeviceID);
    theStatus = AudioHardwareGetProperty(kAudioHardwarePropertyDevices,
                                            &theSize, theDeviceList);
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioHardwareGetProperty(kAudioHardwarePropertyDevices)" withOSStatus:theStatus];
        return;
    }

    // Store the device list
    
    mDeviceArray = [[NSMutableArray arrayWithCapacity:theCount] retain];
    
    int index;
    for(index=0; index<theCount; index++)
    {
        [AudioDeviceManager log:[NSString stringWithFormat:@"Add device %d", theDeviceList[index]]];
        [mDeviceArray addObject:[AudioDeviceObject deviceWithID:theDeviceList[index]]];
    }
    free(theDeviceList);
    
    // Get the current input/output device
        
    mCurrentInputDeviceObject = [[self queryCurrentInputDevice] retain];
    mCurrentOutputDeviceObject = [[self queryCurrentOutputDevice] retain];

    [mCurrentInputDeviceObject setAsCurrentInput];
    [mCurrentOutputDeviceObject setAsCurrentOutput];
}

- (BOOL)inputDeviceAvailable
{
    OSStatus status;
    UInt32 size;
    UInt32 inputDeviceID;
    Boolean isWritable;
                
    status = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &size, NULL);
    if(status != noErr)
        return NO;

    status = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDefaultInputDevice,
                                            &size, &isWritable);  
    if(status != noErr)
        return NO;
        
    status = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice,
                                            &size, &inputDeviceID);  
    if(status != noErr)
        return NO;

    status =  AudioDeviceGetPropertyInfo(inputDeviceID, 0, DIRECTION_INPUT,
                kAudioDevicePropertyStreamConfiguration,  &size, &isWritable);
    if(status != noErr)
        return NO;

// Ignore Data Source because some device don't have data source (like Griffin iMic)
/*    status = AudioDeviceGetPropertyInfo(inputDeviceID, 0, DIRECTION_INPUT,
                                    kAudioDevicePropertyDataSources, &size, NULL);
    if(status != noErr)
        return NO;*/

    return YES;
}

- (BOOL)outputDeviceAvailable
{
    OSStatus status;
    UInt32 size;
    UInt32 outputDeviceID;
    Boolean isWritable;
                
    status = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &size, NULL);
    if(status != noErr)
        return NO;

    status = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDefaultOutputDevice,
                                            &size, &isWritable);  
    if(status != noErr)
        return NO;
        
    status = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &size, &outputDeviceID);  
    if(status != noErr)
        return NO;

    status =  AudioDeviceGetPropertyInfo(outputDeviceID, 0, DIRECTION_OUTPUT,
                kAudioDevicePropertyStreamConfiguration,  &size, &isWritable);
    if(status != noErr)
        return NO;

// Ignore Data Source because some device don't have data source (like Griffin iMic)
/*    status = AudioDeviceGetPropertyInfo(outputDeviceID, 0, DIRECTION_OUTPUT,
                                    kAudioDevicePropertyDataSources, &size, NULL);
    if(status != noErr)
        return NO;*/

    return YES;
}

- (AudioDeviceObject*)deviceObjectForDeviceID:(AudioDeviceID)deviceID
{
    int index;
    for(index=0; index<[mDeviceArray count]; index++)
    {
        AudioDeviceObject *obj = [mDeviceArray objectAtIndex:index];
        if([obj deviceID] == deviceID)
            return obj;
    }
    return NULL;
}

- (void)setCurrentInputDeviceAtIndex:(short)index
{
    [mCurrentInputDeviceObject autorelease];
	NSArray *devices = [self arrayOfArray:mDeviceArray direction:DIRECTION_INPUT];
	if(index >= 0 && index < [devices count]) {
		mCurrentInputDeviceObject = [[devices objectAtIndex:index] retain];
		[mCurrentInputDeviceObject setAsCurrentInput];		
	} else {
		mCurrentInputDeviceObject = nil;
	}
    [self notifyDevicesChanged];
}

- (void)setCurrentOutputDeviceAtIndex:(short)index
{
    [mCurrentOutputDeviceObject autorelease];
	NSArray *devices = [self arrayOfArray:mDeviceArray direction:DIRECTION_OUTPUT];
	if(index >= 0 && index < [devices count]) {
		mCurrentOutputDeviceObject = [[devices objectAtIndex:index] retain];
		[mCurrentOutputDeviceObject setAsCurrentOutput];
	} else {
		mCurrentOutputDeviceObject = nil;
	}
    [self notifyDevicesChanged];
}

- (NSString*)currentInputDeviceTitle
{
	NSString *title = [mCurrentInputDeviceObject title];
    return title?title:@"";
}

- (NSString*)currentOutputDeviceTitle
{
	NSString *title = [mCurrentOutputDeviceObject title];
    return title?title:@"";
}

- (void)setCurrentInputDataSourceAtIndex:(short)index
{
    [mCurrentInputDeviceObject setCurrentInputDataSourceAtIndex:index];
    [self notifyDevicesChanged];
}

- (void)setCurrentOutputDataSourceAtIndex:(short)index
{
    [mCurrentOutputDeviceObject setCurrentOutputDataSourceAtIndex:index];
    [self notifyDevicesChanged];
}

- (NSString*)currentInputDataSourceTitle
{
    return [mCurrentInputDeviceObject currentInputDataSourceTitle];
}

- (AudioStreamBasicDescription)currentInputStreamDescription
{
    return [[mCurrentInputDeviceObject currentInputStream] streamDescription];
}

- (int)numberOfInputChannels
{
	AudioStreamObject *object =	[mCurrentInputDeviceObject currentInputStream];
	if(object)
		return [object streamDescription].mChannelsPerFrame;
	else
		return 0;
}

- (NSString*)currentOutputDataSourceTitle
{
    return [mCurrentOutputDeviceObject currentOutputDataSourceTitle];
}

- (AudioStreamBasicDescription)currentOutputStreamDescription
{
    return [[mCurrentOutputDeviceObject currentOutputStream] streamDescription];
}

- (int)numberOfOutputChannels
{
	AudioStreamObject *object =	[mCurrentOutputDeviceObject currentOutputStream];
	if(object)
		return [object streamDescription].mChannelsPerFrame;
	else
		return 0;
}

- (AudioDeviceObject*)queryCurrentInputDevice
{
    AudioDeviceID theDefaultDeviceID = kAudioDeviceUnknown;
    UInt32 theSize = sizeof(AudioDeviceID);
    OSStatus theStatus = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice,
                                            &theSize, &theDefaultDeviceID);    
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice)" withOSStatus:theStatus];
        return NULL;
    }
    
    return [self deviceObjectForDeviceID:theDefaultDeviceID];
}

- (AudioDeviceObject*)queryCurrentOutputDevice
{
    AudioDeviceID theDefaultDeviceID = kAudioDeviceUnknown;
    UInt32 theSize = sizeof(AudioDeviceID);
    OSStatus theStatus = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &theSize, &theDefaultDeviceID);    
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice)" withOSStatus:theStatus];
        return NULL;
    }
    
    return [self deviceObjectForDeviceID:theDefaultDeviceID];
}

- (NSArray*)arrayOfArray:(NSArray*)array direction:(short)direction
{
    NSMutableArray *array_ = [NSMutableArray arrayWithCapacity:0];
    
    int index;
    for(index=0; index<[array count]; index++)
    {
        AudioDeviceObject *obj = [array objectAtIndex:index];
        if([obj hasDirection:direction])
            [array_ addObject:obj];
    }
    
    return array_;
}

- (NSArray*)titlesArrayFromArray:(NSArray*)array direction:(short)direction
{
    NSArray *array_ = [self arrayOfArray:array direction:direction];
    NSMutableArray *titles = [NSMutableArray arrayWithCapacity:[array_ count]];
    
    int index;
    for(index=0; index<[array_ count]; index++)
        if([[array_ objectAtIndex:index] title])
            [titles addObject:[[array_ objectAtIndex:index] title]];
    
    return titles;
}

- (NSArray*)inputDeviceTitlesArray
{
    return [self titlesArrayFromArray:mDeviceArray direction:DIRECTION_INPUT];
}

- (NSArray*)outputDeviceTitlesArray
{
    return [self titlesArrayFromArray:mDeviceArray direction:DIRECTION_OUTPUT];
}

- (NSArray*)inputStreamTitlesArray
{
    return [mCurrentInputDeviceObject streamTitlesArrayForDirection:DIRECTION_INPUT];
}

- (NSArray*)outputStreamTitlesArray
{
    return [mCurrentOutputDeviceObject streamTitlesArrayForDirection:DIRECTION_OUTPUT];
}

- (NSArray*)inputDataSourceTitlesArray
{
    return [mCurrentInputDeviceObject dataSourceTitlesArrayForDirection:DIRECTION_INPUT];
}

- (NSArray*)outputDataSourceTitlesArray
{
    return [mCurrentOutputDeviceObject dataSourceTitlesArrayForDirection:DIRECTION_OUTPUT];
}

- (NSString*)inputRequestedQuality
{
    NSString *s = [mCurrentInputDeviceObject inputRequestedQuality];
    if(s)
        return s;
    else
        return @"-";
}

- (NSString*)inputObtainedQuality
{
    NSString *s = [mCurrentInputDeviceObject inputObtainedQuality];
    if(s)
        return s;
    else
        return @"-";
}

- (NSString*)outputRequestedQuality
{
    NSString *s = [mCurrentOutputDeviceObject outputRequestedQuality];
    if(s)
        return s;
    else
        return @"-";
}

- (NSString*)outputObtainedQuality
{
    NSString *s = [mCurrentOutputDeviceObject outputObtainedQuality];
    if(s)
        return s;
    else
        return @"-";
}

- (UInt32)currentInputDeviceID
{
    if(mCurrentInputDeviceObject)
        return [mCurrentInputDeviceObject deviceID];
    else
        return kAudioDeviceUnknown;
}

- (UInt32)currentOutputDeviceID
{
    if(mCurrentOutputDeviceObject)
        return [mCurrentOutputDeviceObject deviceID];
    else
        return kAudioDeviceUnknown;
}

@end

@implementation AudioDeviceManager (Clients)

- (id)clientObjectForClient:(id)client deviceID:(AudioDeviceID)deviceID ioProc:(AudioDeviceIOProc)ioProc
{
    NSEnumerator *enumerator = [mClientArray objectEnumerator];
    CAClientObject *object = NULL;
    while(object = [enumerator nextObject])
    {
        if([object client] == client && [object deviceID] == deviceID && [object ioProc] == ioProc)
            return object;
    }
    return NULL;
}

- (id)registerClient:(id)client deviceID:(AudioDeviceID)deviceID ioProc:(AudioDeviceIOProc)ioProc userData:(id)userData notifySelector:(SEL)notifySel
{
    CAClientObject *object = [self clientObjectForClient:client deviceID:deviceID ioProc:ioProc];
    if(object == NULL)
    {
        object = [[[CAClientObject alloc] init] autorelease];
        [mClientArray addObject:object];
    }
    
    [object setClient:client];
    [object setDeviceID:deviceID];
    [object setIOProc:ioProc];
    [object setUserData:userData];
    [object setNotifySelector:notifySel];
    
    [[self deviceObjectForDeviceID:deviceID] setIOProc:ioProc];
    
    return object;
}

- (void)removeClient:(id)ticket
{
    CAClientObject *object = ticket;
    if(object)
        [mClientArray removeObject:object];
}

- (BOOL)addAndStartIOProc:(id)ticket
{
    CAClientObject *object = ticket;
    if(object)
        return [ticket addIOProc] && [ticket startIOProc];
    else
        return NO;
}

- (BOOL)stopAndRemoveIOProc:(id)ticket
{
    CAClientObject *object = ticket;
    if(object)
        return [object stopIOProc] && [object removeIOProc];
    else
        return NO;
}

- (BOOL)isRunningClient:(id)ticket
{
    CAClientObject *object = ticket;
    if(object)
        return [object isRunning];
    else
        return NO;
}

@end

