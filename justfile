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
ecr_endpoint:= env_var("AWS_ACCOUNT") + ".dkr.ecr.eu-west-1.amazonaws.com"


default:
	@just --list --unsorted

cf-changeset filename type="UPDATE":
	{{awscli}} cloudformation create-change-set \
		--stack-name $STACKNAME-{{filename}} \
		--change-set-name {{type}}-$STACKNAME \
		--change-set-type {{type}} \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-body file://cloud/{{filename}}.yml

repo-login region="eu-west-1":
	{{awscli}} ecr get-login-password --region {{region}} | docker login --username AWS --password-stdin {{ecr_endpoint}}

repo-build:
	docker build -f cloud/cicd/Dockerfile.pipeline --force-rm -t $STACKNAME-pipeline .
	docker tag $STACKNAME-pipeline:latest {{ecr_endpoint}}/$STACKNAME-cicd-pipeline:latest

repo-push:
	docker push {{ecr_endpoint}}/$STACKNAME-cicd-pipeline:latest

repo-clean:
	docker rmi {{ecr_endpoint}}/$STACKNAME-cicd-pipeline:latest

repo-deploy: repo-build repo-push repo-clean




