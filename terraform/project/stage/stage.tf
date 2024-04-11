provider "aws" {
  region = "eu-west-3"
}

module "stage_aws_vpc" {
  source = "../../modules/aws_vpc"
  env    = "stage"
}

module "stage_aws_ec2" {
  source = "../../modules/aws_ec2"
  vpc_id = module.stage_aws_vpc.vpc_id
  public_subnet_az1_id = module.stage_aws_vpc.public_subnet_az1_id
  public_subnet_az2_id = module.stage_aws_vpc.public_subnet_az2_id
  public_subnet_az3_id = module.stage_aws_vpc.public_subnet_az3_id
  private_app_subnet_az1_id = module.stage_aws_vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id = module.stage_aws_vpc.private_app_subnet_az2_id
  private_app_subnet_az3_id = module.stage_aws_vpc.private_app_subnet_az3_id
  private_database_subnet_az1_id = module.stage_aws_vpc.private_database_subnet_az1_id
  private_database_subnet_az2_id = module.stage_aws_vpc.private_database_subnet_az2_id
  private_database_subnet_az3_id = module.stage_aws_vpc.private_database_subnet_az3_id

  depends_on = [module.stage_aws_vpc]
}
