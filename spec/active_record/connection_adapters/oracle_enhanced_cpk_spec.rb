require 'spec_helper'

unless defined?(NO_COMPOSITE_PRIMARY_KEYS)

describe "OracleEnhancedAdapter composite_primary_keys support" do
  include SchemaSpecHelper

  before(:all) do
    if defined?(::ActiveRecord::ConnectionAdapters::OracleAdapter)
      @old_oracle_adapter = ::ActiveRecord::ConnectionAdapters::OracleAdapter
      ::ActiveRecord::ConnectionAdapters.send(:remove_const, :OracleAdapter)
    end
    ActiveRecord::Base.establish_connection(CONNECTION_PARAMS)
    if $cpk_oracle_adapter
      ::ActiveRecord::ConnectionAdapters::OracleAdapter = $cpk_oracle_adapter
      $cpk_oracle_adapter = nil
    end
    require 'composite_primary_keys'
  end

  after(:all) do
    # Object.send(:remove_const, 'CompositePrimaryKeys') if defined?(CompositePrimaryKeys)
    if defined?(::ActiveRecord::ConnectionAdapters::OracleAdapter)
      $cpk_oracle_adapter = ::ActiveRecord::ConnectionAdapters::OracleAdapter
      ::ActiveRecord::ConnectionAdapters.send(:remove_const, :OracleAdapter)
    end
    if @old_oracle_adapter
      ::ActiveRecord::ConnectionAdapters::OracleAdapter = @old_oracle_adapter
      @old_oracle_adapter = nil
    end
  end

  describe "table with LOB" do
    before(:all) do
      schema_define do
        create_table  :cpk_write_lobs_test, :primary_key => [:type_category, :date_value], :force => true do |t|
          t.string  :type_category, :limit => 15, :null => false
          t.date    :date_value, :null => false
          t.text    :results, :null => false
          t.timestamps null: true
        end
        create_table :non_cpk_write_lobs_test, :force => true do |t|
          t.date    :date_value, :null => false
          t.text    :results, :null => false
          t.timestamps null: true
        end
      end
      class ::CpkWriteLobsTest < ActiveRecord::Base
        self.table_name = 'cpk_write_lobs_test'
        set_primary_keys :type_category, :date_value
      end
      class ::NonCpkWriteLobsTest < ActiveRecord::Base
        self.table_name = 'non_cpk_write_lobs_test'
      end
    end

    after(:all) do
      schema_define do
        drop_table :cpk_write_lobs_test
        drop_table :non_cpk_write_lobs_test
      end
      Object.send(:remove_const, "CpkWriteLobsTest")
      Object.send(:remove_const, "NonCpkWriteLobsTest")
    end

    it "should create new record in table with CPK and LOB" do
      expect {
        CpkWriteLobsTest.create(:type_category => 'AAA', :date_value => Date.today, :results => 'DATA '*10)
      }.not_to raise_error
    end

    it "should create new record in table without CPK and with LOB" do
      expect {
        NonCpkWriteLobsTest.create(:date_value => Date.today, :results => 'DATA '*10)
      }.not_to raise_error
    end
  end

  # Other testing was done based on composite_primary_keys tests

end

end
