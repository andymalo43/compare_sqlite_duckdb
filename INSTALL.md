# Installation SQLite et DuckDB CLI

## 🎯 Objectif

Installer SQLite et DuckDB en ligne de commande sur Windows (PowerShell) et WSL/Linux (Bash).

---

## 🪟 Installation Windows (PowerShell)

### Méthode 1 : Winget (Recommandée - Windows 11+)

```powershell
# SQLite
winget install SQLite.SQLite

# DuckDB
winget install DuckDB.cli
```

### Méthode 2 : Chocolatey

```powershell
# Installer Chocolatey si pas déjà installé
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Installer SQLite et DuckDB
choco install sqlite -y
choco install duckdb -y
```

### Méthode 3 : Installation Manuelle

#### SQLite

**Étape 1 : Télécharger**

1. Aller sur https://sqlite.org/download.html
2. Section "Precompiled Binaries for Windows"
3. Télécharger `sqlite-tools-win-x64-XXXXXXX.zip`

**Étape 2 : Installer**

```powershell
# Créer un dossier pour les outils
New-Item -ItemType Directory -Path "C:\SQLite" -Force

# Décompresser le ZIP dans C:\SQLite
# (Via l'explorateur Windows ou PowerShell)
Expand-Archive -Path "$env:USERPROFILE\Downloads\sqlite-tools-*.zip" -DestinationPath "C:\SQLite" -Force

# Ajouter au PATH
$env:Path += ";C:\SQLite"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\SQLite", [EnvironmentVariableTarget]::User)
```

**Étape 3 : Vérifier**

```powershell
# Fermer et rouvrir PowerShell, puis :
sqlite3 --version
```

**Résultat attendu** :
```
3.45.0 2024-01-15 ...
```

#### DuckDB

**Étape 1 : Télécharger**

1. Aller sur https://duckdb.org/docs/installation/
2. Section "Direct Download"
3. Cliquer sur "Windows (x86-64)" → `duckdb_cli-windows-amd64.zip`

**Étape 2 : Installer**

```powershell
# Créer un dossier pour DuckDB
New-Item -ItemType Directory -Path "C:\DuckDB" -Force

# Télécharger avec PowerShell
$url = "https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-windows-amd64.zip"
Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\duckdb.zip"

# Décompresser
Expand-Archive -Path "$env:TEMP\duckdb.zip" -DestinationPath "C:\DuckDB" -Force

# Ajouter au PATH
$env:Path += ";C:\DuckDB"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\DuckDB", [EnvironmentVariableTarget]::User)
```

**Étape 3 : Vérifier**

```powershell
# Fermer et rouvrir PowerShell, puis :
duckdb --version
```

**Résultat attendu** :
```
v1.0.0 ...
```

---

## 🐧 Installation WSL/Linux (Bash)

### Ubuntu/Debian

```bash
# Mettre à jour les paquets
sudo apt update

# SQLite (généralement déjà installé)
sudo apt install sqlite3 -y

# DuckDB - Méthode 1 : Via le binaire officiel
wget https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-amd64.zip
unzip duckdb_cli-linux-amd64.zip
sudo mv duckdb /usr/local/bin/
sudo chmod +x /usr/local/bin/duckdb
rm duckdb_cli-linux-amd64.zip

# Vérification
sqlite3 --version
duckdb --version
```

### Alternative : Installation via APT (Ubuntu 22.04+)

```bash
# Ajouter le repository DuckDB
wget -qO- https://packages.duckdb.org/duckdb.gpg | sudo tee /usr/share/keyrings/duckdb.gpg
echo "deb [signed-by=/usr/share/keyrings/duckdb.gpg] https://packages.duckdb.org/apt stable main" | sudo tee /etc/apt/sources.list.d/duckdb.list

# Installer
sudo apt update
sudo apt install duckdb -y
```

### macOS (Homebrew)

```bash
# SQLite (déjà inclus généralement)
brew install sqlite3

# DuckDB
brew install duckdb

# Vérification
sqlite3 --version
duckdb --version
```

---

## ✅ Vérification de l'Installation

### Test SQLite

```powershell
# Windows PowerShell ou WSL Bash
sqlite3 :memory: "SELECT 'SQLite fonctionne!' as message;"
```

**Résultat attendu** :
```
SQLite fonctionne!
```

### Test DuckDB

```powershell
# Windows PowerShell ou WSL Bash
echo "SELECT 'DuckDB fonctionne!' as message;" | duckdb
```

**Résultat attendu** :
```
┌──────────────────────┐
│       message        │
│       varchar        │
├──────────────────────┤
│ DuckDB fonctionne!   │
└──────────────────────┘
```

---

## 🎨 Configuration Optionnelle

### SQLite : Améliorer l'Affichage

Créer un fichier `.sqliterc` :

**Windows** : `C:\Users\VotreNom\.sqliterc`
```sql
.mode column
.headers on
.timer on
.width auto
```

**Linux/WSL** : `~/.sqliterc`
```sql
.mode column
.headers on
.timer on
.width auto
```

### DuckDB : Améliorer l'Affichage

Créer un fichier `.duckdbrc` :

**Windows** : `C:\Users\VotreNom\.duckdbrc`
```sql
.mode line
.timer on
.maxrows 100
```

**Linux/WSL** : `~/.duckdbrc`
```sql
.mode line
.timer on
.maxrows 100
```

---

## 🔧 Dépannage

### Problème : "sqlite3 n'est pas reconnu..."

**Windows** :
```powershell
# Vérifier le PATH
$env:Path -split ';' | Select-String -Pattern 'SQLite'

# Si vide, réajouter :
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\SQLite", [EnvironmentVariableTarget]::User)
```

**Solution** : Redémarrer PowerShell ou la machine

### Problème : "Permission denied" sur WSL

```bash
# Donner les droits d'exécution
sudo chmod +x /usr/local/bin/duckdb
sudo chmod +x /usr/local/bin/sqlite3
```

### Problème : Version ancienne de SQLite

```bash
# Ubuntu/Debian : Installer depuis les sources
wget https://www.sqlite.org/2024/sqlite-autoconf-3450000.tar.gz
tar xvfz sqlite-autoconf-3450000.tar.gz
cd sqlite-autoconf-3450000
./configure
make
sudo make install
```

### Problème : DuckDB ne trouve pas les extensions

```bash
# Créer le dossier d'extensions
mkdir -p ~/.duckdb/extensions

# Dans DuckDB :
INSTALL sqlite;
LOAD sqlite;
```

---

## 📊 Test Complet d'Installation

### Script de Test Windows (PowerShell)

```powershell
Write-Host "=== Test d'Installation ===" -ForegroundColor Cyan

# SQLite
try {
    $sqliteVer = sqlite3 -version
    Write-Host "✓ SQLite: $sqliteVer" -ForegroundColor Green
} catch {
    Write-Host "✗ SQLite: NON INSTALLÉ" -ForegroundColor Red
}

# DuckDB
try {
    $duckdbVer = duckdb -version
    Write-Host "✓ DuckDB: $duckdbVer" -ForegroundColor Green
} catch {
    Write-Host "✗ DuckDB: NON INSTALLÉ" -ForegroundColor Red
}

# Test fonctionnel
Write-Host "`nTest fonctionnel SQLite:" -ForegroundColor Yellow
echo "SELECT 'OK' as status;" | sqlite3 :memory:

Write-Host "`nTest fonctionnel DuckDB:" -ForegroundColor Yellow
echo "SELECT 'OK' as status;" | duckdb :memory:

Write-Host "`n=== Installation Complète ===" -ForegroundColor Green
```

### Script de Test WSL/Linux (Bash)

```bash
#!/bin/bash

echo "=== Test d'Installation ==="

# SQLite
if command -v sqlite3 &> /dev/null; then
    echo "✓ SQLite: $(sqlite3 --version)"
else
    echo "✗ SQLite: NON INSTALLÉ"
fi

# DuckDB
if command -v duckdb &> /dev/null; then
    echo "✓ DuckDB: $(duckdb --version)"
else
    echo "✗ DuckDB: NON INSTALLÉ"
fi

# Test fonctionnel
echo -e "\nTest fonctionnel SQLite:"
echo "SELECT 'OK' as status;" | sqlite3 :memory:

echo -e "\nTest fonctionnel DuckDB:"
echo "SELECT 'OK' as status;" | duckdb :memory:

echo -e "\n=== Installation Complète ==="
```

---

## 🚀 Prochaines Étapes

Une fois l'installation terminée :

1. ✅ **Tester** les commandes ci-dessus
2. 📝 **Exécuter** le script de génération de données : `setup-database.ps1` (Windows) ou `setup-database.sh` (WSL)
3. 📖 **Consulter** le guide 01-concept-ensembliste.md

---

## 📚 Ressources

- [SQLite Download](https://sqlite.org/download.html)
- [DuckDB Installation](https://duckdb.org/docs/installation/)
- [Chocolatey](https://chocolatey.org/)
- [Winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/)

---

**Installation réussie ? Vous êtes prêt ! 🎉**
