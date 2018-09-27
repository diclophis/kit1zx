#

XCODEROOT = %x[xcode-select -print-path].strip
SIM_SYSROOT=SIMSDKPATH=Dir["#{XCODEROOT}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator*.sdk/"].sort.last

#IOSSDKPATH = Dir["#{XCODEROOT}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk/"].sort.last
require_relative './mruby.rb'

MRuby::CrossBuild.new('ios') do |conf|
  conf.bins = []

  conf.cc do |cc|
    cc.command = 'xcrun'
    cc.flags = %W(-sdk iphoneos clang -miphoneos-version-min=5.0 -arch x86_64 -isysroot #{SIM_SYSROOT} -g -O3 -Wall -Werror-implicit-function-declaration)
  end

  conf.linker do |linker|
    linker.command = 'xcrun'
    linker.flags = %W(-sdk iphoneos clang -miphoneos-version-min=5.0 -arch x86_64 -isysroot #{SIM_SYSROOT})
  end
end
