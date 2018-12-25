//
//  ADUnitField.h
//  ADUnitField
//
//  Created by David on 2018/12/17.
//  Copyright © 2018年 ADIOS. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ADUnitField;

NS_ASSUME_NONNULL_BEGIN

@protocol ADUnitFieldDelegate <UITextFieldDelegate>

@optional
- (BOOL)unitField:(ADUnitField *)uniField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

@end


/**
 UnitField 的外观风格
 
 - WLUnitFieldStyleBorder: 边框样式, UnitField 的默认样式
 - WLUnitFieldStyleUnderline: 下滑线样式
 */
typedef NS_ENUM(NSUInteger, ADUnitFieldStyle) {
    ADUnitFieldStyleBorder,
    ADUnitFieldStyleUnderline
};

@interface ADUnitField : UIControl <UIKeyInput>

- (instancetype)initWithInputUnitCount:(NSUInteger)count;
- (instancetype)initWithStyle:(ADUnitFieldStyle)style count:(NSUInteger)count;

@property (nullable, nonatomic, weak) id<ADUnitFieldDelegate> delegate;

@property (nonatomic, assign, readonly) ADUnitFieldStyle style;   /// <边框和下划线
@property (nonatomic, assign, readonly) NSUInteger inputUnitCount;  /// <允许输入的行数

// 每个item直接的间距
@property (nonatomic, assign) IBInspectable NSUInteger unitSpace;

@property (nonatomic, assign) BOOL secureTextEntry;

/**
 设置文本字体
 */
@property (nonatomic, strong) IBInspectable UIFont *textFont;

@property (null_resettable, nonatomic, strong) IBInspectable UIColor *tintColor;

@property (nullable, nonatomic, strong) IBInspectable UIColor *trackTintColor;

@property (nullable, nonatomic, strong) IBInspectable UIColor *cursorColor;
/**
 文本的颜色
 */
@property (null_resettable, nonatomic, strong) IBInspectable UIColor *textColor;

/**
 设置边框宽度，默认为 1。
 */
@property (nonatomic, assign) IBInspectable CGFloat borderWidth;

@property (nonatomic, assign) IBInspectable CGFloat borderRadius;

@property (nonatomic, assign) IBInspectable CGSize unitSize;

/**
 保留的用户输入的字符串，最好使用数字字符串，因为目前还不支持其他字符。
 */
@property (nullable, nonatomic, copy) IBInspectable NSString *text;

/**
 当输入完成后，是否需要自动取消第一响应者。默认为 NO。
 */
@property (nonatomic, assign) IBInspectable BOOL autoResignFirstResponderWhenInputFinished;

@end

NS_ASSUME_NONNULL_END
