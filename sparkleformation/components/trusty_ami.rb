SparkleFormation.component(:trusty_ami) do
  mappings(:region_to_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-9c756ee7')
    set!('us-east-2'.disable_camel!, :ami => 'ami-3a3f1d5f')
    set!('us-west-1'.disable_camel!, :ami => 'ami-dfa394bf')
    set!('us-west-2'.disable_camel!, :ami => 'ami-5610e12e')
  end
end
