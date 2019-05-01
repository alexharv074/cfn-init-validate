# cfn-init Rspec validation

[![Build Status](https://img.shields.io/travis/alexharv074/cfn-init-validate.svg)](https://travis-ci.org/alexharv074/cfn-init-validate)

## Overview

A proof of concept using Rspec to validate AWS::CloudFormation::Init configurations.

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
