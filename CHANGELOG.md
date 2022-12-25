## [0.1.4.2] - 2022-12-13
* プロセス終了時にDRb.stop_serviceを呼ぶのをやめました

## [0.1.4.1] - 2022-12-13
* プロセス終了時にDRb.stop_serviceを呼ぶようにしました

## [0.1.4] - 2022-12-12
* BlueGreenProcess.terminate_workers_immediately を呼び出すことで、シグナル経由で終了できるようになりました

## [0.1.3] - 2022-9-5
* 単一プロセスでの実行を延長するとGC.startを実行しなくなりました
    * 長時間にわたって延長する時は呼び出し側でGC.startを実行してください

## [0.1.2] - 2022-9-5
- プロセス間での値の共有で値の共有ができるようになりました
- 単一プロセスでの実行を延長できるようになりました
- プロセスをforkした時に実行するコールバックをblockで設定できるようになりました
- プロセスの切り替え時にかかった時間を取得できるようになりました
    - BlueGreenProcess.performance.process_switching_time_before_work

## [0.1] - 2022-06-17

- Initial release
