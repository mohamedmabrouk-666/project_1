# =====================================================================
# backend.tf — إعدادات Terraform والـ provider والـ remote state
# =====================================================================
terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"      # يقبل 5.x بس (مايترقّاش لـ 6 فجأة ويكسر حاجة)
    }
  }

  # Remote state: الـ state على S3 مش على جهازك
  #   ← الفريق كله يشوف نفس الحقيقة | ← DynamoDB lock | ← مشفّر
  # (الـ bucket والجدول بيتعملوا من مجلد bootstrap/)
  backend "s3" {
    bucket         = "CHANGE-ME-unique-bucket-name"
    key            = "devops-journey/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  # default_tags: كل مورد يتعلّم تلقائي (مفيد جداً لتتبع التكلفة والملكية)
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Env       = var.environment
    }
  }
}
