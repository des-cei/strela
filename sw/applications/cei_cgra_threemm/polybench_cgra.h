#ifndef _POLYBENCH_CGRA_H
#define _POLYBENCH_CGRA_H

#define INSTR_SHIFT 16

#include "polybench.h"

void init_cgra();

void threemm_cgra(
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C,
    DATA_TYPE *D,
    DATA_TYPE *E,
    DATA_TYPE *F,
    DATA_TYPE *G);

#endif
