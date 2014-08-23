
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

#define PRINT_LOG 0

@interface AIFFChunk : NSObject {
    UInt32 mChunkID;
    ContainerChunk mContainerChunk;
    FormatVersionChunk mFormatVersionChunk;
    ExtCommonChunk mCommonChunk;
    SoundDataChunk mSoundDataChunk;
    long mSoundDataSize;
    void *mSoundDataBuffer;
}

+ (NSString*)stringWithOSType:(OSType)type;
+ (AIFFChunk*)readAIFFHeaderInData:(const void**)dataPtr errorMessage:(NSMutableString*)error;
+ (AIFFChunk*)readOneChunkInData:(const void**)dataPtr headerChunk:(AIFFChunk*)headerChunk errorMessage:(NSMutableString*)error;

- (id)initWithID:(UInt32)ckID;

- (void)writeToData:(NSMutableData*)data;

- (void)setCkID:(UInt32)ckID;
- (void)setCkDataSize:(long)size;
- (void)setFormType:(UInt32)type;
- (void)setckSize:(long)size;
- (void)setTimeStamp:(unsigned long)stamp;
- (void)setNumChannels:(short)channels;
- (void)setNumSampleFrames:(unsigned long)frames;
- (void)setSampleSize:(short)size;
- (void)setSampleRate:(double)rate;
- (void)setCompressionType:(UInt32)type;
- (void)setCompressionName:(char*)name;
- (void)setOffset:(unsigned long)offset;
- (void)setBlockSize:(unsigned long)size;

- (UInt32)chunkID;
- (long)soundDataSize;
- (void*)soundDataBuffer;
- (unsigned long)numberOfSample;
- (short)numberOfChannels;
- (short)sampleSize;
- (double)rate;

- (void)readChunkFormatVersionID:(const void*)dataPtr;
- (void)readChunkCommonID:(const void*)dataPtr headerType:(UInt32)headerType;
- (void)readChunkSoundDataID:(const void*)dataPtr size:(long)size;

@end
    