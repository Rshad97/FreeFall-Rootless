#pragma once
#import <Foundation/Foundation.h>
#import <rootless.h>
#import "FFLogic.h"
#import "FFSelection.h"
static NSString * const FFDomainName = @"com.rashad.freefallrootless";
static NSString * const FFNotifyName = @"com.rashad.freefallrootless/ReloadPrefs";
static inline NSArray<NSString *> *FFNames(void) {
    return @[@"FreeFallScream", @"RashadDrop", @"Laser", @"Phaser", @"PowerDown", @"Zap", @"Alarm", @"Custom"];
}
static inline NSString *FFDataDirectory(void) { return @"/var/mobile/Library/Application Support/FreeFallRootless"; }
static inline NSString *FFDayKey(void) {
    NSDateFormatter *f = [NSDateFormatter new];
    f.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    f.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    f.dateFormat = @"yyyy-MM-dd"; return [f stringFromDate:NSDate.date];
}
static inline NSString *FFSoundPath(NSString *name) {
    if (![FFNames() containsObject:name]) name = @"FreeFallScream";
    NSString *dir = [name isEqualToString:@"Custom"] ? FFDataDirectory() : ROOT_PATH_NS(@"/Library/FreeFallRootless");
    return [dir stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"wav"]];
}
static inline id FFValue(NSString *key) {
    return CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)FFDomainName));
}
static inline BOOL FFBool(NSString *key, BOOL fallback) {
    id v = FFValue(key); return [v isKindOfClass:NSNumber.class] ? [v boolValue] : fallback;
}
static inline double FFNumber(NSString *key, double fallback) {
    id v = FFValue(key); return [v isKindOfClass:NSNumber.class] ? [v doubleValue] : fallback;
}
static inline NSString *FFString(NSString *key, NSString *fallback) {
    id v = FFValue(key); return [v isKindOfClass:NSString.class] ? v : fallback;
}
static inline void FFSave(NSString *key, id value) {
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, (__bridge CFStringRef)FFDomainName);
    CFPreferencesAppSynchronize((__bridge CFStringRef)FFDomainName);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)FFNotifyName, NULL, NULL, true);
}
