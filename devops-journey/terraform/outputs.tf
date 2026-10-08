# =====================================================================
# outputs.tf — القيم اللي عايز تشوفها بعد apply (أو تستخدمها في أدوات تانية)
# =====================================================================
output "website_url" {
  description = "افتحه في المتصفح"
  value       = "http://${aws_eip.web.public_ip}"
}

output "ecr_repository_url" {
  description = "ده اللي هتعمله docker push"
  value       = aws_ecr_repository.app.repository_url
}

output "ec2_public_ip" {
  description = "حطه في ansible/inventory.ini"
  value       = aws_eip.web.public_ip
}

output "secret_name" {
  value = aws_secretsmanager_secret.app.name
}
