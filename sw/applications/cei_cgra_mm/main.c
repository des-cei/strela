#include <stdio.h>
#include "csr.h"
#include "polybench.h"
#include "polybench_cgra.h"

int main(int argc, char *argv[])
{
    init_cgra();
    pinInit();

    int flag = mm();

    return flag;
}