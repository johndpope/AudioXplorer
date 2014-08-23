
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
#import "AIFFProtocol.h"
#import "AIFFChunk.h"

typedef float* AIFF32BitsBufferPtr;

@interface AIFFCodec : NSObject {
    NSMutableArray *mChunkArray;	// Array of chunk
    NSData *mData;			// Data
    NSMutableString *mErrorMessage;
    
    // Exporter
    
    id<ExportDataProviderProtocol> mExportDataProvider;
    short mExportSampleSize;

    NSMutableData *mExportData;
    
    AIFFChunk *mExportFormChunk;
    AIFFChunk *mExportFormatVersionChunk;
    AIFFChunk *mExportCommonChunk;
    AIFFChunk *mExportSoundDataChunk;
}

- (id)initWithContentsOfFile:(NSString*)path errorMessage:(NSMutableString*)error;
- (BOOL)parseChunkInData:(NSData*)data;

- (long)soundDataSize;
- (void*)soundDataBuffer;
- (unsigned long)numberOfSample;
- (short)numberOfChannels;
- (short)sampleSize;
- (double)rate;

@end

@interface AIFFCodec (Importer)
- (BOOL)extractSoundData32BitsAnd44KhzOfSize:(unsigned long*)size leftBuffer:(AIFF32BitsBufferPtr*)left rightBuffer:(AIFF32BitsBufferPtr*)right scaleFactor:(float)factor;
@end

@interface AIFFCodec (Exporter)
- (void)initExporter;
- (void)deallocExporter;
- (void)setExportDataProvider:(id)provider;
- (void)setExportSampleSize:(short)sampleSize;
- (NSData*)export32BitsSoundDataChannel:(short)channel size:(unsigned long)size;
- (NSData*)export32BitsMonoSoundDataInFile16BitsAnd44Khz:(AIFF32BitsBufferPtr)data size:(unsigned long)size;
@end
