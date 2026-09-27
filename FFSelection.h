#pragma once
#import <Foundation/Foundation.h>
static inline NSArray<NSString *> *FFChoices(NSArray<NSString *> *pool, NSString *previous) {
    NSMutableArray *result = [pool mutableCopy];
    if (result.count > 1 && previous) [result removeObject:previous];
    return result;
}
