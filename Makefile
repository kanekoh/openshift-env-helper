export DEBUG = false
WORKER_NUM = 2
INSTALL_ODF = false

ODF_NUM = 3

YUM_MODULES = ansible git
MAKE_HOME = $(shell pwd)
WORK_DIR = $(MAKE_HOME)/ocp4-workingdir
HOME_DIR = $$HOME

SSH_PUB_KEY = $(shell cat $(HOME_DIR)/.ssh/id_rsa.pub)

HELPER_NODE = ocp4-aHelper
HELPER_IP = 192.168.7.77
HELPER_ISO = 8.0.1905/isos/x86_64/CentOS-8-x86_64-1905-dvd1.iso
SSH_PUB_BASTION = $(HOME_DIR)/.ssh/id_rsa.pub

LIBVIRT_ISO_DIR = /var/lib/libvirt/ISO/


VIRSH_NETNAME = openshift4

all: 	prepare network helper ocp
helper: helper_deploy helper_wait helper_start
ocp: ocp_prepare ocp_install
ocp_prepare: masters bootstrap workers setup_helper generate_vars copy_vars run_playbook copy_pullsecret copy_install_script
ocp_install: run_install start_vms wait_bootstrap_complete stop_bootstrap approve_csrs wait_install_complete

prepare:
	#TODO Add check repo/rpms later
	# yum -y install ansible git
	cp ocp4-helpernode/docs/examples/vars.yaml $(WORK_DIR)/
	

network:
	# Define Network 
	pwd
	wget -P $(WORK_DIR) https://raw.githubusercontent.com/RedHatOfficial/ocp4-helpernode/master/docs/examples/virt-net.xml
	virsh net-define --file $(WORK_DIR)/virt-net.xml
	virsh net-autostart $(VIRSH_NETNAME)
	virsh net-start $(VIRSH_NETNAME)


helper_deploy:
	##TODO Why cannot sshkey be inserted the vm?
	# Deploy Helper node
	wget https://raw.githubusercontent.com/RedHatOfficial/ocp4-helpernode/master/docs/examples/helper-ks8.cfg -O $(WORK_DIR)/helper-ks.cfg

	if [ ! -f $(LIBVIRT_ISO_DIR)/$(shell basename $(HELPER_ISO) ) ]; then \
	  wget -P $(LIBVIRT_ISO_DIR) http://ftp.iij.ad.jp/pub/linux/centos-vault/centos/$(HELPER_ISO); \
	fi

	# Modify dnsnameserver
	sed -i -e "s/8.8.8.8/192.168.7.1/g" $(WORK_DIR)/helper-ks.cfg
	# Add ssh key to helper-ks.cfg
	#ansible localhost -m lineinfile -a "path=$(WORK_DIR)/helper-ks.cfg insertafter='rootpw --plaintext changeme' line='sshkey --username=root $(SSH_PUB_KEY)'"

	virt-install --name=$(HELPER_NODE) --vcpus=2 --ram=4096 \
	--disk path=/var/lib/libvirt/images/$(HELPER_NODE).qcow2,bus=virtio,size=50 \
	--os-variant centos8 --network network=openshift4,model=virtio \
	--boot hd,menu=on --location /var/lib/libvirt/ISO/CentOS-8-x86_64-1905-dvd1.iso \
	--initrd-inject $(WORK_DIR)/helper-ks.cfg --extra-args "inst.ks=file:/helper-ks.cfg" --noautoconsole
	@sleep 5

helper_wait:
	## Cant exit loop with some reasons.. 
	# Wait until helper node is stopped.
	./scripts/check_helper_running.sh $(HELPER_NODE)

helper_start:
	##TODO it is not good
	virsh start $(HELPER_NODE)
	# Wait for succeeding connect with ssh
	./scripts/wait_until_helper_running.sh $(HELPER_IP) $(SSH_PUB_BASTION)

ocp_prepare: masters bootstrap workers setup_helper generate_vars copy_vars run_playbook copy_pullsecret copy_install_script

masters:
	./scripts/create_masters.sh

bootstrap:
	./scripts/create_bootstrap.sh

workers:
	./scripts/create_workers.sh $(WORKER_NUM)

setup_helper:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) yum -y install ansible git

	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) git clone https://github.com/RedHatOfficial/ocp4-helpernode

generate_vars:
	./scripts/generate_vars.sh $(WORK_DIR)

copy_vars:
	scp -o "StrictHostKeyChecking=no" $(WORK_DIR)/vars.yaml root@$(HELPER_IP):~/ocp4-helpernode/

run_playbook:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "cd ocp4-helpernode; ansible-playbook -e @vars.yaml tasks/main.yml"

copy_pullsecret:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) mkdir -p ~/.openshift
	scp  -o "StrictHostKeyChecking=no" ./pull-secret root@$(HELPER_IP):~/.openshift/pull-secret

copy_install_script:
	scp  -o "StrictHostKeyChecking=no" ./scripts/install.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x install.sh

run_install:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) ./install.sh

start_vms:
	./scripts/start_vms.sh $(WORKER_NUM)


wait_bootstrap_complete:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) openshift-install wait-for bootstrap-complete --log-level debug --dir ./ocp4

stop_bootstrap:
	virsh shutdown ocp4-bootstrap

approve_csrs:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "echo export KUBECONFIG=/root/ocp4/auth/kubeconfig >> .bashrc"
	scp  -o "StrictHostKeyChecking=no" ./scripts/approve_csrs.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x approve_csrs.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "./approve_csrs.sh $(WORKER_NUM)"

wait_install_complete:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) openshift-install wait-for install-complete --dir ./ocp4

clean:
	rm -f $(WORK_DIR)/*
	sed -i '/^192.168.7.77/d' $(HOME_DIR)/.ssh/known_hosts
	sed -i '/^192.168.7.77/d' /root/.ssh/known_hosts

helper_clean: 
	-virsh destroy $(HELPER_NODE)
	-virsh undefine $(HELPER_NODE) --remove-all-storage

worker_clean:
	-./scripts/destroy_workers.sh $(WORKER_NUM)

master_clean:
	-./scripts/destroy_masters.sh

bootstrap_clean:
	-./scripts/destroy_bootstrap.sh

network_clean:
	-virsh net-destroy $(VIRSH_NETNAME)
	-virsh net-undefine $(VIRSH_NETNAME)

flclean: clean worker_clean master_clean bootstrap_clean helper_clean network_clean

