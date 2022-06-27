# README

DynamoDBをrubyから操作するサンプルアプリ
railsに載せちゃって依存しているのがチョイ嫌

## 環境(2022-06-27)
> Windows 11 Pro 10.0.22000
> WSL2 Ubuntu 20.04.4 LTS
> ruby 3.1.2p20
> aws-sdk-dynamodb 1.75.0

### テーブル作成

すべてデフォルト設定でテーブル`sample2`を作成

```rb
Sample::Dynamodb::Migrate::Sample2.create
```

**設定を変えて作成する**
`Sample::Dynamodb::Migration` を変更する
`Sample::Dynamodb::Migrate::Sample2` で設定を上書きする
実行時に渡す
`Sample::Dynamodb::Migrate::Sample2.create(region: 'us-east-1')`

* 設定できるパラメータ
table_name
key_schema
attribute_definitions
provisioned_throughput
billing_mode
tags
stream_specification
sse_specification
kms_master_key_id
region
stream_enabled
sse_enabled
backup_enabled
replica_regions
global_table_enabled
replica_enabled

### テーブル作成

テーブル`sample2`を削除

```rb
Sample::Dynamodb::Migrate::Sample2.drop
```

### テーブル存在確認

```rb
Sample::Dynamodb::Migrate::Sample2.exists?
```


### データ登録

```rb
Sample::Dynamodb::Models::Sample2.put({ user_id: "1", foo: "FOO" }, 'sample2', 'ap-northeast-1')
```

テーブル名は省略可(モデル名から推測できる場合)
リージョンは省略可(Sample::Dynamodb::Client#default_regionになる)

### データ取得

```rb
Sample::Dynamodb::Models::Sample2.get(user_id: "1", 'sample2', 'ap-northeast-1')
```

テーブル名は省略可(モデル名から推測できる場合)
リージョンは省略可(Sample::Dynamodb::Client#default_regionになる)

