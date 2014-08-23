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

#import "AudioDataUndo.h"
#import "AudioDataAmplitude.h"
#import "AudioDataStruct.h"

@implementation AudioDataUndo

- (id)init
{
	if(self = [super init]) {
		mUndoDataObject = nil;
		unsigned channel;
		for(channel = 0; channel<MAX_CHANNEL; channel++) {
			mUndoBuffer[channel] = nil;
		}
	}
	return self;
}

- (void)dealloc
{
	unsigned channel;
	for(channel = 0; channel<MAX_CHANNEL; channel++) {
		if(mUndoBuffer[channel])
			free(mUndoBuffer[channel]);
	}
	[super dealloc];
}

- (void)setUndo:(id)data
{
	mUndoDataObject = data;
	if([data isKindOfClass:[AudioDataAmplitude class]]) {
		unsigned channel;
		for(channel = 0; channel<MAX_CHANNEL; channel++) {
			AudioDataBuffer buffer = [data dataBufferOfChannel:channel];
			if(buffer.dataBasePtr) {
				mUndoSize[channel] = buffer.dataCurSize;
				mUndoBuffer[channel] = realloc(mUndoBuffer[channel], mUndoSize[channel]);
				memcpy(mUndoBuffer[channel], buffer.dataBasePtr, mUndoSize[channel]);
			} else {
				if(mUndoBuffer[channel]) {
					free(mUndoBuffer[channel]);
					mUndoBuffer[channel] = nil;
				}
			}
		}
	}
}

- (BOOL)canUndoOnData:(id)data
{
	if(data && mUndoDataObject)
		return [data isKindOfClass:[AudioDataAmplitude class]];
	else if(data)
		return YES;
	else
		return NO;
}

- (BOOL)hasUndoData
{
	return mUndoDataObject != NULL;
}

- (void)performUndoOnData:(id)data
{
	if([data isKindOfClass:[AudioDataAmplitude class]]) {
		unsigned channel;
		for(channel = 0; channel<MAX_CHANNEL; channel++) {
			AudioDataBuffer buffer = [data dataBufferOfChannel:channel];
			if(mUndoBuffer[channel] != nil) {
				buffer.dataCurSize = mUndoSize[channel];
				//buffer.dataBasePtr = realloc(buffer.dataBasePtr, mUndoSize[channel]);
				memcpy(buffer.dataBasePtr, mUndoBuffer[channel], mUndoSize[channel]);
				free(mUndoBuffer[channel]);
				mUndoBuffer[channel] = NULL;
			} else {
				if(buffer.dataBasePtr) {
					free(buffer.dataBasePtr);
					buffer.dataBasePtr = nil;
				}
			}
		}
		mUndoDataObject = NULL;
	}
}

@end
