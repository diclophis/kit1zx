#

require 'rack'

htdocs = "/var/tmp/kit1zx/build/kit1zx.html-build"
urls = Dir.glob(File.join(htdocs, "*")).collect { |f| File.join("/", File.basename(f)) }

Rack::Mime::MIME_TYPES.merge!({
  ".wasm" => "application/wasm"
})

use Rack::Static, {
  :urls => urls,
  :root => htdocs
}

run lambda { |env|
  [
    302,
    {
      'Location'  => '/kit1zx.html',
    },
    StringIO.new("")
  ]
}
