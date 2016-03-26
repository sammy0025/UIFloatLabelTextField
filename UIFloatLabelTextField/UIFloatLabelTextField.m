//
//  UIFloatLabelTextField.m
//  UIFloatLabelTextField
//
//  Created by Arthur Sabintsev on 3/3/14.
//  Copyright (c) 2014 Arthur Ariel Sabintsev. All rights reserved.
//

#import "UIFloatLabelTextField.h"

IB_DESIGNABLE
@interface UIFloatLabelTextField ()

@property (nonatomic, copy) NSString *storedText;
@property (nonatomic, strong) UIButton *clearTextFieldButton;
@property (nonatomic, assign) CGFloat xOrigin;

@property (nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat cornerRadius;
@property (nonatomic) IBInspectable CGFloat borderWidth;

@end

@implementation UIFloatLabelTextField

#pragma mark - Initialization
- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
        [self setPlaceholder:self.placeholder];
    }
    
    return self;
}

#pragma mark - Breakdown
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:nil];
}

#pragma mark - Setup
- (void)setup
{
    // Build textField
    [self setupTextField];
    
    // Reference Apple's clearButton and add animation
    [self setupClearTextFieldButton];
    
    // Build floatLabel
    [self setupFloatLabel];
    
    // Enable default UIMenuController options
    [self setupMenuController];
}

- (void)setupTextField
{
    // Textfield Padding
    _horizontalPadding = 10.0f;
    
    // Text Alignment
    [self setTextAlignment:NSTextAlignmentLeft];
    
    // Enable clearButton when textField becomes firstResponder
    self.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    // Setup default values
    _borderColor = [UIColor colorWithRed:213.0f/255.0f green:221.0f/255.0f blue:224.0f/255.0f alpha:1];
    _cornerRadius = 2.0f;
    _borderWidth = 1;
    
    // Enable textfield border
    self.layer.cornerRadius = _cornerRadius;
    self.layer.borderColor = _borderColor.CGColor;
    self.layer.borderWidth = _borderWidth;
    self.layer.masksToBounds = NO;
    
    /*
     Observer for replicating `textField:shouldChangeCharactersInRange:replacementString:` UITextFieldDelegate method,
     without explicitly using UITextFieldDelegate.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)setupClearTextFieldButton
{
    // A boolean that toggles the state of the keyboard after the clear-text button is pressed.
    _dismissKeyboardWhenClearingTextField = @NO;
    
    // Create selector for Apple's built-in UITextField button - clearButton
    SEL clearButtonSelector = NSSelectorFromString(@"clearButton");
    
    // Reference clearButton getter
    IMP clearButtonImplementation = [self methodForSelector:clearButtonSelector];
    
    // Create function pointer that returns UIButton from implementation of method that contains clearButtonSelector
    UIButton * (* clearButtonFunctionPointer)(id, SEL) = (UIButton *(*)(id, SEL))clearButtonImplementation;
    
    // Set clearTextFieldButton reference to "clearButton" from clearButtonSelector
    _clearTextFieldButton = clearButtonFunctionPointer(self, clearButtonSelector);
    
    if (_clearTextFieldButton) {
        // Remove all clearTextFieldButton target-actions (e.g., Apple's standard clearButton actions)
        [self.clearTextFieldButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        
        // Add new target-action for clearTextFieldButton
        [_clearTextFieldButton addTarget:self action:@selector(clearTextField) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupFloatLabel
{
    // floatLabel
    _floatLabel = [UILabel new];
    _floatLabel.textColor = [UIColor blackColor];
    _floatLabel.font =[UIFont boldSystemFontOfSize:12.0f];
    _floatLabel.alpha = 0.0f;
    [_floatLabel setCenter:CGPointMake(_xOrigin - 5.0f, 0.0f)];
    [self addSubview:_floatLabel];
    
    // colors
    _floatLabelPassiveColor = [UIColor lightGrayColor];
    _floatLabelActiveColor = [UIColor colorWithRed:0 green:0.48f blue:1 alpha:1];
    
    // animationDuration
    _floatLabelShowAnimationDuration = @0.25f;
    _floatLabelHideAnimationDuration = @0.05f;
}

- (void)setupMenuController
{
    _pastingEnabled = @YES;
    _copyingEnabled = @YES;
    _cuttingEnabled = @YES;
    _selectEnabled = @YES;
    _selectAllEnabled = @YES;
}

#pragma mark - Animation
- (void)toggleFloatLabel:(UIFloatLabelAnimationType)animationType
{
    // Placeholder
    self.placeholder = (animationType == UIFloatLabelAnimationTypeShow) ? @"" : [_floatLabel text];
    
    // Reference textAlignment to reset origin of textField and floatLabel
    _floatLabel.textAlignment = self.textAlignment = [self textAlignment];
    
    // Common animation parameters
    UIViewAnimationOptions easingOptions = (animationType == UIFloatLabelAnimationTypeShow) ? UIViewAnimationOptionCurveEaseOut : UIViewAnimationOptionCurveEaseIn;
    UIViewAnimationOptions combinedOptions = UIViewAnimationOptionBeginFromCurrentState | easingOptions;
    void (^animationBlock)(void) = ^{
        [self toggleFloatLabelProperties:animationType];
    };
    
    // Toggle floatLabel visibility via UIView animation
    CGFloat duration = (animationType == UIFloatLabelAnimationTypeShow) ? [_floatLabelShowAnimationDuration floatValue] : [_floatLabelHideAnimationDuration floatValue];
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:combinedOptions
                     animations:animationBlock
                     completion:nil];
}

#pragma mark - Helpers
- (UIEdgeInsets)floatLabelInsets
{
    return UIEdgeInsetsMake(0.0f, _horizontalPadding, 0.0f, _horizontalPadding);
}

- (void)textDidChange:(NSNotification *)notification
{
    if (notification.object == self) {
        if ([self.text length]) {
            _storedText = [self text];
            if (![_floatLabel alpha]) {
                [self toggleFloatLabel:UIFloatLabelAnimationTypeShow];
            }
        } else {
            if ([_floatLabel alpha]) {
                [self toggleFloatLabel:UIFloatLabelAnimationTypeHide];
            }
            _storedText = @"";
        }
    }
}

- (void)clearTextField
{
    // Call UITextFieldDelegate's 'textFieldShouldClear' method if delegate is set
    if ([self.delegate respondsToSelector:@selector(textFieldShouldClear:)]) {
        BOOL shouldClear = [self.delegate textFieldShouldClear:self];
        if (!shouldClear) {
            return;
        }
    }

    self.text = @"";
    [self toggleFloatLabel:UIFloatLabelAnimationTypeHide];
    if ([_dismissKeyboardWhenClearingTextField boolValue]) {
        [self resignFirstResponder];
    }
}

- (void)toggleFloatLabelProperties:(UIFloatLabelAnimationType)animationType
{
    _floatLabel.alpha = (animationType == UIFloatLabelAnimationTypeShow) ? 1.0f : 0.0f;
    CGFloat yOrigin = (animationType == UIFloatLabelAnimationTypeShow) ? -16.0f : 0.5f * CGRectGetHeight([self frame]);
    _floatLabel.frame = CGRectMake(_xOrigin - 5.0f,
                                   yOrigin,
                                   CGRectGetWidth([_floatLabel frame]),
                                   CGRectGetHeight([_floatLabel frame]));
}

#pragma mark - UITextField (Override)
- (void)setText:(NSString *)text
{
    [super setText:text];
    
    // When textField is pre-populated, show non-animated version of floatLabel
    if ([text length] && !_storedText) {
        [self toggleFloatLabelProperties:UIFloatLabelAnimationTypeShow];
        _floatLabel.textColor = _floatLabelPassiveColor;
    }
}

- (void)setPlaceholder:(NSString *)placeholder
{
    [super setPlaceholder:placeholder];
    
    if ([placeholder length]) {
        _floatLabel.text = placeholder;
    }
    
    [_floatLabel sizeToFit];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    
    switch (textAlignment) {
        case NSTextAlignmentRight: {
            _xOrigin = CGRectGetWidth([self frame]) - CGRectGetWidth([_floatLabel frame]) - _horizontalPadding;
        } break;
            
        case NSTextAlignmentCenter: {
            _xOrigin = CGRectGetWidth([self frame])/2.0f - CGRectGetWidth([_floatLabel frame])/2.0f;
        } break;
            
        default: // NSTextAlignmentLeft, NSTextAlignmentJustified, NSTextAlignmentNatural
            _xOrigin = _horizontalPadding;
            break;
    }
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return UIEdgeInsetsInsetRect([super textRectForBounds:bounds], [self floatLabelInsets]);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return UIEdgeInsetsInsetRect([super editingRectForBounds:bounds], [self floatLabelInsets]);
}

#pragma mark - UILabel (Override)
- (void)setFloatLabelFont:(UIFont *)floatLabelFont
{
    _floatLabelFont = floatLabelFont;
    _floatLabel.font = _floatLabelFont;
    [_floatLabel sizeToFit];
}

#pragma mark - UIView (Override)
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setTextAlignment:[self textAlignment]];
    
    if (![self isFirstResponder] && ![self.text length]) {
        [self toggleFloatLabelProperties:UIFloatLabelAnimationTypeHide];
    } else if ([self.text length]) {
        [self toggleFloatLabelProperties:UIFloatLabelAnimationTypeShow];
    }
}

#pragma mark - UIResponder (Override)
-(BOOL)becomeFirstResponder
{
    if ([super becomeFirstResponder]) {
        /*
         verticalPadding must be manually set if textField was initialized
         using NSAutoLayout constraints
         */
        
        _floatLabel.textColor = _floatLabelActiveColor;
        _storedText = [self text];
        
        return YES;
    } else {
        return NO;
    }
    
}

- (BOOL)resignFirstResponder
{
    if ([self canResignFirstResponder]) {
        if ([_floatLabel.text length]) {
            _floatLabel.textColor = _floatLabelPassiveColor;
        }
        
        [super resignFirstResponder];
        
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:)) { // Toggle Pasting
        return ([_pastingEnabled boolValue]) ? YES : NO;
    } else if (action == @selector(copy:)) { // Toggle Copying
        return ([_copyingEnabled boolValue]) ? YES : NO;
    } else if (action == @selector(cut:)) { // Toggle Cutting
        return ([_cuttingEnabled boolValue]) ? YES : NO;
    } else if (action == @selector(select:)) { // Toggle Select
        return ([_selectEnabled boolValue]) ? YES : NO;
    } else if (action == @selector(selectAll:)) { // Toggle Select All
        return ([_selectAllEnabled boolValue]) ? YES : NO;
    }
    
    return [super canPerformAction:action withSender:sender];
}

@end
