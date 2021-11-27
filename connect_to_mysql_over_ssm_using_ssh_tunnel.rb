# frozen_string_literal: true

require "aws-sdk"
require "mysql2"
require "json"
require "net/ssh/gateway"
require "net/ssh/proxy/command"

# write aws config file
profile = ENV["AWS_PROFILE"] || "default"

=begin
aws_config_file = File.expand_path("~/.aws/config")
unless File.exist?(aws_config_file) then
  File.open(aws_config_file, "w") do |f|
    f.puts <<-EOS
[default]
region = ap-northeast-1
output = json
[profile #{profile}]
region = ap-northeast-1
output = json
    EOS
  end
end

# write aws credentials file
aws_credentials_file = File.expand_path("~/.aws/credentials")
unless File.exist?(aws_credentials_file) then
  File.open(aws_credentials_file, "w") do |f|
    f.puts <<-EOS
[default]
aws_access_key_id = #{ENV["AWS_ACCESS_KEY_ID"]}
aws_secret_access_key = #{ENV["AWS_SECRET_ACCESS_KEY"]}
[#{profile}]
role_arn = #{ENV["AWS_ROLE_ARN"]}
source_profile = default
    EOS
  end
end
=end

step_user = "ec2-user"
step_host = ENV["INSTANCE_ID"]
db_host = ENV["DB_HOST"]
key_path = ENV["KEY_PATH"] || "~/.ssh/id_rsa.pub"
ssh_options = {
  keys: [key_path],
  # with dynamic config/credentials
  # proxy: Net::SSH::Proxy::Command.new("aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --profile #{ENV["AWS_PROFILE"]}"),
  # without profile
  proxy: Net::SSH::Proxy::Command.new("aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"),
  # with ruby proxy command (not working)
  # proxy: Net::SSH::Proxy::Command.new("ruby /home/tk3fftk/git/ruby-ssm-portforwarding-test/ruby-ssm-startssh-test.rb -h '%h' -p '%p'"),
  # verbose: :info,
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

  results = mysql_client.query("SHOW DATABASES")

  results.each do |row|
    puts row
  end
end

gateway.shutdown!
