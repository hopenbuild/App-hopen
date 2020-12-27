#include <stdio.h>

#ifdef HAVE_LIBVA
#include <va/va.h>
#endif

int main(void)
{
    printf("Hello, world!\n");
    printf("Compiled %s libva\n",
#ifdef HAVE_LIBVA
            "with"
#else
            "without"
#endif
    );
}
