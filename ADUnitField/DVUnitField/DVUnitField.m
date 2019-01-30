//
//  DVUnitField.m
//  DVUnitField
//
//  Created by David on 2018/12/17.
//  Copyright © 2018年 DVIOS. All rights reserved.
//

#import "DVUnitField.h"

@interface DVUnitField ()

@property (nonatomic, assign) DVUnitFieldStyle style;
@property (nonatomic, strong) CALayer *cursorLayer; ///< 光标颜色
@property (nonatomic, strong) NSMutableArray <NSString*>*characterArray;

@end

@implementation DVUnitField
{
    CGContextRef _ctx;  /// < 上下文
    UIColor *_backgroundColor;  /// <背景色
}

- (instancetype)initWithInputUnitCount:(NSUInteger)count
{
    return [self initWithStyle:DVUnitFieldStyleBorder count:count];
}

- (instancetype)initWithStyle:(DVUnitFieldStyle)style count:(NSUInteger)count
{
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;
    
    _style = style;
    _inputUnitCount = count;
    [self _initialize];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _inputUnitCount = 4;
        [self _initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _inputUnitCount = 4;
        [self _initialize];
    }
    return self;
}

- (void)_initialize
{
    [self setBackgroundColor:[UIColor clearColor]];
    self.opaque = NO;
    _cursorColor = [UIColor orangeColor];
    self.cursorLayer.backgroundColor = _cursorColor.CGColor;
    _backgroundColor = _backgroundColor ?: UIColor.clearColor;
     _trackTintColor = [UIColor orangeColor];
    _borderRadius = 0;
    _borderWidth = 1;
    _characterArray = @[].mutableCopy;
    _textColor = [UIColor darkGrayColor];
    _textFont = [UIFont systemFontOfSize:22];
    _tintColor = [UIColor lightGrayColor];
    _unitSpace = 12;
    [self.layer addSublayer:self.cursorLayer];
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self becomeFirstResponder];
}

- (void)drawRect:(CGRect)rect
{
    CGSize unitSize = CGSizeMake((rect.size.width + _unitSpace)/_inputUnitCount - _unitSpace, rect.size.height);
    _ctx = UIGraphicsGetCurrentContext();
    
    [self _fillRect:rect clip:YES];
    [self _drawBorder:rect unitSize:unitSize];
    [self _drawText:rect unitSize:unitSize];
    [self _drawTrackBorder:rect unitSize:unitSize];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL result = [super becomeFirstResponder];
    [self _resetCursorStateIfNeed];
    if (result){
        [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UnitFieldDidBecomeFirstResponderNotification" object:nil];
    }
    return result;
}

- (BOOL)canResignFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    BOOL result = [super resignFirstResponder];
    [self _resetCursorStateIfNeed];
    if (result){
        [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
         [[NSNotificationCenter defaultCenter] postNotificationName:@"UnitFieldDidResignFirstResponderNotification" object:nil];
    }
    return result;
}

/**
 在 AutoLayout 环境下重新指定控件本身的固有尺寸
 
 `-drawRect:`方法会计算控件完成自身的绘制所需的合适尺寸，完成一次绘制后会通知 AutoLayout 系统更新尺寸。
 */
- (void)_resize {
    [self invalidateIntrinsicContentSize];
}


- (void)_fillRect:(CGRect)rect clip:(BOOL)clip
{
    [_backgroundColor setFill];
    if (clip){
        CGFloat radius = _style == DVUnitFieldStyleBorder ? _borderRadius : 0;
        CGContextAddPath(_ctx, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius].CGPath);
        CGContextClip(_ctx);
    }
    CGContextAddPath(_ctx, [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, _borderWidth*0.75, _borderWidth*0.75) cornerRadius:_borderRadius].CGPath);
    CGContextFillPath(_ctx);
}

- (void)_drawBorder:(CGRect)rect unitSize:(CGSize)unitSize
{
    CGRect bounds = CGRectInset(rect, _borderWidth*0.5, _borderWidth*0.5);
    if (_style == DVUnitFieldStyleBorder)
    {
        [self.tintColor setStroke];
        CGContextSetLineWidth(_ctx, _borderWidth);
        CGContextSetLineCap(_ctx, kCGLineCapRound);
        
        if (_unitSpace < 2){
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:_borderRadius];
            CGContextAddPath(_ctx, bezierPath.CGPath);
            
            for (NSUInteger i = 0; i<_inputUnitCount; i++) {
                CGContextMoveToPoint(_ctx, i*unitSize.width, 0);
                CGContextAddLineToPoint(_ctx, i*unitSize.width, unitSize.height);
            }
        } else{
            for (NSUInteger i = self.characterArray.count;i<_inputUnitCount; i++) {
                CGRect unitRect = CGRectMake(i*(unitSize.width + _unitSpace), 0, unitSize.width, unitSize.height);
                unitRect = CGRectInset(unitRect, _borderWidth*0.5, _borderWidth*0.5);
                UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitRect cornerRadius:_borderRadius];
                CGContextAddPath(_ctx, bezierPath.CGPath);
            }
            
        }
        CGContextDrawPath(_ctx, kCGPathStroke);
    }
    else
    {
        [self.tintColor setFill];
        for (int i= (int)_characterArray.count; i<_inputUnitCount; i++) {
            CGRect unitLineRect = CGRectMake(i*(unitSize.width+_unitSpace), unitSize.height-_borderWidth, unitSize.width, _borderWidth);
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitLineRect cornerRadius:_borderRadius];
            CGContextAddPath(_ctx, bezierPath.CGPath);
        }
        CGContextDrawPath(_ctx, kCGPathFill);
    }
}

// 文本绘制。 当密文的时候圆圈会代替文本
- (void)_drawText:(CGRect)rect unitSize:(CGSize)size
{
    if ([self hasText] == NO) return;
    NSDictionary *attr = @{NSForegroundColorAttributeName:_textColor,NSFontAttributeName:_textFont};
    for (int i = 0; i < self.characterArray.count; i++) {
        CGRect unitRect = CGRectMake(i*(size.width + _unitSpace), 0, size.width, size.height);
        CGFloat yOffset = _style == DVUnitFieldStyleBorder ? 0 : _borderWidth;
        if (!self.secureTextEntry) // 非加密
        {
            NSString *subString = [self.characterArray objectAtIndex:i];
            CGSize oneSize = [subString sizeWithAttributes:attr];
            CGRect drawRect = CGRectInset(unitRect, (unitRect.size.width - oneSize.width)/2, (unitRect.size.height - oneSize.height)/2);
            drawRect.size.height -= yOffset;
            [subString drawInRect:drawRect withAttributes:attr];
        }
        else
        {
            CGRect drawRect = CGRectInset(unitRect, unitRect.size.width - _textFont.pointSize/2, unitRect.size.height - _textFont.pointSize/2);
            [_textColor setFill];
            CGContextAddEllipseInRect(_ctx, drawRect);
            CGContextFillPath(_ctx);
        }
    }
}

- (void)_drawTrackBorder:(CGRect)rect unitSize:(CGSize)unitSize
{
    if (_trackTintColor == nil) return;
    
    if (_style == DVUnitFieldStyleBorder)
    {
        if (_unitSpace < 2) return;
       
        [_trackTintColor setStroke];
        
        CGContextSetLineWidth(_ctx, _borderWidth);
        CGContextSetLineCap(_ctx, kCGLineCapRound);
        for (int i = 0; i < _characterArray.count; i++) {
            CGRect unitRect = CGRectMake(i * (unitSize.width + _unitSpace),
                                         0,
                                         unitSize.width,
                                         unitSize.height);
            unitRect = CGRectInset(unitRect, _borderWidth * 0.5, _borderWidth * 0.5);
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitRect cornerRadius:_borderRadius];
            CGContextAddPath(_ctx, bezierPath.CGPath);
        }
        CGContextDrawPath(_ctx, kCGPathStroke);
    }else{
        [_trackTintColor setFill];
        
        for (int i = 0; i < _characterArray.count; i++) {
            CGRect unitLineRect = CGRectMake(i * (unitSize.width + _unitSpace),
                                             unitSize.height - _borderWidth,
                                             unitSize.width,
                                             _borderWidth);
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:unitLineRect cornerRadius:_borderRadius];
            CGContextAddPath(_ctx, bezierPath.CGPath);
        }
        
        CGContextDrawPath(_ctx, kCGPathFill);
    }
}

#pragma mark - UIKeyInput

- (BOOL)hasText
{
    return self.characterArray != nil && self.characterArray.count>0;
}

- (void)insertText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self resignFirstResponder];
        }];
        return;
    }
    if ((self.characterArray.count > self.inputUnitCount))
    {
        if (self.autoResignFirstResponderWhenInputFinished){
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self resignFirstResponder];
            }];
        }
        return;
    }
    // 如果为空格
    if ([text isEqualToString:@" "])
    {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(unitField:shouldChangeCharactersInRange:replacementString:)] && ![self.delegate unitField:self shouldChangeCharactersInRange:NSMakeRange(self.text.length, text.length) replacementString:text])
    {
        return;
    }
    NSRange range;
    for (int i = 0; i<text.length; i += range.length)
    {
        range = [text rangeOfComposedCharacterSequenceAtIndex:i];
        [self.characterArray addObject:[text substringWithRange:range]];
    }
    // 1. 如果超过范围了。缩减到正常范围 2. 然后如果字动弹回键盘,执行自动弹回键盘的操作
    if (self.characterArray.count > self.inputUnitCount)
    {
        [self.characterArray removeObjectsInRange:NSMakeRange(self.inputUnitCount, self.characterArray.count - self.inputUnitCount)];
        [self sendActionsForControlEvents:UIControlEventEditingChanged];
        if (self.autoResignFirstResponderWhenInputFinished){
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self resignFirstResponder];
            }];
        }
    }else{
        [self sendActionsForControlEvents:UIControlEventEditingChanged];
    }
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeed];
}

- (void)deleteBackward
{
   // 1. 如果没有内容,则return  2. 数组中删除,发出EditingChange的消息 3.重绘 4.改变光标的位置
    if (![self hasText])
    {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(unitField:shouldChangeCharactersInRange:replacementString:)])
    {
        CGFloat length = [self.characterArray.lastObject length] ?:0;
        if ([self.delegate unitField:self shouldChangeCharactersInRange:NSMakeRange(MAX(0, self.text.length - length), length) replacementString:@""] == NO)
        {
            return;
        }
    }
    
    [self.characterArray removeLastObject];
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
    
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeed];
}

#pragma mark - Public

- (NSString *)text
{
    if (self.characterArray.count == 0) return nil;
    return [self.characterArray componentsJoinedByString:@""];
}

- (void)setText:(NSString *)text
{
    [self.characterArray removeAllObjects];
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        if (self.characterArray.count < self.inputUnitCount){
            [self.characterArray addObject:substring];
        }else{
            *stop = YES;
        }
    }];
    [self setNeedsDisplay];
}

- (void)setSecureTextEntry:(BOOL)secureTextEntry
{
    _secureTextEntry = secureTextEntry;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeed];
}

- (void)setTextColor:(UIColor *)textColor
{
    UIColor *curColor = textColor ?:[UIColor blackColor];
    _textColor = curColor;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeed];
}

- (void)setTextFont:(UIFont *)textFont {
    if (textFont == nil) {
        _textFont = [UIFont systemFontOfSize:22];
    } else {
        _textFont = textFont;
    }
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeed];
}

- (void)setBorderRadius:(CGFloat)borderRadius
{
    if (borderRadius < 0) return;
    
    _borderRadius = borderRadius;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeed];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    if (borderWidth < 0) return;
    
    _borderWidth = borderWidth;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeed];
}

- (void)setTintColor:(UIColor *)tintColor {
    if (tintColor == nil) {
        _tintColor = [[UIView appearance] tintColor];
    } else {
        _tintColor = tintColor;
    }
    
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeed];
}

- (void)setTrackTintColor:(UIColor *)trackTintColor {
    _trackTintColor = trackTintColor;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeed];
}

- (void)setCursorColor:(UIColor *)cursorColor {
    _cursorColor = cursorColor;
    _cursorLayer.backgroundColor = _cursorColor.CGColor;
    [self _resetCursorStateIfNeed];
}

- (void)setUnitSize:(CGSize)unitSize {
    _unitSize = unitSize;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeed];
}

- (void)setUnitSpace:(NSUInteger)unitSpace
{
    if (unitSpace < 2) unitSpace = 0;
    [self _resize];
    _unitSpace = unitSpace;
    [self setNeedsDisplay];
    [self _resetCursorStateIfNeed];
}

#pragma mark - private

- (CALayer *)cursorLayer
{
    if (_cursorLayer == nil){
        _cursorLayer = [CALayer layer];
        _cursorLayer.hidden = YES;
        _cursorLayer.opaque = 1;
        
        CABasicAnimation *animate = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animate.fromValue = @0;
        animate.toValue = @1.5;
        animate.duration = 0.5;
        animate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        animate.autoreverses = YES;
        animate.removedOnCompletion = NO;
        animate.fillMode = kCAFillModeForwards;
        animate.repeatCount = HUGE_VALF;
        
        [_cursorLayer addAnimation:animate forKey:nil];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self setNeedsDisplay];
            self.cursorLayer.position = CGPointMake(CGRectGetWidth(self.bounds)/2/self.inputUnitCount, CGRectGetHeight(self.bounds));
        }];
    }
    return _cursorLayer;
}

// 重置光标的位置
- (void)_resetCursorStateIfNeed
{
    _cursorLayer.hidden = !self.isFirstResponder || _cursorLayer == nil || self.inputUnitCount == _characterArray.count;
    if (_cursorLayer.hidden) return;
    // 每个元素的尺寸
    CGSize unitSize = CGSizeMake((self.bounds.size.width + _unitSpace)/_inputUnitCount - _unitSpace, self.bounds.size.height);
    // 最后一个滑块的frame
    CGRect unitRect = CGRectMake((unitSize.width + _unitSpace)*self.characterArray.count , 0, unitSize.width, unitSize.height);
    // 最后一个滑块的中心
    unitRect = CGRectInset(unitRect, unitRect.size.width/2-1, (unitRect.size.height - _textFont.pointSize)/2);
    CGFloat offset = _style == DVUnitFieldStyleBorder ? 0 :1;
    unitRect.origin.y -= offset;
    [CATransaction begin];
    [CATransaction setDisableActions:NO];
    [CATransaction setAnimationDuration:0];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    _cursorLayer.frame = unitRect;
    [CATransaction commit];
}


@end
