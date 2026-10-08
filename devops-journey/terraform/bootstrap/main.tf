# =====================================================================
# bootstrap: بيتشغّل مرة واحدة بس عشان ينشئ مكان تخزين الـ state
# مشكلة الدجاجة والبيضة: الـ backend لازم يكون موجود قبل ما Terraform يستخدمه،
# فبننشئه بالـ state المحلي الأول (terraform init && terraform apply هنا)
# =====================================================================
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = "eu-central-1" }

variable "state_bucket" {
  description = "اسم الـ bucket لازم يكون unique عالمياً"
  type        = string
}

# الـ bucket اللي هيشيل terraform.tfstate (فيه كل تفاصيل البنية → حساس!)
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket
  lifecycle { prevent_destroy = true }     # حماية من المسح بالغلط
}

# versioning: لو الـ state اتبوّظ نرجع لنسخة قديمة
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

# تشفير
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# ممنوع أي وصول عام للـ bucket
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# جدول DynamoDB للـ locking: يمنع اتنين يعملوا apply في نفس الوقت (يبوّظوا الـ state)
resource "aws_dynamodb_table" "locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"         # بتدفع على الاستخدام بس
  hash_key     = "LockID"                  # الاسم ده إجباري لـ Terraform
  attribute {
    name = "LockID"
    type = "S"
  }
}
