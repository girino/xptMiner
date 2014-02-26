#include <stdbool.h>
#include <stddef.h>
#include <assert.h>
#include <sys/time.h>
#include "win.h"


void InitializeCriticalSection(CRITICAL_SECTION *s){
    pthread_mutexattr_init(&s->attr);
    pthread_mutexattr_settype(&s->attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&s->mutex, &s->attr);
}

void EnterCriticalSection(CRITICAL_SECTION *s){
    pthread_mutex_lock(&s->mutex);
}

void LeaveCriticalSection(CRITICAL_SECTION *s){
    pthread_mutex_unlock(&s->mutex);
}

void CreateThread(LPVOID ig1, size_t ig2, LPTHREAD_START_ROUTINE func, LPVOID arg, uint32_t ig3,  LPDWORD tid){
    pthread_t thread;
    pthread_create(&thread, NULL, func, arg);
}

/* Helpful conversion constants. */
static const unsigned usec_per_sec = 1000000;
static const unsigned usec_per_msec = 1000;

/* These functions are written to match the win32
   signatures and behavior as closely as possible.
*/
bool QueryPerformanceFrequency(_LARGE_INTEGER *frequency)
{
    /* Sanity check. */
    assert(frequency != NULL);

    /* gettimeofday reports to microsecond accuracy. */
    *((int64_t*)frequency) = usec_per_sec;

    return true;
}

bool QueryPerformanceCounter(_LARGE_INTEGER *performance_count)
{
    struct timeval time;

    /* Sanity check. */
    assert(performance_count != NULL);

    /* Grab the current time. */
    gettimeofday(&time, NULL);
    *((int64_t*)performance_count) = time.tv_usec + /* Microseconds. */
                         time.tv_sec * usec_per_sec; /* Seconds. */

    return true;
}
