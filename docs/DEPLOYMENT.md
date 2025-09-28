# Deployment Guide

## Application Access Information

### Primary Application URLs
- **Web Application**: http://134.149.27.43/
- **Keycloak Admin Console**: http://134.149.27.43:8080/admin
- **Authentication Login**: http://134.149.27.43/login
- **Application Health Check**: http://134.149.27.43/health
- **Keycloak Realm**: http://134.149.27.43:8080/realms/HYLASTIX-Realm

### User Credentials
- **Keycloak Administrator**: admin / admin
- **Application Test User**: testuser / testpassword
- **VM SSH Access**: SSH key authentication as azureuser@134.149.27.43

## Prerequisites

### Azure Environment Requirements
- Active Azure subscription with free tier eligibility
- Service Principal with Contributor permissions
- Resource Group creation and management permissions
- Public IP allocation capability

### Development Environment Setup
```bash
# Required tools
- Git version control system
- SSH key pair for VM authentication  
- Terraform >= 1.0 (for manual deployment)
- Ansible >= 2.9 (for manual deployment)
```

### GitHub Repository Configuration
- Repository with Actions enabled
- Required secrets configured (see below)
- Branch protection rules (optional)

## Required GitHub Secrets

Configure these secrets in Repository Settings → Secrets and variables → Actions:

```
AZURE_CLIENT_ID          # Service Principal Application (Client) ID
AZURE_CLIENT_SECRET      # Service Principal Authentication Secret
AZURE_SUBSCRIPTION_ID    # Target Azure Subscription ID  
AZURE_TENANT_ID          # Azure Active Directory Tenant ID
SSH_PRIVATE_KEY          # Private SSH key for VM authentication
KEYCLOAK_ADMIN_PASSWORD  # Keycloak administrator password
KEYCLOAK_DB_PASSWORD     # Keycloak database connection password
POSTGRES_PASSWORD        # PostgreSQL database root password
KEYCLOAK_CLIENT_SECRET   # OAuth client authentication secret
```

## Project Repository Structure

```
hylastix-keycloak-project/
├── .github/workflows/          # CI/CD automation workflows
│   ├── deploy.yml             # Complete infrastructure deployment
│   ├── configure.yml          # Application configuration updates
│   └── destroy.yml            # Infrastructure teardown
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Primary Terraform configuration
│   ├── variables.tf          # Variable definitions
│   ├── outputs.tf            # Output values
│   ├── provider.tf            # Provider details
│   ├── ssh_key.tf            # Generate ssh key
│   └── local.yml             # Local resources
├── ansible/                   # Configuration management
│   ├── inventory/hosts.yml    # Target infrastructure inventory
│   ├── playbooks/            # Automation playbooks
│   │   ├── site.yml          # Main deployment playbook
│   │   └── configure-keycloak.yml # Keycloak configuration
│   └── ansible.cfg           # Ansible settings
├── docker/                    # Containerized applications
│   ├── docker-compose.yml     # Service orchestration
│   ├── conf.d/               # Nginx configuration
│   │   └── default.conf      # Web server configuration
│   └── html/                 # Web application content
│       └── index.html        # Primary web page
└── docs/                     # Project documentation
    ├── README.md             # Primary project documentation
    ├── ARCHITECTURE.md       # Technical architecture details
    └── DEPLOYMENT.md         # This deployment guide
```

## Deployment Methods

### Method 1: Automated Deployment (GitHub Actions)

#### Initial Repository Setup
```bash
# Clone the project repository
git clone https://github.com/your-username/hylastix-keycloak-project.git
cd hylastix-keycloak-project

# Generate SSH key pair for VM access
ssh-keygen -t rsa -b 4096 -f ~/.ssh/hylastix_vm_key
```

#### GitHub Secrets Configuration
1. Navigate to repository Settings → Secrets and variables → Actions
2. Add all required secrets listed above
3. Ensure SSH_PRIVATE_KEY contains the complete private key content

#### Automated Deployment Execution
```bash
# Method 1: Trigger via Git push
git add .
git commit -m "Initial deployment"
git push origin main

# Method 2: Manual workflow trigger
# Navigate to Actions tab → Deploy Infrastructure and Application → Run workflow
```

#### Deployment Monitoring
- Monitor workflow progress in GitHub Actions tab
- Review deployment logs for any configuration issues
- Note VM public IP address from workflow output
- Verify all services are accessible using provided URLs

### Method 2: Manual Deployment

#### Infrastructure Provisioning
```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform backend and providers
terraform init

# Review planned infrastructure changes
terraform plan -var="ssh_public_key_path=~/.ssh/hylastix_vm_key.pub"

# Deploy Azure infrastructure
terraform apply -var="ssh_public_key_path=~/.ssh/hylastix_vm_key.pub" -auto-approve

# Capture VM IP address
export VM_IP=$(terraform output -raw public_ip_address)
echo "VM deployed at: $VM_IP"
```

#### Application Configuration
```bash
# Navigate to ansible directory  
cd ../ansible

# Create dynamic inventory with VM IP
cat > inventory/hosts.yml << EOF
all:
  hosts:
    keycloak-vm:
      ansible_host: ${VM_IP}
      ansible_user: azureuser
      ansible_ssh_private_key_file: ~/.ssh/hylastix_vm_key
  vars:
    keycloak_admin_password_vault: admin
    keycloak_db_password_vault: keycloakpass
    postgres_password_vault: postgres123
    keycloak_client_secret_vault: myclientsecret
EOF

# Deploy application stack
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# Configure Keycloak realm and authentication
ansible-playbook -i inventory/hosts.yml playbooks/configure-keycloak.yml
```

## Post-Deployment Verification

### Automated Service Health Verification
```bash
# Web application availability
curl -f http://134.149.27.43/health
# Expected response: "healthy"

# Keycloak service availability
curl -f http://134.149.27.43:8080/realms/HYLASTIX-Realm
# Expected response: JSON realm configuration

# Authentication endpoint functionality
curl -I http://134.149.27.43/login
# Expected response: 302 redirect to Keycloak
```

### Interactive Application Testing
1. **Web Application Access**
   - Open http://134.149.27.43/ in web browser
   - Verify HYLASTIX KEYCLOAK PROJECT page loads
   - Confirm "Login with Keycloak" button is present

2. **Authentication Flow Testing**
   - Click "Login with Keycloak" button
   - Verify redirect to http://134.149.27.43:8080/realms/HYLASTIX-Realm/protocol/openid-connect/auth
   - Enter credentials: testuser / testpassword
   - Confirm successful authentication and callback processing

3. **Administrative Interface Testing**
   - Access http://134.149.27.43:8080/admin
   - Login with: admin / admin
   - Verify Keycloak admin console functionality
   - Confirm HYLASTIX-Realm appears in realm list

### Container Infrastructure Verification
```bash
# SSH into the deployed VM
ssh -i ~/.ssh/hylastix_vm_key azureuser@134.149.27.43

# Verify container status
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
# Expected: keycloak, postgres, web containers running

# Check container logs for errors
sudo docker logs keycloak --tail 20
sudo docker logs postgres --tail 20
sudo docker logs web --tail 20

# Verify Docker Compose services
sudo docker-compose -f /home/azureuser/docker-compose.yml ps
```

### Database Connectivity Verification
```bash
# Test PostgreSQL connectivity from Keycloak
sudo docker exec postgres pg_isready -U keycloak
# Expected: "accepting connections"

# Verify Keycloak database connection
sudo docker exec keycloak curl -f http://localhost:8080/health/ready
# Expected: HTTP 200 response
```

## Configuration Management

### Application Configuration Updates
For configuration changes without infrastructure modification:

```bash
# Using GitHub Actions Configure Workflow
1. Navigate to repository Actions tab
2. Select "Configure Application" workflow
3. Click "Run workflow"
4. Input VM IP address: 134.149.27.43
5. Execute workflow and monitor progress
```

### Infrastructure Configuration Changes
```bash
# For infrastructure modifications
1. Update terraform/*.tf files as needed
2. Commit changes to repository
3. Push to main branch (triggers full deployment)
4. Monitor deployment in GitHub Actions
```

### Manual Configuration Updates
```bash
# SSH into VM for direct configuration changes
ssh -i ~/.ssh/hylastix_vm_key azureuser@134.149.27.43

# Update Keycloak configuration
sudo docker exec keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master --user admin --password admin

# Example: Add new user
sudo docker exec keycloak /opt/keycloak/bin/kcadm.sh create users \
  -r HYLASTIX-Realm -s username=newuser -s enabled=true

# Restart services if needed
sudo docker-compose -f /home/azureuser/docker-compose.yml restart
```

## Troubleshooting Guide

### Common Deployment Issues

#### Issue 1: VM Access Problems
```bash
# Verify NSG rules allow SSH access
az network nsg rule list \
  --resource-group rg-keycloak-devops \
  --nsg-name nsg-keycloak-dev \
  --output table

# Test SSH connectivity
ssh -i ~/.ssh/hylastix_vm_key -v azureuser@134.149.27.43

# Check VM status in Azure portal
az vm show --resource-group rg-keycloak-devops --name vm-keycloak-dev --show-details
```

#### Issue 2: Container Service Problems
```bash
# Check container status and restart if needed
sudo docker ps -a
sudo docker-compose -f /home/azureuser/docker-compose.yml restart

# Review container logs for errors
sudo docker logs keycloak --since 10m
sudo docker logs web --since 10m
sudo docker logs postgres --since 10m

# Verify container networking
sudo docker network inspect keycloak-net
```

#### Issue 3: Web Application Access Issues
```bash
# Test nginx configuration syntax
sudo docker exec web nginx -t

# Check nginx process and reload if needed
sudo docker exec web nginx -s reload

# Verify static content exists
sudo docker exec web ls -la /usr/share/nginx/html/

# Test direct container access
sudo docker exec web curl -f http://localhost/health
```

#### Issue 4: Keycloak Authentication Problems
```bash
# Verify Keycloak admin access
curl -f http://134.149.27.43:8080/admin

# Check realm configuration
sudo docker exec keycloak /opt/keycloak/bin/kcadm.sh get realms/HYLASTIX-Realm

# Verify client configuration  
sudo docker exec keycloak /opt/keycloak/bin/kcadm.sh get clients -r HYLASTIX-Realm

# Test authentication endpoints
curl -I http://134.149.27.43/login
```

#### Issue 5: Network Connectivity Problems
```bash
# Test port connectivity from external location
telnet 134.149.27.43 80
telnet 134.149.27.43 8080

# Check Azure NSG rules
az network nsg show \
  --resource-group rg-keycloak-devops \
  --name nsg-keycloak-dev

# Verify public IP assignment
az network public-ip show \
  --resource-group rg-keycloak-devops \
  --name pip-keycloak-vm-dev
```

## Maintenance Procedures

### Regular Maintenance Tasks

#### Security Updates
```bash
# Update VM system packages
sudo apt update && sudo apt upgrade -y

# Update container images
sudo docker-compose -f /home/azureuser/docker-compose.yml pull
sudo docker-compose -f /home/azureuser/docker-compose.yml up -d

# Review security logs
sudo tail -f /var/log/auth.log
```

#### Performance Monitoring
```bash
# Monitor system resources
htop
df -h
free -h

# Check container resource usage
sudo docker stats

# Review application logs
sudo docker logs web --since 24h | grep -i error
sudo docker logs keycloak --since 24h | grep -i error
```

#### Backup Procedures
```bash
# Backup PostgreSQL database
sudo docker exec postgres pg_dump -U keycloak keycloak > backup_$(date +%Y%m%d).sql

# Backup configuration files
tar -czf config_backup_$(date +%Y%m%d).tar.gz /home/azureuser/docker/

# Store backups in Azure Storage (recommended for production)
# az storage blob upload --file backup.sql --container backups --name backup_$(date +%Y%m%d).sql
```

### Scaling Procedures

#### Vertical Scaling (VM Size Increase)
```bash
# Stop VM
az vm deallocate --resource-group rg-keycloak-devops --name vm-keycloak-dev

# Resize VM
az vm resize --resource-group rg-keycloak-devops --name vm-keycloak-dev --size Standard_B2s

# Start VM
az vm start --resource-group rg-keycloak-devops --name vm-keycloak-dev
```

#### Horizontal Scaling Preparation
For production environments requiring high availability:

1. **Load Balancer Implementation**
   - Deploy Azure Load Balancer
   - Configure backend pool with multiple VMs
   - Set up health probes

2. **Database Clustering**
   - Implement PostgreSQL master-slave configuration
   - Configure connection pooling
   - Set up automated failover

3. **Shared Storage**
   - Migrate to Azure Database for PostgreSQL
   - Implement Azure Files for shared configuration
   - Configure persistent volume claims

## Security Hardening

### Production Security Recommendations

#### Network Security Enhancement
```bash
# Restrict SSH access to specific IP ranges
az network nsg rule update \
  --resource-group rg-keycloak-devops \
  --nsg-name nsg-keycloak-dev \
  --name SSH \
  --source-address-prefixes "YOUR_OFFICE_IP/32"

# Implement SSL/TLS certificates
# Configure Let's Encrypt or import custom certificates
# Update nginx configuration for HTTPS redirect
```

#### Keycloak Security Configuration
```bash
# Enable HTTPS in Keycloak
# Update realm SSL requirements
sudo docker exec keycloak /opt/keycloak/bin/kcadm.sh update realms/HYLASTIX-Realm \
  -s sslRequired=external

# Configure session timeouts
# Implement brute force protection
# Set up password policies
```

#### Container Security
```bash
# Run containers as non-root users
# Implement container image scanning
# Configure Docker daemon security options
# Set up container resource limits
```

## Infrastructure Cleanup

### Automated Cleanup (GitHub Actions)
```bash
# Use Destroy Infrastructure workflow
1. Navigate to repository Actions tab
2. Select "Destroy Infrastructure" workflow  
3. Click "Run workflow"
4. Input confirmation text: "DESTROY"
5. Execute workflow and verify resource removal
```

### Manual Cleanup
```bash
# Using Terraform
cd terraform
terraform destroy -var="ssh_public_key_path=~/.ssh/hylastix_vm_key.pub" -auto-approve

# Verify resource removal
az resource list --resource-group rg-keycloak-devops --output table

# Clean up resource group if empty
az group delete --name rg-keycloak-devops --yes --no-wait
```

### Cost Management
```bash
# Monitor Azure spending
az consumption usage list --output table

# Set up budget alerts
az consumption budget create \
  --budget-name "keycloak-project-budget" \
  --amount 50 \
  --time-grain Monthly

# Schedule automatic shutdown
az vm auto-shutdown -g rg-keycloak-devops -n vm-keycloak-dev --time 1900
```

## Production Deployment Considerations

### Environment Separation
- **Development**: Current configuration suitable for development and testing
- **Staging**: Implement identical production configuration for testing  
- **Production**: Enhanced security, monitoring, and high availability

### Monitoring and Observability
- **Azure Monitor**: Infrastructure and application performance monitoring
- **Log Analytics**: Centralized log collection and analysis
- **Application Insights**: Detailed application performance metrics
- **Custom Dashboards**: Business-specific monitoring views

### Compliance and Governance
- **Azure Policy**: Automated compliance enforcement
- **Resource Tagging**: Comprehensive resource categorization and cost allocation
- **Access Control**: Role-based access control (RBAC) implementation
- **Audit Logging**: Comprehensive activity logging and reporting

This deployment guide provides complete procedures for deploying, managing, and maintaining the HYLASTIX KEYCLOAK PROJECT infrastructure while ensuring security, performance, and operational excellence.