# =====================================================================
# Makefile: اختصارات للأوامر الطويلة (make <target>)
# =====================================================================
IMAGE ?= devops-journey:local

.PHONY: up down logs monitoring-up monitoring-down cicd-up scan tf-init tf-plan tf-apply tf-destroy k8s-local helm-lint

## --- تشغيل محلي ---
up:               ## شغّل التطبيق (http://localhost:8080)
	docker compose up -d --build
down:             ## وقّف كل حاجة
	docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.cicd.yml down
logs:
	docker compose logs -f web

## --- المراقبة (بعد make up) ---
monitoring-up:    ## Prometheus:9090 Grafana:3000 Alertmanager:9093
	docker compose -f docker-compose.monitoring.yml up -d
monitoring-down:
	docker compose -f docker-compose.monitoring.yml down

## --- CI/CD tools ---
cicd-up:          ## Jenkins:8081 SonarQube:9000
	docker compose -f docker-compose.cicd.yml up -d

## --- الأمان (شغّلها قبل أي push) ---
scan:             ## فحص كل حاجة محلياً
	docker run --rm -v "$$PWD:/repo" zricethezav/gitleaks:latest detect --source=/repo --config=/repo/security/gitleaks.toml --no-banner
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL $(IMAGE)
	docker run --rm -v "$$PWD/terraform:/tf" bridgecrew/checkov -d /tf --quiet --compact

## --- Terraform ---
tf-init:
	cd terraform && terraform init
tf-plan:          ## يوريك التغيير من غير تنفيذ
	cd terraform && terraform plan -var="my_ip=$$(curl -s ifconfig.me)" -var="alert_email=$(EMAIL)"
tf-apply:
	cd terraform && terraform apply -var="my_ip=$$(curl -s ifconfig.me)" -var="alert_email=$(EMAIL)"
tf-destroy:       ## امسح كل حاجة (وفّر الفلوس)
	cd terraform && terraform destroy -var="my_ip=$$(curl -s ifconfig.me)" -var="alert_email=$(EMAIL)"

## --- Kubernetes محلي ---
k8s-local:        ## cluster محلي + نشر التطبيق
	kind create cluster --name devops-journey
	kind load docker-image $(IMAGE) --name devops-journey
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/
helm-lint:
	helm lint helm/devops-journey
	helm template test helm/devops-journey -f helm/devops-journey/values-prod.yaml | head -50
