# 📐 Architecture & Justification

## 🔧 Overview

This project sets up a secure static website hosted on Azure, protected by **Keycloak** for authentication. All components are deployed via **Terraform**, configured via **Ansible**, and automated with **GitHub Actions**.

---

## 🖼️ Architecture Diagram

![Architecture Diagram](architecture-diagram.png)

*(Tip: Use [draw.io](https://draw.io), Lucidchart, or Excalidraw to create the diagram and save it as `docs/architecture-diagram.png`)*

---

## 🧱 Infrastructure Components

| Component         | Why It's Used                                                      |
|------------------|--------------------------------------------------------------------|
| **Azure VM (Ubuntu)**   | Simple, cost-effective environment for hosting Docker containers |
| **Virtual Network + Subnet** | Isolate traffic, control internal networking                |
| **NSG (Security Group)** | Controls access to SSH, HTTP, Keycloak (8080), and Postgres     |
| **Public IP**      | Enables external access to the web server and Keycloak UI         |

**Justification for not using AKS/App Service**:
- Overhead of Kubernetes is too high for a minimal PoC
- Azure App Service is more opinionated and less flexible than a raw VM
- Using a VM ensures full control and simplicity for container orchestration

---

## 🐳 Containerized Components

| Container     | Image Used                    | Why This Image?                           |
|---------------|-------------------------------|--------------------------------------------|
| **Postgres**  | `postgres:15`                 | Stable, official image; required by Keycloak |
| **Keycloak**  | `quay.io/keycloak/keycloak`   | Official image; secure and up-to-date       |
| **Nginx**     | `nginx:alpine`                | Lightweight, fast, perfect for static files |

**Why Docker?**
- Simple and quick to deploy
- Ideal for PoC and lightweight environments
- Avoids complexity of Kubernetes for this task

---

## 🌐 Network Configuration

| Port | Purpose             | Notes                          |
|------|---------------------|--------------------------------|
| 22   | SSH                 | For Ansible and manual access  |
| 80   | Web (Nginx)         | Hosts the static web page      |
| 8080 | Keycloak            | Keycloak admin/auth UI         |
| 5432 | PostgreSQL          | Used internally by Keycloak    |

---

## 🔐 Authentication Flow

1. User visits the static website (via Nginx)
2. Website redirects to Keycloak login
3. After successful login, user is returned to the site
4. (Future feature: Use OAuth2 Proxy for Keycloak enforcement)

---

## 📈 CI/CD Workflows (GitHub Actions)

| Workflow        | Trigger             | Purpose                            |
|----------------|---------------------|------------------------------------|
| `deploy.yml`    | On push to `main`   | Applies Terraform + runs Ansible   |
| `destroy.yml`   | Manual trigger      | Tears down all infrastructure      |
| `validate.yml`  | On pull request     | Checks code quality & lint errors  |

---

## 🧩 Future Enhancements

| Feature                 | Benefit                                      |
|-------------------------|----------------------------------------------|
| TLS via Let's Encrypt   | Secure HTTPS access                          |
| Use OAuth2 Proxy        | Enforce Keycloak auth for Nginx              |
| Migrate to AKS          | Scalability and high availability            |
| Secrets Manager (Vault) | Securely store Keycloak and DB credentials   |
| Monitoring (Prometheus) | Track container health and performance       |

---

## ✅ Summary

This project demonstrates how to:
- Deploy secure, container-based infrastructure in Azure
- Use IaC (Terraform), automation (Ansible), and CI/CD (GitHub Actions)
- Build modular, extensible systems for real-world DevOps workflows
