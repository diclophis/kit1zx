# Makefile

SHELL := /bin/bash
export PATH := $(PATH):/root/emsdk:/root/emsdk/clang/e1.38.10_64bit:/root/emsdk/node/8.9.1_64bit/bin:/root/emsdk/emscripten/1.38.10

product=kit1zx.html
build=build/$(product)-build
target=$(build)/$(product)
mruby_static_lib=mruby/build/emscripten/lib/libmruby.a
raylib_static_lib=raylib/release/libs/html5/libraylib.bc
mrbc=mruby/bin/mrbc

sources = $(wildcard *.c)
objects = $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))
.SECONDARY: $(static_ruby_headers) $(objects)
.PHONY: $(mruby_static_lib) $(raylib_static_lib)
objects += $(mruby_static_lib)
objects += $(raylib_static_lib)

#LDFLAGS=-lm -lpthread -ldl -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo $(shell (uname | grep -q Darwin || echo -static))
LDFLAGS=-lm -lpthread -ldl $(shell (uname | grep -q Darwin || echo -static))

CFLAGS=-Os -s USE_GLFW=3 -s ASSERTIONS=1 -s WASM=1 -s EMTERPRETIFY=1 -std=c99 -Imruby/include -Iraylib/src -Iraylib/release/include -I$(build)

CC=emcc

$(shell mkdir -p $(build))

run: $(target) $(sources)
	$(target)

$(target): $(objects) $(sources)
	$(CC) -o $@ $(objects) $(LDFLAGS) -Os -s USE_GLFW=3 -s ASSERTIONS=1 -s WASM=1 -s EMTERPRETIFY=1 --shell-file shell.html --preload-file resources -s TOTAL_MEMORY=167772160

$(build)/test.yml: $(target) config.ru
	$(target) > $@

clean:
	cd mruby && make clean
	cd raylib/src && make PLATFORM=PLATFORM_WEB clean && mkdir -p ../release/libs/html5
	rm -R $(build)

$(build):
	mkdir -p $(build)

$(build)/%.o: %.c $(static_ruby_headers) $(sources)
	$(CC) $(CFLAGS) -c $< -o $@

$(mruby_static_lib): config/mruby.rb
	cd mruby && MRUBY_CONFIG=../config/mruby.rb make

$(raylib_static_lib):
	cd raylib/src && make PLATFORM=PLATFORM_WEB -B

$(mrbc): $(mruby_static_lib)

$(build)/%.h: lib/%.rb $(mrbc)
	mruby/bin/mrbc -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<
