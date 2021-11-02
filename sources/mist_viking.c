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
    longjmp(env, true);
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

    volatile short *viking = (short *) strtol(argv[1], NULL, 16);

    access = true;

    printf("checking %p\r\n", viking);

    berr = Setexc(2, err_handler);
    aerr = Setexc(3, err_handler);

    if (!setjmp(env))
    {
        if (argc == 2)
        {
            (void) *viking;
            printf("%p is readable, value=%d\r\n", viking, *viking);
        }
        else if (argc == 3)
        {
            *viking = strtol(argv[2], NULL, 16);
            printf("0x%x written to %p\r\n", *viking, viking);
        }
    }
    else
    {
        printf("%p not accessible\r\n", viking);
    }

    /* reinstall old handlers */
    (void) Setexc(2, berr);
    (void) Setexc(3, aerr);
    Super(ssp);


    return 0;
}

