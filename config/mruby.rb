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

  conf.gem :github => "Asmod4n/mruby-simplemsgpack"

  conf.gem :github => "mattn/mruby-uv"
  conf.gem :github => "Asmod4n/mruby-wslay"
  conf.gem :github => "Asmod4n/mruby-b64"
  conf.gem :github => "Asmod4n/mruby-phr"
end
