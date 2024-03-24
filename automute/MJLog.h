#ifndef MJLog_h
#define MJLog_h


#ifdef DEBUG
#define DEBUG_TEST 1
#else
#define DEBUG_TEST 0
#endif
#define MJLOG(fmt, ...) \
            do { if (DEBUG_TEST) printf(fmt, ##__VA_ARGS__); } while (0)


#endif /* MJLog_h */
