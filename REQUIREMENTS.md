# 💻 REQUIREMENTS - Software necesario en tu máquina

Antes de ejecutar cualquier script, asegúrate de tener instalado lo siguiente.

---

## 🟢 Modo Local (Mac/Linux)

### Obligatorio

| Software | Versión | Verificar | Instalar |
|----------|---------|-----------|----------|
| **Node.js** | 22+ | `node -v` | [nodejs.org](https://nodejs.org/) |
| **npm** | 10+ | `npm -v` | Viene con Node.js |
| **Git** | 2.0+ | `git --version` | [git-scm.com](https://git-scm.com/) |

### Instalación rápida

**macOS (Homebrew):**
```bash
# Instalar Homebrew si no lo tienes
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar dependencias
brew install node@22 git
```

**Ubuntu/Debian:**
```bash
# Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt install -y nodejs git
```

**Windows (WSL2 recomendado):**
```bash
# Primero instalar WSL2, luego seguir instrucciones de Ubuntu
wsl --install
```

---

## 🔵 Modo VPS (Digital Ocean)

### En tu máquina local

| Software | Versión | Verificar | Para qué |
|----------|---------|-----------|----------|
| **Git** | 2.0+ | `git --version` | Clonar el repo |
| **SSH** | - | `ssh -V` | Conectar al VPS |

### Opcional (para Terraform)

| Software | Versión | Verificar | Instalar |
|----------|---------|-----------|----------|
| **Terraform** | 1.0+ | `terraform -v` | [terraform.io](https://terraform.io/downloads) |
| **doctl** | - | `doctl version` | [DO CLI](https://docs.digitalocean.com/reference/doctl/how-to/install/) |

**Instalación Terraform:**

```bash
# macOS
brew install terraform

# Ubuntu/Debian
sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Instalación doctl (Digital Ocean CLI):**

```bash
# macOS
brew install doctl

# Ubuntu/Debian
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
tar xf doctl-1.104.0-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin

# Autenticar
doctl auth init
```

---

## ✅ Script de verificación

Corre esto para verificar que tienes todo:

```bash
#!/bin/bash
echo "=== Verificando requirements ==="

check() {
    if command -v $1 &> /dev/null; then
        echo "✅ $1: $($1 --version 2>&1 | head -1)"
    else
        echo "❌ $1: NO INSTALADO"
    fi
}

echo ""
echo "--- Obligatorios ---"
check node
check npm
check git

echo ""
echo "--- Opcionales (VPS/Terraform) ---"
check terraform
check doctl
check ssh

echo ""
```

O simplemente:

```bash
./scripts/check-requirements.sh
```

---

## 📋 Resumen

### Solo quiero deploy local:
```
✅ Node.js 22+
✅ npm
✅ Git
```

### Quiero deploy en VPS (manual):
```
✅ Git
✅ SSH
```

### Quiero deploy en VPS (Terraform):
```
✅ Git
✅ SSH
✅ Terraform
✅ doctl (opcional pero útil)
```
