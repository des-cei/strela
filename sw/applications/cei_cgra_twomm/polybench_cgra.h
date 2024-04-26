#ifndef _POLYBENCH_CGRA_H
#define _POLYBENCH_CGRA_H

#define INSTR_SHIFT 16

#include "polybench.h"

void init_cgra();

void twomm_cgra(
    DATA_TYPE *alpha,
    DATA_TYPE *beta,
    DATA_TYPE *tmp,
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C,
    DATA_TYPE *D);

#endif
