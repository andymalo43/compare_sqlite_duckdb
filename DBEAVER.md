# Guide : Utiliser DBeaver pour les Benchmarks

## 🎯 Objectif

Utiliser **DBeaver** comme interface graphique pour exécuter et mesurer les requêtes SQL sur SQLite et DuckDB.

---

## 📥 Installation de DBeaver

### Windows

**Méthode 1 : Winget**
```powershell
winget install dbeaver.dbeaver
```

**Méthode 2 : Chocolatey**
```powershell
choco install dbeaver -y
```

**Méthode 3 : Téléchargement Direct**
1. Aller sur https://dbeaver.io/download/
2. Télécharger "DBeaver Community" pour Windows
3. Installer l'exécutable `.exe`

### Linux/WSL

```bash
# Ubuntu/Debian
sudo add-apt-repository ppa:serge-rider/dbeaver-ce
sudo apt update
sudo apt install dbeaver-ce -y

# Ou téléchargement direct
wget https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
sudo dpkg -i dbeaver-ce_latest_amd64.deb
```

### macOS

```bash
brew install --cask dbeaver-community
```

---

## 🔌 Configuration des Connexions

### 1. Connexion SQLite

**Étape 1 : Créer une nouvelle connexion**

1. Ouvrir DBeaver
2. Cliquer sur **"Nouvelle connexion"** (🔌 ou `Ctrl+Shift+N`)
3. Sélectionner **SQLite** dans la liste
4. Cliquer sur **"Suivant"**

**Étape 2 : Configurer la connexion**

```
Path/Database: [Parcourir] → Sélectionner data/facturation.db
Database name: facturation_sqlite
```

**Étape 3 : Tester et enregistrer**

1. Cliquer sur **"Tester la connexion"**
2. Si demandé, télécharger le driver SQLite JDBC
3. Cliquer sur **"Terminer"**

### 2. Connexion DuckDB

**Étape 1 : Installer le driver DuckDB**

DBeaver ne supporte pas nativement DuckDB. Deux options :

#### Option A : Via l'extension Community (Recommandée)

1. `Database` → `Driver Manager`
2. Cliquer sur **"Nouveau"**
3. Remplir :
   ```
   Driver Name: DuckDB
   Class Name: org.duckdb.DuckDBDriver
   URL Template: jdbc:duckdb:{file}
   Default Port: [laisser vide]
   ```
4. Onglet **"Bibliothèques"** → **"Ajouter un fichier"**
5. Télécharger `duckdb_jdbc.jar` depuis https://repo1.maven.org/maven2/org/duckdb/duckdb_jdbc/
6. Sélectionner la dernière version (ex: `duckdb_jdbc-1.0.0.jar`)
7. Cliquer sur **"OK"**

#### Option B : Utiliser le driver générique

1. `Database` → `New Database Connection`
2. Sélectionner **"Generic"** → **"Generic JDBC"**
3. Configurer :
   ```
   Driver Name: DuckDB
   JDBC URL: jdbc:duckdb:data/facturation.duckdb
   Username: [vide]
   Password: [vide]
   ```
4. Onglet **"Driver Properties"** → Ajouter le `duckdb_jdbc.jar`

**Étape 2 : Créer la connexion**

1. Nouvelle connexion → **DuckDB**
2. Database file: `data/facturation.duckdb`
3. Tester et enregistrer

---

## ⚡ Exécuter des Requêtes avec Mesure de Performance

### Activer le Timing dans DBeaver

**Méthode 1 : Via l'éditeur SQL**

1. Ouvrir un éditeur SQL (`Ctrl+]` ou clic droit sur connexion → **"Éditeur SQL"**)
2. Écrire votre requête
3. Exécuter avec `Ctrl+Enter`
4. **Le temps s'affiche automatiquement** dans l'onglet résultats (en bas à droite)

**Méthode 2 : Activer l'affichage détaillé**

1. `Fenêtre` → `Préférences`
2. `Éditeurs` → `Éditeur SQL`
3. Cocher **"Afficher le temps d'exécution"**
4. Cocher **"Afficher les statistiques d'exécution"**

### Exemple : Benchmark EXCEPT

**Créer un script SQL**

1. Clic droit sur connexion SQLite → **"Éditeur SQL"**
2. Coller la requête :

```sql
-- ============================================================================
-- BENCHMARK 1 : EXCEPT - Clients perdus 2024→2025
-- ============================================================================

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE strftime('%Y', f.date_facture) = '2024'
  AND f.statut = 'PAYEE'

EXCEPT

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE strftime('%Y', f.date_facture) = '2025'
  AND f.statut = 'PAYEE';
```

3. Sélectionner tout (`Ctrl+A`)
4. Exécuter (`Ctrl+Enter`)
5. **Noter le temps affiché** en bas à droite (ex: `Exécuté en 2.456s`)

**Répéter sur DuckDB**

1. Ouvrir éditeur SQL sur connexion DuckDB
2. Coller **la même requête** (adapter si besoin : `YEAR()` au lieu de `strftime()`)
3. Exécuter et comparer le temps

### Tableau de Comparaison dans DBeaver

Créer un fichier SQL `benchmark_results.sql` :

```sql
-- ============================================================================
-- TABLEAU DE SUIVI DES BENCHMARKS
-- ============================================================================
-- Copiez cette structure et remplissez manuellement les temps

/*
┌─────────────────────┬──────────────┬──────────────┬───────────┐
│ Benchmark           │ SQLite (s)   │ DuckDB (s)   │ Speedup   │
├─────────────────────┼──────────────┼──────────────┼───────────┤
│ EXCEPT simple       │ ________     │ ________     │ ______x   │
│ UNION ALL multi     │ ________     │ ________     │ ______x   │
│ INTERSECT agrégé    │ ________     │ ________     │ ______x   │
│ Pattern complet     │ ________     │ ________     │ ______x   │
│ Gros volume         │ ________     │ ________     │ ______x   │
└─────────────────────┴──────────────┴──────────────┴───────────┘

Calcul du Speedup : Temps_SQLite / Temps_DuckDB
*/
```

---

## 📊 Fonctionnalités Avancées de DBeaver

### 1. Plan d'Exécution (EXPLAIN)

**SQLite** :
```sql
EXPLAIN QUERY PLAN
SELECT DISTINCT c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE';
```

Dans DBeaver :
1. Exécuter la requête avec `EXPLAIN QUERY PLAN`
2. Onglet **"Résultats"** affiche le plan
3. Chercher **"USING INDEX"** pour vérifier l'utilisation d'index

**DuckDB** :
```sql
EXPLAIN
SELECT DISTINCT c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE';
```

### 2. Export des Résultats

**Export CSV pour analyse** :

1. Exécuter une requête
2. Clic droit dans les résultats → **"Exporter les données"**
3. Choisir **CSV**
4. Définir le chemin : `benchmarks/result_except_sqlite.csv`
5. Répéter pour DuckDB : `benchmarks/result_except_duckdb.csv`

**Comparer dans Excel** :
- Ouvrir les deux CSV
- Créer un graphique comparatif

### 3. Scripts SQL avec Variables

DBeaver supporte les variables SQL :

```sql
-- ============================================================================
-- Script paramétré pour tests multiples
-- ============================================================================

-- Variable d'année
SET @annee = 2024;

-- Requête utilisant la variable
SELECT COUNT(*) as nb_factures
FROM facture
WHERE strftime('%Y', date_facture) = @annee
  AND statut = 'PAYEE';

-- Changer l'année et ré-exécuter
SET @annee = 2025;

SELECT COUNT(*) as nb_factures
FROM facture
WHERE strftime('%Y', date_facture) = @annee
  AND statut = 'PAYEE';
```

### 4. Exécution par Lots (Batch)

**Exécuter tous les benchmarks d'un coup** :

1. Créer un fichier `all_benchmarks.sql`
2. Y coller toutes les requêtes de benchmark
3. Ajouter des commentaires séparateurs :

```sql
-- ============================================================================
-- BENCHMARK 1
-- ============================================================================
SELECT ...;

-- ============================================================================
-- BENCHMARK 2
-- ============================================================================
SELECT ...;
```

4. `Ctrl+Shift+Enter` pour exécuter tout le script
5. Onglets multiples s'ouvrent avec chaque résultat

### 5. Comparaison Visuelle des Résultats

**Créer une vue consolidée** :

```sql
-- Dans SQLite
CREATE VIEW v_stats_sqlite AS
SELECT 
    'SQLite' as db,
    COUNT(DISTINCT client_id) as nb_clients,
    COUNT(DISTINCT facture_id) as nb_factures,
    ROUND(SUM(montant_ttc), 2) as ca_total
FROM facture f
JOIN client c USING (client_id)
WHERE f.statut = 'PAYEE';

-- Dans DuckDB (même requête)
CREATE VIEW v_stats_duckdb AS
SELECT 
    'DuckDB' as db,
    COUNT(DISTINCT client_id) as nb_clients,
    COUNT(DISTINCT facture_id) as nb_factures,
    ROUND(SUM(montant_ttc), 2) as ca_total
FROM facture f
JOIN client c USING (client_id)
WHERE f.statut = 'PAYEE';

-- Comparer
SELECT * FROM v_stats_sqlite
UNION ALL
SELECT * FROM v_stats_duckdb;
```

---

## 📈 Workflow Recommandé de Benchmark

### Étape 1 : Préparation

1. Ouvrir DBeaver
2. Se connecter à SQLite **et** DuckDB (deux onglets)
3. Créer un dossier `Benchmarks` dans chaque connexion (clic droit → **Nouveau dossier**)

### Étape 2 : Exécution

Pour chaque requête benchmark :

1. **SQLite** : Coller requête → Exécuter → Noter temps
2. **DuckDB** : Coller requête → Exécuter → Noter temps
3. Calculer speedup : `Temps_SQLite / Temps_DuckDB`

### Étape 3 : Documentation

Créer un fichier `RESULTS.md` :

```markdown
# Résultats Benchmarks

## Environnement
- CPU: [votre CPU]
- RAM: [votre RAM]
- OS: Windows 11 / Ubuntu 22.04
- SQLite: 3.45.0
- DuckDB: 1.0.0

## Résultats

| Benchmark | SQLite (s) | DuckDB (s) | Speedup |
|-----------|------------|------------|---------|
| EXCEPT simple | 2.45 | 0.32 | 7.7x |
| UNION ALL | 1.23 | 0.18 | 6.8x |
| INTERSECT | 3.56 | 0.45 | 7.9x |
```

---

## 🎨 Personnalisation de DBeaver

### Thème Sombre (Recommandé)

1. `Fenêtre` → `Préférences`
2. `Général` → `Apparence`
3. Thème : **Dark**

### Raccourcis Clavier Utiles

| Action | Raccourci |
|--------|-----------|
| Nouvel éditeur SQL | `Ctrl+]` |
| Exécuter requête | `Ctrl+Enter` |
| Exécuter tout le script | `Ctrl+Shift+Enter` |
| Formatter SQL | `Ctrl+Shift+F` |
| Commenter ligne | `Ctrl+/` |
| Auto-complétion | `Ctrl+Space` |

### Formatter SQL Automatique

1. `Fenêtre` → `Préférences`
2. `Éditeurs` → `Formatteur SQL`
3. Choisir le style : **SQL Standard**
4. Appliquer avec `Ctrl+Shift+F`

---

## 🔧 Dépannage

### DBeaver ne trouve pas la base de données

**Solution** : Chemin absolu
```
Windows: C:\Users\VotreNom\projects\data\facturation.db
WSL: /mnt/c/Users/VotreNom/projects/data/facturation.db
Linux: /home/username/projects/data/facturation.db
```

### Erreur "Driver class not found"

**Solution** : Télécharger le driver JDBC

1. Clic droit sur connexion → **Modifier la connexion**
2. Onglet **"Bibliothèques"** → **"Télécharger"**
3. DBeaver télécharge automatiquement

### DuckDB : Erreur "Extension not found"

**Solution** : Précharger les extensions

```sql
-- Dans DuckDB
INSTALL sqlite;
LOAD sqlite;
```

---

## 📚 Ressources

- [DBeaver Documentation](https://dbeaver.com/docs/)
- [DBeaver GitHub](https://github.com/dbeaver/dbeaver)
- [DuckDB JDBC Driver](https://repo1.maven.org/maven2/org/duckdb/duckdb_jdbc/)

---

## ⏭️ Prochaine Étape

Maintenant que DBeaver est configuré :

👉 Consultez `DUCKDB-UI.md` pour une interface web alternative

---

**DBeaver configuré ! Vous pouvez maintenant exécuter vos benchmarks. 🚀**
