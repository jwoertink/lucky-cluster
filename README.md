# lucky-cluster

When you currently boot your lucky app, you're boot 1 single process. If you're running on a beast server, then you're missing out on some free performance!
This shards lets you boot multiple processes of your lucky app.

## Installation

1. Add the dependency to your `shard.yml`:
```yaml
dependencies:
  lucky-cluster:
    github: jwoertink/lucky-cluster
```
2. Run `shards install`

## Usage

1. Take a look in your `src/app.cr` to see your middleware stack. You'll first want to copy that array, and then you can just delete that whole `App` class.
2. Open `src/server.cr`

It probably looks something like this:

```crystal
# A bare-bones src/server.cr setup
require "./app"

if Lucky::Env.development?
  LuckyRecord::Migrator::Runner.new.ensure_migrated!
end
Habitat.raise_if_missing_settings!

app = App.new
puts "Listening on #{app.base_uri}"
app.listen

Signal::INT.trap do
  app.close
end
```

Just update it to look more like this:

```crystal
require "lucky-cluster"
require "./app"

if Lucky::Env.development?
  LuckyRecord::Migrator::Runner.new.ensure_migrated!
end
Habitat.raise_if_missing_settings!

app = Lucky::Cluster.new([
  Lucky::HttpMethodOverrideHandler.new,
  Lucky::LogHandler.new,
  Lucky::SessionHandler.new,
  Lucky::FlashHandler.new,
  Lucky::ErrorHandler.new(action: Errors::Show),
  Lucky::RouteHandler.new,
  Lucky::StaticFileHandler.new("./public", false),
  Lucky::RouteNotFoundHandler.new
])

# This is optional
app.threads = ENV.fetch("MAX_THREADS") { "10" }.to_i

# This is not
app.listen
```

Since we don't need the `App` class, we remove that line, and replace it with the new `Lucky::Cluster.new`. This takes your middleware stack which you copied from the other file before deleting that class.

Next, you can optionally tell the cluster how many processes to boot by assigning the `threads`. This will always boot a single master, process, but if you want 10 additional processes, then `app.threads = 10`. If you don't call this method, the cluster will assume just 1.

Finally, `app.listen` will boot the server. The cluster handles doing the `Signal::INT.trap` internally so we can catch all the child processes that get booted.

## Development

I don't know yet. Just make sure you don't break this thing, and if you know how I can write specs for this, please help!

## Contributing

1. Fork it (<https://github.com/jwoertink/lucky-cluster/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jeremy Woertink](https://github.com/jwoertink) - creator and maintainer

## Mentions

Thanks to the work done on [Spider-Gazelle](https://github.com/spider-gazelle/action-controller/blob/master/clustering.md) for showing how they did it.
