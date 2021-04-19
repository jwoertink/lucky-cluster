# lucky-cluster

When a lucky app boots, it's only 1 single process. If you're running on a beast server, then you're missing out on some free performance!
This shards lets you boot multiple processes of your lucky app.

## Installation

*NOTE* This version requires Lucky `0.15.0` or later.

1. Add the dependency to your `shard.yml`:
```yaml
dependencies:
  lucky-cluster:
    github: jwoertink/lucky-cluster
```
2. Run `shards install`

## Usage

1. Open `src/start_server.cr`
2. Add your require below the app require
```crystal
require "./app"
require "lucky-cluster"
```
3. Replace `AppServer.new` with `Lucky::Cluster.new`
```crystal
app_server = Lucky::Cluster.new
```
4. Remove the `Signal::INT.trap` block. `lucky-cluster` handles that for you.
5. You can remove the extra `puts` in there too, if you want.

6. Optionally, specify the number of processes to boot with `app_server.threads = 2`

Once done, your `src/start_server.cr` file should look like this:

```crystal
require "./app"
require "lucky-cluster"

if Lucky::Env.development?
  Avram::Migrator::Runner.new.ensure_migrated!
end
Habitat.raise_if_missing_settings!

app_server = Lucky::Cluster.new

# This boots a new process for each thread.
app_server.threads = ENV.fetch("MAX_THREADS") { "10" }.to_i
# You can also use this:
# app_server.threads = System.cpu_count

app_server.listen
```

## Gotchas

Linux will handle load balancing the processes for you, macOS will not. So if you try to load test this on a mac, you're going to have a bad time!

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
