#!/usr/bin/env ruby
# This will create a new system
# Systems host clusters
require 'bundler/setup'
require 'cloudformation-ruby-dsl/cfntemplate'
require 'cloudformation-ruby-dsl/table'

template do

  # Parameters
  parameter 'System',
    :Description => 'The fully qualified domain name for the entire system (eg. daily.digitaljedi.ca)',
    :Type =>  'String',
    :Immutable => true

  parameter 'Cluster',
    :Description => 'The domain prefix associated with this cluster (eg. a, b, c, etc...)',
    :Type =>  'String',
    :Immutable => true

  # Tags
  tag :System => ref('System')
  tag :Cluster => ref('Cluster')

  # Resources
  resource "vpc",
    :Type => 'AWS::EC2::VPC',
    :Properties => {
      :CidrBlock => '10.0.0.0/16',
      :InstanceTenancy => 'default',
      :EnableDnsSupport => 'true',
      :EnableDnsHostnames => 'true',
    }

  resource 'publicsubnet',
    :Type => 'AWS::EC2::Subnet',
    :Properties => {
      :CidrBlock => '10.0.0.0/24',
      :VpcId  => ref('vpc'),
    }

  resource 'privatesubnet1',
    :Type => 'AWS::EC2::Subnet',
    :Properties => {
      :CidrBlock => '10.0.1.0/24',
      :VpcId  => ref('vpc'),
    }

  resource 'dbsubnet1',
    :Type => 'AWS::EC2::Subnet',
    :Properties => {
      :AvailabilityZone => select(0, get_azs(aws_region())),
      :CidrBlock => '10.0.100.0/24',
      :VpcId  => ref('vpc'),
    }

  resource 'dbsubnet2',
    :Type => 'AWS::EC2::Subnet',
    :Properties => {
      :AvailabilityZone => select(1, get_azs(aws_region())),
      :CidrBlock => '10.0.101.0/24',
      :VpcId  => ref('vpc'),
    }

  resource 'dbsubnet',
    :Type => 'AWS::RDS::DBSubnetGroup',
    :Properties => {
      :DBSubnetGroupDescription => 'DBSubnet for ',
      :SubnetIds => [ref('dbsubnet1'),ref('dbsubnet2')],
    }

  resource 'internetgateway',
    :Type => 'AWS::EC2::InternetGateway',
    :Properties => {
    }

  resource 'gatewaytointernet',
    :Type => 'AWS::EC2::VPCGatewayAttachment',
    :Properties => {
      :VpcId => ref('vpc'),
      :InternetGatewayId => ref('internetgateway'),
    }

  resource 'privateroutetable',
    :Type => 'AWS::EC2::RouteTable',
    :Properties => {
      :VpcId => ref('vpc'),
    }

  resource 'publicroutetable',
    :Type => 'AWS::EC2::RouteTable',
    :Properties => {
      :VpcId => ref('vpc'),
    }

  resource 'publicroute',
    :Type => 'AWS::EC2::Route',
    :DependsOn => 'gatewaytointernet',
    :Properties => {
      :RouteTableId => ref('publicroutetable'),
      :DestinationCidrBlock => '0.0.0.0/0',
      :GatewayId => ref('internetgateway'),
    }

  resource 'privateroute',
    :Type => 'AWS::EC2::Route',
    :DependsOn => 'gatewaytointernet',
    :Properties => {
      :RouteTableId => ref('privateroutetable'),
      :DestinationCidrBlock => '0.0.0.0/0',
      :GatewayId => ref('internetgateway')
    }

  resource 'acl1',
    :Type => 'AWS::EC2::NetworkAcl',
    :Properties => {
      :VpcId  => ref('vpc'),
    }

  resource 'ACL001',
    :Type => 'AWS::EC2::NetworkAclEntry',
    :Properties => {
      :CidrBlock => '0.0.0.0/0',
      :Egress => true,
      :Protocol => '-1',
      :RuleAction => 'allow',
      :RuleNumber =>  '100',
      :NetworkAclId => ref('acl1')
    }

  resource 'ACL002',
    :Type => 'AWS::EC2::NetworkAclEntry',
    :Properties => {
      :CidrBlock => '0.0.0.0/0',
      :Protocol => '-1',
      :RuleAction => 'allow',
      :RuleNumber =>  '100',
      :NetworkAclId => ref('acl1')
    }

  resource 'publicsubnetnetworkrouteassociation',
    :Type => 'AWS::EC2::SubnetRouteTableAssociation',
    :Properties => {
      :SubnetId => ref('publicsubnet'),
      :RouteTableId => ref('publicroutetable'),
    }

  resource 'privatesubnetrouteassociation',
    :Type => 'AWS::EC2::SubnetRouteTableAssociation',
    :Properties => {
      :SubnetId => ref('privatesubnet1'),
      :RouteTableId => ref('privateroutetable'),
    }

  resource 'db1subnetrouteassociation',
    :Type => 'AWS::EC2::SubnetRouteTableAssociation',
    :Properties => {
      :SubnetId => ref('dbsubnet1'),
      :RouteTableId => ref('privateroutetable'),
    }

  resource 'db2subnetrouteassociation',
    :Type => 'AWS::EC2::SubnetRouteTableAssociation',
    :Properties => {
      :SubnetId => ref('dbsubnet2'),
      :RouteTableId => ref('privateroutetable'),
    }

  resource 'dhcpoptions',
    :Type => 'AWS::EC2::DHCPOptions',
    :Properties => {
      :DomainName => parameters['System'],
      :DomainNameServers => ['AmazonProvidedDNS'],
    }

  resource 'dhcpassoc',
    :Type => 'AWS::EC2::VPCDHCPOptionsAssociation',
    :Properties => {
      :VpcId => ref('vpc'),
      :DhcpOptionsId => ref('dhcpoptions'),
    }

end.exec!
