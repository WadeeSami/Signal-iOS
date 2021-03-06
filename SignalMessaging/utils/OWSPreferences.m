//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSPreferences.h"
#import <SignalServiceKit/AppContext.h>
#import <SignalServiceKit/NSUserDefaults+OWS.h>
#import <SignalServiceKit/TSStorageHeaders.h>
#import <SignalServiceKit/YapDatabaseConnection+OWS.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const OWSPreferencesSignalDatabaseCollection = @"SignalPreferences";

NSString *const OWSPreferencesKeyScreenSecurity = @"Screen Security Key";
NSString *const OWSPreferencesKeyEnableDebugLog = @"Debugging Log Enabled Key";
NSString *const OWSPreferencesKeyNotificationPreviewType = @"Notification Preview Type Key";
NSString *const OWSPreferencesKeyHasSentAMessage = @"User has sent a message";
NSString *const OWSPreferencesKeyHasArchivedAMessage = @"User archived a message";
NSString *const OWSPreferencesKeyPlaySoundInForeground = @"NotificationSoundInForeground";
NSString *const OWSPreferencesKeyLastRecordedPushToken = @"LastRecordedPushToken";
NSString *const OWSPreferencesKeyLastRecordedVoipToken = @"LastRecordedVoipToken";
NSString *const OWSPreferencesKeyCallKitEnabled = @"CallKitEnabled";
NSString *const OWSPreferencesKeyCallKitPrivacyEnabled = @"CallKitPrivacyEnabled";
NSString *const OWSPreferencesKeyCallsHideIPAddress = @"CallsHideIPAddress";
NSString *const OWSPreferencesKeyHasDeclinedNoContactsView = @"hasDeclinedNoContactsView";
NSString *const OWSPreferencesKeyIOSUpgradeNagDate = @"iOSUpgradeNagDate";
NSString *const OWSPreferencesKey_IsReadyForAppExtensions = @"isReadyForAppExtensions_5";
NSString *const OWSPreferencesKeySystemCallLogEnabled = @"OWSPreferencesKeySystemCallLogEnabled";

@implementation OWSPreferences

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return self;
    }

    OWSSingletonAssert();

    return self;
}

#pragma mark - Helpers

- (void)clear
{
    [NSUserDefaults removeAll];
}

- (nullable id)tryGetValueForKey:(NSString *)key
{
    OWSAssert(key != nil);
    return [TSStorageManager.dbReadConnection objectForKey:key inCollection:OWSPreferencesSignalDatabaseCollection];
}

- (void)setValueForKey:(NSString *)key toValue:(nullable id)value
{
    OWSAssert(key != nil);

    [TSStorageManager.dbReadWriteConnection setObject:value
                                               forKey:key
                                         inCollection:OWSPreferencesSignalDatabaseCollection];
}

#pragma mark - Specific Preferences

+ (BOOL)isReadyForAppExtensions
{
    NSNumber *preference = [NSUserDefaults.appUserDefaults objectForKey:OWSPreferencesKey_IsReadyForAppExtensions];

    if (preference) {
        return [preference boolValue];
    } else {
        return NO;
    }
}

+ (void)setIsReadyForAppExtensions
{
    OWSAssert(CurrentAppContext().isMainApp);

    [NSUserDefaults.appUserDefaults setObject:@(YES) forKey:OWSPreferencesKey_IsReadyForAppExtensions];
    [NSUserDefaults.appUserDefaults synchronize];
}

- (BOOL)screenSecurityIsEnabled
{
    NSNumber *preference = [self tryGetValueForKey:OWSPreferencesKeyScreenSecurity];
    return preference ? [preference boolValue] : YES;
}

- (void)setScreenSecurity:(BOOL)flag
{
    [self setValueForKey:OWSPreferencesKeyScreenSecurity toValue:@(flag)];
}

- (BOOL)getHasSentAMessage
{
    NSNumber *preference = [self tryGetValueForKey:OWSPreferencesKeyHasSentAMessage];
    if (preference) {
        return [preference boolValue];
    } else {
        return NO;
    }
}

- (BOOL)getHasArchivedAMessage
{
    NSNumber *preference = [self tryGetValueForKey:OWSPreferencesKeyHasArchivedAMessage];
    if (preference) {
        return [preference boolValue];
    } else {
        return NO;
    }
}

+ (BOOL)isLoggingEnabled
{
    NSNumber *preference = [NSUserDefaults.appUserDefaults objectForKey:OWSPreferencesKeyEnableDebugLog];

    if (preference) {
        return [preference boolValue];
    } else {
        return YES;
    }
}

+ (void)setIsLoggingEnabled:(BOOL)flag
{
    OWSAssert(CurrentAppContext().isMainApp);

    // Logging preferences are stored in UserDefaults instead of the database, so that we can (optionally) start
    // logging before the database is initialized. This is important because sometimes there are problems *with* the
    // database initialization, and without logging it would be hard to track down.
    [NSUserDefaults.appUserDefaults setObject:@(flag) forKey:OWSPreferencesKeyEnableDebugLog];
    [NSUserDefaults.appUserDefaults synchronize];
}

- (void)setHasSentAMessage:(BOOL)enabled
{
    [self setValueForKey:OWSPreferencesKeyHasSentAMessage toValue:@(enabled)];
}

- (void)setHasArchivedAMessage:(BOOL)enabled
{
    [self setValueForKey:OWSPreferencesKeyHasArchivedAMessage toValue:@(enabled)];
}

- (BOOL)hasDeclinedNoContactsView
{
    NSNumber *preference = [self tryGetValueForKey:OWSPreferencesKeyHasDeclinedNoContactsView];
    // Default to NO.
    return preference ? [preference boolValue] : NO;
}

- (void)setHasDeclinedNoContactsView:(BOOL)value
{
    [self setValueForKey:OWSPreferencesKeyHasDeclinedNoContactsView toValue:@(value)];
}

- (void)setIOSUpgradeNagDate:(NSDate *)value
{
    [self setValueForKey:OWSPreferencesKeyIOSUpgradeNagDate toValue:value];
}

- (nullable NSDate *)iOSUpgradeNagDate
{
    return [self tryGetValueForKey:OWSPreferencesKeyIOSUpgradeNagDate];
}

#pragma mark - Calling

#pragma mark CallKit

- (BOOL)isSystemCallLogEnabled
{
    if (@available(iOS 11, *)) {
        // do nothing
    } else {
        OWSFail(@"%@ Call Logging can only be configured on iOS11+", self.logTag);
        return NO;
    }

    NSNumber *preference = [self tryGetValueForKey:OWSPreferencesKeySystemCallLogEnabled];

    if (preference) {
        return preference.boolValue;
    } else {
        // For legacy users, who may have previously intentionally disabled CallKit because they
        // didn't want their calls showing up in the call log, we want to disable call logging
        NSNumber *callKitPreference = [self tryGetValueForKey:OWSPreferencesKeyCallKitEnabled];
        if (callKitPreference && !callKitPreference.boolValue) {
            // user explicitly opted out of callKit, so disable system call logging.
            return NO;
        }
    }

    // For everyone else, including new users, enable by default.
    return YES;
}

- (void)setIsSystemCallLogEnabled:(BOOL)flag
{
    if (@available(iOS 11, *)) {
        // do nothing
    } else {
        OWSFail(@"%@ Call Logging can only be configured on iOS11+", self.logTag);
        return;
    }

    [self setValueForKey:OWSPreferencesKeySystemCallLogEnabled toValue:@(flag)];
}

// In iOS 10.2.1, Apple fixed a bug wherein call history was backed up to iCloud.
//
// See: https://support.apple.com/en-us/HT207482
//
// In iOS 11, Apple introduced a property CXProviderConfiguration.includesCallsInRecents
// that allows us to prevent Signal calls made with CallKit from showing up in the device's
// call history.
//
// Therefore in versions of iOS after 11, we have no need of call privacy.
#pragma mark Legacy CallKit

- (BOOL)isCallKitEnabled
{
    if (@available(iOS 11, *)) {
        OWSFail(@"%@ CallKit privacy is irrelevant for iOS11+", self.logTag);
        return NO;
    }

    NSNumber *preference = [self tryGetValueForKey:OWSPreferencesKeyCallKitEnabled];
    return preference ? [preference boolValue] : YES;
}

- (void)setIsCallKitEnabled:(BOOL)flag
{
    if (@available(iOS 11, *)) {
        OWSFail(@"%@ CallKit privacy is irrelevant for iOS11+", self.logTag);
        return;
    }

    [self setValueForKey:OWSPreferencesKeyCallKitEnabled toValue:@(flag)];
    OWSFail(@"Rev callUIAdaptee to get new setting");
}

- (BOOL)isCallKitEnabledSet
{
    if (@available(iOS 11, *)) {
        OWSFail(@"%@ CallKit privacy is irrelevant for iOS11+", self.logTag);
        return NO;
    }

    NSNumber *preference = [self tryGetValueForKey:OWSPreferencesKeyCallKitEnabled];
    return preference != nil;
}

- (BOOL)isCallKitPrivacyEnabled
{
    if (@available(iOS 11, *)) {
        OWSFail(@"%@ CallKit privacy is irrelevant for iOS11+", self.logTag);
        return NO;
    }

    NSNumber *_Nullable preference = [self tryGetValueForKey:OWSPreferencesKeyCallKitPrivacyEnabled];
    if (preference) {
        return [preference boolValue];
    } else {
        // Private by default.
        return YES;
    }
}

- (void)setIsCallKitPrivacyEnabled:(BOOL)flag
{
    if (@available(iOS 11, *)) {
        OWSFail(@"%@ CallKit privacy is irrelevant for iOS11+", self.logTag);
        return;
    }

    [self setValueForKey:OWSPreferencesKeyCallKitPrivacyEnabled toValue:@(flag)];
}

- (BOOL)isCallKitPrivacySet
{
    if (@available(iOS 11, *)) {
        OWSFail(@"%@ CallKit privacy is irrelevant for iOS11+", self.logTag);
        return NO;
    }

    NSNumber *preference = [self tryGetValueForKey:OWSPreferencesKeyCallKitPrivacyEnabled];
    return preference != nil;
}

#pragma mark direct call connectivity (non-TURN)

// Allow callers to connect directly, when desirable, vs. enforcing TURN only proxy connectivity

- (BOOL)doCallsHideIPAddress
{
    NSNumber *preference = [self tryGetValueForKey:OWSPreferencesKeyCallsHideIPAddress];
    return preference ? [preference boolValue] : NO;
}

- (void)setDoCallsHideIPAddress:(BOOL)flag
{
    [self setValueForKey:OWSPreferencesKeyCallsHideIPAddress toValue:@(flag)];
}

#pragma mark Notification Preferences

- (BOOL)soundInForeground
{
    NSNumber *preference = [self tryGetValueForKey:OWSPreferencesKeyPlaySoundInForeground];
    if (preference) {
        return [preference boolValue];
    } else {
        return YES;
    }
}

- (void)setSoundInForeground:(BOOL)enabled
{
    [self setValueForKey:OWSPreferencesKeyPlaySoundInForeground toValue:@(enabled)];
}

- (void)setNotificationPreviewType:(NotificationType)type
{
    [self setValueForKey:OWSPreferencesKeyNotificationPreviewType toValue:@(type)];
}

- (NotificationType)notificationPreviewType
{
    NSNumber *preference = [self tryGetValueForKey:OWSPreferencesKeyNotificationPreviewType];

    if (preference) {
        return [preference unsignedIntegerValue];
    } else {
        return NotificationNamePreview;
    }
}

- (NSString *)nameForNotificationPreviewType:(NotificationType)notificationType
{
    switch (notificationType) {
        case NotificationNamePreview:
            return NSLocalizedString(@"NOTIFICATIONS_SENDER_AND_MESSAGE", nil);
        case NotificationNameNoPreview:
            return NSLocalizedString(@"NOTIFICATIONS_SENDER_ONLY", nil);
        case NotificationNoNameNoPreview:
            return NSLocalizedString(@"NOTIFICATIONS_NONE", nil);
        default:
            DDLogWarn(@"Undefined NotificationType in Settings");
            return @"";
    }
}

#pragma mark - Push Tokens

- (void)setPushToken:(NSString *)value
{
    [self setValueForKey:OWSPreferencesKeyLastRecordedPushToken toValue:value];
}

- (nullable NSString *)getPushToken
{
    return [self tryGetValueForKey:OWSPreferencesKeyLastRecordedPushToken];
}

- (void)setVoipToken:(NSString *)value
{
    [self setValueForKey:OWSPreferencesKeyLastRecordedVoipToken toValue:value];
}

- (nullable NSString *)getVoipToken
{
    return [self tryGetValueForKey:OWSPreferencesKeyLastRecordedVoipToken];
}

- (void)unsetRecordedAPNSTokens
{
    DDLogWarn(@"%@ Forgetting recorded APNS tokens", self.logTag);
    [self setValueForKey:OWSPreferencesKeyLastRecordedPushToken toValue:nil];
    [self setValueForKey:OWSPreferencesKeyLastRecordedVoipToken toValue:nil];
}

@end

NS_ASSUME_NONNULL_END
