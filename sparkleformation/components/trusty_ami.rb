SparkleFormation.component(:trusty_ami) do
  mappings(:region_to_ami) do
    set!('us-east-1'.disable_camel!, :ami => 'ami-6967b413')
    set!('us-east-2'.disable_camel!, :ami => 'ami-d0163ab5')
    set!('us-west-1'.disable_camel!, :ami => 'ami-466a5726')
    set!('us-west-2'.disable_camel!, :ami => 'ami-ef61a297')
  end
end
