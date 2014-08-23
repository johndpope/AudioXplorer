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

#import "AXAUComponent.h"
#import "AudioConstants.h"
#import <AudioUnit/AudioUnitCarbonView.h>

@implementation AXAUComponent

OSStatus inputCallback(void     *inRefCon, 
                        AudioUnitRenderActionFlags      *ioActionFlags,
                        const AudioTimeStamp            *inTimeStamp, 
                        UInt32                          inBusNumber,
                        UInt32                          inNumFrames, 
                        AudioBufferList                 *ioData)
{
    AXAUComponent *component = inRefCon;
    id<DataSourceProtocol> data = component->mInputCallbackData;
    unsigned short channel = component->mInputCallbackDataChannel;
    AudioBufferList *buffer = ioData;
    
    short c;
    for(c=0; c<buffer->mNumberBuffers; c++)
    {
        unsigned short dataChannel = channel==STEREO_CHANNEL?c:channel;
        
        Float32* ptr = [data dataBasePtrOfChannel:dataChannel];
        ptr += (long)(inTimeStamp->mSampleTime);

        unsigned long byteLength = MIN(buffer->mBuffers[c].mDataByteSize,
                ([data maxIndex]-inTimeStamp->mSampleTime)*sizeof(Float32));
        
        memcpy(buffer->mBuffers[c].mData, ptr, byteLength);
    }
    
    return noErr;
}

void auCarbonViewCallback(
  void *                      inUserData,
  AudioUnitCarbonView         inView,
  const AudioUnitParameter *  inParameter,
  AudioUnitCarbonViewEventID  inEvent,
  const void *                inEventParam
)
{
}

OSStatus carbonEventCallback(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData)
{
    AXAUComponent *component = (AXAUComponent*)inUserData;
    [component closeUI];
    return noErr;
}

OSStatus carbonButtonEventCallback(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData)
{
  //  AXAUComponent *component = (AXAUComponent*)inUserData;
    return noErr;
}

+ (AXAUComponent*)componentWithDescription:(ComponentDescription)description name:(NSString*)name
{
    AXAUComponent *component = [[AXAUComponent alloc] init];
    [component setDescription:description];
    [component setName:name];
    return [component autorelease];
}

- (id)init
{
    if(self = [super init])
    {
        mName = NULL;
        mComponent = NULL;
        mEditorDescriptionArray = NULL;
        mCarbonWindow = NULL;
        mInputCallbackData = NULL;
        mOpened = NO;
        mHasUI = NO;
    }
    return self;
}

- (void)dealloc
{
    [self close];
    
    if(mEditorDescriptionArray)
        free(mEditorDescriptionArray);
    
    [mName release];
    
    [super dealloc];
}

- (void)setDescription:(ComponentDescription)description
{
    mDescription = description;
}

- (void)setName:(NSString*)name
{
    [mName autorelease];
    mName = [name retain];
}

- (NSString*)title
{
    return mName;
    return [NSString stringWithFormat:@"%4.4s - %4.4s - %4.4s",
                        (char*)&mDescription.componentManufacturer,
                        (char*)&mDescription.componentType,
                        (char*)&mDescription.componentSubType];
}

- (NSComparisonResult)componentCompare:(AXAUComponent*)component
{
    return [[self title] caseInsensitiveCompare:[component title]];
}

- (void)findUIComponent
{
    // Setup the default UI
    mEditorDescription.componentType = kAudioUnitCarbonViewComponentType;
    mEditorDescription.componentSubType = 'gnrc';
    mEditorDescription.componentManufacturer = 'appl';
    mEditorDescription.componentFlags = 0;
    mEditorDescription.componentFlagsMask = 0;

    // Get the property size (if it exists for the AudioUnit)
    UInt32 propertySize;
    OSStatus err = AudioUnitGetPropertyInfo(mAudioUnit,
                                            kAudioUnitProperty_GetUIComponentList,
                                            kAudioUnitScope_Global,
                                            0,
                                            &propertySize,
                                            NULL);
    if (err) {
        // No custom UI, we are done.
        mHasUI = YES;
        return;
    }
    
    // Allocate enough memory
    mAUEditorCount = propertySize / sizeof(ComponentDescription);
    
    if(mEditorDescriptionArray)
        free(mEditorDescriptionArray);
        
    mEditorDescriptionArray = malloc(propertySize);
    
    // Get the property
    err = AudioUnitGetProperty(mAudioUnit,
                            kAudioUnitProperty_GetUIComponentList,
                            kAudioUnitScope_Global,
                            0,
                            mEditorDescriptionArray,
                            &propertySize);
    if (err) {
        NSLog(@"Unable to get the UI editor, error %d", err);
        free(mEditorDescriptionArray);
        mEditorDescriptionArray = NULL;
        return;
    }
    
    mEditorDescription = mEditorDescriptionArray[0];
    
    mHasUI = YES;
}

- (BOOL)open
{
    [self close];
    
    // Find the component
    mComponent = FindNextComponent (NULL, &mDescription);
    if (mComponent == NULL) {
        NSLog(@"Unable to find the component (open)");
        return NO;
    }
    
    // Open the component
    OSErr result = OpenAComponent (mComponent, &mAudioUnit);
    if (result) {
        NSLog(@"OpenAComponent error %d", result);
        return NO;
    }

    // Initialize the component
    result = AudioUnitInitialize(mAudioUnit);
    if (result) {
        NSLog(@"AudioUnitInitialize error %d", result);
        CloseComponent(mAudioUnit);
        return NO;
    }
    
    // Register the callback
    AURenderCallbackStruct theCallback;
    theCallback.inputProc = inputCallback;
    theCallback.inputProcRefCon = self;
    
    result = AudioUnitSetProperty(mAudioUnit, 
                                kAudioUnitProperty_SetRenderCallback,
                                kAudioUnitScope_Input,
                                0,
                                &theCallback,
                                sizeof (theCallback)); 
    if (result) {
        NSLog(@"Unable to register the callback, error %d", result);
        AudioUnitUninitialize(mAudioUnit);
        CloseComponent(mAudioUnit);
        return NO;
    }

    // Set the input data format (of the callback)
    AudioStreamBasicDescription theStreamFormat;
    theStreamFormat.mSampleRate = 44100.0;
    theStreamFormat.mFormatID = kAudioFormatLinearPCM;
    theStreamFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked 
                                   | kAudioFormatFlagIsNonInterleaved;
    theStreamFormat.mBytesPerPacket = 4;        
    theStreamFormat.mFramesPerPacket = 1;       
    theStreamFormat.mBytesPerFrame = 4;         
    theStreamFormat.mChannelsPerFrame = 2;      
    theStreamFormat.mBitsPerChannel = sizeof (Float32) * 8;     

    result = AudioUnitSetProperty (mAudioUnit, 
                      kAudioUnitProperty_StreamFormat,
                      kAudioUnitScope_Input,
                      0,
                      &theStreamFormat,
                      sizeof (theStreamFormat));
    if (result) {
        NSLog(@"Unable to set the stream format of the callback, error %d", result);
        AudioUnitUninitialize(mAudioUnit);
        CloseComponent(mAudioUnit);
        return NO;
    }

    // Find the UI component
    [self findUIComponent];
    
    // The component is now opened
    mOpened = YES;
    
    return YES;
}

- (BOOL)close
{
    if(mOpened == NO) return YES;

    // Uninitialize the component
    OSErr result = AudioUnitUninitialize(mAudioUnit);
    if (result) {
        NSLog(@"AudioUnitUninitialize error %d", result);
        return NO;
    }

    // Close the component
    result = CloseComponent(mAudioUnit);
    if (result) {
        NSLog(@"CloseComponent error %d", result);
        return NO;
    }
    
    // The component is closed
    mOpened = NO;
    
    return YES;
}

- (BOOL)openUI
{
    if(mOpened == NO)
        if([self open] == NO)
            return NO;
            
    if(mHasUI == NO) return NO;

    if(mCarbonWindow)
    {
        [mCarbonWindow makeKeyAndOrderFront:nil];
        return YES;
    }

    // Find the component
    mEditorComponent = FindNextComponent(NULL, &mEditorDescription);
    if(mEditorComponent == NULL)
    {
        NSLog(@"Unable to find the editor component");
        return NO;
    }
    
    // Open the component
    OSErr err = OpenAComponent(mEditorComponent, &mEditorView);
    if(err)
    {
        NSLog(@"OpenAComponent error %d", err);
        return NO;
    }

    // Create the carbon view for the component UI
    CFBundleRef bundleRef = CFBundleGetMainBundle();
    IBNibRef 	nibRef;

    err = CreateNibReferenceWithCFBundle(bundleRef, CFSTR("CarbonWindow"), &nibRef);
    if(err)
    {
        NSLog(@"Failed to create carbon nib reference, error %d", err);
        return NO;
    }

 //   CFRelease(bundleRef);

    // Create the carbon window
    err = CreateWindowFromNib(nibRef, CFSTR("Window"), &mWindowRef);
    if (err)
    {
        NSLog(@"Failed to create carbon window from nib, error %d", err);
        return NO;
    }

    DisposeNibReference(nibRef);
    
    // Create the cocoa window
    mCarbonWindow = [[NSWindow alloc] initWithWindowRef:mWindowRef];
    [mCarbonWindow setDelegate:self];
    [mCarbonWindow setTitle:mName];
    
    // Get the root control (the window itself)
    ControlRef theRootControl;
    err = GetRootControl(mWindowRef, &theRootControl);
    if(err)
    {
        NSLog(@"GetRootControl error %d", err);
        return NO;
    }
    
    Float32Point theLocation = { 0, 0 };
    Float32Point theSize = { 400, 100 };
    ControlRef theViewPane;
        
    err = AudioUnitCarbonViewCreate(mEditorView, mAudioUnit, mWindowRef,
                            theRootControl, &theLocation, &theSize, &theViewPane);
    if(err)
    {
        NSLog(@"AudioUnitCarbonViewCreate error %d", err);
        return NO;
    }

    err = AudioUnitCarbonViewSetEventListener(mEditorView, auCarbonViewCallback, self);
    if(err)
    {
        NSLog(@"AudioUnitCarbonViewSetEventListener error %d", err);
        return NO;
    }
    
    // Change the window size to fit the UI
    Rect r;
    GetControlBounds(theViewPane, &r);
    theSize.x = r.right-r.left;
    theSize.y = r.bottom-r.top;
    SizeWindow(mWindowRef, theSize.x, theSize.y, YES);
    
    // Show the window now
//    [mCarbonWindow makeKeyAndOrderFront:nil];
    [mCarbonWindow setIsVisible:YES];

    // Register the close window event callback routine
    EventTypeSpec event;
    event.eventClass = kEventClassWindow;
    event.eventKind = kEventWindowClosed;
    
    InstallWindowEventHandler(mWindowRef,
                                NewEventHandlerUPP(carbonEventCallback),
                                1,
                                &event,
                                self,
                                NULL);
    
    return YES;
}

- (BOOL)closeUI
{
    if(mCarbonWindow)
    {
        [mCarbonWindow close];
        mCarbonWindow = NULL;
        mCarbonWindow = NULL;
    }
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
   /* if([notification object] == mCarbonWindow && mCarbonWindow && mWindowRef)
    {
        DisposeWindow(mWindowRef);
        mWindowRef = NULL;
    }*/
}

- (BOOL)performEffectOnData:(id<DataSourceProtocol>)data channel:(unsigned short)channel parentWindow:(NSWindow*)parentWindow
{    
    if(mOpened == NO)
        if([self open] == NO)
            return NO;
            
    mInputCallbackData = data;
    mInputCallbackDataChannel = channel;
        
    short theNumberOfChannels = channel==STEREO_CHANNEL?2:1;
    long theNumberOfFramesPerSlice = 512;
    long theNumberOfFrames = [data maxIndex];
    long theNumberOfSlices = (float)theNumberOfFrames/theNumberOfFramesPerSlice;
    
    if(theNumberOfSlices<(float)theNumberOfFrames/theNumberOfFramesPerSlice)
        theNumberOfSlices++;
        
    AudioTimeStamp theTimeStamp;
    theTimeStamp.mSampleTime = 0;
    theTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    
    AudioBufferList *theAudioData = (AudioBufferList *)malloc(offsetof(AudioBufferList, mBuffers[theNumberOfChannels]));
    
    theAudioData->mNumberBuffers = theNumberOfChannels;
    
    short c;
    for (c = 0; c < theNumberOfChannels; c++) 
    {
        theAudioData->mBuffers[c].mNumberChannels = 1;
        theAudioData->mBuffers[c].mDataByteSize = theNumberOfFramesPerSlice * sizeof(Float32);
    }
    
    long slice;
    for (slice = 0; slice < theNumberOfSlices; slice++, theTimeStamp.mSampleTime += theNumberOfFramesPerSlice)
    {         
        AudioUnitRenderActionFlags theActionFlags = 0;
        
        for (c = 0; c < theNumberOfChannels; c++)
            theAudioData->mBuffers[c].mData = NULL;

        AudioUnitRender (mAudioUnit, 
                            &theActionFlags, 
                            &theTimeStamp, 
                            0, 
                            theNumberOfFramesPerSlice, 
                            theAudioData); 
        
        for (c = 0; c < theNumberOfChannels; c++)
        {
            unsigned short dataChannel = channel==STEREO_CHANNEL?c:channel;
            
            Float32* ptr = [data dataBasePtrOfChannel:dataChannel];
            ptr += (long)theTimeStamp.mSampleTime;

			// NOTE: par sécurité, on enlève 1 au dernier bloc à copier pour éviter de "taper" en-dehors
			//		 de la zone mémoire (je ne sais pas si c'est utile ici)
            unsigned long byteLength = MIN(theAudioData->mBuffers[c].mDataByteSize,
                    ([data maxIndex]-1-theTimeStamp.mSampleTime)*sizeof(Float32));
            memcpy(ptr, theAudioData->mBuffers[c].mData, byteLength);
        }
    }
    
    mInputCallbackData = NULL;
    
    free (theAudioData);
    
    return YES;
}

@end
