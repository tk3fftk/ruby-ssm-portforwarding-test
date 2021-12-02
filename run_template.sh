#!/bin/bash -eu

export INSTANCE_ID='i-hogehogereplaceme'
export DB_HOST='replaceme'
export KEY_PATH='replaceme'
export AWS_ACCESS_KEY_ID='replaceme'
export AWS_SECRET_ACCESS_KEY='replaceme'
export AWS_REGION="ap-northeast-1"
export MYSQL_USERNAME='user'
export MYSQL_PASSWORD='password'
export MYSQL_DATABASE='database'
export NO_ENV='true'

ruby connect_to_mysql_over_ssm_using_ssh_tunnel.rb
