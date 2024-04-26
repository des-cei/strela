#include <stdint.h>
#define DATA_SIZE 1024
#define RESULT_SIZE 900
volatile int32_t image[DATA_SIZE] __attribute__((section(".data_interleaved"))) = 
{
25, 64, 66, 94, 40, 91, 16, 28, 59, 16, 88, 97, 54, 53, 49, 0, 55, 30, 70, 76, 50, 69, 27, 73, 72, 70, 55, 53, 43, 38, 25, 56, 58, 31, 21, 58, 79, 81, 91, 54, 89, 4, 65, 39, 30, 31, 86, 53, 68, 40, 90, 33, 78, 40, 97, 8, 83, 28, 31, 62, 36, 39, 64, 63, 98, 33, 68, 87, 92, 2, 11, 35, 62, 26, 50, 54, 38, 35, 88, 68, 44, 39, 38, 75, 31, 5, 64, 42, 69, 3, 28, 71, 31, 54, 89, 68, 49, 2, 46, 57, 58, 2, 55, 15, 41, 49, 30, 24, 66, 47, 53, 31, 26, 16, 26, 11, 10, 26, 54, 28, 25, 84, 84, 95, 68, 14, 25, 39, 16, 56, 95, 50, 99, 41, 10, 86, 78, 4, 97, 29, 20, 82, 52, 91, 26, 64, 40, 36, 70, 76, 18, 79, 66, 2, 82, 38, 70, 10, 32, 49, 23, 59, 11, 34, 91, 91, 58, 13, 67, 33, 98, 11, 79, 30, 25, 10, 53, 19, 54, 69, 66, 14, 27, 79, 4, 53, 14, 61, 69, 98, 21, 92, 91, 84, 21, 90, 82, 4, 86, 38, 85, 57, 75, 21, 36, 2, 64, 80, 61, 35, 13, 89, 53, 27, 71, 14, 45, 79, 5, 77, 47, 41, 79, 68, 28, 70, 69, 78, 27, 84, 41, 81, 27, 83, 36, 31, 32, 98, 33, 93, 69, 59, 86, 59, 5, 81, 69, 61, 2, 50, 5, 19, 23, 50, 62, 24, 80, 85, 49, 2, 67, 75, 11, 92, 1, 77, 0, 19, 65, 26, 36, 58, 48, 16, 91, 53, 99, 59, 5, 25, 28, 74, 95, 29, 88, 95, 95, 72, 33, 47, 9, 71, 29, 5, 10, 68, 9, 78, 17, 34, 74, 28, 87, 61, 38, 16, 57, 95, 10, 52, 58, 77, 86, 3, 83, 10, 43, 8, 39, 2, 19, 88, 75, 24, 8, 2, 45, 66, 75, 92, 11, 94, 17, 56, 93, 51, 41, 23, 88, 30, 92, 99, 11, 33, 96, 86, 69, 70, 19, 8, 0, 43, 50, 69, 11, 67, 22, 11, 59, 84, 66, 17, 17, 59, 62, 36, 31, 47, 16, 78, 64, 1, 40, 50, 97, 62, 91, 50, 88, 62, 50, 62, 93, 34, 38, 5, 51, 72, 31, 11, 44, 22, 31, 9, 37, 5, 65, 85, 78, 84, 80, 88, 35, 67, 75, 10, 43, 77, 99, 37, 66, 79, 90, 98, 28, 76, 33, 77, 44, 52, 7, 40, 81, 27, 92, 66, 39, 23, 27, 23, 63, 62, 46, 29, 15, 16, 59, 79, 78, 6, 37, 13, 33, 45, 88, 16, 48, 94, 24, 20, 33, 71, 10, 63, 53, 82, 80, 7, 53, 1, 89, 62, 5, 91, 21, 34, 64, 48, 70, 78, 59, 1, 27, 41, 83, 17, 66, 43, 24, 21, 98, 6, 25, 19, 15, 33, 40, 86, 55, 27, 68, 2, 87, 8, 95, 12, 54, 6, 15, 20, 93, 80, 75, 18, 79, 29, 7, 90, 3, 58, 97, 8, 63, 96, 84, 15, 85, 83, 28, 60, 3, 57, 43, 32, 34, 99, 6, 25, 56, 82, 1, 29, 53, 10, 23, 27, 87, 54, 45, 25, 17, 14, 44, 2, 8, 87, 1, 90, 98, 48, 90, 70, 6, 47, 35, 44, 50, 69, 58, 94, 71, 68, 63, 53, 5, 17, 85, 15, 90, 54, 15, 96, 43, 19, 1, 24, 90, 11, 24, 29, 50, 98, 15, 86, 92, 76, 7, 52, 54, 64, 71, 43, 72, 2, 15, 13, 17, 57, 72, 67, 28, 50, 75, 4, 30, 9, 11, 2, 35, 11, 66, 25, 21, 42, 44, 8, 64, 22, 56, 85, 78, 3, 94, 58, 53, 43, 57, 34, 70, 53, 92, 87, 91, 38, 35, 8, 52, 96, 24, 33, 7, 67, 96, 38, 65, 21, 28, 40, 14, 47, 89, 80, 90, 23, 3, 32, 77, 13, 84, 76, 9, 38, 80, 58, 25, 40, 41, 45, 18, 0, 45, 36, 45, 66, 82, 62, 26, 33, 18, 99, 61, 25, 46, 93, 60, 28, 49, 23, 60, 6, 9, 16, 31, 24, 18, 38, 76, 54, 81, 71, 41, 34, 99, 59, 40, 89, 14, 21, 65, 7, 26, 21, 48, 59, 73, 95, 28, 21, 16, 65, 59, 84, 41, 89, 77, 91, 26, 6, 28, 18, 89, 49, 36, 54, 8, 56, 17, 19, 67, 28, 25, 83, 22, 83, 79, 96, 91, 7, 21, 0, 14, 24, 0, 59, 42, 53, 37, 90, 24, 87, 49, 69, 42, 81, 35, 85, 79, 22, 70, 56, 66, 0, 82, 81, 27, 16, 4, 45, 97, 25, 10, 31, 98, 6, 95, 36, 13, 78, 3, 9, 31, 12, 77, 31, 6, 89, 57, 74, 59, 6, 14, 61, 21, 80, 51, 88, 4, 0, 72, 38, 44, 35, 25, 74, 92, 90, 65, 74, 16, 89, 39, 50, 10, 90, 36, 44, 86, 60, 75, 26, 71, 3, 50, 57, 20, 70, 85, 17, 7, 65, 56, 50, 49, 44, 57, 11, 37, 92, 38, 66, 17, 66, 94, 75, 67, 1, 25, 1, 83, 67, 80, 56, 94, 9, 63, 8, 20, 79, 97, 91, 98, 25, 6, 6, 11, 2, 8, 44, 63, 32, 42, 75, 82, 87, 48, 7, 84, 22, 54, 54, 39, 81, 50, 43, 89, 31, 11, 30, 88, 25, 31, 13, 84, 88, 37, 33, 5, 53, 12, 42, 63, 77, 2, 98, 99, 81, 69, 50, 33, 21, 57, 18, 84, 29, 44, 41, 82, 58, 55, 17, 35, 0, 24, 7, 96, 38, 73, 16, 21, 12, 60, 41, 46, 24, 84, 70, 46, 73, 35, 57, 56, 64, 72, 39, 93, 36, 49, 69, 76, 21, 68, 73, 92, 47, 80, 38, 16, 61, 83, 77, 12, 59, 44, 1, 82, 82, 64, 19, 37, 31, 11, 24, 12, 11, 76, 67, 18, 80, 8, 86, 79, 92, 84, 40, 13, 47, 20, 2, 95, 69, 80, 49, 69, 95, 56, 76, 37, 46, 12, 56, 37, 77, 30, 7, 39, 87, 29, 81, 5, 15, 40, 13, 23, 60
};
volatile int32_t result[RESULT_SIZE] __attribute__((section(".data_interleaved"))) = 
{
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};
