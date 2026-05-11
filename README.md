# Ansible + Terraform Learning Project

A hands-on DevOps learning project that provisions an Azure VM using Terraform
and configures it with Ansible to run a Flask web app.

---

## What This Project Does

```
Terraform  → creates an Ubuntu VM in Azure (the house)
Ansible    → installs Python, Flask, runs the app as a service (furnishes the house)
Browser    → visits http://<VM-IP>:5000 to see the running app
```

---

## ELI5 — Explain Like I'm 5

| Tool        | ELI5                                                                 |
|-------------|----------------------------------------------------------------------|
| **Terraform**  | A builder. You give it a blueprint (main.tf) and it builds the server in Azure. |
| **Ansible**    | An interior designer. It SSHs into the server and sets everything up inside. |
| **Azure VM**   | A computer in Microsoft's data center that you rent by the hour.     |
| **SSH Key**    | A digital lock and key. Ansible uses your private key to get into the VM without a password. |
| **Playbook**   | Ansible's to-do list. Each task = one thing to install or configure. |
| **Inventory**  | Ansible's address book. Tells Ansible which VM(s) to connect to.    |
| **Systemd**    | A manager inside Linux that keeps your Flask app running even after reboot. |

---

## Tools Used

| Tool       | Version  | Purpose                        |
|------------|----------|-------------------------------|
| Terraform  | v1.15.2  | Provision Azure infrastructure |
| Ansible    | 2.16.3   | Configure the VM               |
| Azure CLI  | latest   | Login and manage Azure         |
| WSL2       | Ubuntu   | Run Ansible (Linux required)   |

---

## How Terraform and Bicep Differ

Both are Infrastructure as Code (IaC) tools but serve different scopes:

| Feature       | Terraform             | Bicep                    |
|---------------|-----------------------|--------------------------|
| Cloud support | Multi-cloud (Azure, AWS, GCP) | Azure only         |
| Language      | HCL (.tf files)       | Bicep (.bicep files)     |
| State file    | Yes (terraform.tfstate) | No (ARM manages state) |
| Best for      | Multi-cloud projects  | Azure-only projects      |

---

## How Terraform and Ansible Differ

They work together — not against each other:

| Tool       | Role                  | When it runs             |
|------------|-----------------------|--------------------------|
| Terraform  | Creates the VM        | Before Ansible           |
| Ansible    | Configures inside VM  | After VM is running      |

```
Terraform (create) → VM exists → Ansible (configure) → App is running
```

---

## Project Structure

```
ansible-terraform/
├── terraform/
│   ├── main.tf          # Blueprint: what Azure resources to build
│   ├── variables.tf     # Settings: VM name, location, size, username
│   └── outputs.tf       # Results: prints VM public IP when done
└── ansible/
    ├── inventory.ini    # Address book: VM IP and SSH credentials
    └── playbook.yml     # Task list: install Python, Flask, start service
```

---

## What Each Terraform File Does

### main.tf — The Blueprint
Tells Terraform to create these 8 Azure resources:
1. **Resource Group** — a folder in Azure that holds all resources
2. **Virtual Network** — private network for the VM
3. **Subnet** — a section of the network (10.0.1.0/24)
4. **Public IP** — so you can reach the VM from the internet
5. **Network Security Group (NSG)** — firewall, allows SSH (port 22)
6. **Network Interface (NIC)** — connects the VM to the network
7. **NSG Association** — links the firewall to the network card
8. **Linux VM** — Ubuntu 22.04, Standard_B2als_v2

### variables.tf — The Settings
Holds all configurable values in one place:
- Resource group name: `ansible-lab-rg`
- Location: `southeastasia`
- VM name: `ansible-target`
- Admin username: `ansibleuser`
- SSH public key path: `~/.ssh/id_rsa.pub`

### outputs.tf — The Results
After `terraform apply`, prints the VM's public IP so you can put it in Ansible's inventory.

---

## What Each Ansible File Does

### inventory.ini — Address Book
```ini
[webservers]
13.67.71.202 ansible_user=ansibleuser ansible_ssh_private_key_file=~/.ssh/id_rsa
```
Tells Ansible: "connect to this IP, as this user, using this SSH key."

### playbook.yml — Task List
Runs 8 tasks on the VM in order:
1. Update apt package cache
2. Install Python3, pip, venv
3. Install Flask via pip
4. Create `/opt/flaskapp` directory
5. Create `app.py` (simple Flask app)
6. Create systemd service file (keeps app running)
7. Start the Flask service
8. Enable it on reboot

---

## Step-by-Step: What Was Done

### 1. Generate SSH Key (WSL2)
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```
Creates a key pair:
- `~/.ssh/id_rsa` — private key (never share this)
- `~/.ssh/id_rsa.pub` — public key (goes into the VM)

### 2. Install Terraform (WSL2)
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y
```

### 3. Install Ansible (WSL2)
```bash
sudo apt update && sudo apt install ansible -y
```

### 4. Login to Azure (WSL2)
```bash
az login --use-device-code
```

### 5. Create Azure VM (Azure CLI)
Standard_B1s and Standard_B2s were unavailable in Southeast Asia.
Used Standard_B2als_v2 instead (same size used for AKS cluster):
```bash
az vm create \
  --resource-group ansible-lab-rg \
  --name ansible-target \
  --image Ubuntu2204 \
  --size Standard_B2als_v2 \
  --admin-username ansibleuser \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --public-ip-sku Standard
```

VM public IP: **13.67.71.202**

### 6. Test Ansible Connection
```bash
ansible webservers -i ~/ansible-terraform/ansible/inventory.ini -m ping
```
Expected output: `13.67.71.202 | SUCCESS => { "ping": "pong" }`

### 7. Run Ansible Playbook
```bash
ansible-playbook -i ~/ansible-terraform/ansible/inventory.ini ~/ansible-terraform/ansible/playbook.yml
```
Ansible SSHs into the VM and runs all 8 tasks automatically.

### 8. Open Port 5000
```bash
az vm open-port --resource-group ansible-lab-rg --name ansible-target --port 5000
```

### 9. Visit the App
Open browser: `http://13.67.71.202:5000`

---

## Errors Encountered and Fixed

| Error | Cause | Fix |
|-------|-------|-----|
| `terraform` not found in WSL2 | Terraform installed on Windows, not WSL2 | Installed via HashiCorp apt repo |
| `state lock` error | Terraform files on Windows filesystem (`/mnt/c/`) | Moved terraform files to WSL2 home directory (`~/`) |
| `exec format error` on Terraform auth | Windows `az.exe` in WSL2 PATH | Used `az vm create` directly instead |
| `Standard_B1s` not available | Capacity restrictions in Southeast Asia | Used `Standard_B2als_v2` |
| `Basic SKU` public IP limit | Azure for Students restriction | Changed to `Standard` SKU |

---

## Azure Resources Created

| Resource | Name | Type |
|----------|------|------|
| Resource Group | ansible-lab-rg | Container |
| Virtual Network | ansible-target-vnet | Network |
| Subnet | ansible-target-subnet | Network |
| Public IP | ansible-target-pip | Network |
| NSG (Firewall) | ansible-target-nsg | Security |
| Network Interface | ansible-target-nic | Network |
| Virtual Machine | ansible-target | Compute |
| OS Disk | auto-generated | Storage |

---

## Teardown (Stop Spending Credits)

When done learning, deallocate the VM to stop charges:
```bash
az vm deallocate --resource-group ansible-lab-rg --name ansible-target
```

To delete everything:
```bash
az group delete --name ansible-lab-rg --yes
```

---

## Key Learnings

- Terraform and Ansible are **complementary**, not competing tools
- Ansible requires **Linux** to run — WSL2 provides this on Windows
- Terraform stores **state** in `terraform.tfstate` — do not delete this file
- SSH keys are used instead of passwords for server access
- Systemd keeps services **running automatically** after VM restarts
- Azure for Students has **SKU restrictions** — not all VM sizes are available
