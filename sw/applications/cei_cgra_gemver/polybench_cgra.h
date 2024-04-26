#ifndef _POLYBENCH_CGRA_H
#define _POLYBENCH_CGRA_H

#define INSTR_SHIFT 16

#include "polybench.h"

void init_cgra();

void gemver_cgra(
    DATA_TYPE *alpha, 
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *u1,
    DATA_TYPE *v1,
    DATA_TYPE *u2,
    DATA_TYPE *v2,
    DATA_TYPE *w,
    DATA_TYPE *x,
    DATA_TYPE *y,
    DATA_TYPE *z);

#endif
