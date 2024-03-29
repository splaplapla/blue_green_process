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
  config.after_fork = ->{ puts 'forked!' }
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
# or BlueGreenProcess.terminate_workers_immediately
Process.waitall
```

### プロセス間での値の共有
* Hashが入っている'BlueGreenProcess::SharedVariable.data' の値はmaster process, work processで共有します.
* 共有するHashのキーは `config.shared_variables` で許可する必要があります
* プロセスを入れ替えるタイミングで値の復元とダンプを行います
* JSONでシリアライズしているので共有できるオブジェクトはプリミティブ型に限定されます
* GCの時間を軽減するために整数型だけを共有するとパフォーマンスに良さそう
* `config.shared_variables` に最初から入っている `extend_run_on_this_process` は消すことができません

```ruby
BlueGreenProcess.configure do |config|
  config.shared_variables = [:count]
end

worker_class = Class.new(BlueGreenProcess::BaseWorker) do
  def initialize(*); end

  def work(label)
    BlueGreenProcess::SharedVariable.data['count'] += 1
    puts "#{label}'s data['count'] is #{BlueGreenProcess::SharedVariable.data['count']}"
  end
end

BlueGreenProcess::SharedVariable.data['count'] = 0
process = BlueGreenProcess.new(worker_instance: worker_class.new, max_work: 3)
process.work # blue
process.work # green
process.work # blue
BlueGreenProcess::SharedVariable.data['count']
```

outputs

```
blue's data['count'] is 1
blue's data['count'] is 2
blue's data['count'] is 3
green's data['count'] is 4
green's data['count'] is 5
green's data['count'] is 6
blue's data['count'] is 7
blue's data['count'] is 8
blue's data['count'] is 9
9
```

### 単一プロセスでの実行を延長する
* workerクラスの中で、`BlueGreenProcess::SharedVariable.extend_run_on_this_process`にtrueをセットするともう一度同じプロセスで処理を行います
    * 次の実行でtrueを明示しない限りはプロセスを切り替えます
* 単一プロセスでの実行を延長するとGC.startを実行しなくなります
    * 長時間にわたって延長する時は呼び出し側でGC.startを実行してください

```ruby
BlueGreenProcess.configure do |config|
  config.shared_variables = [:count]
end

worker_class = Class.new(BlueGreenProcess::BaseWorker) do
  def initialize(*); end

  def work(label)
    BlueGreenProcess::SharedVariable.data['count'] += 1
    BlueGreenProcess::SharedVariable.extend_run_on_this_process = true
    puts "#{label}'s data['count'] is #{BlueGreenProcess::SharedVariable.data['count']}"
  end
end

BlueGreenProcess::SharedVariable.data['count'] = 0
process = BlueGreenProcess.new(worker_instance: worker_class.new, max_work: 3)
process.work # blue
process.work # blue
process.work # blue
process.work # blue
```

### Metrics
パフォーマンスの解析に使えます

##### BlueGreenProcess.performance.process_switching_time_before_work
* プロセスを最後に入れ替えた時にかかった時間を返す

### Callbacks
#### after_fork

プロセスをforkした時に実行する

```ruby
BlueGreenProcess.configure do |config|
  config.after_fork = ->{ puts 'forked!' }
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
* 処理は直列で行う
* processが行う処理内容は引数を含めて固定
* A processがinactiveになった時に行うGC.startに時間がかかると、次にA processがbe_activeになったらレスポンスが遅れる. 構造上の仕様.
  * これが起きる場合はオブジェクトの生成を減らすとか、blue, greenではなくプロセスのプールを作ってプロセスがGCに時間を費やせるようにする
* workerプロセスでエラーが起きたらmasterプロセスにそのエラーが伝わり、workerプロセスは終了します

## TODO
* shutdownしないでプロセスを停止したときにSIGINTを受け取りたい
