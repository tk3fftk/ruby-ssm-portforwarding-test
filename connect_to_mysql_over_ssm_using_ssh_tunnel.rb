# frozen_string_literal: true

require "aws-sdk"
require "mysql2"
require "json"
require "net/ssh/gateway"
require "net/ssh/proxy/command"

step_user = "ec2-user"
step_host = ENV["INSTANCE_ID"]
db_host = ENV["DB_HOST"]
key_path = ENV["KEY_PATH"] || "~/.ssh/id_rsa.pub"
ssh_options = {
  keys: [key_path],
  proxy: Net::SSH::Proxy::Command.new("aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --profile pn-playground")
}

gateway = Net::SSH::Gateway.new(step_host, step_user, ssh_options)

gateway.open(db_host, 3306) do |forwared_port|
  puts "Connecting to #{db_host}:#{forwared_port}"

  # connect to the database
  mysql_client = Mysql2::Client.new(
    host: "127.0.0.1",
    username: ENV["MYSQL_USERNAME"],
    password: ENV["MYSQL_PASSWORD"],
    port: forwared_port,
    database: ENV["MYSQL_DATABASE"]
  )

  results = mysql_client.query("SELECT * FROM user")

  results.each do |row|
    puts row
  end
end
