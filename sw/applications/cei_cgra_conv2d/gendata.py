import random

size = 32
data_size = size * size
result_size = (size - 2) * (size - 2)

X = [int(random.random()*100.00) for x in range(data_size)]
Y = [int(0.0) for x in range(result_size)]

def print_arr(array_type, array_name, array_sz, pyarr):
    print "volatile {} {}[{}] __attribute__((section(\".data_interleaved\"))) = ".format(array_type, array_name, array_sz)
    print "{"
    print ", ".join(map(str, pyarr))
    print "};"

def print_scalar(scalar_type, scalar_name, pyscalar):
    print "{} {} = {};".format(scalar_type, scalar_name, pyscalar)


print "#include <stdint.h>"
print "#define DATA_SIZE {}".format(data_size)
print "#define RESULT_SIZE {}".format(result_size)

print_arr("int32_t", "image", "DATA_SIZE", X)
print_arr("int32_t", "result", "RESULT_SIZE", Y)