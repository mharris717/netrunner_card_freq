require 'spec_helper'

describe 'redis smoke' do
  it 'smoke' do
    redis = Setup.make_redis
    key = rand(1000000000).to_s
    val = rand(100000000).to_s
    redis.set key,val
    redis.get(key).should == val
  end
end