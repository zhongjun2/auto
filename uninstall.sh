

#!/usr/bin/env bash

# ``install cloudfoundry by bosh``

checkCmdSuccess(){
  $@
  if [ $? -eq 0 ]; then
    echo "Running $@ is success!"
  else
    echo "Running $@ is failed!"
  exit
fi
}

echo "*********************************************************************"
echo "Begin $0"
echo "*********************************************************************"

. ./keystonerc

origin_dir=.validator_cpi

cd $origin_dir/init-bosh
echo yes | ./terraform destroy
