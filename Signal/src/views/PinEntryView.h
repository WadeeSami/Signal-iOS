//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class PinEntryView;

@protocol PinEntryViewDelegate

- (void)pinEntryView:(PinEntryView *)entryView submittedPinCode:(NSString *)pinCode;
- (void)pinEntryView:(PinEntryView *)entryView pinCodeDidChange:(NSString *)pinCode;
- (void)pinEntryViewForgotPinLinkTapped:(PinEntryView *)entryView;

@end

@interface PinEntryView : UIView

@property (nonatomic, weak, nullable) id<PinEntryViewDelegate> delegate;
@property (nonatomic, readonly) BOOL hasValidPin;
@property (nullable, nonatomic) NSString *instructionsText;

- (BOOL)makePinTextFieldFirstResponder;

@end

NS_ASSUME_NONNULL_END
