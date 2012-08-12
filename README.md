# EVALSHA.com

A content-addressable database of Lua Scripts for the Redis database.

## Goals:

* Let people share and discover Redis Lua Scripts
* Each script is identified by its Redis SHA ( no version conflicts! )
* [TODO] Let people modify script documentation

## Eventual Goals:

* Automated testing / Example output
* Implement better analyzer for search: http://stackoverflow.com/questions/9421358/filename-search-with-elasticsearch
* API
* Download whole db automatically (currently, just email aaron.blohowiak@gmail.com and I'll send you a copy)

## Notes:

EVALSHA.com uses the script's content as its primary id using the same mechanism that Redis does, SHA1.  This means that the SHA used in redis is the same as the id of the script on this site.  There are no anti-spam measures yet, but I will probably be adding some form of anti-spam soon.  In the meantime, the AOF is my roll-back mechanism ;)

The contribute code could be cleaned up a bit and I should also DRY up the seaching code.

The EVALSHA logo currently sucks, but Adam from &yet said he'd look into it ;)


## Contributing

The site is a Cuba app and modeled after the redis-io site, taking lots of its styles and approaches.  Thanks to CitrusByte!  To get EVALSHA.com running locally, you'll need ruby, redis and a running instance of elasticsearch (i run this in a virtualbox vm.) ElasticSearch is accessed using rubberband, with the url of: (ENV['ELASTICSEARCH_URL'] || "http://localhost:9200") so the default should work out of the box.

You have to `rake style` each time you modify the sass because I don't touch it a lot so it is simpler to have a static generator than dynamic dispatch.

In general, I prefer to use OpenStruct's to hashes because they make it easier to eventually move to real domain objects if we want to in the future. 

