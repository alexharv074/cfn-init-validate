#!/usr/bin/env bash

if [ ! -e 'venv' ] ; then
  virtualenv venv
  pip install -r requirements.txt
fi

if ! which -s cfn-flip ; then
  . venv/bin/activate
fi

for i in \
  https://gist.githubusercontent.com/miyamoto-daisuke/6087331/raw/807352ff593327089689a1e6f71fb469d0f8ae11/cfn-init.template
do
  curl -s "$i" -o cloudformation.json
  cfn-flip -y cloudformation.json > cloudformation.yml
  bundle exec rspec spec/validate_spec.rb
done
