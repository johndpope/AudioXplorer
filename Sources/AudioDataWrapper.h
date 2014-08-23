
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

#import <Cocoa/Cocoa.h>
#import "AudioTypes.h"
#import "AudioProtocols.h"

// One wrapper for each view

@class AudioView;

@interface AudioDataWrapper : NSObject <NSCoding>
{

        // Model & view
    id mWindowController;	// Not encoded    
    AudioView* mView;		// Not encoded (created when loaded)

    NSRect mViewFrame; 			// Encoded
    id mData;	// Encoded
    NSMutableDictionary *mViewFeatures;	// Encoded
    
        // Link parameters
        
    BOOL mLinkState;
    ULONG mLinkedViewID;	// Linked view ID
    
        // Associated parameters
    
    BOOL mAllowsFFTSize;
    NSColor *mFFTSizeColor;
    
    SHORT mFFTWindowFunctionID;
    SHORT mSonoWindowFunctionID;
    
    FLOAT mFFTWindowFunctionParameter;
    FLOAT mSonoWindowFunctionParameter;
    
    ULONG mWindowSize;
    ULONG mWindowOffset;
    ULONG mFFTSize;
    ULONG mDataRate;
    
        // View parameters
        
    NSString *mViewName;
    BOOL mViewNameImmutable;
    FLOAT mViewVisualMinX, mViewVisualMaxX;
    FLOAT mViewVisualMinY, mViewVisualMaxY;
    FLOAT mViewSelMinX, mViewSelMaxX;
    FLOAT mViewCursorX, mViewCursorY;
    FLOAT mViewPlayerHeadPosition;
}

+ (AudioDataWrapper*)initWithAudioData:(id)data;
+ (AudioDataWrapper*)wrapperLinkedToWrapper:(AudioDataWrapper*)wrapper;
+ (AudioDataWrapper*)copyFromAudioDataWrapper:(AudioDataWrapper*)wrapper;

- (void)objectDidLoad;

- (void)linkToView:(AudioView*)view;
- (void)linkToWrapper:(AudioDataWrapper*)wrapper;

- (void)setLinkState:(BOOL)flag;
- (BOOL)linkState;
- (ULONG)linkedViewID;

- (void)setData:(id)data;
- (void)setView:(id)view;

- (id)data;
- (id)view;

- (void)setViewFrame:(NSRect)frame;
- (NSRect)viewFrame;

- (SHORT)displayedChannel;

- (BOOL)leftChannelExists;
- (BOOL)rightChannelExists;
- (BOOL)stereoChannelExists;

- (void)resetXAxis;
- (void)resetYAxis;
- (void)refreshXAxis;
- (void)refreshYAxis;
- (void)applyDataToView;
- (void)setViewFeatures:(id)features;
- (void)applyToView;
- (void)applyFromView;

- (void)updateRangeFromView;
- (void)updateRangeToView;

- (void)drawCustomRect:(NSRect)rect;

- (BOOL)supportFFT;
- (BOOL)supportSono;

@end

@interface AudioDataWrapper (Appearance)

- (void)initAppearanceWithCoder:(NSCoder*)coder;
- (void)encodeAppearanceWithCoder:(NSCoder*)coder;

- (void)defaultAppearanceValues;

- (void)setAllowsFFTSize:(BOOL)flag;
- (void)setFFTSizeColor:(NSColor*)color;

- (BOOL)allowsFFTSize;
- (NSColor*)fftSizeColor;

@end

@interface AudioDataWrapper (Info)

- (NSString*)infoNumberOfChannels;
- (NSString*)infoSampleRate;
- (NSString*)infoSampleSize;
- (NSString*)infoSoundSize;
- (NSString*)infoHorizontalResolution;
- (NSString*)infoVerticalResolution;

@end

@interface AudioDataWrapper (Parameters)

- (void)setDataRate:(ULONG)rate;
- (ULONG)dataRate;

- (void)setXAxisScale:(SHORT)scale;
- (SHORT)xAxisScale;

- (void)setYAxisScale:(SHORT)scale;
- (SHORT)yAxisScale;

- (BOOL)selectionExist;

- (void)setViewVisualMinX:(FLOAT)minX maxX:(FLOAT)maxX;
- (void)setViewVisualMinY:(FLOAT)minY maxY:(FLOAT)maxY;
- (void)setViewCursorX:(FLOAT)x cursorY:(FLOAT)y;
- (void)setViewSelMinX:(FLOAT)from maxX:(FLOAT)maxX;
- (void)setViewPlayerHeadPosition:(FLOAT)x;

- (FLOAT)visualMinX;
- (FLOAT)visualMaxX;
- (FLOAT)visualMinY;
- (FLOAT)visualMaxY;
- (FLOAT)selMinX;
- (FLOAT)selMaxX;
- (FLOAT)cursorX;
- (FLOAT)cursorY;
- (FLOAT)cursorZ;
- (FLOAT)playerHeadPosition;

- (FLOAT)convertFactorFromUnit:(SHORT)sourceUnit toUnit:(SHORT)targetUnit;

- (void)setFFTWindowFunctionID:(SHORT)windowID;
- (SHORT)fftWindowFunctionID;
- (void)setFFTWindowFunctionParameterValue:(FLOAT)value;
- (FLOAT)fftWindowFunctionParameterValue;
- (NSArray*)fftWindowParametersArray;

- (void)setSonoWindowFunctionID:(SHORT)windowID;
- (SHORT)sonoWindowFunctionID;
- (void)setSonoWindowFunctionParameterValue:(FLOAT)value;
- (FLOAT)sonoWindowFunctionParameterValue;
- (NSArray*)sonoWindowParametersArray;

- (void)setWindowSize:(FLOAT)windowSize fromUnit:(SHORT)unit;
- (void)setWindowOffset:(FLOAT)windowOffset fromUnit:(SHORT)unit;
- (void)setFFTSize:(FLOAT)fftSize fromUnit:(SHORT)unit;

- (FLOAT)windowSizeForUnit:(SHORT)unit;
- (FLOAT)windowOffsetForUnit:(SHORT)unit;
- (FLOAT)fftSizeForUnit:(SHORT)unit;

- (ULONG)windowSize;
- (ULONG)windowOffset;
- (ULONG)fftSize;
- (ULONG)fftSize2;
- (ULONG)fftLog2;

- (FLOAT)deltaT;

@end

@interface AudioDataWrapper (Delegate)
- (void)audioViewSelectionHasChanged:(AudioView*)view;
- (void)audioViewCursorHasChanged:(AudioView*)view;
- (void)audioViewPlayerHeadHasChanged:(AudioView*)view;
- (void)audioViewDidSelected:(AudioView*)view;
@end

@interface AudioDataWrapper (LinkWith2DModel)

- (void)setViewNameImmutable:(BOOL)flag;
- (BOOL)viewNameImmutable;

- (void)setViewName:(NSString*)name always:(BOOL)always;
- (NSString*)viewName;

- (void)setViewID:(ULONG)viewID;
- (ULONG)viewID;

- (NSString*)xAxisUnit;
- (NSString*)yAxisUnit;
- (NSString*)xAxisName;
- (NSString*)yAxisName;
- (SHORT)kind;
- (FLOAT)yValueAtX:(FLOAT)x channel:(SHORT)channel;

- (FLOAT)minXOfChannel:(SHORT)channel;
- (FLOAT)maxXOfChannel:(SHORT)channel;
- (FLOAT)minYOfChannel:(SHORT)channel;
- (FLOAT)maxYOfChannel:(SHORT)channel;

- (BOOL)supportPlayback;
- (BOOL)supportHarmonicCursor;

@end

@interface AudioDataWrapper (LinkWith3DModel)

- (NSString*)zAxisUnit;

- (void)setImageContrast:(FLOAT)contrast;
- (FLOAT)imageContrast;

- (void)setImageGain:(FLOAT)gain;
- (FLOAT)imageGain;

- (void)setInverseVideo:(BOOL)flag;
- (BOOL)inverseVideo;

- (void)setMinThreshold:(FLOAT)value;
- (FLOAT)minThreshold;

- (void)setMaxThreshold:(FLOAT)value;
- (FLOAT)maxThreshold;

- (FLOAT)minThresholdValue;
- (FLOAT)maxThresholdValue;

- (FLOAT)zValueAtX:(FLOAT)x y:(FLOAT)y;

- (void)renderImage;
- (CGImageRef)imageQ2D;

@end
