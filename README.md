# DevOps Journey 🚀

موقع static بسيط (HTML/CSS/JS) اتبنى حواليه pipeline DevOps/Cloud كامل.
الهدف: تطبيق كل أداة على مشروع صغير يفضل واضح ومفهوم.

## ترتيب التطبيق (من الأول للآخر)

| # | المرحلة | الأداة | المجلد/الملف |
|---|---------|--------|--------------|
| 1 | Version Control | Git + GitHub | `.gitignore`, `.pre-commit-config.yaml` |
| 2 | Containerization | Docker, Compose | `Dockerfile`, `docker-compose*.yml` |
| 3 | CI | Jenkins / GitHub Actions | `Jenkinsfile`, `.github/workflows/` |
| 4 | Code Quality | SonarQube | `security/sonar-project.properties` |
| 5 | Security Scans | Gitleaks, Trivy, Checkov | `security/` |
| 6 | IaC | Terraform | `terraform/` |
| 7 | Config Mgmt | Ansible | `ansible/` |
| 8 | Orchestration | Kubernetes | `k8s/` |
| 9 | Packaging | Helm | `helm/` |
| 10 | GitOps / CD | ArgoCD | `argocd/` |
| 11 | Monitoring | Prometheus, Grafana, Alertmanager | `monitoring/` |
| 12 | Logging | Loki + Promtail | `monitoring/` |
| 13 | Secrets | AWS Secrets Manager, External Secrets | `terraform/main.tf`, `k8s/external-secret.yaml` |
| 14 | Policy as Code | Kyverno | `k8s/policies/` |
| 15 | Dependencies | Dependabot | `.github/dependabot.yml` |

## تشغيل سريع محلياً
```bash
make up              # التطبيق      → http://localhost:8080
make monitoring-up   # Grafana      → http://localhost:3000  (admin/admin)
make cicd-up         # Jenkins      → http://localhost:8081 | SonarQube → :9000
make scan            # فحوصات الأمان
make down
```

## على AWS
```bash
cd terraform/bootstrap && terraform init && terraform apply -var="state_bucket=<unique-name>"
# حط نفس الاسم في terraform/backend.tf ثم:
make tf-init && make tf-plan EMAIL=you@example.com && make tf-apply EMAIL=you@example.com
make tf-destroy EMAIL=you@example.com     # بعد التجربة!
```

## Kubernetes + GitOps
```bash
make k8s-local
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/application.yaml
```

## ⚠️ قبل ما ترفع على GitHub
- غيّر `mohamedmabrouk` لاسم حسابك في Docker Hub في كل الملفات (`grep -r mohamedmabrouk .`).
- ماترفعش `terraform.tfvars` ولا `*.pem` (موجودين في `.gitignore`).
- فعّل Branch Protection على `main`.
