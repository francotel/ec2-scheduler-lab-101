.EXPORT_ALL_VARIABLES:

AWS_PROFILE ?= scc-aws

.PHONY: init fmt validate plan apply destroy output

init:
	terraform init

fmt:
	terraform fmt -recursive

validate: fmt
	terraform validate

plan: validate
	terraform plan -out=plan.out

apply:
	terraform apply plan.out

output:
	terraform output

destroy:
	terraform destroy
