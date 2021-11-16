# frozen_string_literal: true

require "aws-sdk"
require "aws_config"

role_credentials = Aws::AssumeRoleCredentials.new(
  role_arn: ENV["AWS_ROLE_ARN"],
  role_session_name: "sesseion-from-ruby"
)

client = Aws::SSM::Client.new(
  access_key_id: ENV["AWS_ACCESS_KEY_ID"],
  secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
  region: ENV["AWS_REGION"] || "ap-northeast-1",
  credentials: role_credentials
)

res = client.start_session({
                             target: ENV["INSTANCE_ID"],
                             document_name: "AWS-StartSSHSession",
                             reason: "test",
                           })
print(res)
