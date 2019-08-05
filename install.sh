
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

echo "************************** prepare resources *******************************"
echo "configure keystonera filvore"
. ./keystonerc

export OS_PROJECT_DOMAIN_NAME=$OS_DOMAIN_NAME
export OS_USER_DOMAIN_NAME=$OS_DOMAIN_NAME


# 在固定的目录下执行
origin_dir=.validator_cpi

if [ ! -d $origin_dir ]; then
  mkdir $origin_dir
fi

cd $origin_dir


###########################################################################
cp -r ../init-bosh/  ./
cd init-bosh

sed -i -e "s#\(auth_url = \"\).*#\1${OS_AUTH_URL}\"#" \
-e "s/\(domain_name = \"\).*/\1${OS_DOMAIN_NAME}\"/" \
-e "s/\(user_name = \"\).*/\1${OS_USERNAME}\"/" \
-e "s/\(password = \"\).*/\1${OS_PASSWORD}\"/" \
-e "s/\(tenant_name = \"\).*/\1${OS_TENANT_NAME}\"/" \
-e "s/\(region_name = \"\).*/\1${OS_REGION_NAME}\"/" \
-e "s/\(availability_zone = \"\).*/\1${OS_AVAILABILITY_ZONE}\"/" resources.tf


## 生成bosh.pem秘钥，用于登录后续cf相关的vm机器
if [ -f "validator.pem" ]
then
  echo "The validator.pem already exsit."
else
  echo "Started to generate ssh keypair."
  checkCmdSuccess ./generate_ssh_keypair.sh
fi


downloadTerraform(){
  ./terraform -v
  if [ $? -eq 0 ]
  then
    echo "The terraform command already exsit."
  else
    echo "Started to download the terraform package"
    checkCmdSuccess wget -O terraform_0.12.6_linux_amd64 https://releases.hashicorp.com/terraform/0.12.6/terraform_0.12.6_linux_amd64.zip
    unzip -v > /dev/null
    if [ ! $? -eq 0 ];then
      sudo apt-get update
      echo yes | apt install zip
    fi
      echo yes | unzip terraform_0.12.6_linux_amd64
      echo "SUCCESS: Install terraform"
  fi
}

downloadTerraform
echo "Waiting for the resources to be created in cloud......."
checkCmdSuccess  ./terraform init
checkCmdSuccess  ./terraform plan

bosh_init_dir_tmp_file=bosh_init_dir_tmp.file
echo yes | ./terraform apply > $bosh_init_dir_tmp_file

default_key_name=$(grep -o 'default_key_name = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
floating_ip=$(grep -o 'external_ip = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
static_ip=$(grep -o 'internal_ip = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
network_id=$(grep -o 'network_id = [^,]*' $bosh_init_dir_tmp_file  | grep -o '[A-Za-z0-9-]\+\-[a-zA-Z0-9-]\+')

echo "*****************************Get resources value from output ****************************************"
echo default_key_name=$default_key_name
echo floating_ip=$floating_ip
echo static_ip=$static_ip
echo network_id=$network_id
echo "*****************************Finished to create resource for bosh director in cloud***************"

cd ../
if [ ! -d "cf-openstack-validator" ]; then
  checkCmdSuccess git clone https://github.com/cloudfoundry-incubator/cf-openstack-validator
fi

cp init-bosh/validator.pem cf-openstack-validator/
cp cf-openstack-validator/validator.template.yml cf-openstack-validator/validator.yml

instance_type="4u8g160g"

sed -i -e "s/\(instance_type: \).*/\1${instance_type}/" \
-e "s/\(default_key_name: \).*/\1"validator"/" \
-e "s/\(private_key_path: \).*/\1"validator.pem"/" \
-e "s/\(default_security_groups: \).*/\1\["bosh"\]/" \
-e "s/\(network_id: \).*/\1${network_id}/" \
-e "s/\(floating_ip: \).*/\1${floating_ip}/" \
-e "s/\(static_ip: \).*/\1${static_ip}/" \
-e "s/\(domain: \).*/\1${OS_DOMAIN_NAME}/" \
-e "s/\(username: \).*/\1${OS_USERNAME}/" \
-e "s/\(password: \).*/\1${OS_PASSWORD}/" \
-e "s/\(project: \).*/\1${OS_TENANT_NAME}/" cf-openstack-validator/validator.yml


sed -i -e "s#\(auth_url: \).*#\1${OS_AUTH_URL}#" cf-openstack-validator/validator.yml

if [ ! -e "bosh-stemcell-1.0-huaweicloud-xen-ubuntu-trusty-go_agent.tgz" ]; then
  wget https://obs-bosh.obs.otc.t-systems.com/bosh-stemcell-1.0-huaweicloud-xen-ubuntu-trusty-go_agent.tgz
fi

checkCmdSuccess gem install bundler
checkCmdSuccess bundle install

./validate --stemcell bosh-stemcell-1.0-huaweicloud-xen-ubuntu-trusty-go_agent.tgz --config validator.yml


