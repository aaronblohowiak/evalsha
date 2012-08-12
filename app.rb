require 'hiredis'
require 'redis'
require 'compass'
require 'sass'
require 'cuba'
require "cuba/render"
require 'redcarpet'
require "ostruct"
require 'digest/sha1'
require 'set'
require 'rubberband'


COMMAND_FIELDS = Set.new(%w{num_keys script description name sha example})

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

def sha(str)
  Digest::SHA1.hexdigest str
end


class OpenStruct
  def tbl
    @table
  end
end

def create_command(cmd)
  hsh = cmd.tbl
  @redis.hmset cmd.sha, hsh.to_a.flatten
  @search.index hsh, :id => cmd.sha
end

Cuba.define do
  @redis = Redis.connect()
  @search = ElasticSearch.new(ENV['ELASTICSEARCH_URL'] || "http://localhost:9200", :index => :commands, :type =>:command)
  @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(:filter_html=> true, :no_links => true), :space_after_headers => true)

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

  on get, "commands" do
    @commands = @search.search({:sort => [{"updated_at"=>"asc"}], :fields => ["name", "sha", "updated_at"]})
    res.write haml("commands")
  end

  on get, "terms" do
    res.write haml("terms")
  end

  on get, "contribute" do
    @command = OpenStruct.new({:description=>"## Description\n\n\n\n## Return Value\n\n"})
    res.write haml("contribute")
  end

  on post, "contribute" do
    @errors = []

    hsh = {}
    
    Rack::Request.new(env).params.each_pair do |k,v|
      if COMMAND_FIELDS.include?(k)
        hsh[k] = v
      end
    end

    @command = OpenStruct.new(hsh)
    @command.updated_at = Time.now.xmlschema
    @command.script = @command.script.to_s.strip

    if @command.script.to_s.length <= 20
      @errors.push "You must have a script at least 20 characters long. It's the only required field!"
    else
      @command.sha = sha(@command.script)
    end

    if @command.num_keys != nil && @command.num_keys.to_s.length > 0  && @command.num_keys.to_s != @command.num_keys.to_i.to_s
      @errors.push "You must enter an integer number of keys"
    end

    if @command.name.to_s.length > 20
      @errors.push "Please use a name less than 20 letters"
    end

    if @command.description.to_s.length > 4096*2
      @errors.push "Please use a shorter description"
    end

    if @command.example.to_s.length > 1096*2
      @errors.push "please use a shorter example"
    end

    if @errors.length > 0
      res.write haml("contribute")
    else
      create_command(@command)
      res.redirect "/scripts/#{@command.sha}"
    end
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

    returns = <<-RETURNS
      Multi-Bulk Reply: a list of hashes by key.
RETURNS

    command = OpenStruct.new({
        :sha => "18ee51336532b6d3a3a07620cad0b7a1935476f3",
        :name => "SMEMHASHES",
        :num_keys => 1,
        :source => src,
        :return_value => returns,
        :description => "This command gets all of the values for all of the hashes whose keys are stored in a given set, identified by the argument `setKey` ",
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

    hsh = @redis.hgetall sha
    if hsh.keys.length > 0
      @command = OpenStruct.new(hsh)
      res.write haml("script")
    else

    end
  end
end