#include <mintbind.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <setjmp.h>

static bool access;
jmp_buf env;

void err_handler(int err)
{
    access = false;
    longjmp(env, false);
}

long ssp;

int main(int argc, char *argv[])
{

    /*
     * reroute bus error vector
     */
    ssp = Super(0L);

    void (*berr)(void);               /* previous handler */
    void (*aerr)(void);

    volatile const short *viking = (short *) strtol(argv[1], NULL, 16);

    access = true;

    printf("checking %p\r\n", viking);

    berr = Setexc(2, err_handler);
    aerr = Setexc(3, err_handler);
    if (!setjmp(env))
        *viking;
    (void) Setexc(2, berr);
    (void) Setexc(3, aerr);
    Super(ssp);
    printf("%p is%sreadable\r\n", viking, access ? " " : " not ");

    return 0;
}

