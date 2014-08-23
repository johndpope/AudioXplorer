
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

#import "AIFFCodec.h"
#import "AIFFChunk.h"

#import <libkern/OSByteOrder.h>

#define LEFT 0
#define RIGHT 1
#define STEREO 2
#define DEFAULT_RATE 44100

@implementation AIFFCodec

- (id)initWithContentsOfFile:(NSString*)path errorMessage:(NSMutableString*)error
{
    if(self = [super init])
    {
        mErrorMessage = error;
        
        mChunkArray = [[NSMutableArray alloc] init];
        mData = [[NSData dataWithContentsOfFile:path] retain];
        BOOL success = mData != NULL;
        if(mData)
        {
            success = [self parseChunkInData:mData];
            [mData release];
            mData = NULL;
        }
        
        if(success == NO)
        {
            [self dealloc];
            return NULL;
        }
    }
    return self;
}

- (id)init
{
    if(self = [super init])
    {
        mChunkArray = NULL;
        mData = NULL;
        [self initExporter];
    }
    return self;
}

- (void)dealloc
{
    [mData release];
    [mChunkArray release];
    [self deallocExporter];
    [super dealloc];
}

- (BOOL)parseChunkInData:(NSData*)data
{
    const void* dataPtr = [data bytes];
    
    // Reading Header Chunk
    
    AIFFChunk *headerChunk = [AIFFChunk readAIFFHeaderInData:&dataPtr errorMessage:mErrorMessage];
    if(headerChunk == NULL)
        return NO;
        
    [mChunkArray addObject:headerChunk];
    
    // Read all recognized chunks
    
    while(dataPtr<([data bytes]+[data length]))
    {
        AIFFChunk *chunk = [AIFFChunk readOneChunkInData:&dataPtr headerChunk:headerChunk errorMessage:mErrorMessage];
        if(chunk)
            [mChunkArray addObject:chunk];
        else
            return NO;
    }
    return YES;
}

- (AIFFChunk*)findChunkWithID:(UInt32)ckID
{
    NSEnumerator *enumerator = [mChunkArray objectEnumerator];
    AIFFChunk *chunk;
    while(chunk = [enumerator nextObject])
    {
        if([chunk chunkID] == ckID)
            return chunk;
    }
    return NULL;
}

- (long)soundDataSize
{
    AIFFChunk *chunk = [self findChunkWithID:SoundDataID];
    if(chunk)
        return [chunk soundDataSize];
    else
        return 0;
}

- (void*)soundDataBuffer
{
    AIFFChunk *chunk = [self findChunkWithID:SoundDataID];
    if(chunk)
        return [chunk soundDataBuffer];
    else
        return NULL;
}

- (unsigned long)numberOfSample
{
    AIFFChunk *chunk = [self findChunkWithID:CommonID];
    if(chunk)
        return [chunk numberOfSample];
    else
        return 0;
}

- (short)numberOfChannels
{
    AIFFChunk *chunk = [self findChunkWithID:CommonID];
    if(chunk)
        return [chunk numberOfChannels];
    else
        return 0;
}

- (short)sampleSize
{
    AIFFChunk *chunk = [self findChunkWithID:CommonID];
    if(chunk)
        return [chunk sampleSize];
    else
        return 0;
}

- (double)rate
{
    AIFFChunk *chunk = [self findChunkWithID:CommonID];
    if(chunk)
        return [chunk rate];
    else
        return DEFAULT_RATE;
}

@end

@implementation AIFFCodec (Importer)

- (BOOL)extractSoundData32BitsAnd44KhzOfSize:(unsigned long*)size leftBuffer:(AIFF32BitsBufferPtr*)left rightBuffer:(AIFF32BitsBufferPtr*)right scaleFactor:(float)factor
{
    if(PRINT_LOG)
        NSLog(@"** 32 Bits / 44.1Khz Extractor");
    
    unsigned char *soundDataBuffer = [self soundDataBuffer];
    long soundDataSize = [self soundDataSize];
    unsigned long numberOfSamples = [self numberOfSample];
    short sampleSize = [self sampleSize];
    short numChannels = [self numberOfChannels];
    double rate = [self rate];
    
    if(sampleSize!=8 && sampleSize!=16 && sampleSize!=32)
    {
        [mErrorMessage setString:[NSString stringWithFormat:NSLocalizedString(@"Supports only 8, 16 or 32 bits sample size (this file is %d bits).", NULL), sampleSize]];
        return NO;
    }
    
    if(rate!=22050 && rate!=44100)
    {
        [mErrorMessage setString:[NSString stringWithFormat:NSLocalizedString(@"Supports only 22.05 kHz or 44.1 kHz file rate (this file is %f Hz).", NULL), rate]];
        return NO;
    }

    if(PRINT_LOG)
        NSLog(@"Sound data size %d", soundDataSize);
    
    soundDataSize /= numChannels;
    
    short rateFactor = 44100.0/rate;
    long soundSize = soundDataSize*(32/sampleSize)*rateFactor;
    *size = soundSize;
            
    AIFF32BitsBufferPtr leftBufferPtr = malloc(soundSize);
    if(leftBufferPtr == NULL)
    {
        [mErrorMessage setString:NSLocalizedString(@"Unable to allocate memory for the converted sound.", NULL)];
        return NO;
    }
    
    AIFF32BitsBufferPtr rightBufferPtr = NULL;
    
    if(numChannels==2)
    {
        rightBufferPtr = malloc(soundSize); // 32 bits
        if(rightBufferPtr == NULL)
        {
            [mErrorMessage setString:NSLocalizedString(@"Unable to allocate memory for the converted sound.", NULL)];
            return NO;
        }
    }
    
    *left = leftBufferPtr;
    *right = rightBufferPtr;
    
    unsigned long sample = 0;
    for(sample=0; sample<numberOfSamples*numChannels; sample++)
    {
        float value = 0;
        switch(sampleSize) {
            case 8:
                {
                    signed char a = *soundDataBuffer++;
                    value = (float)a/128;
                }
                break;
            case 16:
                {
                    unsigned char a, b;
                    a = *soundDataBuffer++;
                    b = *soundDataBuffer++;
                    short bit16 = a * 0x100 + b;
                    value = (float)bit16/32768;
                }
                break;
            case 32:
            {
                unsigned char a, b, c, d;
                a = *soundDataBuffer++;
                b = *soundDataBuffer++;
                c = *soundDataBuffer++;
                d = *soundDataBuffer++;
                long bit32 = a * 0x300 + b * 0x200 + c * 0x100 + b;
                value = (float)(bit32/2147483648UL);
            }
            break;
        }
        
        value *= factor;
        
        short r;
        for(r=0; r<rateFactor; r++)
        {
            if(numChannels == 1 || sample%2 == 0)
                memcpy(leftBufferPtr++, &value, 4);
            else
                memcpy(rightBufferPtr++, &value, 4);
        }
    }
        
    return YES;
}

@end

@implementation AIFFCodec (Exporter)

- (void)initExporter
{
    mExportDataProvider = NULL;		// No provider
    mExportSampleSize = 16;		// 16 bits
    
    mExportData = NULL;
    
    mExportFormChunk = [[AIFFChunk alloc] initWithID:FORMID];
    mExportFormatVersionChunk = [[AIFFChunk alloc] initWithID:FormatVersionID];
    mExportCommonChunk = [[AIFFChunk alloc] initWithID:CommonID];
    mExportSoundDataChunk = [[AIFFChunk alloc] initWithID:SoundDataID];
}

- (void)deallocExporter
{
    [mExportData release];
    [mExportFormChunk release];
    [mExportFormatVersionChunk release];
    [mExportCommonChunk release];
    [mExportSoundDataChunk release];
}

- (void)setExportDataProvider:(id)provider
{
    mExportDataProvider = provider;
}

- (void)setExportSampleSize:(short)sampleSize
{
    mExportSampleSize = sampleSize;
}

- (void)prepareExportation:(unsigned long)size channel:(short)channel
{
    unsigned long theNumberOfFrames = size/4; 		// Input size for 32 bits (4 bytes)
    unsigned long theSize = theNumberOfFrames*2;	// Size of AIFF sound (16 bits = 2 bytes)

    if(channel==STEREO)	// Stereo ?
        theSize *= 2;
            
    [mExportFormChunk setCkDataSize:(8+4)+(8+38)+(8+8)+theSize];
    [mExportFormChunk setFormType:AIFCID];

    [mExportFormatVersionChunk setckSize:4];
    [mExportFormatVersionChunk setTimeStamp:0];
    
    [mExportCommonChunk setckSize:24];
    [mExportCommonChunk setNumChannels:channel==STEREO?2:1];		// 1 channel
    [mExportCommonChunk setNumSampleFrames:theNumberOfFrames];	// Number of frames
    [mExportCommonChunk setSampleSize:16];		// 16 Bits
    [mExportCommonChunk setSampleRate:44100.0];		// 44.1 kHz
    [mExportCommonChunk setCompressionType:NoneType];	// No compression
    [mExportCommonChunk setCompressionName:""];			// empty string

    [mExportSoundDataChunk setckSize:8+theSize];
    [mExportSoundDataChunk setOffset:0];
    [mExportSoundDataChunk setBlockSize:0];

    // Write chunk to NSData stream
    
    [mExportData release];
    mExportData = [[NSMutableData dataWithCapacity:theSize] retain];
        
    [mExportFormChunk writeToData:mExportData];
    [mExportFormatVersionChunk writeToData:mExportData];
    [mExportCommonChunk writeToData:mExportData];
    [mExportSoundDataChunk writeToData:mExportData];
}

- (NSData*)export32BitsSoundDataMono:(short)channel size:(unsigned long)size
{
    unsigned long offset = [mExportDataProvider aiffCodecIndexOffsetOfChannel:channel];

    unsigned long numberOfFrames = size/4; 		// Input size for 32 bits (4 bytes)
    unsigned long sample = 0;
    for(sample=0; sample<numberOfFrames; sample++)
    {
        unsigned long index = offset+sample;
        float value = [mExportDataProvider aiffCodecValueAtIndex:index channel:channel];
        short bits16 = value*32767;

		bits16 = OSSwapHostToBigInt16(bits16);
        [mExportData appendBytes:&bits16 length:sizeof(short)];
    }
    
    if(numberOfFrames!=0)
    {
        short padByte = 0;
        [mExportData appendBytes:&padByte length:1];
    }

    return mExportData;
}

- (NSData*)export32BitsSoundDataStereoOfSize:(unsigned long)size
{
    unsigned long offsetLeft = [mExportDataProvider aiffCodecIndexOffsetOfChannel:LEFT];
    unsigned long offsetRight = [mExportDataProvider aiffCodecIndexOffsetOfChannel:RIGHT];

    unsigned long numberOfFrames = size/4; 		// Input size for 32 bits (4 bytes)
    unsigned long sample = 0;
    for(sample=0; sample<numberOfFrames; sample++)
    {
        // Left channel
        unsigned long index = offsetLeft+sample;
        float value = [mExportDataProvider aiffCodecValueAtIndex:index channel:LEFT];
        short bits16 = value*32767;

		bits16 = OSSwapHostToBigInt16(bits16);
        [mExportData appendBytes:&bits16 length:sizeof(short)];
        
        // Right channel
        index = offsetRight+sample;
        value = [mExportDataProvider aiffCodecValueAtIndex:index channel:RIGHT];
        bits16 = value*32767;

		bits16 = OSSwapHostToBigInt16(bits16);
        [mExportData appendBytes:&bits16 length:sizeof(short)];
    }
    
    if(numberOfFrames!=0)
    {
        short padByte = 0;
        [mExportData appendBytes:&padByte length:1];
    }

    return mExportData;
}

- (NSData*)export32BitsSoundDataChannel:(short)channel size:(unsigned long)size
{
    [self prepareExportation:size channel:channel];
        
    if(channel == STEREO)
        return [self export32BitsSoundDataStereoOfSize:size];
    else
        return [self export32BitsSoundDataMono:channel size:size];
}

- (NSData*)export32BitsMonoSoundDataInFile16BitsAnd44Khz:(AIFF32BitsBufferPtr)soundData
                size:(unsigned long)size
{
    [self prepareExportation:size channel:LEFT];

    // Write the sound data

    unsigned long numberOfFrames = size/4; 		// Input size for 32 bits (4 bytes)
    unsigned long sample = 0;
    for(sample=0; sample<numberOfFrames; sample++)
    {
        float value = soundData[sample];
        short bits16 = value*32767;

		bits16 = OSSwapHostToBigInt16(bits16);
        [mExportData appendBytes:&bits16 length:sizeof(short)];
    }
    
    if(numberOfFrames!=0)
    {
        short padByte = 0;
        [mExportData appendBytes:&padByte length:1];
    }
    
    return mExportData;
}

@end
