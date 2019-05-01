#!/usr/bin/env bash

if [ ! -e 'venv' ] ; then
  virtualenv venv
  . venv/bin/activate
  pip install -r requirements.txt
fi

if ! which cfn-flip > /dev/null ; then
  . venv/bin/activate
fi

echo "This is a demo of Rspec validation of sample AWS CloudFormation templates."
echo "See spec/validate_spec.rb for more info."
sleep 2

set -x

# JSON templates.
for i in \
  https://gist.githubusercontent.com/miyamoto-daisuke/6087331/raw/807352ff593327089689a1e6f71fb469d0f8ae11/cfn-init.template \
  https://raw.githubusercontent.com/stackmate/stackmate/master/templates/AWS/LAMP_Single_Instance.template \
  https://raw.githubusercontent.com/awslabs/aws-cloudformation-templates/master/aws/solutions/HelperNonAmaznAmi/RHEL7_cfn-hup.template \
  https://raw.githubusercontent.com/awslabs/aws-cloudformation-templates/master/aws/services/CloudFormation/HostnameChangeRHEL-Metadata.template \
  https://s3.amazonaws.com/cloudformation-templates-us-east-1/Drupal_Single_Instance.template \
  https://raw.githubusercontent.com/aws-samples/aws-cfn-custom-resource-examples/master/examples/dns-mapping/example.template \
  https://raw.githubusercontent.com/rowlinsonmike/cf_win_template/master/cf_win_template.json \
  https://s3.amazonaws.com/cloudformation-templates-us-east-1/Windows_Single_Server_SharePoint_Foundation.template
do
  curl -s "$i" -o cloudformation.json
  cfn-flip -y cloudformation.json > cloudformation.yml
  bundle exec rspec spec/validate_spec.rb || exit $?
done

# YAML templates.
for i in \
  https://raw.githubusercontent.com/awslabs/aws-cloudformation-templates/master/aws/solutions/AmazonCloudWatchAgent/inline/windows.template \
  https://raw.githubusercontent.com/awslabs/aws-cloudformation-templates/master/aws/solutions/AmazonCloudWatchAgent/inline/centos.template \
  https://raw.githubusercontent.com/awslabs/aws-cloudformation-templates/master/aws/services/AutoScaling/AutoScalingRollingUpdates.yaml \
  https://raw.githubusercontent.com/awslabs/aws-cloudformation-templates/master/aws/solutions/AmazonCloudWatchAgent/inline/ubuntu.template \
  https://raw.githubusercontent.com/awslabs/aws-cloudformation-templates/master/aws/services/ElasticLoadBalancing/ELB_Access_Logs_And_Connection_Draining.yaml
do
  curl -s "$i" -o cloudformation.yml
  bundle exec rspec spec/validate_spec.rb || exit $?
done

# Unsupported: If condition in Boolean not being handled:
#   https://raw.githubusercontent.com/widdix/aws-cf-templates/master/ec2/ec2-auto-recovery.yaml

set +x

echo "All tests passed."
