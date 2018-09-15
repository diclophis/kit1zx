# Makefile

product=kit1zx
build=build/$(product)-build
target=$(build)/$(product)
mruby_static_lib=mruby/build/host/lib/libmruby.a
raylib_static_lib=release/libs/osx/libraylib.a
mrbc=mruby/bin/mrbc

sources = $(wildcard *.c)
objects = $(patsubst %,$(build)/%, $(patsubst %.c,%.o, $(sources)))
static_ruby_headers = $(patsubst %,$(build)/%, $(patsubst lib/%.rb,%.h, $(wildcard lib/*.rb)))
static_ruby_headers += $(patsubst %,$(build)/%, $(patsubst lib/desktop/%.rb,%.h, $(wildcard lib/desktop/*.rb)))
.SECONDARY: $(static_ruby_headers) $(objects)
objects += $(mruby_static_lib)
objects += $(raylib_static_lib)

LDFLAGS=-lm -lpthread -ldl -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo

CFLAGS=-DPLATFORM_DESKTOP -Os -std=c99 -Imruby/include -Iraylib-src -Irelease/include -I$(build)

$(shell mkdir -p $(build))

run: $(target) $(sources)
	echo $(target)

$(target): $(objects) $(sources)
	$(CC) $(CFLAGS) -o $@ $(objects) $(LDFLAGS)

$(build)/test.yml: $(target) config.ru
	$(target) > $@

clean:
	cd mruby && make clean
	cd raylib-src && make PLATFORM=PLATFORM_DESKTOP clean
	rm -R $(build)

$(build):
	mkdir -p $(build)

$(build)/%.o: %.c $(static_ruby_headers) $(sources)
	$(CC) $(CFLAGS) -c $< -o $@

$(mruby_static_lib): config/mruby.rb
	cd mruby && MRUBY_CONFIG=../config/mruby.rb make

$(raylib_static_lib):
	cd raylib-src && make PLATFORM=PLATFORM_DESKTOP -B

$(mrbc): $(mruby_static_lib)

$(build)/%.h: lib/desktop/%.rb $(mrbc)
	mruby/bin/mrbc -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<

$(build)/%.h: lib/%.rb $(mrbc)
	mruby/bin/mrbc -g -B $(patsubst $(build)/%.h,%, $@) -o $@ $<
