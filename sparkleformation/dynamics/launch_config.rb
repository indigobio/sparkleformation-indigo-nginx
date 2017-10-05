SparkleFormation.dynamic(:launch_config) do |_name, _config = {}|

  _config[:ami_map]              ||= :region_to_ami
  _config[:iam_instance_profile] ||= "#{_name}_i_a_m_instance_profile".to_sym
  _config[:iam_role]             ||= "#{_name}_i_a_m_role".to_sym
  _config[:chef_run_list]        ||= 'role[base]'

  parameters("#{_name}_instance_type".to_sym) do
    type 'String'
    allowed_values registry!(:ec2_instance_types)
    default _config[:instance_type] || 't2.small'
  end

  parameters("#{_name}_instance_monitoring".to_sym) do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:monitoring, 'false').to_s
    description 'Enable detailed cloudwatch monitoring for each instance'
  end

  parameters("#{_name}_associate_public_ip_address".to_sym)do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:public_ips, 'false').to_s
    description 'Associate public IP addresses to instances'
  end

  parameters("#{_name}_chef_run_list".to_sym) do
    type 'CommaDelimitedList'
    default _config[:chef_run_list]
    description 'The run list to run when Chef client is invoked'
  end

  parameters("#{_name}_root_volume_size".to_sym) do
    type 'Number'
    min_value '1'
    max_value '1000'
    default _config[:root_volume_size] || '12'
    description 'The size of the root volume (/dev/sda1) in gigabytes'
  end

  # _config[:volume_count] has to be set to non-zero while compiling the template.
  # The number of block device mappings are coded into the json file.
  if _config.fetch(:volume_count, 0).to_i > 0

    conditions.set!(
      "#{_name}_volumes_are_io1".to_sym,
      equals!(ref!("#{_name}_ebs_volume_type".to_sym), 'io1')
    )

    parameters("#{_name}_ebs_volume_type".to_sym) do
      type 'String'
      allowed_values ['gp2', 'io1']
      default _config.fetch(:volume_type, 'gp2')
      description 'EBS volume type: General Purpose (gp2) or Provisioned IOPS (io1).  Provisioned IOPS costs more.'
    end

    parameters("#{_name}_ebs_provisioned_iops".to_sym) do
      type 'Number'
      min_value '1'
      max_value '4000'
      default _config.fetch(:provisioned_iops, '300')
    end

    parameters("#{_name}_ebs_volume_size".to_sym) do
      type 'Number'
      min_value '1'
      max_value '1000'
      default _config.fetch(:volume_size, '100')
    end

    parameters("#{_name}_delete_ebs_volume_on_termination".to_sym) do
      type 'String'
      allowed_values ['true', 'false']
      default _config.fetch(:delete_on_termination, 'true')
    end

    parameters("#{_name}_ebs_optimized".to_sym) do
      type 'String'
      allowed_values _array('true', 'false')
      default _config.fetch(:ebs_optimized, 'false')
      description 'Create an EBS-optimized instance (instance type restrictions and additional charges apply)'
    end
  end

  dynamic!(:auto_scaling_launch_configuration, _name).properties do
    image_id map!(_config[:ami_map], region!, :ami)
    instance_type ref!("#{_name}_instance_type".to_sym)
    instance_monitoring ref!("#{_name}_instance_monitoring".to_sym)
    iam_instance_profile ref!(_config[:iam_instance_profile])
    associate_public_ip_address ref!("#{_name}_associate_public_ip_address".to_sym)
    key_name ref!(:ssh_key_pair)
    security_groups _config[:security_groups]
    block_device_mappings registry!(:ebs_volumes,
                                    :io1_condition => "#{_name.capitalize}VolumesAreIo1",
                                    :restore_condition => 'RestoreFromSnapshots',
                                    :volume_count => _config[:volume_count],
                                    :volume_size => ref!("#{_name}_ebs_volume_size".to_sym),
                                    :provisioned_iops => ref!("#{_name}_ebs_provisioned_iops".to_sym),
                                    :delete_on_termination => ref!("#{_name}_delete_ebs_volume_on_termination".to_sym),
                                    :root_volume_size => ref!("#{_name}_root_volume_size".to_sym)
                          )
    if _config.fetch(:volume_count, 0).to_i > 0
      ebs_optimized ref!("#{_name}_ebs_optimized".to_sym)
    end
    user_data registry!(:user_data, _name,
                        :iam_role => ref!(_config[:iam_role]),
                        :launch_config => "#{_name.capitalize}AutoScalingLaunchConfiguration",
                        :resource_id => "#{_name.capitalize}AutoScalingAutoScalingGroup"
                       )
  end

  dynamic!(:auto_scaling_launch_configuration, _name).registry!(:chef_client, _name,
           :chef_bucket => registry!(:my_s3_bucket, 'chef'),
           :chef_server => ref!(:chef_server),
           :chef_version => ref!(:chef_version),
           :chef_run_list => ref!("#{_name}_chef_run_list".to_sym),
           :iam_role => ref!(_config[:iam_role]),
           :chef_validation_client => ref!(:chef_validation_client_name),
           :chef_data_bag_secret => true
          )

  dynamic!(:auto_scaling_launch_configuration, _name).depends_on "#{_name.capitalize}IAMInstanceProfile"
end
