# Terraform Azure Demo Stack

This project demonstrates the use of **Terraform** with **Azure** by provisioning a small infrastructure stack that includes networking, virtual machines, a public load balancer, and a Bastion host.  
It is intended as a showcase of Terraform + Azure skills.

---

## Requirements

### Provider
- Uses the `azurerm` provider (≥ 3.x).

### Resource Group
- Single resource group containing all resources.

### Networking
- **Virtual Network**: `10.10.0.0/16`
- **Subnets**:
  - `snet-app-core-dev-eus-001` → App tier (`10.10.1.0/24`)
  - `snet-db-core-dev-eus-001` → Database tier (`10.10.2.0/24`)
  - `AzureBastionSubnet` → Bastion host (`10.10.3.0/27`)
- **NSGs**:
  - App subnet allows HTTP (80) from Load Balancer and SSH (22) from Bastion subnet.
  - DB subnet allows PostgreSQL (5432) from App subnet and SSH (22) from Bastion subnet.
  - No direct Internet access to VMs.

### Load Balancer
- **Public IP**: Standard SKU, Static.
- **Azure Load Balancer**: Standard SKU.
- **Frontend**: Internet-facing.
- **Backend Pool**: App VM.
- **Probe**: HTTP on `/health`.
- **Rule**: TCP 80 → App VM.

### Compute
- **App VM**:
  - Ubuntu 22.04 LTS Gen2.
  - Size: `Standard_B2s`.
  - Custom data installs Nginx and provides `/health` endpoint.
- **DB VM**:
  - Ubuntu 22.04 LTS Gen2.
  - Size: `Standard_B2ms`.
  - OS + data disk.
  - Custom data installs PostgreSQL, creates database and user, binds to subnet.
- **Admin Credentials**:
  - Randomly generated passwords via `random_password` (or replace with SSH keys).
  - Passwords are marked sensitive and not stored in code.

### Bastion
- **Azure Bastion Host**:
  - Name: `bast-core-dev-eus-001`.
  - Subnet: `AzureBastionSubnet` (`/27` as required by Azure).
  - Public IP: Standard SKU, Static.
- Used for secure SSH/RDP into VMs without exposing them to the Internet.

### Naming
- Follows Azure CAF-style convention:  
  `{resource-type}-{prefix}-{env}-{loc}-{nnn}`  
  Examples:  
  - `rg-core-dev-eus-001`  
  - `vnet-core-dev-eus-001`  
  - `vm-app-core-dev-eus-001`  
  - `bast-core-dev-eus-001`  

### Outputs
- Public IP of the Load Balancer.
- Public IP of the Bastion.
- Private IPs of App VM and DB VM.

---

## Usage

```bash
# Initialise providers (only needed once)
terraform init

# Review what will be created
terraform plan

# Deploy
terraform apply