#include <stdint.h>
#define DATA_SIZE 1024
volatile int32_t stimuli[DATA_SIZE] __attribute__((section(".data_interleaved"))) = 
{
64, 57, 22, 79, 26, 45, 1, 86, 77, 77, 68, 90, 49, 78, 7, 83, 43, 34, 10, 99, 82, 93, 49, 92, 49, 58, 62, 17, 72, 32, 18, 63, 13, 80, 39, 91, 48, 68, 53, 78, 75, 39, 18, 62, 80, 7, 69, 81, 28, 8, 2, 27, 76, 17, 42, 89, 16, 97, 24, 88, 39, 35, 3, 51, 50, 93, 21, 66, 16, 87, 4, 42, 84, 46, 41, 98, 97, 11, 18, 97, 54, 38, 41, 21, 24, 37, 23, 86, 12, 61, 72, 51, 35, 62, 90, 83, 55, 21, 59, 34, 81, 32, 67, 28, 51, 75, 35, 37, 6, 96, 70, 11, 23, 66, 34, 24, 77, 20, 86, 22, 60, 93, 87, 87, 15, 26, 36, 78, 9, 65, 99, 69, 44, 88, 2, 11, 71, 12, 18, 15, 17, 62, 50, 58, 22, 89, 9, 21, 19, 4, 27, 89, 43, 91, 53, 78, 12, 62, 90, 28, 40, 99, 10, 52, 91, 70, 5, 91, 30, 1, 36, 27, 58, 41, 98, 23, 25, 87, 43, 70, 88, 97, 8, 76, 92, 91, 47, 64, 16, 96, 86, 17, 75, 81, 11, 9, 96, 83, 84, 2, 84, 93, 53, 28, 56, 15, 94, 4, 7, 57, 52, 15, 62, 17, 87, 94, 96, 3, 56, 33, 10, 94, 83, 0, 73, 6, 10, 1, 22, 99, 8, 90, 39, 93, 23, 96, 49, 48, 66, 23, 26, 63, 91, 76, 39, 33, 51, 70, 37, 26, 51, 1, 35, 91, 45, 14, 40, 7, 48, 53, 83, 71, 11, 81, 57, 54, 39, 37, 28, 96, 4, 23, 40, 17, 85, 46, 27, 28, 78, 3, 28, 20, 47, 76, 3, 66, 37, 29, 54, 84, 40, 72, 7, 22, 76, 79, 19, 63, 3, 34, 92, 50, 52, 18, 92, 21, 48, 45, 95, 55, 80, 6, 9, 38, 95, 49, 88, 73, 88, 27, 7, 40, 72, 9, 84, 89, 41, 68, 12, 53, 26, 82, 14, 59, 28, 87, 1, 98, 24, 0, 88, 62, 43, 8, 82, 7, 20, 10, 24, 5, 45, 6, 8, 2, 16, 9, 24, 63, 75, 53, 60, 44, 24, 1, 32, 84, 58, 55, 21, 85, 92, 69, 8, 25, 22, 34, 35, 52, 0, 17, 83, 28, 38, 30, 11, 83, 86, 18, 27, 7, 90, 65, 45, 7, 41, 67, 69, 91, 27, 48, 75, 2, 39, 33, 31, 10, 12, 65, 6, 9, 64, 41, 94, 88, 98, 26, 64, 57, 41, 94, 61, 51, 98, 6, 56, 82, 99, 89, 17, 77, 10, 7, 55, 65, 95, 44, 45, 16, 61, 90, 99, 81, 66, 23, 42, 29, 83, 61, 34, 48, 20, 99, 13, 7, 17, 77, 32, 45, 93, 8, 27, 92, 83, 38, 35, 23, 64, 70, 83, 84, 94, 63, 96, 76, 78, 83, 29, 61, 42, 98, 90, 41, 12, 91, 79, 66, 42, 36, 33, 87, 92, 78, 69, 92, 82, 57, 31, 57, 80, 98, 89, 39, 82, 69, 98, 28, 73, 43, 56, 87, 63, 70, 64, 79, 72, 45, 10, 28, 49, 69, 8, 25, 10, 40, 77, 12, 55, 19, 54, 31, 95, 31, 86, 74, 96, 48, 32, 32, 58, 77, 18, 87, 69, 86, 27, 31, 45, 22, 40, 39, 67, 52, 29, 38, 50, 51, 5, 69, 78, 32, 3, 58, 14, 44, 58, 5, 92, 48, 35, 93, 45, 5, 90, 46, 83, 84, 5, 61, 88, 46, 99, 39, 87, 1, 61, 99, 20, 61, 19, 21, 52, 38, 77, 99, 74, 13, 52, 89, 33, 18, 66, 77, 96, 93, 27, 19, 28, 64, 22, 93, 33, 61, 83, 70, 48, 67, 98, 48, 18, 67, 34, 83, 43, 38, 41, 23, 36, 62, 34, 78, 15, 76, 72, 28, 0, 92, 25, 67, 37, 6, 92, 76, 70, 17, 83, 20, 58, 13, 66, 99, 38, 29, 90, 7, 23, 6, 46, 99, 33, 22, 13, 12, 90, 32, 21, 22, 72, 11, 27, 21, 76, 83, 40, 34, 75, 45, 5, 28, 22, 77, 0, 77, 82, 12, 66, 39, 46, 65, 19, 53, 59, 43, 7, 93, 89, 6, 98, 92, 58, 84, 17, 61, 14, 84, 3, 93, 31, 16, 1, 87, 17, 77, 61, 80, 81, 38, 87, 99, 23, 62, 50, 67, 62, 70, 98, 69, 45, 91, 48, 97, 75, 61, 7, 86, 18, 88, 64, 82, 62, 30, 26, 58, 69, 31, 84, 7, 74, 7, 22, 99, 75, 44, 23, 46, 13, 4, 84, 30, 14, 66, 18, 84, 15, 89, 7, 24, 57, 78, 89, 64, 8, 43, 86, 89, 88, 89, 32, 9, 89, 58, 20, 98, 34, 83, 41, 59, 48, 16, 79, 51, 97, 2, 34, 86, 17, 91, 15, 52, 87, 95, 3, 99, 96, 7, 49, 8, 50, 31, 18, 78, 19, 14, 73, 38, 81, 35, 70, 29, 17, 40, 88, 76, 42, 28, 84, 32, 86, 31, 52, 45, 8, 52, 85, 83, 10, 79, 87, 51, 40, 84, 57, 90, 83, 47, 45, 81, 94, 57, 26, 18, 18, 70, 12, 74, 38, 98, 7, 35, 41, 59, 7, 72, 29, 30, 90, 72, 84, 70, 35, 67, 96, 0, 47, 10, 43, 93, 0, 79, 80, 41, 80, 93, 94, 6, 56, 87, 74, 70, 84, 39, 77, 36, 51, 11, 88, 92, 59, 94, 77, 27, 64, 43, 76, 87, 86, 95, 58, 18, 2, 54, 16, 65, 25, 20, 53, 43, 2, 50, 22, 63, 1, 77, 13, 86, 74, 3, 95, 63, 75, 38, 31, 78, 60, 29, 66, 18, 91, 31, 83, 74, 85, 93, 8, 52, 35, 42, 90, 48, 88, 45, 85, 44, 50, 97, 76, 5, 19, 61, 31, 32, 72, 93, 21, 49, 28, 40, 54, 77, 23, 73, 2, 65, 69, 50, 25, 41, 37, 52, 62, 85, 11, 91, 11, 60, 21, 48, 43, 16, 98, 79, 79, 50, 87, 29, 15, 58, 5, 61, 90, 17, 31, 78, 83, 75, 85, 61, 95, 57, 46, 1, 66, 72, 30, 67, 33, 79, 12, 49, 57, 85, 46, 14, 86, 19
};
