# frozen_string_literal: true

require "aws-sdk"
require "optparse"
require "json"

# parse cli options
opt = OptionParser.new
host = nil
port = "22"

opt.on("-h", "--host HOST") { |v| host = v }
opt.on("-p", "--port [PORT]") { |v| port = v }

opt.parse!(ARGV)
p host
p port

# connect ssm
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
  target: host,
  document_name: "AWS-StartSSHSession",
  reason: "test",
  parameters: {
    portNumber: [port],
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
  target: host,
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
  Target: host,
  DocumentName: "AWS-StartSSHSession",
  Parameters: {
    portNumber: [port],
  }
}

# run session-manager-plugin
cmd = "session-manager-plugin '#{session.to_json}' 'ap-northeast-1' 'StartSession' 'session-from-ruby' '#{plugin_parametes.to_json}' '#{ssm_endpoint}'"
puts cmd
exec(
  cmd
)
