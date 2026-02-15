# 00 - Configuration de l'environnement

## 🎯 Objectif

Installer et configurer DuckDB et SQLite avec un jeu de données de test de **~27M lignes** (100K clients, 3M factures, 24M lignes) pour expérimenter les opérations ensemblistes.

**Durée estimée : 15 minutes**

---

## 📋 Prérequis système

### Configuration minimale

- **OS** : Windows 10/11, Linux, macOS, ou WSL
- **SQLite** : 3.35+ (généralement pré-installé)
- **DuckDB** : 0.9.0+ 
- **RAM** : 8 Go minimum (16 Go recommandé)
- **Disque** : 4 Go d'espace libre (bases: 2.4 GB + 850 MB)
- **Processeur** : CPU moderne (2+ cœurs)

### 🔗 Installation Complète

**Consultez le guide détaillé** : **[INSTALL.md](INSTALL.md)**

Ce guide contient toutes les instructions pour :
- ✅ Installation SQLite CLI (Windows PowerShell et WSL/Linux)
- ✅ Installation DuckDB CLI (Windows PowerShell et WSL/Linux)
- ✅ Configuration des outils
- ✅ Vérification de l'installation

**Vérification rapide** :

```bash
# SQLite
sqlite3 --version

# DuckDB
duckdb --version
```

---

## 🗂️ Structure du projet

### Créer l'arborescence

**Windows PowerShell** :
```powershell
mkdir ensemblistes-guide
cd ensemblistes-guide

# Créer les dossiers
mkdir data, sql, scripts

# Structure finale :
# ensemblistes-guide/
# ├── data/              # Bases de données générées
# ├── sql/               # Scripts SQL
# ├── scripts/           # Scripts PowerShell/Bash
# └── README.md
```

**Linux/WSL Bash** :
```bash
mkdir -p ensemblistes-guide/{data,sql,scripts}
cd ensemblistes-guide
```

---

## 🎲 Génération des données

### Méthode 1 : Script PowerShell (Windows)

**Fichier fourni** : `setup-database.ps1`

```powershell
# Exécuter le script
.\setup-database.ps1

# Ou avec un chemin personnalisé
.\setup-database.ps1 -OutputPath "C:\data"
```

**Ce que fait le script** :
1. ✅ Vérifie que SQLite et DuckDB sont installés
2. ✅ Génère un script SQL pur (génération déterministe, pas de RANDOM())
3. ✅ Crée `facturation.db` (SQLite) avec 100K clients, 3M factures, ~24M lignes
4. ✅ Copie les données vers `facturation.duckdb`
5. ✅ Crée les index pour optimiser les performances
6. ⏱️ Durée: ~7 minutes (406s pour SQLite + 10s pour DuckDB)

**Sortie attendue** :
```
============================================================================
GÉNÉRATION DES DONNÉES DE TEST - SQLITE + DUCKDB
============================================================================

✓ SQLite détecté : 3.45.0
✓ DuckDB détecté

📁 Création des bases de données...
  - SQLite  : .\data\facturation.db
  - DuckDB  : .\data\facturation.duckdb

📝 Script SQL généré : .\data\setup_database.sql

💾 Création de la base SQLite...
  ✅ SQLite créée en 15.2s

🦆 Création de la base DuckDB...
  ✅ DuckDB créée

✔️  VÉRIFICATION

SQLite - Clients: 100000
SQLite - Factures: 3000000
SQLite - Lignes: 24000000

DuckDB - Clients: 100000
DuckDB - Factures: 3000000
DuckDB - Lignes: 24000000

============================================================================
✨ GÉNÉRATION TERMINÉE AVEC SUCCÈS !
============================================================================
```

### Méthode 2 : Script Bash (WSL/Linux/macOS)

**Fichier fourni** : `setup-database.sh`

```bash
# Rendre exécutable
chmod +x setup-database.sh

# Exécuter
./setup-database.sh

# Ou avec chemin personnalisé
./setup-database.sh /home/user/data
```

**Fonctionnement identique à la version PowerShell.**

### Méthode 3 : SQL Manuel (Avancé)

Si vous préférez tout faire manuellement :

```bash
# Le script génère automatiquement setup_database.sql
# Vous pouvez l'exécuter vous-même :

# SQLite
sqlite3 data/facturation.db < data/setup_database.sql

# DuckDB (nécessite extension SQLite)
duckdb data/facturation.duckdb
```

Puis dans DuckDB :
```sql
INSTALL sqlite;
LOAD sqlite;
ATTACH 'data/facturation.db' AS sqlite_db (TYPE sqlite);

CREATE TABLE client AS SELECT * FROM sqlite_db.client;
CREATE TABLE facture AS SELECT * FROM sqlite_db.facture;
CREATE TABLE ligne_facture AS SELECT * FROM sqlite_db.ligne_facture;
```

---

## ✅ Vérification de l'installation

### Vérification automatique

Les scripts PowerShell/Bash affichent automatiquement les statistiques.

### Vérification manuelle

**SQLite** :
```bash
sqlite3 data/facturation.db "SELECT 'Clients:', COUNT(*) FROM client;
                              SELECT 'Factures:', COUNT(*) FROM facture;
                              SELECT 'Lignes:', COUNT(*) FROM ligne_facture;"
```

**DuckDB** :
```bash
duckdb data/facturation.duckdb "SELECT 'Clients:', COUNT(*) FROM client;
                                 SELECT 'Factures:', COUNT(*) FROM facture;
                                 SELECT 'Lignes:', COUNT(*) FROM ligne_facture;"
```

**Résultats attendus** :
```
Clients: 100000
Factures: 3000000
Lignes: 24000000
```

---

## 🧪 Test rapide des bases

### Test SQLite

**Windows PowerShell** :
```powershell
sqlite3 data\facturation.db
```

**WSL/Linux** :
```bash
sqlite3 data/facturation.db
```

**Dans le shell SQLite** :
```sql
.timer on
.mode column
.headers on

SELECT COUNT(*) FROM client;
SELECT COUNT(*) FROM facture;
SELECT COUNT(*) FROM ligne_facture;

.quit
```

### Test DuckDB

**Windows PowerShell** :
```powershell
duckdb data\facturation.duckdb
```

**WSL/Linux** :
```bash
duckdb data/facturation.duckdb
```

**Dans le shell DuckDB** :
```sql
.timer on

SELECT COUNT(*) FROM client;
SELECT COUNT(*) FROM facture;
SELECT COUNT(*) FROM ligne_facture;

.quit
```

---

## 🎨 Interfaces Graphiques Alternatives

### Option 1 : DBeaver (Recommandée)

**Interface graphique professionnelle** pour gérer vos bases de données.

🔗 **Guide complet** : **[DBEAVER.md](DBEAVER.md)**

**Avantages** :
- ✅ Interface visuelle moderne
- ✅ Éditeur SQL avec auto-complétion
- ✅ Mesure de performance automatique
- ✅ Export de résultats (CSV, Excel, JSON)
- ✅ Visualisation de plans d'exécution

### Option 2 : DuckDB UI (Web)

**Interface web moderne** dans votre navigateur.

🔗 **Guide complet** : **[DUCKDB-UI.md](DUCKDB-UI.md)**

**Avantages** :
- ✅ Aucune installation (version web)
- ✅ Interface moderne et rapide
- ✅ Timer intégré
- ✅ Export facile
- ✅ Parfait pour DuckDB

### Option 3 : VSCode + Extensions

**Éditeur de code avec extensions SQL.**

1. Installer VSCode
2. Installer extension **"SQLite"** par alexcvzz
3. Installer extension **"DuckDB SQL Tools"**
4. Ouvrir `data/facturation.db` ou `data/facturation.duckdb`

---

## 📊 Données générées

### Schéma de la base

```sql
client (100 000 lignes)
├── client_id       INTEGER PRIMARY KEY
├── nom             TEXT
├── prenom          TEXT
├── email           TEXT
├── telephone       TEXT
├── adresse         TEXT
├── ville           TEXT (18 villes françaises)
├── code_postal     TEXT
├── pays            TEXT
└── date_creation   DATE (2020-2025)

facture (3 000 000 lignes)
├── facture_id      INTEGER PRIMARY KEY
├── client_id       INTEGER → client
├── numero_facture  TEXT UNIQUE
├── date_facture    DATE (2020-2025)
├── date_echeance   DATE
├── montant_ht      REAL
├── montant_tva     REAL
├── montant_ttc     REAL
└── statut          TEXT (BROUILLON, EMISE, PAYEE, ANNULEE)

ligne_facture (~24 000 000 lignes)
├── ligne_id        INTEGER PRIMARY KEY
├── facture_id      INTEGER → facture
├── numero_ligne    INTEGER
├── description     TEXT (25 produits IT)
├── quantite        REAL
├── prix_unitaire   REAL
├── taux_tva        REAL (5.5, 10.0, 20.0)
├── montant_ht      REAL
├── montant_tva     REAL
└── montant_ttc     REAL
```

### Caractéristiques

- **Volume** : ~27M lignes au total (100K clients, 3M factures, 24M lignes)
- **Période** : 2020-2025 (6 ans, 2190 jours)
- **Villes** : 18 villes françaises (Paris, Lyon, Marseille, etc.)
- **Produits** : 25 produits IT/services
- **CA moyen** : 10K-200K€ par facture
- **Statuts** : Distribution réaliste (65% PAYEE, 25% EMISE, 5% BROUILLON, 5% ANNULEE)

### Index créés (pour performance)

```sql
CREATE INDEX idx_facture_client ON facture(client_id);
CREATE INDEX idx_facture_date ON facture(date_facture);
CREATE INDEX idx_facture_statut ON facture(statut);
CREATE INDEX idx_ligne_facture ON ligne_facture(facture_id);
CREATE INDEX idx_client_ville ON client(ville);
```

---

## 🎯 Vérification finale

### Checklist

- [ ] SQLite 3.35+ installé
- [ ] DuckDB 0.9+ installé
- [ ] Dossier `data/` créé
- [ ] `facturation.db` créé (~50-100 Mo)
- [ ] `facturation.duckdb` créé (~20-40 Mo)
- [ ] 5000 clients dans chaque base
- [ ] 150000 factures dans chaque base
- [ ] ~500000 lignes facture dans chaque base
- [ ] Index créés avec succès

### En cas de problème

**Erreur : "sqlite3/duckdb n'est pas reconnu..."**

→ Consultez **[INSTALL.md](INSTALL.md)** pour l'installation complète

**Erreur : "Permission denied" (Linux/WSL)**

```bash
chmod +x setup-database.sh
sudo chmod 777 data/
```

**Données incomplètes**

```bash
# Supprimer et regénérer
rm data/*.db data/*.duckdb

# Windows
.\setup-database.ps1

# Linux/WSL
./setup-database.sh
```

**Script trop lent**

→ Normal : Génération de 500K lignes peut prendre 20-60 secondes selon votre machine

---

## 📊 Statistiques attendues

Après génération, vous devriez avoir :

| Métrique | Valeur |
|----------|--------|
| Clients | 100 000 |
| Factures | 3 000 000 |
| Lignes facture | 24 000 000 |
| Villes | 18 |
| Produits | 25 |
| Période | 2020-2025 (6 ans) |
| Taille SQLite | 2.4 GB |
| Taille DuckDB | 850 MB |
| Temps génération | ~7 minutes |

**Note** : DuckDB est plus petit grâce à la compression columnar.

---

## ⏭️ Prochaine étape

Environnement configuré ? Parfait !

### Option 1 : Interface en Ligne de Commande (CLI)

👉 Passez à **[01-concept-ensembliste.md](01-concept-ensembliste.md)** pour comprendre les opérations ensemblistes.

### Option 2 : Interface Graphique

👉 Consultez **[DBEAVER.md](DBEAVER.md)** ou **[DUCKDB-UI.md](DUCKDB-UI.md)** pour configurer votre interface préférée.

---

## 📚 Récapitulatif des fichiers

| Fichier | Usage |
|---------|-------|
| `setup-database.ps1` | Script PowerShell pour Windows |
| `setup-database.sh` | Script Bash pour Linux/WSL/macOS |
| `INSTALL.md` | Guide d'installation SQLite/DuckDB |
| `DBEAVER.md` | Guide DBeaver (interface graphique) |
| `DUCKDB-UI.md` | Guide DuckDB UI (interface web) |
| `data/setup_database.sql` | Script SQL généré (référence) |

---

**Félicitations ! Votre environnement est prêt. 🎉**
