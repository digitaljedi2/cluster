#!/usr/bin/env ruby
#
require 'aws-sdk'
require 'yaml'

# load credentials from disk
creds = YAML.load(File.read('/Users/jpoole/.aws/credentials.yml'))

client = Aws::CloudFormation::Client.new(
  access_key_id: creds['access_key_id'],
  secret_access_key: creds['secret_access_key']
)

template = File.open("template.json", "rb")
contents = template.read
resp = client.create_stack({
  stack_name: "b-jpoole-auvik-com", # required
  template_body: contents,
  parameters: [
    {
      parameter_key: "System",
      parameter_value: "jpoole.auvik.com",
      use_previous_value: true,
    },
    {
      parameter_key: "Cluster",
      parameter_value: "b",
      use_previous_value: true,
    },
  ],
  disable_rollback: true,
  timeout_in_minutes: 1,
  capabilities: ["CAPABILITY_IAM"], # accepts CAPABILITY_IAM
})
