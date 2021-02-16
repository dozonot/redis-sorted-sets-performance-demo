require "redis"
require "mysql2"
require "faker"
require "time"

mode = ARGV[0]
count = ARGV[1].to_i

users = {}

count.times do
  users[Faker::Name.unique.name] = rand(count * 2)
end

if mode == 'store' then
  # Insert into redis srotedset
  redis = Redis.new
  redis.del("ranking")

  puts Time.now.to_s + " : Redisのソート済みハッシュに " + count.to_s + " 件のデータを追加します。"
  users.each{|key, value|
    redis.zadd("ranking", value, key)
  }
  puts Time.now.to_s + " : Redisのソート済みハッシュに " + count.to_s + " 件のデータを追加しました。"

  # Insert into mysql table
  mysql = Mysql2::Client.new(:host => "127.0.0.1", :username => "demo", :password => "demo", :database => 'demo')
  mysql.query("DROP TABLE IF EXISTS ranking")
  mysql.query("CREATE TABLE ranking (id INTEGER PRIMARY KEY AUTO_INCREMENT, name VARCHAR(50), score INTEGER)")

  statement = mysql.prepare("INSERT INTO ranking SET name = ?, score = ?")
  puts Time.now.to_s + " : MySQLのテーブルに " + count.to_s + " 件のデータを追加します。"
  users.each{|key, value|
    statement.execute(key, value)
  }
  puts Time.now.to_s + " : MySQLのテーブルに " + count.to_s + " 件のデータを追加しました。"
end


if mode == 'redis' then
  redis = Redis.new
  puts Time.now.to_s + " : Redisのソート済みハッシュからランキング上位3名のデータを取得します。"
  puts redis.zrevrange("ranking", 0, 2)
  puts Time.now.to_s + " : Redisのソート済みハッシュからランキング上位3名のデータを取得しました。"
elsif mode == 'mysql' then
  mysql = Mysql2::Client.new(:host => "127.0.0.1", :username => "demo", :password => "demo", :database => 'demo')
  puts Time.now.to_s + " : Redisのソート済みハッシュからランキング上位3名のデータを取得します。"
  users = mysql.query("SELECT * FROM ranking ORDER BY score DESC LIMIT 3")
  users.each{|user|
    puts user
  }
  puts Time.now.to_s + " : Redisのソート済みハッシュからランキング上位3名のデータを取得しました。"
end
