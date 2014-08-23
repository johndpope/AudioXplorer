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

@interface AudioView (Features)

- (void)initDefaultFeatures;

- (void)setFeatures:(NSMutableDictionary*)features;
- (NSMutableDictionary*)features;

- (void)queryCursorDisplayPosition;
- (void)queryScrollerUsage;

- (void)setViewName:(NSString*)name;
- (NSString*)viewName;

- (void)setViewID:(ULONG)viewID;
- (ULONG)viewID;

- (void)setXAxisUnit:(NSString*)unit;
- (void)setYAxisUnit:(NSString*)unit;
- (void)setZAxisUnit:(NSString*)unit;

- (NSString*)xAxisUnit;
- (NSString*)yAxisUnit;
- (NSString*)zAxisUnit;

- (void)setXAxisName:(NSString*)name;
- (NSString*)xAxisName;

- (void)setYAxisName:(NSString*)name;
- (NSString*)yAxisName;

- (void)setZAxisName:(NSString*)name;
- (NSString*)zAxisName;

- (void)setXAxisAutoGridSpace:(BOOL)state;
- (BOOL)xAxisAutoGridSpace;

- (void)setXAxisCustomGridSpace:(FLOAT)space;
- (FLOAT)xAxisCustomGridSpace;

- (void)setAllowsTitle:(BOOL)flag;
- (BOOL)allowsTitle;

- (void)setAllowsSelection:(BOOL)flag;
- (BOOL)allowsSelection;

- (void)setAllowsCursor:(BOOL)flag;
- (BOOL)allowsCursor;

- (void)setAllowsPlayerhead:(BOOL)flag;
- (BOOL)allowsPlayerhead;

- (void)setAllowsXAxis:(BOOL)flag;
- (BOOL)allowsXAxis;

- (void)setAllowsYAxis:(BOOL)flag;
- (BOOL)allowsYAxis;

- (void)setAllowsGrid:(BOOL)flag;
- (BOOL)allowsGrid;

- (void)setAllowsViewSelect:(BOOL)flag;
- (BOOL)allowsViewSelect;

- (void)setAllowsPlayback:(BOOL)flag;
- (BOOL)allowsPlayback;

- (void)setShowCursor:(BOOL)flag;
- (BOOL)showCursor;

- (void)setShowCursorHarmonic:(BOOL)flag;
- (BOOL)showCursorHarmonic;

- (void)setShowTriggerCursor:(BOOL)flag;
- (BOOL)showTriggerCursor;

- (void)setDisplayedChannel:(SHORT)channel;
- (SHORT)displayedChannel;

- (void)setTitleColor:(NSColor*)color;
- (void)setBackgroundColor:(NSColor*)color;
- (void)setGridColor:(NSColor*)color;
- (void)setLeftDataColor:(NSColor*)color;
- (void)setRightDataColor:(NSColor*)color;
- (void)setCursorColor:(NSColor*)color;
- (void)setSelectionColor:(NSColor*)color;
- (void)setPlayerheadColor:(NSColor*)color;
- (void)setXAxisColor:(NSColor*)color;
- (void)setYAxisColor:(NSColor*)color;

- (NSColor*)titleColor;
- (NSColor*)backgroundColor;
- (NSColor*)gridColor;
- (NSColor*)leftDataColor;
- (NSColor*)rightDataColor;
- (NSColor*)cursorColor;
- (NSColor*)selectionColor;
- (NSColor*)playerheadColor;
- (NSColor*)xAxisColor;
- (NSColor*)yAxisColor;

- (void)setLissajousFrom:(FLOAT)from;
- (FLOAT)lissajousFrom;
- (void)setLissajousTo:(FLOAT)to;
- (FLOAT)lissajousTo;
- (void)setLissajousQuality:(FLOAT)quality;
- (FLOAT)lissajousQuality;

- (void)setLineWidth:(FLOAT)width;
- (FLOAT)lineWidth;

@end
