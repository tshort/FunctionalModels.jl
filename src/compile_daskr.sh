
gcc -std=gnu99 -pipe -fPIC -fno-strict-aliasing -D_FILE_OFFSET_BITS=64 -O2 -I ../julia/src -I ../julia/src/support -shared -o daskr_interface.so daskr_interface.c 
gfortran -fPIC -O2 -shared -o daskr.so DASKR/ddaskr.f DASKR/dlinpk.f DASKR/daux.f