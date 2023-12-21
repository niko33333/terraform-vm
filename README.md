# terraform-vm
This repository contains the infrastructure for a private VM created in a dedicated network environment behind a public application load balancer.

The VM exposes a web server on port 80 HTTP, which can only be accessed from the application load balancer. It runs a Docker image containing a three-tier web application using Apache, NodeJS, and MySQL.

For security purposes, the machine does not expose port 22 but only the 80 from the ALB. However, you can access the machine using SSM through the console or from the command line by using AWS CLI.

## infrastructure provisionig

To provision the infrastructure, you need to create an S3 bucket and a DynamoDB table, which will contain the Terraform state:

**bucket name**: *vmex-prod-terraform-state*

**dynamo table name**: *terraform-state-locking*

Setup the AWS CLI. You can do this manually by modifying **.aws/config**, or you can use a tool like [leapp](https://www.leapp.cloud/) to manage the AWS credentials for you.

After this, you can launch the following commands:
```
terraform init
terraform plan
terraform apply
```

After creating the infrastructure, you have to build and push the Docker image, which is used by the VM:
```
docker build . -t <ecr_repo_url>
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin <ecr_repo_url>
docker push <ecr_repo_url>
```

Finally, you can launch the EC2 from the console by adjusting the desired count of the autoscaling group that was created.
