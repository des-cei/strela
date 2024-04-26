#ifndef _POLYBENCH_H
#define _POLYBENCH_H

#define ENABLE_PIN_TOGGLE 0
#define PIN_TO_CTRL_VCD 6
#define PIN_TO_NEW_VCD 7

/* Default to MINI_DATASET. */
#if !defined(DEBUG_DATASET) && \
 !defined(MINI_DATASET) && \
 !defined(SMALL_DATASET) && \
 !defined(MEDIUM_DATASET) && \
 !defined(LARGE_DATASET) && \
 !defined(EXTRALARGE_DATASET)
#define DEBUG_DATASET
#endif

/* Define sample dataset sizes. */
#ifdef DEBUG_DATASET
#   define GEMM_NI 64
#   define GEMM_NJ 64
#   define GEMM_NK 64
#   define GEMVER_N 20
#   define GESUMMV_N 20
#   define TWOMM_NI 20
#   define TWOMM_NJ 20
#   define TWOMM_NK 20
#   define TWOMM_NL 20
#   define THREEMM_NI 20
#   define THREEMM_NJ 20
#   define THREEMM_NK 20
#   define THREEMM_NL 20
#   define THREEMM_NM 20
#   define ATAX_M 20
#   define ATAX_N 20
#   define DOITGEN_NQ 20
#   define DOITGEN_NR 20
#   define DOITGEN_NP 20
#   define MVT_N 20
#endif

#ifdef MINI_DATASET
#   define GEMM_NI 20
#   define GEMM_NJ 25
#   define GEMM_NK 30
#   define GEMVER_N 40
#   define GESUMMV_N 30
#   define TWOMM_NI 16
#   define TWOMM_NJ 18
#   define TWOMM_NK 22
#   define TWOMM_NL 24
#   define THREEMM_NI 16
#   define THREEMM_NJ 18
#   define THREEMM_NK 20
#   define THREEMM_NL 22
#   define THREEMM_NM 24
#   define ATAX_M 38
#   define ATAX_N 42
#   define DOITGEN_NQ 8
#   define DOITGEN_NR 10
#   define DOITGEN_NP 12
#   define MVT_N 40
#endif

#ifdef SMALL_DATASET
#   define GEMM_NI 60
#   define GEMM_NJ 70
#   define GEMM_NK 80
#   define GEMVER_N 120
#   define GESUMMV_N 90
#   define TWOMM_NI 40
#   define TWOMM_NJ 50
#   define TWOMM_NK 70
#   define TWOMM_NL 80
#   define THREEMM_NI 40
#   define THREEMM_NJ 50
#   define THREEMM_NK 60
#   define THREEMM_NL 70
#   define THREEMM_NM 80
#   define ATAX_M 116
#   define ATAX_N 124
#   define DOITGEN_NQ 20
#   define DOITGEN_NR 25
#   define DOITGEN_NP 30
#   define MVT_N 120
#endif

#ifdef MEDIUM_DATASET
#   define GEMM_NI 200
#   define GEMM_NJ 220
#   define GEMM_NK 240
#   define GEMVER_N 400
#   define GESUMMV_N 250
#   define TWOMM_NI 180
#   define TWOMM_NJ 190
#   define TWOMM_NK 210
#   define TWOMM_NL 220
#   define THREEMM_NI 180
#   define THREEMM_NJ 190
#   define THREEMM_NK 200
#   define THREEMM_NL 210
#   define THREEMM_NM 220
#   define ATAX_M 390
#   define ATAX_N 410
#   define DOITGEN_NQ 40
#   define DOITGEN_NR 50
#   define DOITGEN_NP 60
#   define MVT_N 400
#endif

#ifdef LARGE_DATASET
#   define GEMM_NI 1000
#   define GEMM_NJ 1100
#   define GEMM_NK 1200
#   define GEMVER_N 2000
#   define GESUMMV_N 1300
#   define TWOMM_NI 800
#   define TWOMM_NJ 900
#   define TWOMM_NK 1100
#   define TWOMM_NL 1200
#   define THREEMM_NI 800
#   define THREEMM_NJ 900
#   define THREEMM_NK 1000
#   define THREEMM_NL 1100
#   define THREEMM_NM 1200
#   define ATAX_M 1900
#   define ATAX_N 2100
#   define DOITGEN_NQ 140
#   define DOITGEN_NR 150
#   define DOITGEN_NP 160
#   define MVT_N 2000
#endif

#ifdef EXTRALARGE_DATASET
#   define GEMM_NI 2000
#   define GEMM_NJ 2300
#   define GEMM_NK 2600
#   define GEMVER_N 4000
#   define GESUMMV_N 2800
#   define TWOMM_NI 1600
#   define TWOMM_NJ 1800
#   define TWOMM_NK 2200
#   define TWOMM_NL 2400
#   define THREEMM_NI 1600
#   define THREEMM_NJ 1800
#   define THREEMM_NK 2000
#   define THREEMM_NL 2200
#   define THREEMM_NM 2400
#   define ATAX_M 1800
#   define ATAX_N 2200
#   define DOITGEN_NQ 220
#   define DOITGEN_NR 250
#   define DOITGEN_NP 270
#   define MVT_N 4000
#endif

#define SYMM_M GEMM_NI
#define SYMM_N GEMM_NK
#define BICG_M ATAX_M
#define BICG_N ATAX_N

#include <stdint.h>
#include <inttypes.h>

/* Default data type */
#define DATA_TYPE int32_t
#define DATA_PRINTF_MODIFIER ("%" PRIi32 " ")

void pinInit();
int mm();

#endif
