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

#import "CAPlaythruDevice.h"

@implementation CAPlaythruDevice

- (id)init
{
	if(self = [super init]) {
		// Allocate enough memory to hold 32 channels with 2048 bytes per frame at once (262 Kb)
		mRingBuffer = [[CARingBuffer alloc] initWithBufferSize:sizeof(Float32)*2048*32]; 
		
		mChannelMixer = [[CAChannelMixer alloc] init];
		
		mTempBuffer = nil;
		mTempBufferSize = 0;
		
		mEnabled = YES;
	}
	return self;
}

- (void)dealloc
{
	if(mTempBuffer)
		free(mTempBuffer);
		
	[mChannelMixer release];
	[mRingBuffer release];	
	[super dealloc];
}

- (void)setChannelMixer:(CAChannelMixer*)mixer
{
	[mChannelMixer autorelease];
	mChannelMixer = [mixer retain];
}

- (CAChannelMixer*)channelMixer
{
	return mChannelMixer;
}

- (void)setEnabled:(BOOL)flag
{
	mEnabled = flag;
}

- (BOOL)enabled
{
	return mEnabled;
}

- (void)startDevice
{
	[mChannelMixer prepare];
	[mRingBuffer start];
}

- (void)stopDevice
{
	[mRingBuffer stop];
}

- (void)writeDataFromAudioBufferList:(const AudioBufferList*)abl
{
	unsigned numberOfChannels = abl->mBuffers[0].mNumberChannels;
	unsigned numberOfFrames = abl->mBuffers[0].mDataByteSize/(sizeof(Float32)*numberOfChannels);
	
	// Allocate or reallocate the temporary buffer used to perform the channel mix
	if(mTempBuffer == 0) {
		mTempBufferSize = sizeof(Float32)*[mChannelMixer numberOfOutputChannels]*numberOfFrames;
		mTempBuffer = malloc(mTempBufferSize);
	} else if(mTempBufferSize != sizeof(Float32)*[mChannelMixer numberOfOutputChannels]*numberOfFrames) {
		mTempBufferSize = sizeof(Float32)*[mChannelMixer numberOfOutputChannels]*numberOfFrames;
		mTempBuffer = realloc(mTempBuffer, mTempBufferSize);
	}
	
	// Mix the input channel with the corresponding output channel
	[mChannelMixer mixOutputBuffer:mTempBuffer fromInputBuffer:abl->mBuffers[0].mData frameCount:numberOfFrames];
	
	// Write the mixing result buffer to the ring buffer (which is used later to read back data for the playthru)
	[mRingBuffer writeData:mTempBuffer ofSize:mTempBufferSize];		
}

- (void)readDataToAudioBufferList:(AudioBufferList*)abl
{
	if(mEnabled)	
		[mRingBuffer readData:abl->mBuffers[0].mData
					   ofSize:abl->mBuffers[0].mDataByteSize];	
	else
		[mRingBuffer readData:nil
					   ofSize:abl->mBuffers[0].mDataByteSize];	
}

- (Float32*)convertedBuffer
{
	return mTempBuffer;
}

- (long)convertedBufferSize
{
	return mTempBufferSize;
}

@end
