require 'hiredis'
require 'redis'
require 'compass'
require 'sass'
require 'cuba'
require "cuba/render"
require 'redcarpet'
require "ostruct"

ROOT_PATH = File.dirname(__FILE__)
Cuba.use Rack::Static, urls: ["/images", "/css"], root: File.join(ROOT_PATH, "public")


Cuba.plugin Cuba::Render

class Tilt::SassTemplate
  OPTIONS = Compass.sass_engine_options
  OPTIONS.merge!(style: :compact, line_comments: false)
  OPTIONS[:load_paths] << File.expand_path("sass")

  def prepare
    @engine = ::Sass::Engine.new(data, sass_options.merge(OPTIONS))
  end
end

# Encoding.default_external = Encoding::UTF_8

Cuba.define do
  def markdown(name)
    render("views/markdown/#{name}.md")
  end

  def haml(template, locals = {})
    layout(partial(template, locals))
  end

  def partial(template, locals = {})
    render("views/#{template}.haml", locals)
  end

  def layout(content)
    partial("layout", content: content)
  end


  def not_found(locals = {path: nil})
    res.status = 404
    res.write haml("404", locals)
  end

  on get, "" do
    res.write haml("home")
  end

  on get, "documentation" do
    res.write haml("documentation")
  end

  on get, "scripts/:sha" do |sha|
    #Get script!

    src = <<-LUA
local keys = redis.call("smembers", KEYS[1])
local ret = {}
for k,v in pairs(keys) do 
  ret[k] = {v, redis.call("hgetall", v)}
end
return ret
LUA

    @command = OpenStruct.new({
        :sha => "18ee51336532b6d3a3a07620cad0b7a1935476f3",
        :name => "SMEMHASHES",
        :keys => [
          OpenStruct.new({"name" => "setkey", "description" => "The "})
        ],
        :source => src,
        :example => <<-EXAMPLE
redis> hset aaron favorites 1
(integer) 1
redis> hset aaron name aaron
(integer) 1
redis> hset antirez favorites 10341513551
(integer) 1
redis> hset antirez name salvatore
(integer) 1
(integer) 1
redis> sadd people aaron
(integer) 1
redis> sadd people antirez
(integer) 1
redis> evalsha 18ee51336532b6d3a3a07620cad0b7a1935476f3 1 people
1. 1. "antirez"
2. 1. "favorites"
2. "10341513551"
3. "name"
4. "salvatore"
2. 1. "aaron"
2. 1. "favorites"
2. "1"
3. "name"
4. "aaron"
EXAMPLE
      })
    res.write haml("script")
  end
end