# AWS::CloudFormation::Init RSpec validation

[![Build Status](https://img.shields.io/travis/alexharv074/cfn-init-validate.svg)](https://travis-ci.org/alexharv074/cfn-init-validate)

## Overview

A proof of concept using RSpec to validate AWS::CloudFormation::Init configurations.

## What it does

Based on documentation [here](docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-init.html), I have reduced the AWS::CloudFormation::Init configuration to a specification in [this](./spec/validate_spec.rb#L25-79) Ruby Hash in the RSpec test file:

```ruby
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
      'command'  => String, 
      'env'      => Hash,   
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
```

I take this to be a concise specification of all valid AWS::CloudFormation::Init configurations.

The contents of the AWS::CloudFormation::Init is then recursively compared against this structure. Data types and regular expressions in the structure are taken as placeholders for real data and data is validated against these. A few other bits and pieces are also validated.

For more information, everything interesting is in the source code in [spec/validate_spec.rb](./spec/validate_spec.rb) and [test_runner.sh](./test_runner.sh).

## Dependencies

To run the demo you need:

- Ruby (tested on Ruby 2.1.4)
- Rubygems
- Bundler
- Python
- Virtualenv
- Make

## Demo

To run the demo:

```text
▶ make
```

The test runner will download a bunch of example CloudFormation templates with AWS::CloudFormation::Init blocks and validate them.

## Usage

To validate your own CloudFormation template:

- Clone this project and cd to the project root.

- Save your template as `cloudformation.yml`.

- If necessary, convert it from JSON (look in `test_runner.sh` to understand how to do that).

- Then:

```text
▶ bundle install
▶ bundle exec rake
```

Or, just fork this project and use `spec/validate_spec.rb` in your own project.

## Known issues

Use of If conditionals to populate fields within the AWS::CloudFormation::Init config will cause fields to appears as Arrays instead of Booleans etc. For example, [here](https://github.com/widdix/aws-cf-templates/blob/master/ec2/ec2-auto-recovery.yaml#L540-L541).

## License

MIT.
