
gcc -std=gnu99 -pipe -fPIC -fno-strict-aliasing -D_FILE_OFFSET_BITS=64 -O2 -I ../../jul/src -I ../../jul/src/support -I ../../jul/usr/include -shared -o daskr_interface.so daskr_interface.c 
gfortran -ffpe-trap=invalid -fPIC -O2 -shared -o daskr.so DASKR/ddaskr.f DASKR/dlinpk.f DASKR/daux.f