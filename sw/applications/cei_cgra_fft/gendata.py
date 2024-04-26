import random

data_size = 256

X = [int(random.random()*100.00) for x in range(data_size)]
Y = [int(random.random()*100.00) for x in range(data_size)]
Z = [int(random.random()*100.00) for x in range(data_size)]
T = [int(random.random()*100.00) for x in range(data_size)]


def print_arr(array_type, array_name, array_sz, pyarr):
    print "volatile {} {}[{}] __attribute__((section(\".data_interleaved\"))) = ".format(array_type, array_name, array_sz)
    print "{"
    print ", ".join(map(str, pyarr))
    print "};"

def print_scalar(scalar_type, scalar_name, pyscalar):
    print "{} {} = {};".format(scalar_type, scalar_name, pyscalar)


print "#include <stdint.h>"
print "#define DATA_SIZE {}".format(data_size)

print_arr("int32_t", "real_l", "DATA_SIZE", X)
print_arr("int32_t", "real_h", "DATA_SIZE", Y)
print_arr("int32_t", "imag_l", "DATA_SIZE", Z)
print_arr("int32_t", "imag_h", "DATA_SIZE", T)