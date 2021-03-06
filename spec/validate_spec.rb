require 'yaml'
require 'spec_helper'

module Boolean; end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end

# Supporting Ruby < 2.4.
#
if not defined?(Fixnum)
  class Fixnum < Integer; end
end

# This hash defines the expected format of
# config sets in AWS::CloudFormation::Init blocks.
#
# Data types and regular expressions used as
# placeholders for real values.
#
# Based on documentation here:
#
# https://docs.aws.amazon.com/AWSCloudFormation/
#   latest/UserGuide/aws-resource-init.html
#
$types = {
  'packages' => {
    'apt'      => {String => Array},
    'msi'      => {String => String},
    'python'   => {String => Array},
    'rpm'      => {String => String},
    'rubygems' => {String => Array},
    'yum'      => {String => Array},
  },
  'groups' => {
    String => {'gid' => Fixnum},
  },
  'users' => {
    String => {
      'groups'  => Array,
      'uid'     => Fixnum,
      'homeDir' => String,
    },
  },
  'sources' => {String => String},
  'files' => {
    String => {
      'content'   => String,
      'source'    => /^http/,
      'encoding'  => /plain|base64/,
      'group'     => String,
      'owner'     => String,
      'mode'      => Fixnum,
      'authentication' => String,
      'context'        => String,
    },
  },
  'commands' => {
    String => {
      'command'  => String, # TODO. Apparently the only mandatory
      'env'      => Hash,   #       attribute.
      'cwd'      => String,
      'test'     => String,
      'ignoreErrors'   => Boolean,
      'waitAfterCompletion' => Boolean,
    },
  },
  'services' => {
    /sysvinit|windows/ => {
      String => {
        'ensureRunning' => Boolean,
        'enabled'   => Boolean,
        'files'     => Array,
        'sources'   => Array,
        'packages'  => Array,
        'commands'  => Array,
      },
    },
  },
}

# Method: check_config_sets
#
# Check that a configSets block in the template
# has the expected format.
#
def check_config_sets(init)
  context "configSets" do
    config_sets = init['configSets']

    it "should be a Hash" do
      expect(config_sets.class).to be Hash
    end

    config_sets.each do |k,v|
      context k do
        it "should be an Array" do
          expect(v.class).to be Array
        end

        v.each do |config_set|
          context config_set do
            it "should have a corresponding key" do
              expect(init.include?(config_set))
                .to be true
            end
          end
        end
      end
    end
  end
end

# Method: check_keys
#
# Check that the keys in the real data are a subset of the
# keys in the reference data $types.
#
# @param data_keys [Array] The actual keys.
# @param spec_keys [Array] The keys in $types.
#
def check_keys(data_keys, spec_keys)
  context data_keys do
    if spec_keys == [String] or spec_keys.first.is_a?(Regexp)
      it "should all match String" do
        expect(data_keys.map{|k| k.is_a?(String)}.uniq).to eq [true]
      end
    else
      it "should be a subset of #{spec_keys}" do
        expect((data_keys - spec_keys).empty?).to be true
      end
    end
  end
end

# Method: compare
#
# Recursively compare real blocks in a CloudFormation template
# with the spec defined in $types.
#
# @param data [Hash] The real data in the template.
# @param spec [Hash] The reference data corresponding to this
#                    key in $types.
#
def compare(data, spec)
  if spec.is_a?(Hash)
    check_keys(data.keys, spec.keys)
  end
  data.each do |k,v|
    context k do
      if spec == Array
        it "#{k} should match Array" do
          expect(v.class).to eq Array
        end

      elsif spec[k] == Hash
        it "#{k} should match Hash" do
          expect(v.class).to eq Hash
        end

      elsif spec == {String => Array} or
            spec == {String => String}
        it "#{k}=>#{v} should match #{spec}" do
          expect(k.class).to eq spec.keys.first
          expect(v.class).to eq spec[spec.keys.first]
        end

      elsif spec.has_key?(k)
        if v.is_a?(Hash)
          compare(v, spec[k]) # recurse.
        elsif spec[k].is_a?(Regexp)
          it "#{k} should match #{spec[k]}" do
            expect(v).to match spec[k]
          end
        elsif spec[k] == String

          # Actually, an Array of Strings joined by CloudFormation
          # is also okay.
          #
          it "#{k} should match #{spec[k]}" do
            expect([String, Array].include?(v.class)).to be true
          end
        elsif spec[k] == Fixnum
          it "#{k} should match (or be cast to) #{spec[k]}" do
            expect { v.to_i }.to_not raise_error
          end
        elsif [Array, TrueClass, FalseClass]
            .include?(v.class)
          it "#{v} should be a #{spec[k]}" do
            expect(v).to be_a spec[k]
          end
        end

      elsif v.is_a?(Hash)
        spec_key = spec.keys.first
        compare(v, spec[spec_key]) # recurse.

      else
        raise "Something went wrong"
      end
    end
  end
end

# Method: validate
#
# A wrapper around the compare() and check_config_sets()
# methods.
#
def validate(init)
  if init.has_key?('configSets')
    check_config_sets(init)
  end
  init.each do |config,config_data|
    next if config == 'configSets'
    context config do
      compare(config_data, $types)
    end
  end
end

# Method: validate_resource
#
def validate_resource(name, resource)
  allowed = %w{
    AWS::EC2::Instance AWS::AutoScaling::LaunchConfiguration
  }
  context name do
    it "Type should be one of #{allowed}" do
      expect(allowed.include?(resource['Type'])).to be true
    end
  end
end

yaml = YAML.load_file('cloudformation.yml')
keys = yaml['Resources'].select do |k,v|
  v.has_key?('Metadata') and v['Metadata'].has_key?(
      'AWS::CloudFormation::Init')
end

keys.each do |k,v|
  init = v['Metadata']['AWS::CloudFormation::Init']
  validate_resource(k,v)
  describe k do
    validate(init)
  end
end
