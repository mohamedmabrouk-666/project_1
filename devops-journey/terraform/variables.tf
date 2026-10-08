# =====================================================================
# variables.tf — المدخلات: نفس الكود لبيئات مختلفة بتغيير القيم بس
# =====================================================================
variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type    = string
  default = "devops-journey"
}

variable "environment" {
  description = "dev | staging | prod"
  type        = string
  default     = "dev"
  validation {                                 # فحص المدخل قبل التنفيذ
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment لازم يكون dev أو staging أو prod."
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "my_ip" {
  description = "الـ IP بتاعك لـ SSH (من: curl ifconfig.me). بدون /32"
  type        = string
}

variable "app_image" {
  description = "الـ image اللي هتشتغل على السيرفر (يفضّل tag محدد مش latest)"
  type        = string
  default     = "mohamedmabrouk/devops-journey:1"
}

variable "alert_email" {
  description = "الإيميل اللي هيستقبل تنبيهات CloudWatch"
  type        = string
}

variable "monthly_budget_usd" {
  type    = number
  default = 10
}
