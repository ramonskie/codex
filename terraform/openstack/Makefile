SHELL := $(SHELL) -e
VARS_FILE  := openstack.tfvars
PLAN_FILE  := openstack.tfplan
STATE_FILE := terraform.tfstate
OUT_FILE   := properties.yml

all: manifest deploy

manifest:
	terraform get -update
	terraform plan -var-file ${VARS_FILE} -out ${PLAN_FILE}

deploy:
	terraform apply -var-file ${VARS_FILE} -parallelism=1
	terraform output | ./yamler meta tf > ${OUT_FILE}

destroy:
	terraform plan -destroy -var-file ${VARS_FILE} -out ${PLAN_FILE}
	terraform apply ${PLAN_FILE}

clean:
	rm -f ${PLAN_FILE}
	rm -f ${STATE_FILE}
	rm -f ${STATE_FILE}.backup

.PHONY: all manifest deploy destroy clean
