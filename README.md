# BlueGreenProcess

A library that solves GC bottlenecks with multi-process.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add blue_green_process

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install blue_green_process

## Usage

```ruby
BlueGreenProcess.configure do |config|
  config.after_fork = ->{ puts 'forked!'  }
end

process = BlueGreenProcess.new(
  worker_instance: BlueGreenProcess::BaseWorker.new,
  max_work: 14,
)

40.times do
  process.work
end

sleep(1)

process.shutdown
loop do
  result = Process.waitall
  if result.empty?
    break
  else
    sleep(0.01)
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/blue_green_process.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## NOTE
* 前回の処理が終わっていないのにqueuingしない
* workerの処理内容は固定

## TODO
* signal handle
* プロセスを入れ替えるときに変数を受け渡しをする
* queueしてからのdequeueするまでの時間を測定したい
    * webサーバでよくあるqueued timeみたいな扱い
    * これが伸びると致命的なのでチューニングできるようにしたいため
* inactiveからactiveへの切り替えになる時間を測定したい
  * GCが長引いてactiveプロセスが処理開始に時間がかかるので
