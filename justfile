#!just

# setup
set dotenv-load
set positional-arguments

d4r_run:= "docker run -it --rm "
mount_aws:= "-v " + env_var('DOTAWS_PATH') + ":/root/.aws "
workdir:= "/root/src "
mount_src:= "-v " + `pwd` + ":" + workdir
changedir:= "-w " + workdir

awscli:= d4r_run + mount_aws + mount_src + changedir + "amazon/aws-cli --profile " + env_var('AWS_PROFILE')


default:
	@just --list --unsorted

cf-changeset filename type="UPDATE":
		{{awscli}} cloudformation create-change-set \
				--stack-name $STACKNAME-{{filename}} \
				--change-set-name {{type}}-$STACKNAME \
				--change-set-type {{type}} \
				--capabilities CAPABILITY_NAMED_IAM \
				--template-body file://cloud/{{filename}}.yml

