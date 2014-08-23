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

#import "AudioConstants.h"
#import "AudioDataWrapper.h"
#import "AudioDataFFT.h"
#import "AudioView.h"
#import "AudioView+Categories.h"
#import "AudioNotifications.h"
#import "AudioDialogPrefs.h"

#define WRAPPER_VERSION_CURRENT 1

@class AudioDataAmplitude;

@implementation AudioDataWrapper

+ (AudioDataWrapper*)initWithAudioData:(id)data
{
    AudioDataWrapper *wrapper = [[AudioDataWrapper alloc] init];
    [wrapper setData:data];
    return [wrapper autorelease];
}

+ (AudioDataWrapper*)wrapperLinkedToWrapper:(AudioDataWrapper*)sourceWrapper
{
    // Create a FFT wrapper linked to a Sonogram wrapper
    AudioDataWrapper *wrapper = [[AudioDataWrapper alloc] init];
    [wrapper linkToWrapper:sourceWrapper];
    [wrapper setLinkState:YES];
    return [wrapper autorelease];
}

+ (AudioDataWrapper*)copyFromAudioDataWrapper:(AudioDataWrapper*)wrapper
{
    NSData *copyData = [NSArchiver archivedDataWithRootObject:wrapper];
    AudioDataWrapper *copyWrapper = [NSUnarchiver unarchiveObjectWithData:copyData];
    return copyWrapper;
}

- (id)init
{
    if(self = [super init])
    {
        mData = NULL;
        mView = NULL;
        mViewFrame = NSMakeRect(0, 0, DEFAULT_VIEWCELL_WIDTH, DEFAULT_VIEWCELL_HEIGHT);
        mViewFeatures = NULL;
        
        [self defaultAppearanceValues];
        
        mLinkState = NO;
        mLinkedViewID = 0;
        
        mFFTWindowFunctionID = 0;
        mSonoWindowFunctionID = 0;
        
        mFFTWindowFunctionParameter = 0;
        mSonoWindowFunctionParameter = 0;
        
        mWindowSize = DEFAULT_FFT_SIZE;
        mWindowOffset = DEFAULT_FFT_SIZE*0.125;
        mFFTSize = DEFAULT_FFT_SIZE;
        
        mDataRate = SOUND_DEFAULT_RATE;
        mViewName = NULL;
        mViewNameImmutable = NO;
        mViewVisualMinX = mViewVisualMaxX = 0;
        mViewVisualMinY = mViewVisualMaxY = 0;
        mViewSelMinX = mViewSelMaxX = 0;
        mViewCursorX = mViewCursorY = 0;   
        mViewPlayerHeadPosition = 0;     
        
        [self objectDidLoad];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioWrapperWillDeallocateNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [mView release];
    [mData release];
    [mViewFeatures release];
    [mFFTSizeColor release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder*)coder
{
    if(self = [super init])
    {
        mView = NULL;
        
       /* long version = */ [[coder decodeObject] longValue];

        mData = [[coder decodeObject] retain];
        mViewFrame = [coder decodeRect];
        mViewName = [[coder decodeObject] retain];
        mViewFeatures = [[coder decodeObject] retain];
        [coder decodeValueOfObjCType:@encode(BOOL) at:&mLinkState];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mLinkedViewID];
        [coder decodeValueOfObjCType:@encode(SHORT) at:&mFFTWindowFunctionID];
        [coder decodeValueOfObjCType:@encode(SHORT) at:&mSonoWindowFunctionID];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mFFTWindowFunctionParameter];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mSonoWindowFunctionParameter];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mWindowSize];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mWindowOffset];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mFFTSize];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mDataRate];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mViewVisualMinX];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mViewVisualMaxX];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mViewVisualMinY];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mViewVisualMaxY];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mViewSelMinX];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mViewSelMaxX];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mViewCursorX];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mViewCursorY];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mViewPlayerHeadPosition];
        [self initAppearanceWithCoder:coder];
                
        if([mData respondsToSelector:@selector(applyParametersFromWrapper:)])
            [mData performSelector:@selector(applyParametersFromWrapper:) withObject:self];
            
        [self objectDidLoad];
   }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [self applyFromView];
    
    [coder encodeObject:[NSNumber numberWithLong:WRAPPER_VERSION_CURRENT]];
    [coder encodeObject:mData];
    [coder encodeRect:mViewFrame];
    [coder encodeObject:mViewName];
    [coder encodeObject:mViewFeatures];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&mLinkState];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mLinkedViewID];
    [coder encodeValueOfObjCType:@encode(SHORT) at:&mFFTWindowFunctionID];
    [coder encodeValueOfObjCType:@encode(SHORT) at:&mSonoWindowFunctionID];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mFFTWindowFunctionParameter];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mSonoWindowFunctionParameter];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mWindowSize];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mWindowOffset];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mFFTSize];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mDataRate];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mViewVisualMinX];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mViewVisualMaxX];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mViewVisualMinY];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mViewVisualMaxY];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mViewSelMinX];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mViewSelMaxX];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mViewCursorX];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mViewCursorY];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mViewPlayerHeadPosition];

    [self encodeAppearanceWithCoder:coder];
}

- (void)objectDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(audioViewCursorHasChangedNotification:) 
                                            name:AudioViewCursorHasChangedNotification
                                            object:NULL];
}

- (void)linkToView:(AudioView*)view
{
    FLOAT cursor = [view xCursorPosition];
    
    [mData release];
    mData = [[AudioDataFFT alloc] init];
    
    [mData copyFFTDataFromSonoData:[view dataSource] atX:cursor channel:[view displayedChannel]];   
    
    [mView setDataSource:mData];
    [mView applyDataSourceToView];
    [mView refresh];
}

- (void)linkToWrapper:(AudioDataWrapper*)wrapper
{
    mLinkedViewID = [wrapper viewID];
    [self linkToView:[wrapper view]];
}

- (void)setLinkState:(BOOL)flag
{
    mLinkState = flag;
}

- (BOOL)linkState
{
    return mLinkState;
}

- (ULONG)linkedViewID
{
    return mLinkedViewID;
}

- (void)setData:(id)data
{
    [mData autorelease];
    mData = [data retain];
}

- (void)setView:(id)view
{
    [mView autorelease];
    mView = [view retain];
}

- (id)data
{
    return mData;
}

- (id)view
{
    return mView;
}

- (void)setViewFrame:(NSRect)frame
{
    mViewFrame = frame;
}

- (NSRect)viewFrame
{
    return mViewFrame;
}

- (SHORT)displayedChannel
{
    if(mView)
        return [mView displayedChannel];
    else
        return LEFT_CHANNEL;
}

- (SHORT)currentChannel
{
    SHORT channel = [self displayedChannel];
    return (channel == STEREO_CHANNEL)?LEFT_CHANNEL:channel;
}

- (BOOL)leftChannelExists
{
    if([mData respondsToSelector:@selector(dataExistsForChannel:)])
        return [mData dataExistsForChannel:LEFT_CHANNEL];
    else
        return FALSE;
}

- (BOOL)rightChannelExists
{
    if([mData respondsToSelector:@selector(dataExistsForChannel:)])
        return [mData dataExistsForChannel:RIGHT_CHANNEL];
    else
        return FALSE;
}

- (BOOL)stereoChannelExists
{
    return [self leftChannelExists] && [self rightChannelExists];
}

- (void)checkXAxisRange
{
    if([self displayedChannel] == LISSAJOUS_CHANNEL)
    {
        mViewVisualMinX = MAX(mViewVisualMinX, [self minYOfChannel:LEFT_CHANNEL]);
        mViewVisualMinX = MIN(mViewVisualMinX, [self maxYOfChannel:LEFT_CHANNEL]);
    
        mViewVisualMaxX = MAX(mViewVisualMaxX, [self minYOfChannel:LEFT_CHANNEL]);
        mViewVisualMaxX = MIN(mViewVisualMaxX, [self maxYOfChannel:LEFT_CHANNEL]);
    } else
    {
        mViewVisualMinX = MAX(mViewVisualMinX, [self minXOfChannel:[self currentChannel]]);
        mViewVisualMinX = MIN(mViewVisualMinX, [self maxXOfChannel:[self currentChannel]]);
    
        mViewVisualMaxX = MAX(mViewVisualMaxX, [self minXOfChannel:[self currentChannel]]);
        mViewVisualMaxX = MIN(mViewVisualMaxX, [self maxXOfChannel:[self currentChannel]]);
    }
}

- (void)checkYAxisRange
{
    if([self displayedChannel] == LISSAJOUS_CHANNEL)
    {
        mViewVisualMinY = MAX(mViewVisualMinY, [self minYOfChannel:RIGHT_CHANNEL]);
        mViewVisualMinY = MIN(mViewVisualMinY, [self maxYOfChannel:RIGHT_CHANNEL]);
    
        mViewVisualMaxY = MAX(mViewVisualMaxY, [self minYOfChannel:RIGHT_CHANNEL]);
        mViewVisualMaxY = MIN(mViewVisualMaxY, [self maxYOfChannel:RIGHT_CHANNEL]);
    } else if([[AudioDialogPrefs shared] yAxisFree] == NO)
    {
        mViewVisualMinY = MAX(mViewVisualMinY, [self minYOfChannel:[self currentChannel]]);
        mViewVisualMinY = MIN(mViewVisualMinY, [self maxYOfChannel:[self currentChannel]]);
    
        mViewVisualMaxY = MAX(mViewVisualMaxY, [self minYOfChannel:[self currentChannel]]);
        mViewVisualMaxY = MIN(mViewVisualMaxY, [self maxYOfChannel:[self currentChannel]]);
    }
}

- (void)checkAxisRange
{
    [self checkXAxisRange];
    [self checkYAxisRange];
}

- (void)resetXAxis
{
    if([self displayedChannel] == LISSAJOUS_CHANNEL)    
        [self setViewVisualMinX:[self minYOfChannel:LEFT_CHANNEL]
                            maxX:[self maxYOfChannel:LEFT_CHANNEL]];
    else
    {
        [self setViewVisualMinX:[self minXOfChannel:[self currentChannel]]
                            maxX:[self maxXOfChannel:[self currentChannel]]];
    }
    [self updateRangeToView];
    [mView refresh];
    [mView scaleHasChanged];
}

- (void)resetYAxis
{
    if([self displayedChannel] == LISSAJOUS_CHANNEL)    
        [self setViewVisualMinY:[self minYOfChannel:RIGHT_CHANNEL]
                            maxY:[self maxYOfChannel:RIGHT_CHANNEL]];
    else
        [self setViewVisualMinY:[self minYOfChannel:[self currentChannel]]
                            maxY:[self maxYOfChannel:[self currentChannel]]];
    [self updateRangeToView];
    [mView refresh];
    [mView scaleHasChanged];
}

- (void)refreshXAxis
{
    if(mViewVisualMinX==mViewVisualMaxX)
    {
        if([self displayedChannel] == LISSAJOUS_CHANNEL)
        {
            mViewVisualMinX = [self minYOfChannel:LEFT_CHANNEL];
            mViewVisualMaxX = [self maxYOfChannel:LEFT_CHANNEL];
        } else
        {
            mViewVisualMinX = [self minXOfChannel:[self currentChannel]];
            mViewVisualMaxX = [self maxXOfChannel:[self currentChannel]];
        }
    } else
        [self checkXAxisRange];
}

- (void)refreshYAxis
{
    if(mViewVisualMinY==mViewVisualMaxY)
    {
        if([self displayedChannel] == LISSAJOUS_CHANNEL)
        {
            mViewVisualMinY = [self minYOfChannel:RIGHT_CHANNEL];
            mViewVisualMaxY = [self maxYOfChannel:RIGHT_CHANNEL];
        } else
        {
            mViewVisualMinY = [self minYOfChannel:[self currentChannel]];
            mViewVisualMaxY = [self maxYOfChannel:[self currentChannel]];
        }
    } else
        [self checkYAxisRange];
}

- (void)applyDataToView
{    
    if(mData && mView)
    {
        [mView setFeatures:mViewFeatures];

        [self refreshXAxis];
        [self refreshYAxis];
        
        [mView setXAxisUnit:[mData xAxisUnit]];        
        [mView setXAxisName:[mData xAxisName]];

        [mView setYAxisUnit:[mData yAxisUnit]];        
        [mView setYAxisName:[mData yAxisName]];
    }
    
    if([mData respondsToSelector:@selector(refresh)])
        [mData performSelector:@selector(refresh)];
}

- (void)setViewFeatures:(id)features
{
    [mViewFeatures autorelease];
    mViewFeatures = [features retain];
    
    [mView setFeatures:mViewFeatures];
}

- (void)applyToView
{        
    if(mViewName==NULL)
        [self setViewName:NSLocalizedString(@"View", NULL) always:YES];
        
    [mView setViewName:mViewName];

    [self updateRangeToView];
}

- (void)applyFromView
{
    [self setViewName:[mView viewName] always:YES];
    [self setViewFrame:[mView viewFrame]];
    [self setViewFeatures:[mView features]];
}

- (void)updateRangeFromView
{
    [self setViewVisualMinX:[mView xAxisVisualRangeFrom] maxX:[mView xAxisVisualRangeTo]];
    [self setViewVisualMinY:[mView yAxisVisualRangeFrom] maxY:[mView yAxisVisualRangeTo]];
    
    [self setViewCursorX:[mView xCursorPosition] cursorY:[mView yCursorPosition]];
    [self setViewPlayerHeadPosition:[mView playerHeadPosition]];
    [self setViewSelMinX:[mView xAxisSelectionRangeFrom] maxX:[mView xAxisSelectionRangeTo]];
}

- (void)updateRangeToView
{
    [self checkAxisRange];

    if([self displayedChannel] == LISSAJOUS_CHANNEL)
    {
        [mView setRangeForXAxisFrom:[self minYOfChannel:LEFT_CHANNEL]
                                to:[self maxYOfChannel:LEFT_CHANNEL]];
        [mView setRangeForYAxisFrom:[self minYOfChannel:RIGHT_CHANNEL]
                                to:[self maxYOfChannel:RIGHT_CHANNEL]];
    
        [mView setVisualRangeForXAxisFrom:[self visualMinX] to:[self visualMaxX]];
        [mView setVisualRangeForYAxisFrom:[self visualMinY] to:[self visualMaxY]];
        
        [mView checkRanges];
    } else
    {
        [mView setRangeForXAxisFrom:[self minXOfChannel:[self currentChannel]]
                                to:[self maxXOfChannel:[self currentChannel]]];
        [mView setRangeForYAxisFrom:[self minYOfChannel:[self currentChannel]]
                                to:[self maxYOfChannel:[self currentChannel]]];
    
        [mView setVisualRangeForXAxisFrom:[self visualMinX] to:[self visualMaxX]];
        [mView setVisualRangeForYAxisFrom:[self visualMinY] to:[self visualMaxY]];

        if([mData kind]==KIND_SONO)
        {
            [mView setRangeForZAxisFrom:0 to:[mData maxZOfChannel:LEFT_CHANNEL]];
            [mView setVisualRangeForZAxisFrom:0 to:[mData maxZOfChannel:LEFT_CHANNEL]];
        }
        
        [mView checkRanges];
        
        [mView setCursorPositionX:mViewCursorX positionY:mViewCursorY];
        [mView setPlayerHeadPosition:mViewPlayerHeadPosition];
        [mView setSelectionRangeForXAxisFrom:[self selMinX] to:[self selMaxX]];
    }
}

- (void)drawCustomRect:(NSRect)rect
{
    if(![self allowsFFTSize])
        return;
        
    FLOAT cursor = [mView computeXPixelFromXRealValue:[mView xCursorPosition]];
    FLOAT delta = [mView computeXDeltaPixelFromRealValue:(FLOAT)mFFTSize / mDataRate];
    
    NSPoint p1 = NSMakePoint(cursor, rect.origin.y);
    NSPoint p2 = NSMakePoint(cursor+delta, rect.size.height+rect.origin.y);

    [[self fftSizeColor] set];
    [NSBezierPath fillRect:NSMakeRect(p1.x, p1.y, p2.x-p1.x, p2.y)];
}

- (BOOL)supportFFT
{
    return [mData isKindOfClass:[AudioDataAmplitude class]];
}

- (BOOL)supportSono
{
    return [mData isKindOfClass:[AudioDataAmplitude class]];
}

@end

@implementation AudioDataWrapper (Appearance)

- (void)initAppearanceWithCoder:(NSCoder*)coder
{    
    [coder decodeValueOfObjCType:@encode(BOOL) at:&mAllowsFFTSize];
    [self setFFTSizeColor:[coder decodeObject]];
}

- (void)encodeAppearanceWithCoder:(NSCoder*)coder
{
    [coder encodeValueOfObjCType:@encode(BOOL) at:&mAllowsFFTSize];
    [coder encodeObject:[self fftSizeColor]];
}

- (void)defaultAppearanceValues
{
    [self setAllowsFFTSize:NO];
    [self setFFTSizeColor:[NSColor colorWithDeviceRed:0 green:0 blue:1 alpha:0.5]];
}

- (void)setAllowsFFTSize:(BOOL)flag
{
    mAllowsFFTSize = flag;
}
- (void)setFFTSizeColor:(NSColor*)color
{
    [mFFTSizeColor autorelease];
    mFFTSizeColor = [color retain];
}

- (BOOL)allowsFFTSize
{
    return mAllowsFFTSize;
}
- (NSColor*)fftSizeColor
{
    return mFFTSizeColor;
}

@end

@implementation AudioDataWrapper (Info)

- (USHORT)numberOfChannels
{
    return [self stereoChannelExists]?2:1;
}

- (NSString*)infoNumberOfChannels
{
    return [NSString stringWithFormat:@"%d", [self numberOfChannels]];
}

- (NSString*)infoSampleRate
{
    return [NSString stringWithFormat:@"%d Hz", [self dataRate]];
}

- (NSString*)infoSampleSize
{
    return @"32 Bits";
}

- (NSString*)infoSoundSize
{
    ULONG size = 0;
    switch([self kind]) {
        case KIND_AMPLITUDE:
        case KIND_FFT:
            size = [mData maxIndex]*[self numberOfChannels]*4;
            break;
        case KIND_SONO:
            size = (ULONG)[mData maxFFT]*(ULONG)[mData fftWindowWidth]*0.5*4;
            break;
    }
    size /= 1000;
    return [NSString stringWithFormat:@"%d Kb", size];
}

- (NSString*)infoHorizontalResolution
{
    NSString *unit = NULL;
    DOUBLE res = 0, value = 0;
    
    switch([self kind]) {
        case KIND_AMPLITUDE:
            res = 1.0/[mData dataRate];
            unit = [mData xAxisUnitForRange:res];
            value = [mData xAxisUnitFactorForRange:res]*res;
            break;
        case KIND_SONO:
            res = ([mData maxXOfChannel:LEFT_CHANNEL]-[mData minXOfChannel:LEFT_CHANNEL])/(ULONG)[mData maxFFT];
            unit = [mData xAxisUnitForRange:res];
            value = [mData xAxisUnitFactorForRange:res]*res;
            break;
        case KIND_FFT:
            res = 1.0/[mData deltaT];
            unit = [mData xAxisUnitForRange:res];
            value = [mData xAxisUnitFactorForRange:res]*res;
            break;
    }

    return [NSString stringWithFormat:@"%5.2f %@", value, unit];
}

- (NSString*)infoVerticalResolution
{
    NSString *unit = NULL;
    DOUBLE res = 0, value = 0;
    
    switch([self kind]) {
        case KIND_AMPLITUDE:
        case KIND_FFT:
            return @"-"; // Pas de signification
            break;
        case KIND_SONO:
            res = (float)[mData maxYOfChannel:LEFT_CHANNEL]/((ULONG)[mData fftWindowWidth]*0.5);
            unit = [mData yAxisUnitForRange:res];
            value = [mData yAxisUnitFactorForRange:res]*res;
            break;
    }

    return [NSString stringWithFormat:@"%5.2f %@", value, unit];
}

@end

@implementation AudioDataWrapper (Parameters)

- (FLOAT)convertFactorFromUnit:(SHORT)sourceUnit toUnit:(SHORT)targetUnit
{
    switch(sourceUnit) {
        case UNIT_POINTS:
            if(targetUnit==UNIT_MS) return 1.0/mDataRate*1000;
            if(targetUnit==UNIT_S) return 1.0/mDataRate;
            break;
        case UNIT_MS:
            if(targetUnit==UNIT_POINTS) return 1.0/1000*mDataRate;
            if(targetUnit==UNIT_S) return 1.0/1000;
            break;
        case UNIT_S:
            if(targetUnit==UNIT_POINTS) return mDataRate;
            if(targetUnit==UNIT_MS) return 1000;
            break;
        default:
            NSLog(@"Unknown unit (%d)", sourceUnit);
    }
    
    return 1;
}

- (FLOAT)convertLong:(SLONG)value fromUnit:(SHORT)sourceUnit toUnit:(SHORT)targetUnit
{
    FLOAT factor = [self convertFactorFromUnit:sourceUnit toUnit:targetUnit];
    return value*factor;
}

- (SLONG)convertFloat:(FLOAT)value fromUnit:(SHORT)sourceUnit toUnit:(SHORT)targetUnit
{
    FLOAT factor = [self convertFactorFromUnit:sourceUnit toUnit:targetUnit];
    return round(value*factor);
}

- (void)setFFTWindowFunctionID:(SHORT)windowID
{
    mFFTWindowFunctionID = windowID;
}

- (SHORT)fftWindowFunctionID
{
    return mFFTWindowFunctionID;
}

- (void)setFFTWindowFunctionParameterValue:(FLOAT)value
{
    mFFTWindowFunctionParameter = value;
}

- (FLOAT)fftWindowFunctionParameterValue
{
    return mFFTWindowFunctionParameter;
}

- (NSArray*)fftWindowParametersArray
{
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:mFFTWindowFunctionID],
                                        [NSNumber numberWithFloat:mFFTWindowFunctionParameter],
                                        NULL];
}

- (void)setSonoWindowFunctionID:(SHORT)windowID
{
    mSonoWindowFunctionID = windowID;
}

- (SHORT)sonoWindowFunctionID
{
    return mSonoWindowFunctionID;
}

- (void)setSonoWindowFunctionParameterValue:(FLOAT)value
{
    mSonoWindowFunctionParameter = value;
}

- (FLOAT)sonoWindowFunctionParameterValue
{
    return mSonoWindowFunctionParameter;
}

- (NSArray*)sonoWindowParametersArray
{
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:mSonoWindowFunctionID],
                                        [NSNumber numberWithFloat:mSonoWindowFunctionParameter],
                                        NULL];
}

- (void)setWindowSize:(FLOAT)windowSize fromUnit:(SHORT)unit
{
    mWindowSize = [self convertFloat:windowSize fromUnit:unit toUnit:UNIT_POINTS];
}

- (void)setWindowOffset:(FLOAT)windowOffset fromUnit:(SHORT)unit
{
    mWindowOffset = [self convertFloat:windowOffset fromUnit:unit toUnit:UNIT_POINTS];
}

- (void)setFFTSize:(FLOAT)fftSize fromUnit:(SHORT)unit
{
    mFFTSize = [self convertFloat:fftSize fromUnit:unit toUnit:UNIT_POINTS];
}

- (void)setDataRate:(ULONG)rate
{
    mDataRate = rate;
}

- (ULONG)dataRate
{
    return mDataRate;
}

- (void)setXAxisScale:(SHORT)scale
{
    if([mData respondsToSelector:@selector(setXAxisScale:)])
    {
        [mData setXAxisScale:scale];
        [mView setXAxisUnit:[mData xAxisUnit]];        
    }
}

- (SHORT)xAxisScale
{
    if([mData respondsToSelector:@selector(xAxisScale)])
        return [mData xAxisScale];
    else
        return XAxisLinearScale;
}

- (void)setYAxisScale:(SHORT)scale
{
    if([mData respondsToSelector:@selector(setYAxisScale:)])
    {
        [mData setYAxisScale:scale];
        [mView setYAxisUnit:[mData yAxisUnit]];        
    }
}

- (SHORT)yAxisScale
{
    if([mData respondsToSelector:@selector(yAxisScale)])
        return [mData yAxisScale];
    else
        return YAxisLinearScale;
}

- (BOOL)selectionExist
{
    return [self selMinX]!=[self selMaxX];
}

- (void)setViewVisualMinX:(FLOAT)minX maxX:(FLOAT)maxX
{
    mViewVisualMinX = minX;
    mViewVisualMaxX = maxX;
}

- (void)setViewVisualMinY:(FLOAT)minY maxY:(FLOAT)maxY
{
    mViewVisualMinY = minY;
    mViewVisualMaxY = maxY;
}

- (void)setViewCursorX:(FLOAT)x cursorY:(FLOAT)y
{
    mViewCursorX = x;
    mViewCursorY = y;
}

- (void)setViewSelMinX:(FLOAT)minX maxX:(FLOAT)maxX
{
    mViewSelMinX = minX;
    mViewSelMaxX = maxX;
}

- (void)setViewPlayerHeadPosition:(FLOAT)x
{
    mViewPlayerHeadPosition = x;
}

- (FLOAT)visualMinX
{
    return mViewVisualMinX;
}

- (FLOAT)visualMaxX
{
    return mViewVisualMaxX;
}

- (FLOAT)visualMinY
{
    return mViewVisualMinY;
}

- (FLOAT)visualMaxY
{
    return mViewVisualMaxY;
}

- (FLOAT)selMinX
{
    return mViewSelMinX;
}

- (FLOAT)selMaxX
{
    return mViewSelMaxX;
}

- (FLOAT)cursorX
{
    return mViewCursorX;
}

- (FLOAT)cursorY
{
    return mViewCursorY;
}

- (FLOAT)cursorZ
{
    if([mData respondsToSelector:@selector(zValueAtX:y:)])
        return [mData zValueAtX:[self cursorX] y:[self cursorY]];
    else
        return 0;
}

- (FLOAT)playerHeadPosition
{
    return mViewPlayerHeadPosition;
}

- (FLOAT)windowSizeForUnit:(SHORT)unit
{
    return [self convertLong:mWindowSize fromUnit:UNIT_POINTS toUnit:unit];
}

- (FLOAT)windowOffsetForUnit:(SHORT)unit
{
    return [self convertLong:mWindowOffset fromUnit:UNIT_POINTS toUnit:unit];
}

- (FLOAT)fftSizeForUnit:(SHORT)unit
{
    return [self convertLong:mFFTSize fromUnit:UNIT_POINTS toUnit:unit];
}

- (ULONG)windowSize
{
    return [self windowSizeForUnit:UNIT_POINTS];
}

- (ULONG)windowOffset
{
    return [self windowOffsetForUnit:UNIT_POINTS];
}

- (ULONG)fftSize
{
    return [self fftSizeForUnit:UNIT_POINTS];
}

- (ULONG)fftSize2
{
    return [self fftSize]*0.5;
}

- (ULONG)fftLog2
{
    return log([self fftSize])/log(2);
}

- (FLOAT)deltaT
{
    return mViewSelMaxX-mViewSelMinX;
}

@end

@implementation AudioDataWrapper (Notification)

- (void)audioViewCursorHasChangedNotification:(NSNotification*)notif
{
    AudioView *view = [notif object];
    if([view viewID] == mLinkedViewID
        && mLinkState
        && [view window] == [mView window])
        [self linkToView:view];
}

@end

@implementation AudioDataWrapper (Delegate)

- (void)audioViewSelectionHasChanged:(AudioView*)view
{
    [self setViewSelMinX:[view xAxisSelectionRangeFrom] maxX:[view xAxisSelectionRangeTo]];
}

- (void)audioViewCursorHasChanged:(AudioView*)view
{
    [self setViewCursorX:[view xCursorPosition] cursorY:[view yCursorPosition]];
}

- (void)audioViewScaleHasChanged:(AudioView*)view
{
    [self setViewVisualMinX:[view xAxisRangeFrom] maxX:[view xAxisRangeTo]];
    [self setViewVisualMinY:[view yAxisRangeFrom] maxY:[view yAxisRangeTo]];
}

- (void)audioViewPlayerHeadHasChanged:(AudioView*)view
{
    [self setViewPlayerHeadPosition:[view playerHeadPosition]];
}

- (void)audioViewDidSelected:(AudioView*)view
{
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioWrapperDidBecomeSelectNotification
                                            object:self];
    [[mWindowController window] makeFirstResponder:view];
}

@end

@implementation AudioDataWrapper (LinkWith2DModel)

- (void)setViewNameImmutable:(BOOL)flag
{
    mViewNameImmutable = flag;
}

- (BOOL)viewNameImmutable
{
    return mViewNameImmutable;
}

- (void)setViewName:(NSString*)name always:(BOOL)always;
{
    if(mViewNameImmutable && always == NO) return;
    
    [mViewName autorelease];
    mViewName = [name retain];
    [mView setViewName:mViewName];
}
- (NSString*)viewName { return mViewName; }
- (void)setViewID:(ULONG)viewID
{
    [mView setViewID:viewID];
}
- (ULONG)viewID { return [mView viewID]; }
- (NSString*)xAxisUnit { return [mData xAxisUnit]; }
- (NSString*)yAxisUnit { return [mData yAxisUnit]; }
- (NSString*)xAxisName { return [mData xAxisName]; }
- (NSString*)yAxisName { return [mData yAxisName]; }
- (SHORT)kind { return [mData kind]; }
- (FLOAT)yValueAtX:(FLOAT)x channel:(SHORT)channel { return [mData yValueAtX:x channel:channel]; }

- (FLOAT)minXOfChannel:(SHORT)channel { return [mData minXOfChannel:channel]; }
- (FLOAT)maxXOfChannel:(SHORT)channel { return [mData maxXOfChannel:channel]; }
- (FLOAT)minYOfChannel:(SHORT)channel { return [mData minYOfChannel:channel]; }
- (FLOAT)maxYOfChannel:(SHORT)channel { return [mData maxYOfChannel:channel]; }
- (BOOL)supportTrigger { return [mData supportTrigger]; }
- (BOOL)supportPlayback { return [mData supportPlayback]; }
- (BOOL)supportHarmonicCursor { return [mData supportHarmonicCursor]; }

@end

@implementation AudioDataWrapper (LinkWith3DModel)

- (NSString*)zAxisUnit { return @""; }

- (void)setImageContrast:(FLOAT)contrast
{
    if([mData respondsToSelector:@selector(setImageContrast:)])
        [mData setImageContrast:contrast];
}

- (FLOAT)imageContrast
{
    if([mData respondsToSelector:@selector(imageContrast)])
        return [mData imageContrast];
    else
        return 0;
}

- (void)setImageGain:(FLOAT)gain
{
    if([mData respondsToSelector:@selector(setImageGain:)])
        [mData setImageGain:gain];
}

- (FLOAT)imageGain
{
    if([mData respondsToSelector:@selector(imageGain)])
        return [mData imageGain];
    else
        return 0;
}

- (void)setInverseVideo:(BOOL)flag
{
    if([mData respondsToSelector:@selector(setInverseVideo:)])
        [mData setInverseVideo:flag];
}

- (BOOL)inverseVideo
{
    if([mData respondsToSelector:@selector(inverseVideo)])
        return [mData inverseVideo];
    else
        return NO;
}

- (void)setMinThreshold:(FLOAT)value
{
    if([mData respondsToSelector:@selector(setMinThreshold:)])
        [mData setMinThreshold:value];
}

- (FLOAT)minThreshold
{
    if([mData respondsToSelector:@selector(minThreshold)])
        return [mData minThreshold];
    else
        return 0;
}

- (void)setMaxThreshold:(FLOAT)value
{
    if([mData respondsToSelector:@selector(setMaxThreshold:)])
        [mData setMaxThreshold:value];
}

- (FLOAT)maxThreshold
{
    if([mData respondsToSelector:@selector(maxThreshold)])
        return [mData maxThreshold];
    else
        return 0;
}

- (FLOAT)minThresholdValue
{
    if([mData respondsToSelector:@selector(minThresholdValue)])
        return [mData minThresholdValue];
    else
        return 0;
}

- (FLOAT)maxThresholdValue
{
    if([mData respondsToSelector:@selector(maxThresholdValue)])
        return [mData maxThresholdValue];
    else
        return 0;
}

- (FLOAT)zValueAtX:(FLOAT)x y:(FLOAT)y
{
    if([mData respondsToSelector:@selector(zValueAtX::)])
        return [mData zValueAtX:x y:y];
    else
        return 0;
}

- (void)renderImage { [mData createImage]; }
- (CGImageRef)imageQ2D { return [mData imageQ2D]; }

@end

