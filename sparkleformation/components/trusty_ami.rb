SparkleFormation.component(:trusty_ami) do
  mappings(:region_to_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-a49f4dde')
    set!('us-east-2'.disable_camel!, :ami => 'ami-a2123ec7')
    set!('us-west-1'.disable_camel!, :ami => 'ami-89665be9')
    set!('us-west-2'.disable_camel!, :ami => 'ami-8f6eadf7')
  end
end
