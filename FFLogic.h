#pragma once
#include <stdbool.h>
#include <math.h>
static inline bool FFQuietHour(int hour, int start, int end) {
    if (start == end) return true;
    return start < end ? hour >= start && hour < end : hour >= start || hour < end;
}
static inline double FFClamp(double v, double lo, double hi, double fallback) {
    return isfinite(v) ? fmin(hi, fmax(lo, v)) : fallback;
}
typedef struct { bool falling; double lowSince; double triggered; } FFState;
// 1: fall, 2: impact. Timeout is not an impact. Suppression resets the event.
static inline int FFStep(FFState *s, double g, double now, double fall, double impact, double hold, bool suppressed) {
    if (!isfinite(g) || !isfinite(now)) return 0;
    if (suppressed) { s->falling = false; s->lowSince = -1; return 0; }
    if (s->falling) {
        if (now - s->triggered > 2.5) { s->falling = false; return 0; }
        if (g > impact) { s->falling = false; return 2; }
        return 0;
    }
    if (g >= fall) { s->lowSince = -1; return 0; }
    if (s->lowSince < 0) s->lowSince = now;
    if (now - s->triggered > 1 && now - s->lowSince >= hold) {
        s->falling = true; s->triggered = now; s->lowSince = -1; return 1;
    }
    return 0;
}
