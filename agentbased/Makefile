export DEBUG = false
WORKER_NUM = 2
export INSTALL_ODF = false
OCP_VERSION=''

ODF_NUM = 3

YUM_MODULES = ansible git
MAKE_HOME = $(shell pwd)
export WORK_DIR = $(MAKE_HOME)/resources
HOME_DIR = $$HOME

export NETWORK_NAME = ocp4-public
VIRSH_NETNAME = $(NETWORK_NAME)
export NETWORK_CIDR = 192.168.7
export PRIVATE_NETWORK_NAME = ocp4-private

#PRIVATE_NETWORK_CIDR = 192.168.4

SSH_PUB_KEY = $(shell cat $(HOME_DIR)/.ssh/id_rsa.pub)

HELPER_NODE = ocp4-aHelper
HELPER_IP = $(NETWORK_CIDR).77
HELPER_ISO = rhel-9.3-x86.iso
SSH_PUB_BASTION = $(HOME_DIR)/.ssh/id_rsa.pub

LIBVIRT_ISO_DIR = /var/lib/libvirt/ISO/

RHSM_USERNAME = MYNAME
RHSM_PASSWORD = MYPASSWD

export AGENT_ISO =  agent.x86_64.iso

all: deploy_ocp install_lso install_ocs
deploy_ocp: network helper ocp
helper: helper_deploy helper_wait helper_start
ocp: ocp_prepare ocp_install
ocp_prepare: masters bootstrap workers odfs setup_helper generate_vars copy_vars run_playbook copy_pullsecret copy_install_script
ocp_install: run_install start_vms wait_bootstrap_complete stop_bootstrap approve_csrs wait_install_complete
ocs_install: install_lso install_ocs

network:
	# Define Network 
	virsh net-define --file $(WORK_DIR)/virt-net.xml
	virsh net-autostart $(VIRSH_NETNAME)
	virsh net-start $(VIRSH_NETNAME)

	virsh net-define --file $(WORK_DIR)/private-virt-net.xml
	virsh net-autostart $(PRIVATE_NETWORK_NAME)
	virsh net-start $(PRIVATE_NETWORK_NAME)


helper_deploy:

	#./scripts/add-rhsm-to-ks.sh $(WORK_DIR) $(RHSM_USERNAME) $(RHSM_PASSWORD)

	# Add ssh key to helper-ks.cfg

	virt-install --name=$(HELPER_NODE) --vcpus=2 --ram=4096 \
	--disk path=/var/lib/libvirt/images/$(HELPER_NODE).qcow2,bus=virtio,size=200 \
	--os-variant rhel8.0 --network network=$(NETWORK_NAME),model=virtio \
	--network network=$(PRIVATE_NETWORK_NAME),model=virtio \
	--boot hd,menu=on --location /var/lib/libvirt/ISO/$(HELPER_ISO) \
	--initrd-inject $(WORK_DIR)/helper-ks.cfg --extra-args "inst.ks=file:/helper-ks.cfg" --graphics vnc,listen=0.0.0.0 --noautoconsole
	@sleep 5

helper_wait:
	## Cant exit loop with some reasons.. 
	# Wait until helper node is stopped.
	../scripts/check_helper_running.sh $(HELPER_NODE)

helper_start:
	##TODO it is not good
	virsh start $(HELPER_NODE)
	# Wait for succeeding connect with ssh
	../scripts/wait_until_helper_running.sh $(HELPER_IP) $(SSH_PUB_BASTION)


masters:
	./scripts/create_masters.sh


workers:
	./scripts/create_workers.sh $(WORKER_NUM)


setup_helper:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) dnf -y install ansible-core git wget
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) ansible-galaxy collection install community.crypto
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) ansible-galaxy collection install ansible.posix

	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) git clone https://github.com/RedHatOfficial/ocp4-helpernode
	#ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) git clone -b image_url https://github.com/kanekoh/ocp4-helpernode
	scp -o "StrictHostKeyChecking=no" ./files/bashrc root@$(HELPER_IP):/tmp/bashrc
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "cat /tmp/bashrc >> ~/.bashrc"

	scp -o "StrictHostKeyChecking=no" ./scripts/install_clis.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x install_clis.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "NETWORK_CIDR=$(NETWORK_CIDR)  ./install_clis.sh"

generate_vars:
	./scripts/generate_vars.sh $(WORK_DIR) $(OCP_VERSION)

copy_vars:
	scp -o "StrictHostKeyChecking=no" $(WORK_DIR)/vars.yaml root@$(HELPER_IP):~/ocp4-helpernode/

run_playbook:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "cd ocp4-helpernode; ansible-playbook -e @vars.yaml tasks/main.yml"

copy_pullsecret:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) mkdir -p ~/.openshift
	scp -o "StrictHostKeyChecking=no" ./pull-secret root@$(HELPER_IP):~/.openshift/pull-secret

copy_install_script:
	scp -o "StrictHostKeyChecking=no" ./scripts/install.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x install.sh

run_install:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "oc completion bash > /etc/bash_completion.d/oc_bash_completion"
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "NETWORK_CIDR=$(NETWORK_CIDR)  ./install.sh"

start_vms:
	./scripts/start_vms.sh $(WORKER_NUM)


wait_bootstrap_complete:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) openshift-install wait-for bootstrap-complete --log-level debug --dir ./ocp4

stop_bootstrap:
	virsh shutdown ocp4-bootstrap

approve_csrs:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "echo export KUBECONFIG=/root/ocp4/auth/kubeconfig >> .bashrc"
	scp -o "StrictHostKeyChecking=no" ./scripts/approve_csrs.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x approve_csrs.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "DEBUG=$(DEBUG) INSTALL_ODF=$(INSTALL_ODF) ./approve_csrs.sh $(WORKER_NUM) $(ODF_NUM)"

wait_install_complete:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) openshift-install wait-for install-complete --dir ./ocp4

install_lso:
	scp -o "StrictHostKeyChecking=no" ./scripts/install_lso.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x install_lso.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "DEBUG=$(DEBUG) INSTALL_ODF=$(INSTALL_ODF) ./install_lso.sh"

install_ocs:
	scp -o "StrictHostKeyChecking=no" ./scripts/install_odf.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x install_odf.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "DEBUG=$(DEBUG) INSTALL_ODF=$(INSTALL_ODF) ./install_odf.sh"

setup_registry:
	scp -o "StrictHostKeyChecking=no" ./scripts/create_pvc.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x create_pvc.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "DEBUG=$(DEBUG) INSTALL_ODF=$(INSTALL_ODF) ./create_pvc.sh"

setup_efk:
	scp -o "StrictHostKeyChecking=no" ./scripts/install_clo.sh root@$(HELPER_IP):~/
	scp -o "StrictHostKeyChecking=no" ./scripts/install_efk.sh root@$(HELPER_IP):~/
	scp -o "StrictHostKeyChecking=no" ./scripts/deploy_efk.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x install_clo.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x install_efk.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x deploy_efk.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "DEBUG=$(DEBUG) INSTALL_ODF=$(INSTALL_ODF) ./install_efk.sh"

setup_loki:
	scp -o "StrictHostKeyChecking=no" ./scripts/install_clo.sh root@$(HELPER_IP):~/
	scp -o "StrictHostKeyChecking=no" ./scripts/deploy_loki.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x install_clo.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x deploy_loki.sh

attach_additional_network:
	./scripts/add_additional_network.sh $(PRIVATE_NETWORK_NAME) $(PRIVATE_NETWORK_CIDR)
	./scripts/attach_additional_interface.sh 

detach_additional_network:
	./scripts/detach_additional_interface.sh

restart_vms:
	./scripts/restart_domains.sh

clean:
	rm -f $(WORK_DIR)/*
	ssh-keygen -R $(NETWORK_CIDR).77

helper_clean: 
	-virsh destroy $(HELPER_NODE)
	-virsh undefine $(HELPER_NODE) --remove-all-storage

odf_clean:
	-./scripts/destroy_odf.sh

worker_clean:
	-./scripts/destroy_workers.sh $(WORKER_NUM)

master_clean:
	-./scripts/destroy_masters.sh

bootstrap_clean:
	-./scripts/destroy_bootstrap.sh

network_clean:
	virsh net-destroy $(NETWORK_NAME)
	virsh net-undefine $(NETWORK_NAME)

	virsh net-destroy $(PRIVATE_NETWORK_NAME)
	virsh net-undefine $(PRIVATE_NETWORK_NAME)

additional_network_clean:
	./scripts/remove_additional_network.sh 

flclean:  worker_clean master_clean helper_clean network_clean


