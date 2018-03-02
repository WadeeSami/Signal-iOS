//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class PinEntryView;

@protocol OWS2FAEntryViewDelegate

- (void)pinEntryView:(PinEntryView *)entryView submittedPinCode:(NSString *)pinCode;
- (void)pinEntryViewForgotPinLinkTapped:(PinEntryView *)entryView;

@end

@interface PinEntryView : UIView

@property (nonatomic, weak, nullable) id<OWS2FAEntryViewDelegate> delegate;
@property (nonatomic, readonly) BOOL hasValidPin;

- (BOOL)makePinTextFieldFirstResponder;

@end

NS_ASSUME_NONNULL_END
