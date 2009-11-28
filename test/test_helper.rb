require 'rubygems'
require 'test/unit'
require 'shoulda'
begin
  require 'redgreen'
rescue LoadError
end

require 'active_support'
require 'active_record'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'bitmask-attribute'
require File.dirname(__FILE__) + '/../rails/init'

ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Schema.define do 
  create_table :campaigns do |table|
    table.column :medium, :integer
    table.column :misc, :integer
    table.column :Legacy, :integer
  end
end

# Pseudo model for testing purposes
class Campaign < ActiveRecord::Base
  bitmask :medium, :as => [:web, :print, :email, :phone]
  bitmask :misc, :as => %w(some useless values) do
    def worked?
      true
    end
  end

  bitmask :Legacy, :as => [:upper, :case]
end

class Test::Unit::TestCase
  
  def assert_unsupported(&block)
    assert_raises(ArgumentError, &block)
  end
  
  def assert_stored(record, *values)
    values.each do |value|
      assert record.medium.any? { |v| v.to_s == value.to_s }, "Values #{record.medium.inspect} does not include #{value.inspect}"
    end
    full_mask = values.inject(0) do |mask, value|
      mask | Campaign.bitmasks[:medium][value]
    end
    assert_equal full_mask, record.medium.to_i
  end
  
end
