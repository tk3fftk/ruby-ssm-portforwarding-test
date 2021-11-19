# frozen_string_literal: true

require "aws-sdk"
require "mysql2"
require "json"

ssm_endpoint = "https://ssm.ap-northeast-1.amazonaws.com"

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

start_session_response = client.start_session({
  target: ENV["INSTANCE_ID"],
  document_name: "AWS-StartPortForwardingSession",
  reason: "test",
  parameters: {
    portNumber: ["3306"],
    localPortNumber: ["13306"],
  }
})

puts start_session_response
session = {
  SessionId: start_session_response["session_id"],
  TokenValue: start_session_response["token_value"],
  StreamUrl: start_session_response["stream_url"],
}

puts session

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
        value: session[:SessionId], # required
      },
    ],
  })
  status = res["sessions"][0]["status"]
  count += 1
  sleep(0.5)
  puts(res)
end

plugin_parametes = {
  Target: ENV["INSTANCE_ID"],
  DocumentName: "AWS-StartPortForwardingSession",
  Parameters: {
    portNumber: ["3306"],
    localPortNumber: ["13306"],
  }
}

# run session-manager-plugin
cmd = "session-manager-plugin '#{session.to_json}' 'ap-northeast-1' 'StartSession' 'session-from-ruby' '#{plugin_parametes.to_json}' '#{ssm_endpoint}'"
puts cmd
pid = spawn(
  cmd
)
Signal.trap(0, proc {
  puts "Terminating: #{$$}, send SIGTERM to #{pid}"
  Process.kill("TERM", pid)
})

sleep(1)

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
