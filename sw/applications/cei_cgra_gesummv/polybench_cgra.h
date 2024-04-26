#ifndef _POLYBENCH_CGRA_H
#define _POLYBENCH_CGRA_H

#define INSTR_SHIFT 16

#include "polybench.h"

void init_cgra();

void gesummv_cgra(
    DATA_TYPE *alpha, 
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *B, 
    DATA_TYPE *tmp,
    DATA_TYPE *x,
    DATA_TYPE *y);

#endif
