#!/usr/bin/env bash

if [ ! -e 'venv' ] ; then
  virtualenv venv
  pip install -r requirements.txt
fi

if ! which -s cfn-flip ; then
  . venv/bin/activate
fi

echo "This is a demo of Rspec validation of sample AWS CloudFormation templates."
echo "See spec/validate_spec.rb for more info."
sleep 2

set -x

# JSON templates.
for i in \
  https://gist.githubusercontent.com/miyamoto-daisuke/6087331/raw/807352ff593327089689a1e6f71fb469d0f8ae11/cfn-init.template \
  https://raw.githubusercontent.com/stackmate/stackmate/master/templates/AWS/LAMP_Single_Instance.template
do
  curl -s "$i" -o cloudformation.json
  cfn-flip -y cloudformation.json > cloudformation.yml
  bundle exec rspec spec/validate_spec.rb || exit $?
done

# YAML templates.
for i in \
  https://raw.githubusercontent.com/awslabs/aws-cloudformation-templates/master/aws/solutions/AmazonCloudWatchAgent/inline/windows.template \
  https://raw.githubusercontent.com/awslabs/aws-cloudformation-templates/master/aws/solutions/AmazonCloudWatchAgent/inline/centos.template
do
  curl -s "$i" -o cloudformation.yml
  bundle exec rspec spec/validate_spec.rb || exit $?
done

echo "All tests passed."
