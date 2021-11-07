#include <mintbind.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#define __BSD_SOURCE

#include <setjmp.h>

static bool access;
jmp_buf env;


void err_handler(void)
{
    short local;

    //printf("segmentation violation.\r\n");
    //for (int i = 1; i < 4; i ++)
    //  printf("(sp + %d) = 0x%04x\r\n", i * 2 - 2, * (&local + i));

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

    volatile short *trgt = (short *) strtoul(argv[1], NULL, 0);

    access = true;

    printf("checking %p\r\n", trgt);

    berr = Setexc(2, err_handler);
    aerr = Setexc(3, err_handler);

    if (!setjmp(env))
    {
        if (argc == 2)
        {
            (void) *trgt;
            printf("%p is readable, value=%d\r\n", trgt, *trgt);
        }
        else if (argc == 3)
        {
            *trgt = strtol(argv[2], NULL, 16);
            printf("0x%x written to %p\r\n", *trgt, trgt);
        }
    }
    else
    {
        printf("%p not accessible\r\n", trgt);
    }

    /* reinstall old handlers */
    (void) Setexc(2, berr);
    (void) Setexc(3, aerr);
    Super(ssp);


    return 0;
}

