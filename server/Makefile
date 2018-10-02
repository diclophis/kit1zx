# Makefile

product=kit1zx-server
build=release/libs/osx
target=$(build)/$(product)
mruby_static_lib=../mruby/build/host/lib/libmruby.a
mruby_static_lib_deps=$(shell find ../mruby -type f | grep -v 'mruby/build\|mruby/bin')
mrbc=../mruby/bin/mrbc

sources = $(wildcard *.c)
objects = $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))
.SECONDARY: $(static_ruby_headers) $(objects)
#.PHONY: $(mruby_static_lib)
objects += $(mruby_static_lib)

LDFLAGS=-lm -lpthread -ldl

CFLAGS=-Os -std=c99 -I../mruby/include -I$(build)

$(shell mkdir -p $(build))

run: $(target) $(sources)
	echo $(sources)
	echo $(target)

$(target): $(objects) $(sources)
	$(CC) $(CFLAGS) -o $@ $(objects) $(LDFLAGS)

clean:
	cd ../mruby && make clean
	rm -R $(build)

$(build):
	mkdir -p $(build)

$(build)/%.o: %.c $(static_ruby_headers) $(sources)
	$(CC) $(CFLAGS) -c $< -o $@

$(mruby_static_lib): ../config/mruby.rb $(mruby_static_lib_deps)
	cd ../mruby && MRUBY_CONFIG=../config/mruby.rb make -j

$(mrbc): $(mruby_static_lib)

$(build)/%.h: lib/%.rb $(mrbc)
	$(mrbc) -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<
