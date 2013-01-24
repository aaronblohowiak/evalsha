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

# Checks if the parameter contains
# certain HTML tags by downcasing
# the string and removing all
# whitespace, and then checking for
# the precense of the tags
def check_html(str)
    str = str.downcase
    str.gsub! /\s/, ''
    check_for = [ /<a/, /<p/ ]

    check_for.inject(false) { |accum, cond| accum ||= (str =~ cond) }
end

Cuba.define do
  @redis = Redis.connect()
  @search = ElasticSearch.new(ENV['ELASTICSEARCH_URL'] || "http://localhost:9200", :index => :commands, :type =>:command)
  @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(:filter_html=> true, :no_links => true, :hard_wrap => true), :space_after_headers => true)

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

  on get, "commands/:name" do |name|
    @name = name
    @commands = @search.search({:query=>{:field=>{"name"=>name}}, :sort => [{"updated_at"=>"asc"}], :fields => ["name", "sha", "updated_at"]},{:limit=>10_000}).to_a
    @commands.map!{|c| OpenStruct.new(c.fields) }

    if @commands.length == 1
      res.redirect "/scripts/"+@commands[0].sha
    else
      res.write haml("by_name")
    end
  end

  on get, "commands" do
    @commands = @search.search({:sort => [{"updated_at"=>"asc"}], :fields => ["name", "sha", "updated_at"]},{:limit=>10_000}).to_a
    @commands = @commands.map{|c| OpenStruct.new(c.fields) }
    res.write haml("commands")
  end

  on get, "terms" do
    res.write haml("terms")
  end

  on get, "contribute" do
    @command = OpenStruct.new({:description=>"## Description\n\n\n\n## Return Value\n\n"})
    res.write haml("contribute")
  end

  on get, "search" do
    @query =  Rack::Request.new(env).params["q"]
    real_query = "*#{@query}*"
    @commands = @search.search({:query=>{:query_string=>{:query => real_query, :default_operator=>"AND"}}, :sort => [{"updated_at"=>"asc"}], :fields => ["name", "sha", "updated_at"]}).to_a
    @commands = @commands.map{|c| OpenStruct.new(c.fields) }

    res.write haml("search")
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
    @command.script = @command.script.to_s.strip.gsub("\r", "")

    if @command.script.to_s.length <= 20
      @errors.push "You must have a script at least 20 characters long. It's the only required field!"
    else
      @command.sha = sha(@command.script)
    end

    if (@command.num_keys != nil) && (@command.num_keys.to_s.length > 0)  && (@command.num_keys.to_s != @command.num_keys.to_i.to_s) ||( @command.num_keys.to_i < 0)
      @errors.push "You must enter a positive integer number of keys"
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

    # Checks for certain HTML in fields
    # While this could be bypassed by looking at the source 
    # and figuring out what is and isn't acceptable
    # since most of these spammers aren't using the markdown
    # syntax for their links, I don't think they care
    if check_html(@command.script.to_s)
        @errors.push "Please do not use HTML in your command"
    end
    if check_html(@command.name.to_s)
        @errors.push "Please do not use HTML in your name"
    end
    if check_html(@command.description.to_s)
        @errors.push "Please do not use HTML in your description"
    end
    if check_html(@command.example.to_s)
        @errors.push "Please do not use HTML in your example"
    end

    if @errors.length > 0
      res.write haml("contribute")
    else
      create_command(@command)
      res.redirect "/scripts/#{@command.sha}"
    end
  end

  on get, "raw/:sha" do |sha|
    hsh = @redis.hgetall sha
    res["Content-Disposition"] = "attachment; filename=#{sha}.lua"
    res.write hsh["script"]
  end

  on get, "scripts/:sha" do |sha|
    #Get script!

    hsh = @redis.hgetall sha
    if hsh.keys.length > 0
      @command = OpenStruct.new(hsh)
      @related_commands = @search.search({:query=>{:field=>{"name"=>@command.name}}, :sort => [{"updated_at"=>"asc"}], :fields => ["name", "sha", "updated_at"]}).to_a
      @related_commands.map!{|c| OpenStruct.new(c.fields) }
      res.write haml("script")
    else
      res.write "SHA NOT FOUND"
    end
  end
end