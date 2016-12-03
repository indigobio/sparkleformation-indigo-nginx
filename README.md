## sparkleformation-indigo-nginx
This repository contains a SparkleFormation template that creates a 
multi-member nginx auto scaling group.

Additionally, the template creates two security groups (public, nginx), and
creates an Elastic Load Balancer that forwards traffic to both nginx instances.

Finally, the template will create a Route53 DNS record: *.`ENV['public_domain']`.
### Dependencies

The template requires external Sparkle Pack gems, which are noted in
the Gemfile and the .sfn file.  These gems interact with AWS through the
`aws-sdk-core` gem to identify or create  availability zones, subnets, and 
security groups.

### Parameters

When launching the compiled CloudFormation template, you will be prompted for
some stack parameters:

| Parameter | Default Value | Purpose |
|-----------|---------------|---------|
| ChefServer | https://api.opscode.com/organizations/product_dev | No need to change |
| ChefValidationClientName | product_dev-validator | No need to change |
| ChefVersion | 12.4.0 | No need to change |
| ElbSecurityPolicy | automatically determined | You should use the latest security policy, which is subject to change. |
| NginxAssociatePublicIpAddress | false | No need to change |
| NginxChefrunList | role[base],role[loadbalancer] | The Chef run list to run on tokumx01 |
| NginxDesiredCapacity | 1 | Set to at least 2 |
| NginxInstanceMonitoring | false | Set to true to enable detailed cloudwatch monitoring (additional costs incurred) |
| NginxInstanceType | t2.small | Set to at least t2.medium |
| NginxMaxSize | 1 | Set to at least 2 |
| NginxMinSize | 0 | Set to at most 1 |
| NginxNotificationTopic | automatically determined | The SNS notification topic of the Chef handler, for terminated Chef nodes |
| NginxRootVolumeSize | 12 | Size of the root EBS volume, in GB |
| PublicElbName | ENV['org']-ENV['environment']-public-elb | Change in the event that you don't want to replace your public ELB during a stack update. |
| SshKeyPair | indigo-bootstrap | No need to change |
| Vpc | automatically determined | Cannot change |
