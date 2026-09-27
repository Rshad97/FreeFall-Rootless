#import "../FFSelection.h"
#include <assert.h>
int main(void) { @autoreleasepool {
    assert(FFChoices(@[], nil).count == 0);
    assert(FFChoices(@[@"a"], @"a").count == 1);
    NSArray *pool = @[@"a", @"b", @"c"];
    NSString *previous = nil;
    for (int i=0; i<10000; i++) {
        NSArray *choices = FFChoices(pool, previous);
        NSString *picked = choices[arc4random_uniform((uint32_t)choices.count)];
        assert([pool containsObject:picked]); assert(![previous isEqual:picked]);
        previous = picked;
    }
    assert(FFChoices(pool, @"missing").count == 3);
    assert(pool.count == 3);
    NSLog(@"PASS: empty/singleton/subset pools and 10000 non-repeating selections.");
} }
