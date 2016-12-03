SparkleFormation.component(:trusty_ami) do
  mappings(:region_to_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-4d2f105a')
    set!('us-east-2'.disable_camel!, :ami => 'ami-f08ad095')
    set!('us-west-1'.disable_camel!, :ami => 'ami-a7ce9ac7')
    set!('us-west-2'.disable_camel!, :ami => 'ami-7d6cc21d')
  end
end
