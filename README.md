# Terraforming AWS [![build-status](https://infra.ci.cf-app.com/api/v1/teams/main/pipelines/terraforming-aws/jobs/deploy-pas/badge)](https://infra.ci.cf-app.com/teams/main/pipelines/terraforming-aws)

## What is this?

Set of terraform modules for deploying Ops Manager, PAS and PKS infrastructure requirements like:

- Friendly DNS entries in Route53
- A RDS instance (optional)
- A Virtual Private Network (VPC), subnets, Security Groups
- Necessary s3 buckets
- A NAT Box
- Network Load Balancers
- An AWS Role with proper permissions
- Tagged resources

Note: This is not an exhaustive list of resources created, this will vary depending of your arguments and what you're deploying.

## Prerequisites

### AWS Permissions
- AmazonEC2FullAccess
- AmazonRDSFullAccess
- AmazonRoute53FullAccess
- AmazonS3FullAccess
- AmazonVPCFullAccess
- IAMFullAccess
- AWSKeyManagementServicePowerUser

Note: You will also need to create a custom policy as the following and add to
      the same user:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "KMSKeyDeletionAndUpdate",
            "Effect": "Allow",
            "Action": [
                "kms:UpdateKeyDescription",
                "kms:ScheduleKeyDeletion"
            ],
            "Resource": "*"
        }
    ]
}
```

### Create an AWS Role

Create an AWS Role with the above permissions assigned.

### Deploy a Jumpbox

Create an EC2 Jumpbox and associate the above created IAM Role. For this purpose a Amazon Linux 2 AMI (HVM), SSD Volume Type - ami-030dbca661d402413 (64-bit x86) / ami-08c5dd5d585629c8f (64-bit Arm) was choosen.

### Terraform CLI

[SSH into your EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html)

```bash
sudo yum install unzip
sudo wget https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip
unzip terraform_0.11.13_linux_amd64.zip
sudo mv terraform /usr/bin/
terraform --version
```

## Deploying Ops Manager

First, you'll need to clone this repo. Then, depending on if you're deploying PAS or PKS you need to perform the following steps:

1. `cd` into [terraforming-pks/](terraforming-pks/)
1. Create [`terraform.tfvars`](/README.md#var-file) file
1. Run terraform apply:
  ```bash
  terraform init
  terraform plan
  terraform apply
  ```

### Var File

Copy the stub content below into a file called `terraform.tfvars` and put it in the root of this project.
These vars will be used when you run `terraform apply`.
You should fill in the stub values with the correct content.

```hcl
env_name           = "some-environment-name"
region             = "us-west-1"
availability_zones = ["us-west-1a", "us-west-1c"]
ops_manager_ami    = "ami-4f291f2f"
rds_instance_count = 1
dns_suffix         = "example.com"

ssl_cert = <<EOF
-----BEGIN CERTIFICATE-----
some cert
-----END CERTIFICATE-----
EOF

ssl_private_key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
some cert private key
-----END RSA PRIVATE KEY-----
EOF

tags = {
    Team = "Dev"
    Project = "WebApp3"
}
```

### Variables

- env_name: **(required)** An arbitrary unique name for namespacing resources
- region: **(required)** Region you want to deploy your resources to
- availability_zones: **(required)** List of AZs you want to deploy to
- dns_suffix: **(required)** Domain to add environment subdomain to
- ssl_cert: **(optional)** SSL certificate for HTTP load balancer configuration. Required unless `ssl_ca_cert` is specified.
- ssl_private_key: **(optional)** Private key for above SSL certificate. Required unless `ssl_ca_cert` is specified.
- ssl_ca_cert: **(optional)** SSL CA certificate used to generate self-signed HTTP load balancer certificate. Required unless `ssl_cert` is specified.
- ssl_ca_private_key: **(optional)** Private key for above SSL CA certificate. Required unless `ssl_cert` is specified.
- tags: **(optional)** A map of AWS tags that are applied to the created resources. By default, the following tags are set: Application = Cloud Foundry, Environment = $env_name

### Ops Manager (optional)
- ops_manager_ami: **(optional)**  Ops Manager AMI, get the right AMI according to your region from the AWS guide downloaded from [Pivotal Network](https://network.pivotal.io/products/ops-manager) (if not provided you get no Ops Manager)
- optional_ops_manager: **(default: false)** Set to true if you want an additional Ops Manager (useful for testing upgrades)
- optional_ops_manager_ami: **(optional)**  Additional Ops Manager AMI, get the right AMI according to your region from the AWS guide downloaded from [Pivotal Network](https://network.pivotal.io/products/ops-manager)
- ops_manager_instance_type: **(default: m4.large)** Ops Manager instance type
- ops_manager_private: **(default: false)** Set to true if you want Ops Manager deployed in a private subnet instead of a public subnet

### RDS (optional)
- rds_instance_count: **(default: 0)** Whether or not you would like an RDS for your deployment
- rds_instance_class: **(default: db.m4.large)** Size of the RDS to deploy
- rds_db_username: **(default: admin)** Username for RDS authentication

## Notes

You can choose whether you would like an RDS or not. By default we have
`rds_instance_count` set to `0` but setting it to `1` will deploy an RDS instance.

Note: RDS instances take a long time to deploy, keep that in mind. They're not required.

## Tearing down environment

**Note:** This will only destroy resources deployed by Terraform. You will need to clean up anything deployed on top of that infrastructure yourself (e.g. by running `om delete-installation`)

```bash
terraform destroy
```

## Looking to setup a different IaaS

We have have other terraform templates:

- [Azure](https://github.com/pivotal-cf/terraforming-azure)
- [Google Cloud Platform](https://github.com/pivotal-cf/terraforming-gcp)
- [vSphere](https://github.com/pivotal-cf/terraforming-vsphere)
- [OpenStack](https://github.com/pivotal-cf/terraforming-openstack)

## What do the terraform scripts create from the above repository?
As part of deploying OpsMan for PKS, the above repo requires to create an IAM User with high permissions. This user is only used by terraform to access AWS, so this is not necessary if you run these terraform from a Jumpbox in AWS. If you do use a AWS IAM user, then make sure to rotate access key and secret key often as a good way to secure your AWS account.
Moreover, these terraform scripts create an additional AWS IAM user with high permissions. This user is only created for the purpose of allowing AWS Management Console Config option of Using AWS Keys. Recommendation is to follow [Pivotal Network](https://docs.pivotal.io/pivotalcf/2-5/om/aws/config-terraform.html) suggesting to Use AWS Instance Profile instead of the AWS IAM user above mentioned.
This user is not used by any of the BOSH and PKS operations.

## What was modified from the above repository
In `terraform.tfvars`, remove:
```bash
access_key         = "access-key-id"
secret_key         = "secret-access-key"
```
In `main.tf`, remove:
```bash
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}
```
In `outputs.tf`, remove:
```bash
output "ops_manager_iam_user_name" {
  value = "${module.ops_manager.ops_manager_iam_user_name}"
}

output "ops_manager_iam_user_access_key" {
  value = "${module.ops_manager.ops_manager_iam_user_access_key}"
}

output "ops_manager_iam_user_secret_key" {
  value     = "${module.ops_manager.ops_manager_iam_user_secret_key}"
  sensitive = true
}
```
In `variables.tf`, remove:
```bash
variable "access_key" {}

variable "secret_key" {}
```
In `iam.tf` under `/modules/opsman` folder, remove:
```bash
resource "aws_iam_user_policy_attachment" "ops_manager" {
  user       = "${aws_iam_user.ops_manager.name}"
  policy_arn = "${aws_iam_policy.ops_manager_user.arn}"
}

resource "aws_iam_user" "ops_manager" {
  name = "${var.env_name}_om_user"
}

resource "aws_iam_access_key" "ops_manager" {
  user = "${aws_iam_user.ops_manager.name}"
}
```
In `outputs.tf` under `/modules/opsman` folder, remove:
```bash
output "ops_manager_iam_user_name" {
  value = "${aws_iam_user.ops_manager.name}"
}

output "ops_manager_iam_user_access_key" {
  value = "${aws_iam_access_key.ops_manager.id}"
}

output "ops_manager_iam_user_secret_key" {
  value     = "${aws_iam_access_key.ops_manager.secret}"
  sensitive = true
}
```
