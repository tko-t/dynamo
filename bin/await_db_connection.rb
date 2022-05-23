require 'active_record'
require 'erb'

# mysqldが起動されるまでジッと待つ
config_database =
  # ruby 3.1系変更による Psych <~ 4.0 対応
  # https://secret-garden.hatenablog.com/entry/2021/05/23/200803
  # この辺を参考にした
  Psych.safe_load(
    ERB.new(
      File.read(
        File.join(__dir__, '../', 'config', 'database.yml')
      ) # raw config/database.yml
    ).result, # parse ERB
    aliases: true) # to_hash

development = config_database.dig('development')

begin
  ActiveRecord::Base.establish_connection(development)
  ActiveRecord::Base.connection

  puts 'database connected!'
rescue
  sleep 0.5
  retry if (@retry ||= 0).tap { print "\r#{@retry += 1}" } < 20 # 最大10秒

  raise $!
end
