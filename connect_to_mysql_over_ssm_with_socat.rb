# frozen_string_literal: true

require "aws-sdk"
require "mysql2"

role_credentials = Aws::AssumeRoleCredentials.new(
  role_arn: ENV["AWS_ROLE_ARN"],
  role_session_name: "session-from-ruby"
)

client = Aws::SSM::Client.new(
  access_key_id: ENV["AWS_ACCESS_KEY_ID"],
  secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
  region: ENV["AWS_REGION"] || "ap-northeast-1",
  credentials: role_credentials
)

res = client.start_session({
  target: ENV["INSTANCE_ID"],
  document_name: "AWS-StartPortForwardingSession",
  reason: "test",
  parameters: {
    portNumber: ["3306"],
    localPortNumber: ["13306"],
  }
})

puts res
session_id = res["session_id"]
token = res["token_value"]
stream_url = res["stream_url"]

res = client.get_connection_status({
  target: ENV["INSTANCE_ID"],
})

puts res

status = ""
max_attempt = 10
count = 0

while status != "Connected" && count < max_attempt
  res = client.describe_sessions({
    state: "Active", # required, accepts Active, History
    max_results: 1,
    #  next_token: token,
    filters: [
      {
        key: "SessionId", # required, accepts InvokedAfter, InvokedBefore, Target, Owner, Status, SessionId
        value: session_id, # required
      },
    ],
  })
  status = res["sessions"][0]["status"]
  count += 1
  sleep(0.5)
  puts(res)
end

mysql_client = Mysql2::Client.new(
  host: "127.0.0.1",
  username: ENV["MYSQL_USERNAME"],
  password: ENV["MYSQL_PASSWORD"],
  port: 13306,
  database: ENV["MYSQL_DATABASE"]
)

results = mysql_client.query("SELECT * FROM user")

results.each do |row|
  puts row
end
