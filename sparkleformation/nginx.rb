ENV['chef_run_list']      ||= 'role[base],role[loadbalancer]'
ENV['notification_topic'] ||= "#{ENV['org']}_#{ENV['environment']}_deregister_chef_node"
ENV['lb_name']            ||= "#{ENV['org']}-#{ENV['environment']}-public-elb"

SparkleFormation.new(:vpn, :provider => :aws).load(:base, :chef_base, :ssh_key_pair, :trusty_ami, :elb_security_policies, :git_rev_outputs).overrides do
  description <<"EOF"
Nginx EC2 instance, configured by Chef. Public ELB. Public security group. Nginx security group. Route53 record: *.#{ENV['public_domain']}.
EOF

  parameters(:vpc) do
    type 'String'
    default registry!(:my_vpc)
    allowed_values array!(registry!(:my_vpc))
  end

  dynamic!(:vpc_security_group, 'public',
           :ingress_rules =>
             [
               { :cidr_ip => '0.0.0.0/0', :ip_protocol => 'tcp', :from_port => '80', :to_port => '80' },
               { :cidr_ip => '0.0.0.0/0', :ip_protocol => 'tcp', :from_port => '443', :to_port => '443' }
             ]
          )

  dynamic!(:vpc_security_group, 'nginx',
           :ingress_rules => []
          )

  dynamic!(:security_group_ingress, 'public-elb-to-nginx-http',
           :source_sg => attr!(:public_ec2_security_group, 'GroupId'),
           :ip_protocol => 'tcp',
           :from_port => '80',
           :to_port => '80',
           :target_sg => attr!(:nginx_ec2_security_group, 'GroupId')
          )

  dynamic!(:security_group_ingress, 'public-elb-to-nginx-https',
           :source_sg => attr!(:public_ec2_security_group, 'GroupId'),
           :ip_protocol => 'tcp', 
           :from_port => '443',
           :to_port => '443',
           :target_sg => attr!(:nginx_ec2_security_group, 'GroupId')
          )

  dynamic!(:security_group_ingress, 'nginx-to-nat-all',
           :source_sg => attr!(:nginx_ec2_security_group, 'GroupId'),
           :ip_protocol => '-1',
           :from_port => '-1',
           :to_port => '-1',
           :target_sg => registry!(:my_security_group_id, 'nat_sg')
          )

  dynamic!(:security_group_ingress, 'vpn-to-nginx-all',
           :source_sg => registry!(:my_security_group_id,  'vpn_sg'),
           :ip_protocol => '-1',
           :from_port => '-1',
           :to_port => '-1',
           :target_sg => attr!(:nginx_ec2_security_group, 'GroupId')
          )

  dynamic!(:security_group_ingress, 'nginx-to-empire-minions-http',
           :source_sg => attr!(:nginx_ec2_security_group, 'GroupId'),
           :ip_protocol => 'tcp',
           :from_port => '80',
           :to_port => '80',
           :target_sg => registry!(:my_security_group_id, 'minion_sg')
          )

  dynamic!(:iam_instance_profile, 'nginx',
           :chef_bucket => registry!(:my_s3_bucket, 'chef')
          )

  dynamic!(:elb, 'public',
           :listeners => [
              { :instance_port => '80', :instance_protocol => 'tcp', :load_balancer_port => '80', :protocol => 'tcp'},
              { :instance_port => '443', :instance_protocol => 'tcp', :load_balancer_port => '443', :protocol => 'ssl', :ssl_certificate_id => registry!(:my_acm_server_certificate), :policy_names => [ref!(:elb_security_policy)] }
            ],
            :policies => [
              { :instance_ports => ['80', '443'], :policy_name => 'EnableProxyProtocol', :policy_type => 'ProxyProtocolPolicyType', :attributes => [ { 'Name' => 'ProxyProtocol', 'Value' => true} ] }
            ],
            :security_groups => _array( attr!(:public_ec2_security_group, 'GroupId') ),
            :idle_timeout => '600',
            :subnets => registry!(:my_public_subnet_ids),
            :lb_name => ENV['lb_name'],
            :ssl_certificate_ids => registry!(:my_acm_server_certificate)
          )

  dynamic!(:launch_config, 'nginx',
           :iam_instance_profile => 'NginxIAMInstanceProfile',
           :iam_role => 'NginxIAMRole',
           :public_ips => 'false',
           :chef_run_list => ENV['chef_run_list'],
           :security_groups => _array(ref!(:nginx_ec2_security_group)),
          )

  dynamic!(:auto_scaling_group, 'nginx',
           :min_size => 0,
           :launch_config => :nginx_auto_scaling_launch_configuration,
           :load_balancers => _array(ref!(:public_elastic_load_balancing_load_balancer)),
           :subnet_ids => registry!(:my_private_subnet_ids),
           :notification_topic => registry!(:my_sns_topics, ENV['notification_topic'])
          )

  dynamic!(:record_set, 'wildcard',
           :record => '*',
           :target => :public_elastic_load_balancing_load_balancer,
           :domain_name => ENV['public_domain'],
           :attr => 'CanonicalHostedZoneName',
           :ttl => '60'
  )
end
