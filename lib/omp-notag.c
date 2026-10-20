// Preloaded into the i3 session: turn off Android's heap pointer tagging (TBI).
// Tagged pointers (0xb400...) are above LONG_MAX, and i3 uses pointers as con_id: i3bar sends
// "[con_id=12970367454953468416] focus workspace" and i3 rejects it, so clicking the bar did nothing.
// Build: clang -shared -fPIC -O2 -o ~/.local/lib/omp-notag.so lib/omp-notag.c  (install.sh does it)
#include <malloc.h>

int mallopt(int, int);   // the header hides it below API 26 (Termux builds for 24); libc has it

__attribute__((constructor)) static void omp_notag(void) {
    mallopt(M_BIONIC_SET_HEAP_TAGGING_LEVEL, M_HEAP_TAGGING_LEVEL_NONE);
}
