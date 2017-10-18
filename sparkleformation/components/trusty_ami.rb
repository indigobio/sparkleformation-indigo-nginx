SparkleFormation.component(:trusty_ami) do
  mappings(:region_to_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-73489b09')
    set!('us-east-2'.disable_camel!, :ami => 'ami-0e163a6b')
    set!('us-west-1'.disable_camel!, :ami => 'ami-c66954a6')
    set!('us-west-2'.disable_camel!, :ami => 'ami-09589b71')
  end
end
