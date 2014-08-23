
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

#import "AudioTypes.h"

@class AudioDataWrapper;

@protocol AudioSTWindowControllerProtocol
- (void)addAudioDataWrapper:(id)wrapper parentWrapper:(id)parent;
- (void)audioDialogRecordHasFinished:(AudioDataWrapper*)wrapper;
- (void)audioDialogGenerateHasFinished:(AudioDataWrapper*)wrapper;
@end

@protocol DataSourceProtocol <NSObject>

- (BOOL)supportTrigger;
- (BOOL)supportPlayback;
- (BOOL)supportHarmonicCursor;

- (SHORT)kind;
- (ULONG)dataRate;

- (FLOAT)yValueAtX:(FLOAT)x channel:(SHORT)channel;
- (FLOAT)yValueAtIndex:(ULONG)index channel:(SHORT)channel;
- (FLOAT)yValueNormalizedAtX:(FLOAT)x channel:(SHORT)channel;
- (FLOAT)zValueNormalizedAtX:(FLOAT)x y:(FLOAT)y;
- (FLOAT)zValueAtX:(FLOAT)x y:(FLOAT)y;

- (ULONG)maxIndex;
- (ULONG)indexOfXValue:(FLOAT)value channel:(SHORT)channel;

- (CGImageRef)imageQ2D;

- (BOOL)dataExistsForChannel:(SHORT)channel;
- (FLOAT_PTR)dataBasePtrOfChannel:(SHORT)channel;

- (FLOAT)minXOfChannel:(SHORT)channel;
- (FLOAT)maxXOfChannel:(SHORT)channel;
- (FLOAT)minYOfChannel:(SHORT)channel;
- (FLOAT)maxYOfChannel:(SHORT)channel;
- (FLOAT)minZOfChannel:(SHORT)channel;
- (FLOAT)maxZOfChannel:(SHORT)channel;

- (NSString*)xAxisUnitForRange:(FLOAT)range;
- (FLOAT)xAxisUnitFactorForRange:(FLOAT)range;

- (NSString*)yAxisUnitForRange:(FLOAT)range;
- (FLOAT)yAxisUnitFactorForRange:(FLOAT)range;

- (NSString*)zAxisUnitForRange:(FLOAT)range;
- (FLOAT)zAxisUnitFactorForRange:(FLOAT)range;

- (BOOL)supportRawDataExport;
- (NSString*)stringOfRawDataFromIndex:(ULONG)from to:(ULONG)to channel:(USHORT)channel delimiter:(NSString*)delimiter;

@end
