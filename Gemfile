# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem "aws_config"
gem "aws-sdk", "~> 3"
gem "mysql2"
gem "net-ssh"
gem "net-ssh-gateway"

group :rubocop do
  gem "rubocop", ">= 0.90", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-packaging", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
end
