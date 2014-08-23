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

#import "AudioView.h"

@interface AudioView (Range)

- (void)setRangeForXAxisFrom:(FLOAT)inVisualFrom to:(FLOAT)inVisualTo;
- (void)setRangeForYAxisFrom:(FLOAT)inVisualFrom to:(FLOAT)inVisualTo;
- (void)setRangeForZAxisFrom:(FLOAT)inVisualFrom to:(FLOAT)inVisualTo;
- (void)setVisualRangeForXAxisFrom:(FLOAT)inVisualFrom to:(FLOAT)inVisualTo;
- (void)setVisualRangeForYAxisFrom:(FLOAT)inVisualFrom to:(FLOAT)inVisualTo;
- (void)setVisualRangeForZAxisFrom:(FLOAT)inVisualFrom to:(FLOAT)inVisualTo;
- (void)setSelectionRangeForXAxisFrom:(FLOAT)inSelFrom to:(FLOAT)inSelTo;
- (void)setSelectionRangeForYAxisFrom:(FLOAT)inSelFrom to:(FLOAT)inSelTo;
- (void)setCursorPositionX:(FLOAT)x positionY:(FLOAT)y;
- (void)setPlayerHeadPosition:(FLOAT)x;

- (FLOAT)xAxisRangeFrom;
- (FLOAT)xAxisRangeTo;
- (FLOAT)yAxisRangeFrom;
- (FLOAT)yAxisRangeTo;
- (FLOAT)xAxisVisualRangeFrom;
- (FLOAT)xAxisVisualRangeTo;
- (FLOAT)yAxisVisualRangeFrom;
- (FLOAT)yAxisVisualRangeTo;
- (FLOAT)xAxisSelectionRangeFrom;
- (FLOAT)xAxisSelectionRangeTo;
- (FLOAT)yAxisSelectionRangeFrom;
- (FLOAT)yAxisSelectionRangeTo;
- (FLOAT)xCursorPosition;
- (FLOAT)yCursorPosition;
- (FLOAT)zCursorPosition;
- (FLOAT)playerHeadPosition;

- (BOOL)selectionExists;

- (void)refreshRanges;
- (void)updateVisualDisplayedXAxisParameters;
- (void)updateVisualDisplayedYAxisParameters;
- (void)updateVisualDisplayedZAxisParameters;
- (void)checkRanges;

- (void)updateXAxisScrollerFrame;
- (void)updateXAxisScroller;
- (void)updateYAxisScrollerFrame;
- (void)updateYAxisScroller;

@end
