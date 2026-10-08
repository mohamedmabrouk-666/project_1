# =====================================================================
# main.tf — البنية التحتية كاملة ككود
# المشكلة: الـ Console يدوي = مش قابل للتكرار ومحدش يعرف مين غيّر إيه
# الحل: كل مورد مكتوب هنا، وأي تغيير بيعدّي على plan + review
# =====================================================================

# ---------------------------------------------------------------------
# 1) الشبكة: VPC + Subnet عامة + Internet Gateway + Route Table
# ---------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

# البوابة اللي بتوصّل الـ VPC بالإنترنت
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = "${var.aws_region}a"
  # false = السيرفر مايخدش IP عام تلقائي، هنديله Elastic IP صراحةً تحت (أنضف وأأمن)
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.project_name}-public" }
}

# جدول الـ routing: أي traffic لبره (0.0.0.0/0) يروح للـ Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------
# 2) Security Group = firewall على مستوى السيرفر (كل حاجة ممنوعة إلا المسموح)
# ---------------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "HTTP للجميع - SSH من IP واحد بس"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH من IP بتاعي بس"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]      # /32 = عنوان واحد بالظبط
  }

  egress {
    description = "السيرفر يخرج لأي مكان (يسحب updates و images)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-web-sg" }
}

# ---------------------------------------------------------------------
# 3) IAM: السيرفر ياخد "هوية" بصلاحيات محدودة (بدل access keys جواه)
# ---------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]   # EC2 بس هو اللي يقدر "يلبس" الـ role ده
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "${var.project_name}-web-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# CloudWatch agent: السيرفر يبعت metrics و logs
resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# SSM: دخول للسيرفر من غير SSH ولا بورت 22 (أأمن)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web" {
  name = "${var.project_name}-web-profile"
  role = aws_iam_role.web.name
}

# ---------------------------------------------------------------------
# 4) EC2: السيرفر
# ---------------------------------------------------------------------
# بنجيب أحدث AMI رسمية من Amazon بدل ما نكتب ID ثابت (بيتغير حسب الـ region)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.web.name
  monitoring             = true                # detailed monitoring (كل دقيقة)

  # IMDSv2 إجباري: يحمي من هجمات سرقة credentials عن طريق SSRF
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted   = true                          # تشفير الهارد
    volume_size = 8
  }

  # user_data بيشتغل مرة واحدة أول تشغيل (provisioning أولي بس —
  # التهيئة المستمرة بـ Ansible)
  user_data = <<-EOT
    #!/bin/bash
    dnf install -y docker
    systemctl enable --now docker
    docker run -d --name web --restart unless-stopped -p 80:8080 ${var.app_image}
  EOT

  tags = { Name = "${var.project_name}-web" }
}

# Elastic IP: عنوان ثابت مايتغيّرش لو السيرفر اتعمله restart
resource "aws_eip" "web" {
  instance   = aws_instance.web.id
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

# ---------------------------------------------------------------------
# 5) ECR: مخزن الـ images الخاص بيك على AWS (بديل Docker Hub)
# ---------------------------------------------------------------------
resource "aws_ecr_repository" "app" {
  name                 = var.project_name
  image_tag_mutability = "IMMUTABLE"           # tag مايتكتبش فوقه (rollback موثوق)
  image_scanning_configuration { scan_on_push = true }   # فحص ثغرات تلقائي عند الرفع
}

# سياسة دورة حياة: احتفظ بآخر 10 images بس (توفير فلوس)
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10"
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }
      action       = { type = "expire" }
    }]
  })
}

# ---------------------------------------------------------------------
# 6) Secrets Manager: مكان آمن للأسرار (مش في الكود ولا في env)
# ---------------------------------------------------------------------
resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project_name}/${var.environment}/app"
  recovery_window_in_days = 7
}
# القيمة نفسها نحطها بره Terraform (عشان مايدخلش في الـ state):
#   aws secretsmanager put-secret-value --secret-id <name> --secret-string '{"api_key":"..."}'

# ---------------------------------------------------------------------
# 7) المراقبة والتنبيه: SNS (إيميل) + CloudWatch Alarms + Budget
# ---------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

# هيوصلك إيميل تأكيد لازم تضغط Confirm
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# تنبيه: CPU عدّى 80% لـ 10 دقايق
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { InstanceId = aws_instance.web.id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# تنبيه: فشل health check للسيرفر (السيرفر نفسه واقع)
resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "${var.project_name}-status-check-failed"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  dimensions          = { InstanceId = aws_instance.web.id }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# حماية الفاتورة: تنبيه لما التكلفة تقترب من الميزانية
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project_name}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80            # عند 80% من الميزانية
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}
