
gcc -std=gnu99 -pipe -fPIC -fno-strict-aliasing -D_FILE_OFFSET_BITS=64 -O2 -I ../julia/src -I ../julia/src/support -shared -o dassl_interface.so dassl_interface.c 
gfortran -fPIC -O2 -shared -o dassl.so ddassl.f dlinpk.f daux.f