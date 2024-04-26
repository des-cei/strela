#include <stdio.h>
#include "csr.h"
#include "polybench.h"

int main(int argc, char *argv[])
{
    pinInit();

    int flag = gemm();

    return flag;
}