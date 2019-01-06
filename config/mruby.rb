#

MRuby::Build.new do |conf|
  # load specific toolchain settings
  toolchain :gcc

  enable_debug

  conf.bins = ["mrbc", "mirb"]

  conf.gem :core => "mruby-bin-mirb"
  conf.gem :core => "mruby-math"
  conf.gem :core => "mruby-random"
  conf.gem :core => "mruby-io"
  conf.gem :core => "mruby-enum-ext"
  conf.gem :core => "mruby-struct"

  conf.gem :github => "Asmod4n/mruby-simplemsgpack"

  conf.gem :github => "mattn/mruby-uv"
  conf.gem :github => "diclophis/mruby-wslay", :branch => "fix-intended-return-of-exceptions-1.0"
  conf.gem :github => "Asmod4n/mruby-b64"
  conf.gem :github => "Asmod4n/mruby-phr"
end
