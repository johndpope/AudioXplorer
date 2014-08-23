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
#import "CAStreamObject.h"
#import "CADeviceObject.h"
#import "CADeviceManager.h"

@implementation AudioStreamObject

+ (AudioStreamObject*)streamWithID:(AudioStreamID)streamID direction:(short)direction deviceParent:(AudioDeviceObject*)deviceParent
{
    AudioStreamObject *obj = [[AudioStreamObject alloc] init];
    [obj setStreamID:streamID];
    [obj setDirection:direction];
    [obj setDeviceParent:deviceParent];
    [obj update];
    return [obj autorelease];
}

- (id)init
{
    if(self = [super init])
    {
        mDeviceParent = NULL;
        mDirection = DIRECTION_NONE;
        mTitle = NULL;

        mStreamFormats = NULL;

        mStreamPhysicalFormatMatched = NO;
        
        mRequestedSampleRate = 44100.0;
        mRequestedBitsPerChannel = 32;
        mRequestedChannelsPerFrame = -1;	// any number of channels
    }
    return self;
}

- (void)dealloc
{
    if(mStreamFormats)
        free(mStreamFormats);
        
    [mDeviceParent release];
    [mTitle release];
    [super dealloc];
}

- (void)setStreamID:(AudioStreamID)streamID
{
    mStreamID = streamID;
    [self update];
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

- (void)setRequestedSampleRate:(Float64)sample
{
    mRequestedSampleRate = sample;
}

- (void)setRequestedBitsPerChannel:(unsigned)bits
{
    mRequestedBitsPerChannel = bits;
}

- (void)setRequestedChannelsPerFrame:(unsigned)channels
{
    mRequestedChannelsPerFrame = channels;
}

- (NSString*)title
{
    return mTitle;
}

- (void)update
{
    [mTitle autorelease];
    mTitle = [[self humanDescriptionOfStreamFormat:[self streamDescriptionForStreamID:mStreamID]] retain];
}

- (AudioStreamBasicDescription)streamDescriptionForStreamID:(AudioStreamID)streamID
{
    OSStatus theStatus = noErr;
    UInt32 theSize;

    AudioStreamBasicDescription format;

    theStatus = AudioStreamGetPropertyInfo(streamID, 0, kAudioDevicePropertyStreamFormat,  &theSize, NULL);
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioStreamGetPropertyInfo(kAudioDevicePropertyStreamFormat)" withOSStatus:theStatus];
        return format;
    }

    theStatus = AudioStreamGetProperty(streamID, 0, kAudioDevicePropertyStreamFormat, &theSize, &format);
    if(theStatus!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioStreamGetProperty(kAudioDevicePropertyStreamFormat)" withOSStatus:theStatus];
        return format;
    }

    return format;
}

- (AudioStreamBasicDescription)streamDescription
{
    return [self streamDescriptionForStreamID:mStreamID];
}

- (NSString*)stringWithOSType:(OSType)type
{
    char *t = (char*)&type;
    return [NSString stringWithFormat:@"%c%c%c%c", t[0], t[1], t[2], t[3]];
}

- (NSString*)humanDescriptionOfStreamFormat:(AudioStreamBasicDescription)descr
{
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [numberFormatter setFormat:@"#,###.00"];
    [numberFormatter setThousandSeparator:@"'"];

    NSString *rate = [numberFormatter stringForObjectValue:[NSNumber numberWithFloat:descr.mSampleRate]];

    return [NSString stringWithFormat:NSLocalizedString(@"%@ - %@ Hz - %hi bits/channel", NULL), [self stringWithOSType:descr.mFormatID], rate, descr.mBitsPerChannel];
}

- (int)indexOfBestMatchedFormatForRate:(float)rate bits:(int)bits channels:(int)channels
{
    while(bits >= 8)
    {
        int index;
        for(index=0; index<mNumberOfStreams; index++)
        {
            AudioStreamBasicDescription format = mStreamFormats[index];
            // mSampleRate = 0, the device can sample at any rate (see Daisy example in the MacOS X Dev CD)
            if( (format.mSampleRate == rate || format.mSampleRate == 0)
                && format.mBitsPerChannel == bits
                && (format.mChannelsPerFrame == channels || channels == -1))
            {
                if(format.mSampleRate == 0)
                    mStreamFormats[index].mSampleRate = rate;
                return index;
            }
        }
        
        // Decrease requested bits
        bits -= 2;
    }
    
    return -1;
}

- (void)findBestPhysicalFormatNeeded
{
    OSStatus	status = noErr;
    UInt32	outSize;
    Boolean	outWritable;
    
    mStreamPhysicalFormatMatched = NO;

    status =  AudioDeviceGetPropertyInfo([mDeviceParent deviceID], 0, mDirection, kAudioStreamPropertyPhysicalFormats,  &outSize, &outWritable);
    if(status!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceGetPropertyInfo(kAudioStreamPropertyPhysicalFormats)" withOSStatus:status];
        return;
    }
    
    if(mStreamFormats)
        free(mStreamFormats);
    mStreamFormats = malloc(outSize);

    status = AudioDeviceGetProperty([mDeviceParent deviceID], 0, mDirection, kAudioStreamPropertyPhysicalFormats, &outSize, mStreamFormats);
    if(status!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioDeviceGetProperty(kAudioStreamPropertyPhysicalFormats)" withOSStatus:status];
        return;
    }

    // Find the best matched format
    
    mNumberOfStreams = outSize/sizeof(AudioStreamBasicDescription);
    if(mNumberOfStreams<=0)
    {
        [AudioDeviceManager log:@"No stream"];
        return;
    }

    int index = [self indexOfBestMatchedFormatForRate:mRequestedSampleRate
                            bits:mRequestedBitsPerChannel
                            channels:mRequestedChannelsPerFrame];
                            
    mStreamPhysicalFormatMatched = index>-1;

    if(mStreamPhysicalFormatMatched)
        mStreamPhysicalFormat = mStreamFormats[index];    
        
    // Set the best matched format to be used
    
    if(mStreamPhysicalFormatMatched == NO)
    {
        [AudioDeviceManager log:@"No matched stream format"];
        return;
    } else
        [AudioDeviceManager log:[NSString stringWithFormat:@"Stream %d matched", index]];
        	
    status = AudioStreamGetPropertyInfo(mStreamID, 0, kAudioStreamPropertyPhysicalFormat, &outSize, &outWritable);
    if(status!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioStreamGetPropertyInfo(kAudioStreamPropertyPhysicalFormat)" withOSStatus:status];
        return;
    }
    
    /*AudioStreamBasicDescription physicalFormat;
    status = AudioStreamGetProperty(mStreamID, 0, kAudioStreamPropertyPhysicalFormat, &outSize, &physicalFormat);
    if(status!=noErr)
    {
        [AudioDeviceManager displayCoreAudioMessage:@"AudioStreamGetProperty(kAudioStreamPropertyPhysicalFormat)" withOSStatus:status];
        return;
    }*/
        
    if(outWritable)
    {
        status = AudioStreamSetProperty(mStreamID, 0, 0, kAudioStreamPropertyPhysicalFormat, outSize, &mStreamPhysicalFormat); 
        if(status!=noErr)
        {
            [AudioDeviceManager displayCoreAudioMessage:@"AudioStreamSetProperty(kAudioStreamPropertyPhysicalFormat)" withOSStatus:status];
            return;
        }
    } else
        [AudioDeviceManager log:@"kAudioStreamPropertyPhysicalFormat is not writable!"];
}

- (NSString*)composeQualityStringWithRate:(int)rate bits:(int)bits channels:(int)channels
{
	if(channels == -1)
		return [NSString stringWithFormat:@"%d Hz, %d bits", rate, bits];
	else
		return [NSString stringWithFormat:@"%d Hz, %d bits, %d channels", rate, bits, channels];
}

- (NSString*)requestedQuality
{
    return [self composeQualityStringWithRate:mRequestedSampleRate bits:mRequestedBitsPerChannel
                            channels:mRequestedChannelsPerFrame];
}

- (NSString*)obtainedQuality
{
    if(mStreamPhysicalFormatMatched)
    {
        return [self composeQualityStringWithRate:mStreamPhysicalFormat.mSampleRate
                                bits:mStreamPhysicalFormat.mBitsPerChannel
                                channels:mStreamPhysicalFormat.mChannelsPerFrame];
    } else
        return NSLocalizedString(@"Not available", NULL);
}

@end
