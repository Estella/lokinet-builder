REPO := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))


BUILD_DIR=$(REPO)/build

EXE = $(REPO)/llarpd

DEP_PREFIX=$(BUILD_DIR)/prefix
PREFIX_SRC=$(DEP_PREFIX)/src

SODIUM_SRC=$(REPO)/deps/sodium
LLARPD_SRC=$(REPO)/deps/llarp

SODIUM_BUILD=$(PREFIX_SRC)/sodium
SODIUM_CONFIG=$(SODIUM_SRC)/configure
SODIUM_LIB=$(DEP_PREFIX)/lib/libsodium.a


all: build

ensure:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(DEP_PREFIX)
	mkdir -p $(PREFIX_SRC)
	mkdir -p $(SODIUM_BUILD)

sodium-configure: ensure
	cd $(SODIUM_SRC) && $(SODIUM_SRC)/autogen.sh
	cd $(SODIUM_BUILD) && $(SODIUM_CONFIG) --prefix=$(DEP_PREFIX) --enable-static --disable-shared

sodium: sodium-configure
	$(MAKE) -C $(SODIUM_BUILD) clean
	$(MAKE) -C $(SODIUM_BUILD) install CFLAGS=-fPIC

build: ensure sodium
	cd $(BUILD_DIR) && cmake $(LLARPD_SRC) -DSODIUM_LIBRARIES=$(SODIUM_LIB) -DSODIUM_INCLUDE_DIR=$(DEP_PREFIX)/include
	$(MAKE) -C $(BUILD_DIR)
	cp $(BUILD_DIR)/llarpd $(EXE)

static-sodium-configure: ensure
	cd $(SODIUM_SRC) && $(SODIUM_SRC)/autogen.sh
	cd $(SODIUM_BUILD) && CC=ecc CXX=ecc++ $(SODIUM_CONFIG) --prefix=$(DEP_PREFIX) --enable-static --disable-shared

static-sodium: static-sodium-configure
	$(MAKE) -C $(SODIUM_BUILD) clean
	$(MAKE) -C $(SODIUM_BUILD) install CFLAGS=-fPIC CC=ecc CXX=ecc++

static: static-sodium
	cd $(BUILD_DIR) && cmake $(LLARPD_SRC) -DSODIUM_LIBRARIES=$(SODIUM_LIB) -DSODIUM_INCLUDE_DIR=$(DEP_PREFIX)/include -DSTATIC_LINK=ON -DCMAKE_C_COMPILER=ecc -DCMAKE_CXX_COMPILER=ecc++
	$(MAKE) -C $(BUILD_DIR)
	cp $(BUILD_DIR)/llarpd $(EXE)

clean:
	rm -rf $(BUILD_DIR) $(EXE)
