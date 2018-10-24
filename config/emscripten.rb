#

require_relative './mruby.rb'

MRuby::CrossBuild.new('emscripten') do |conf|
  # load specific toolchain settings
  toolchain :clang

  enable_debug

  conf.gem :core => "mruby-bin-mirb"
  conf.gem :core => "mruby-math"
  conf.gem :core => "mruby-random"
  conf.gem :core => "mruby-io"
  conf.gem :core => "mruby-enum-ext"

  conf.gem :github => "Asmod4n/mruby-simplemsgpack"

  conf.cc.command = '/root/emsdk/emscripten/1.38.14/emcc'
  conf.linker.command = '/root/emsdk/emscripten/1.38.14/emcc'
  conf.archiver.command = '/root/emsdk/emscripten/1.38.14/emar'
end
