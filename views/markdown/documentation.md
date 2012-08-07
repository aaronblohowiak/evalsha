#Official Redis Scripting Documentation

## Commands

* [EVAL](http://redis.io/commands/eval) - This has most of the docs.
* [EVALSHA](http://redis.io/commands/evalsha) :-)
* [SCRIPT EXISTS](http://redis.io/commands/script-exists) - Check if redis knows about the script already
* [SCRIPT FLUSH](http://redis.io/commands/script-flush) - Clear Redis script cache. This will make all EVALSHAs fail until you replay the scripts
* [SCRIPT KILL](http://redis.io/commands/script-kill) - Kills script IFF it hasn't written yet
* [SCRIPT LOAD](http://redis.io/commands/script-kill) - Preload your Redis


# Blogs

## Antirez's thoughts:

* 17 March 12 [Redis reliable queues with Lua scripting](http://antirez.com/post/250)
* 13 May 11 [An update on Redis and Lua](http://antirez.com/post/an-update-on-redis-and-lua.html) - [HN](http://news.ycombinator.com/item?id=2545047)
* &nbsp;2 May 11 [Scripting branch released](http://antirez.com/post/scripting-branch-released.html/) - [HN](http://news.ycombinator.com/item?id=2506027)
* 27 April 11 [Redis and scripting](http://antirez.com/post/redis-and-scripting.html) - [HN](http://news.ycombinator.com/item?id=2490068)
* 1 March 11 [Redis Manifesto](http://antirez.com/post/redis-manifesto)

## Other's thoughts:

* 18 June 12 Sunil Arora - [Redis Lua Scripting](http://sunilarora.org/redis-lua-scripting)
* 14 March 12 TJ Holowaychuk - [Redis Lua scripting is badass](http://tjholowaychuk.com/post/19321054250/redis-lua-scripting-is-badass)

## Tutorial Blog posts:

* <http://blog.vishalshah.org/post/22175246910/redis-lua-for-processing-json-values>

# Other scripting projects:

* Lua script management for ruby <http://shopify.github.com/wolverine/>
* Lua Scripting-Based Reliable Queue implementation <https://github.com/seomoz/qless-core>

# Want to add more?
[Fork this site](http://github.com/aaronblohowiak/evalsha) and send a pull request
