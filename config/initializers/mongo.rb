# coding: utf-8
MongoMapper.connection = Mongo::Connection.new('localhost', 27017)
MongoMapper.database = "#mongo_test-#{Rails.env}"

# Passengerを利用する場合のみ必要？
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    MongoMapper.connection.connect if forked
  end
end