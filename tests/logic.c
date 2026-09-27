#include "../FFLogic.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
    for (int start=0; start<24; start++) for (int end=0; end<24; end++) for (int h=0; h<24; h++) {
        int duration = (end-start+24)%24;
        bool expected = duration == 0 || (h-start+24)%24 < duration;
        assert(FFQuietHour(h,start,end) == expected);
    }
    assert(FFClamp(NAN,.01,.25,.04)==.04);
    assert(FFClamp(INFINITY,.01,.25,.04)==.04);
    assert(FFClamp(2,.01,.25,.04)==.25);
    FFState s={false,-1,-100};
    assert(FFStep(&s,1,1,.04,6,0,false)==0);
    assert(FFStep(&s,.01,2,.04,6,0,false)==1);
    assert(FFStep(&s,.01,2.1,.04,6,0,false)==0);
    assert(FFStep(&s,7,2.2,.04,6,0,false)==2);
    assert(FFStep(&s,7,2.3,.04,6,0,false)==0);
    assert(FFStep(&s,.01,2.4,.04,6,0,false)==0);
    assert(FFStep(&s,.01,4,.04,6,0,false)==1);
    assert(FFStep(&s,7,7,.04,6,0,false)==0); // expired, not impact
    s=(FFState){false,-1,-100};
    assert(FFStep(&s,.01,10,.04,6,.06,true)==0);
    assert(FFStep(&s,.01,11,.04,6,.06,false)==0);
    assert(FFStep(&s,.01,11.02,.04,6,.06,false)==0);
    assert(FFStep(&s,1,11.03,.04,6,.06,false)==0); // reset short dip
    assert(FFStep(&s,.01,12,.04,6,.06,false)==0);
    assert(FFStep(&s,.01,12.07,.04,6,.06,false)==1);
    assert(FFStep(&s,.01,12.1,.04,6,.06,true)==0);
    assert(!s.falling);
    assert(FFStep(&s,NAN,20,.04,6,0,false)==0);
    puts("PASS: 13824 quiet-hour cases, threshold clamps, fall/impact/cooldown/timeout and pocket filtering.");
}
