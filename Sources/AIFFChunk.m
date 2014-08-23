
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

#import "AIFFChunk.h"

#import <libkern/OSByteOrder.h>

@implementation AIFFChunk

#define READ_BUFFER(target, source, size) memcpy(target, source, size); \
                                            source += size;

+ (NSString*)stringWithOSType:(OSType)type
{
    char *t = (char*)&type;
    return [NSString stringWithFormat:@"%c%c%c%c", t[0], t[1], t[2], t[3]];
}

+ (AIFFChunk*)readAIFFHeaderInData:(const void**)dataPtr errorMessage:(NSMutableString*)error
{
    UInt32 ckID;
    READ_BUFFER(&ckID, *dataPtr, sizeof(UInt32));
    if(ckID != OSSwapHostToBigConstInt32(FORMID))
    {
        [error setString:[NSString stringWithFormat:NSLocalizedString(@"First chunk is not 'FORM' but '%@'", NULL), [AIFFChunk stringWithOSType:ckID]]];
        return NULL;
    }
    if(PRINT_LOG)
        NSLog(@"Form %@", [AIFFChunk stringWithOSType:ckID]);

    long ckSize = 0;
    READ_BUFFER(&ckSize, *dataPtr, sizeof(long));
	ckSize = OSSwapBigToHostInt32(ckSize);
    if(PRINT_LOG)
        NSLog(@"Length %d", ckSize);
    
    UInt32 formType;
    READ_BUFFER(&formType, *dataPtr, sizeof(UInt32));
	formType = OSSwapBigToHostInt32(formType);
    if(PRINT_LOG)
        NSLog(@"Form type %@", [AIFFChunk stringWithOSType:formType]);

    AIFFChunk *theChunk = [[AIFFChunk alloc] initWithID:formType];
    
    return [theChunk autorelease];
}

+ (AIFFChunk*)readOneChunkInData:(const void**)dataPtr headerChunk:(AIFFChunk*)headerChunk errorMessage:(NSMutableString*)error
{    
    UInt32 ckID;
    long ckSize = 0;
    READ_BUFFER(&ckID, *dataPtr, sizeof(UInt32));
    READ_BUFFER(&ckSize, *dataPtr, sizeof(long));
    
	ckID = OSSwapBigToHostInt32(ckID);
	ckSize = OSSwapBigToHostInt32(ckSize);

    AIFFChunk *theChunk = [[AIFFChunk alloc] initWithID:ckID];
    switch(ckID) {
        case FormatVersionID:
            [theChunk readChunkFormatVersionID:*dataPtr];
            break;
        case CommonID:
            [theChunk readChunkCommonID:*dataPtr headerType:headerChunk->mChunkID];
            if(theChunk->mCommonChunk.compressionType != NoneType)
            {
                [error setString:[NSString stringWithFormat:NSLocalizedString(@"AudioXplorer doesn't support compressed file yet (%@).", NULL), [AIFFChunk stringWithOSType:theChunk->mCommonChunk.compressionType]]];
                [theChunk release];
                return NULL;
            }
            break;
        case SoundDataID:
            [theChunk readChunkSoundDataID:*dataPtr size:ckSize];
            break;
        default:
            if(ckSize%2!=0)
                ckSize++;
                
            //NSLog(@"Unknown chunk ID %@", [AIFFChunk stringWithOSType:ckID]);
            break;
    }
    *dataPtr += ckSize;
    return [theChunk autorelease];
}

- (id)initWithID:(UInt32)ckID
{
    if(self = [super init])
    {
        mChunkID = ckID;
        [self setCkID:ckID];
        mSoundDataSize = 0;
        mSoundDataBuffer = NULL;
    }
    return self;
}

- (void)dealloc
{
    if(mSoundDataBuffer)
        free(mSoundDataBuffer);
    [super dealloc];
}

- (void)writeToData:(NSMutableData*)data
{
    switch(mChunkID) {
        case FORMID:
		{
			ContainerChunk			formChunk;
			
			formChunk.ckID		= OSSwapHostToBigInt32(mContainerChunk.ckID);
			formChunk.ckSize	= OSSwapHostToBigInt32(mContainerChunk.ckSize);
			formChunk.formType	= OSSwapHostToBigInt32(mContainerChunk.formType);

            [data appendBytes:&formChunk length:sizeof(formChunk)];
            break;
		}
        case FormatVersionID:
		{
			FormatVersionChunk		formatVersionChunk;

			formatVersionChunk.ckID			= OSSwapHostToBigInt32(mFormatVersionChunk.ckID);
			formatVersionChunk.ckSize		= OSSwapHostToBigInt32(mFormatVersionChunk.ckSize);
			formatVersionChunk.timestamp	= OSSwapHostToBigInt32(mFormatVersionChunk.timestamp);

            [data appendBytes:&formatVersionChunk length:sizeof(formatVersionChunk)];
            break;
		}
        case CommonID:
		{
			ExtCommonChunk			commonChunk;

			commonChunk.ckID			= OSSwapHostToBigInt32(mCommonChunk.ckID);
			commonChunk.ckSize			= OSSwapHostToBigInt32(mCommonChunk.ckSize);
			commonChunk.numChannels		= OSSwapHostToBigInt16(mCommonChunk.numChannels);
			commonChunk.numSampleFrames	= OSSwapHostToBigInt32(mCommonChunk.numSampleFrames);
			commonChunk.sampleSize		= OSSwapHostToBigInt16(mCommonChunk.sampleSize);
			commonChunk.sampleRate		= mCommonChunk.sampleRate;	// doesn't need to be swapped
			commonChunk.compressionType	= OSSwapHostToBigInt32(mCommonChunk.compressionType);
			commonChunk.compressionName[0] = 0;

            [data appendBytes:&commonChunk length:sizeof(commonChunk)];
            break;
		}
        case SoundDataID:
		{
			SoundDataChunk			soundDataChunk;

			soundDataChunk.ckID			= OSSwapHostToBigInt32(mSoundDataChunk.ckID);
			soundDataChunk.ckSize		= OSSwapHostToBigInt32(mSoundDataChunk.ckSize);
			soundDataChunk.offset		= OSSwapHostToBigInt32(mSoundDataChunk.offset);
			soundDataChunk.blockSize	= OSSwapHostToBigInt32(mSoundDataChunk.blockSize);

            [data appendBytes:&soundDataChunk length:sizeof(soundDataChunk)];
            break;
		}
    }

}

- (void)setCkID:(UInt32)ckID
{
    switch(mChunkID) {
        case FORMID:
            mContainerChunk.ckID = ckID;
            break;
        case FormatVersionID:
            mFormatVersionChunk.ckID = ckID;
            break;
        case CommonID:
            mCommonChunk.ckID = ckID;
            break;
        case SoundDataID:
            mSoundDataChunk.ckID = ckID;
            break;
    }
}

- (void)setCkDataSize:(long)size
{
    mContainerChunk.ckSize = size;
}

- (void)setFormType:(UInt32)type
{
    mContainerChunk.formType = type;
}

- (void)setckSize:(long)size
{
    switch(mChunkID) {
        case FormatVersionID:
            mFormatVersionChunk.ckSize = size;
            break;
        case CommonID:
            mCommonChunk.ckSize = size;
            break;
        case SoundDataID:
            mSoundDataChunk.ckSize = size;
            break;
    }
}

- (void)setTimeStamp:(unsigned long)stamp
{
    mFormatVersionChunk.timestamp = stamp;
}

- (void)setNumChannels:(short)channels
{
    mCommonChunk.numChannels = channels;
}

- (void)setNumSampleFrames:(unsigned long)frames
{
    mCommonChunk.numSampleFrames = frames;
}

- (void)setSampleSize:(short)size
{
    mCommonChunk.sampleSize = size;
}

- (void)setSampleRate:(double)rate
{ 
    dtox80(&rate, &mCommonChunk.sampleRate);
}

- (void)setCompressionType:(UInt32)type
{
    mCommonChunk.compressionType = type;
}

- (void)setCompressionName:(char*)name
{
    mCommonChunk.compressionName[0] = 0;
}

- (void)setOffset:(unsigned long)offset
{
    mSoundDataChunk.offset = offset;
}

- (void)setBlockSize:(unsigned long)size
{
    mSoundDataChunk.blockSize = size;
}

- (UInt32)chunkID
{
    return mChunkID;
}

- (long)soundDataSize
{
    return mSoundDataSize;
}

- (void*)soundDataBuffer
{
    return mSoundDataBuffer;
}

- (unsigned long)numberOfSample
{
    return mCommonChunk.numSampleFrames;
}

- (short)numberOfChannels
{
    return mCommonChunk.numChannels;
}

- (short)sampleSize
{
    return mCommonChunk.sampleSize;
}

- (double)rate
{
    return x80tod(&mCommonChunk.sampleRate);
}

- (void)readChunkFormatVersionID:(const void*)dataPtr
{
    READ_BUFFER(&mFormatVersionChunk.timestamp, dataPtr, sizeof(unsigned long));
	mFormatVersionChunk.timestamp = OSSwapBigToHostInt32(mFormatVersionChunk.timestamp);
    if(PRINT_LOG)
    {
        NSLog(@"* Format Version Chunk *");
        NSLog(@"Time stamp %u", mFormatVersionChunk.timestamp); 
    }
}

- (void)readChunkCommonID:(const void*)dataPtr headerType:(UInt32)headerType
{
    READ_BUFFER(&mCommonChunk.numChannels, dataPtr, sizeof(short));
	mCommonChunk.numChannels = OSSwapBigToHostInt16(mCommonChunk.numChannels);
    READ_BUFFER(&mCommonChunk.numSampleFrames, dataPtr, sizeof(unsigned long));
	mCommonChunk.numSampleFrames = OSSwapBigToHostInt32(mCommonChunk.numSampleFrames);
    READ_BUFFER(&mCommonChunk.sampleSize, dataPtr, sizeof(short));
	mCommonChunk.sampleSize = OSSwapBigToHostInt16(mCommonChunk.sampleSize);
    READ_BUFFER(&mCommonChunk.sampleRate, dataPtr, sizeof(extended80));	// extended80s don't need swapping
    if(headerType == AIFCID)
    {
        READ_BUFFER(&mCommonChunk.compressionType, dataPtr, sizeof(UInt32));
		mCommonChunk.compressionType = OSSwapBigToHostInt32(mCommonChunk.compressionType);
    } else
        mCommonChunk.compressionType = NoneType;

    double rate = x80tod(&mCommonChunk.sampleRate);
    
    if(PRINT_LOG)
    {
        NSLog(@"* Common Chunk *");
        NSLog(@"Number of channels %hi", mCommonChunk.numChannels); 
        NSLog(@"Number of sample frames %u", mCommonChunk.numSampleFrames);
        NSLog(@"Sample size %hi", mCommonChunk.sampleSize);
        NSLog(@"Sample rate %f", rate);
        if(headerType == AIFCID)
            NSLog(@"Compression type %@", [AIFFChunk stringWithOSType:mCommonChunk.compressionType]);
    }
}

- (void)readChunkSoundDataID:(const void*)dataPtr size:(long)size
{
    READ_BUFFER(&mSoundDataChunk.offset, dataPtr, sizeof(unsigned long));
	mSoundDataChunk.offset = OSSwapBigToHostInt32(mSoundDataChunk.offset);
    READ_BUFFER(&mSoundDataChunk.blockSize, dataPtr, sizeof(unsigned long));
    
    mSoundDataSize = size-2*sizeof(unsigned long);
    mSoundDataBuffer = malloc(mSoundDataSize);
    
    memcpy(mSoundDataBuffer, dataPtr, mSoundDataSize);
    
    if(PRINT_LOG)
    {
        NSLog(@"* SoundData Chunk *");
        NSLog(@"Offset %u", mSoundDataChunk.offset); 
        NSLog(@"Block size %u", mSoundDataChunk.blockSize);
        NSLog(@"Sound data size %u", mSoundDataSize);
    }
}

@end
