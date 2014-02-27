CXX = g++
CC = cc
CXXFLAGS = -Wall -Wextra -std=c++0x -O2 -fomit-frame-pointer 

OSVERSION := $(shell uname -s)

ifeq ($(OSVERSION),CYGWIN_NT-6.1)
	#CXXFLAGS = -Wall -Wextra -std=gnu++0x -O2 -fomit-frame-pointer 
	CXXFLAGS = -std=gnu++0x -O2 -fomit-frame-pointer 
endif

CFLAGS = -Wall -Wextra -O2 -fomit-frame-pointer 
# add these for more speed! (if your cpu can do them)
#-msse2 -msse3 -mssse3 -msse4a -msse2avx -msse4a -msse4.1 -msse4.2 -mavx 


#LIBS = -lcrypto -lssl -lpthread
LIBS =

ifeq ($(OSVERSION),Linux)
	LIBS += -lrt -lOpenCL
	CFLAGS += -march=native
	CXXFLAGS += -march=native
endif

ifeq ($(OSVERSION),FreeBSD)
	CXX = clang++
	CC = clang
	CFLAGS += -DHAVE_DECL_LE32DEC -march=native
	CXXFLAGS += -DHAVE_DECL_LE32DEC -march=native
endif

# You might need to edit these paths too
LIBPATHS = -L/usr/local/lib -L/usr/lib
INCLUDEPATHS = -I/usr/local/include -I/usr/include -IxptMiner/includes/

ifeq ($(OSVERSION),Darwin)
	LIBS += -framework OpenCL
	EXTENSION = -mac
	GOT_MACPORTS := $(shell which port)
ifdef GOT_MACPORTS
	LIBPATHS += -L/opt/local/lib
	INCLUDEPATHS += -I/opt/local/include
endif
else
       EXTENSION =

endif

ifeq ($(OSVERSION),CYGWIN_NT-6.1)
	EXTENSION = .exe
	LIBS += -lOpenCL
        LIBPATHS += -L/cygdrive/c/Program\ Files\ \(x86\)/AMD\ APP\ SDK/2.9/lib/x86_64/
	INCLUDEPATHS += -I/cygdrive/c/Program\ Files\ \(x86\)/AMD\ APP\ SDK/2.9/include
endif


JHLIB = xptMiner/jhlib.o \

OBJS = \
	xptMiner/win.o \
	xptMiner/ticker.o \
	xptMiner/main.o \
	xptMiner/sha2.o \
	xptMiner/xptClient.o \
	xptMiner/keccak.o \
	xptMiner/metis.o \
	xptMiner/shavite.o \
	xptMiner/metiscoinMiner.o \
	xptMiner/xptClientPacketHandler.o \
	xptMiner/xptPacketbuffer.o \
	xptMiner/xptServer.o \
	xptMiner/xptServerPacketHandler.o \
	xptMiner/transaction.o \
	xptMiner/OpenCLObjects.o \

all: xptminer$(EXTENSION)

xptMiner/%.o: xptMiner/%.cpp
	$(CXX) -c $(OPTFLAGS) $(CXXFLAGS) $(INCLUDEPATHS) $< -o $@ 

xptMiner/%.o: xptMiner/%.c
	$(CC) -c $(OPTFLAGS) $(CFLAGS) $(INCLUDEPATHS) $< -o $@ 

xptMiner/shavite_ref_impl/%.o: xptMiner/shavite_ref_impl/%.c
	$(CC) -c $(OPTFLAGS) $(CFLAGS) $(INCLUDEPATHS) $< -o $@ 

xptminer$(EXTENSION): $(OBJS:xptMiner/%=xptMiner/%) $(JHLIB:xptMiner/jhlib/%=xptMiner/jhlib/%)
	$(CXX) $(CFLAGS) $(LIBPATHS) $(INCLUDEPATHS) -o $@ $^ $(LIBS) -flto

clean:
	-rm -f xptminer$(EXTENSION)
	-rm -f xptMiner/*.o
	-rm -f xptMiner/jhlib/*.o
