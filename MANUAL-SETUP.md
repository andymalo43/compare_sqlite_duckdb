# Génération Manuelle des Données - Guide Complet

## 🎯 Objectif

Créer manuellement les bases de données SQLite et DuckDB avec 500K lignes de données de test, **sans aucun script automatique**.

**Durée estimée** : 5-10 minutes d'exécution SQL

---

## 📋 Prérequis

- SQLite 3.35+ installé et accessible en CLI
- DuckDB 0.9.0+ installé et accessible en CLI
- 2 Go d'espace disque libre

---

## 🗂️ Étape 1 : Créer la Structure de Dossiers

### Windows (PowerShell)

```powershell
mkdir ensemblistes-guide
cd ensemblistes-guide
mkdir data, sql
```

### Linux/WSL/macOS (Bash)

```bash
mkdir -p ensemblistes-guide/{data,sql}
cd ensemblistes-guide
```

---

## 📝 Étape 2 : Créer le Script SQL de Génération

Créez un fichier `sql/setup_database.sql` avec le contenu suivant :

```sql
-- ============================================================================
-- GÉNÉRATION MANUELLE DES DONNÉES DE TEST
-- ============================================================================
-- 5K clients, 150K factures, ~500K lignes de facture
-- Exécution : sqlite3 data/facturation.db < sql/setup_database.sql
-- ============================================================================

-- Nettoyage
DROP TABLE IF EXISTS ligne_facture;
DROP TABLE IF EXISTS facture;
DROP TABLE IF EXISTS client;

-- ============================================================================
-- SCHÉMA
-- ============================================================================

CREATE TABLE client (
    client_id INTEGER PRIMARY KEY,
    nom TEXT NOT NULL,
    prenom TEXT NOT NULL,
    email TEXT,
    telephone TEXT,
    adresse TEXT,
    ville TEXT,
    code_postal TEXT,
    pays TEXT,
    date_creation DATE NOT NULL
);

CREATE TABLE facture (
    facture_id INTEGER PRIMARY KEY,
    client_id INTEGER NOT NULL,
    numero_facture TEXT UNIQUE NOT NULL,
    date_facture DATE NOT NULL,
    date_echeance DATE NOT NULL,
    montant_ht REAL NOT NULL,
    montant_tva REAL NOT NULL,
    montant_ttc REAL NOT NULL,
    statut TEXT NOT NULL CHECK (statut IN ('BROUILLON', 'EMISE', 'PAYEE', 'ANNULEE')),
    FOREIGN KEY (client_id) REFERENCES client(client_id)
);

CREATE TABLE ligne_facture (
    ligne_id INTEGER PRIMARY KEY,
    facture_id INTEGER NOT NULL,
    numero_ligne INTEGER NOT NULL,
    description TEXT NOT NULL,
    quantite REAL NOT NULL,
    prix_unitaire REAL NOT NULL,
    taux_tva REAL NOT NULL,
    montant_ht REAL NOT NULL,
    montant_tva REAL NOT NULL,
    montant_ttc REAL NOT NULL,
    FOREIGN KEY (facture_id) REFERENCES facture(facture_id),
    UNIQUE (facture_id, numero_ligne)
);

-- ============================================================================
-- INDEX POUR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_facture_client ON facture(client_id);
CREATE INDEX idx_facture_date ON facture(date_facture);
CREATE INDEX idx_facture_statut ON facture(statut);
CREATE INDEX idx_ligne_facture ON ligne_facture(facture_id);
CREATE INDEX idx_client_ville ON client(ville);

-- ============================================================================
-- GÉNÉRATION DES CLIENTS (5000)
-- ============================================================================

WITH RECURSIVE
  noms(nom) AS (
    VALUES ('Martin'),('Bernard'),('Dubois'),('Thomas'),('Robert'),
           ('Richard'),('Petit'),('Durand'),('Leroy'),('Moreau'),
           ('Simon'),('Laurent'),('Lefebvre'),('Michel'),('Garcia'),
           ('David'),('Bertrand'),('Roux'),('Vincent'),('Fournier')
  ),
  prenoms(prenom) AS (
    VALUES ('Jean'),('Pierre'),('Marie'),('Sophie'),('Luc'),
           ('Anne'),('Paul'),('Julie'),('Marc'),('Céline'),
           ('François'),('Isabelle'),('Jacques'),('Nathalie'),
           ('Philippe'),('Sylvie'),('Antoine'),('Catherine'),
           ('Nicolas'),('Valérie')
  ),
  villes(ville) AS (
    VALUES ('Paris'),('Lyon'),('Marseille'),('Toulouse'),('Nice'),
           ('Nantes'),('Bordeaux'),('Lille'),('Rennes'),('Strasbourg'),
           ('Montpellier'),('Grenoble'),('Dijon'),('Angers'),('Nîmes'),
           ('Villeurbanne'),('Le Mans'),('Aix-en-Provence')
  ),
  numbers(n) AS (
    VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)
  ),
  client_ids(id) AS (
    SELECT n1.n + (n2.n-1)*10 + (n3.n-1)*100 + (n4.n-1)*1000
    FROM numbers n1, numbers n2, numbers n3, numbers n4
    WHERE n1.n + (n2.n-1)*10 + (n3.n-1)*100 + (n4.n-1)*1000 <= 5000
  )
INSERT INTO client
SELECT 
  id,
  (SELECT nom FROM noms ORDER BY RANDOM() LIMIT 1),
  (SELECT prenom FROM prenoms ORDER BY RANDOM() LIMIT 1),
  lower((SELECT prenom FROM prenoms ORDER BY RANDOM() LIMIT 1)) || '.' || 
    lower((SELECT nom FROM noms ORDER BY RANDOM() LIMIT 1)) || '@example.com',
  '0' || (ABS(RANDOM()) % 7 + 1) || substr(printf('%08d', ABS(RANDOM()) % 100000000), 1, 8),
  (ABS(RANDOM()) % 999 + 1) || ' rue de la Paix',
  (SELECT ville FROM villes ORDER BY RANDOM() LIMIT 1),
  printf('%05d', ABS(RANDOM()) % 95000 + 1000),
  'France',
  date('2020-01-01', '+' || (ABS(RANDOM()) % 1800) || ' days')
FROM client_ids;

-- ============================================================================
-- GÉNÉRATION DES FACTURES (150000)
-- ============================================================================

WITH RECURSIVE
  numbers(n) AS (
    VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)
  ),
  facture_ids(id) AS (
    SELECT n1.n + (n2.n-1)*10 + (n3.n-1)*100 + (n4.n-1)*1000 + (n5.n-1)*10000 + (n6.n-1)*100000
    FROM numbers n1, numbers n2, numbers n3, numbers n4, numbers n5, numbers n6
    WHERE n1.n + (n2.n-1)*10 + (n3.n-1)*100 + (n4.n-1)*1000 + (n5.n-1)*10000 + (n6.n-1)*100000 <= 150000
  )
INSERT INTO facture (facture_id, client_id, numero_facture, date_facture, date_echeance, 
                      montant_ht, montant_tva, montant_ttc, statut)
SELECT 
  id,
  (ABS(RANDOM()) % 5000 + 1),
  'FAC-' || strftime('%Y', date('2020-01-01', '+' || (ABS(RANDOM()) % 2190) || ' days')) || 
    '-' || printf('%06d', id),
  date('2020-01-01', '+' || (ABS(RANDOM()) % 2190) || ' days') as df,
  date(df, '+' || ((ABS(RANDOM()) % 4 + 1) * 15) || ' days'),
  0, 0, 0,
  CASE (ABS(RANDOM()) % 100)
    WHEN 0,1,2,3,4 THEN 'BROUILLON'
    WHEN 95,96,97,98,99 THEN 'ANNULEE'
    WHEN 5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29 THEN 'EMISE'
    ELSE 'PAYEE'
  END
FROM facture_ids;

-- ============================================================================
-- GÉNÉRATION DES LIGNES DE FACTURE (~500000)
-- ============================================================================

WITH RECURSIVE
  produits(description) AS (
    VALUES 
      ('Ordinateur portable'),('Souris sans fil'),('Clavier mécanique'),
      ('Écran 27"'),('Webcam HD'),('Casque audio'),('Imprimante laser'),
      ('Disque dur SSD'),('Câble HDMI'),('Hub USB'),('Tapis de souris'),
      ('Lampe LED bureau'),('Chaise ergonomique'),('Bureau ajustable'),
      ('Station d''accueil'),('Tablette graphique'),('Licence logicielle'),
      ('Service support'),('Formation utilisateur'),('Maintenance matériel'),
      ('Hébergement cloud'),('Sauvegarde cloud'),('Antivirus entreprise'),
      ('Suite bureautique'),('Logiciel comptabilité')
  ),
  factures_expanded AS (
    SELECT 
      facture_id,
      (ABS(RANDOM()) % 15 + 1) as nb_lignes
    FROM facture
  ),
  lines_per_facture AS (
    SELECT 
      f.facture_id,
      n.n as numero_ligne
    FROM factures_expanded f
    CROSS JOIN (
      SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
      UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
      UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
    ) n
    WHERE n.n <= f.nb_lignes
  ),
  ligne_ids AS (
    SELECT 
      ROW_NUMBER() OVER () as ligne_id,
      facture_id,
      numero_ligne
    FROM lines_per_facture
  )
INSERT INTO ligne_facture
SELECT 
  ligne_id,
  facture_id,
  numero_ligne,
  (SELECT description FROM produits ORDER BY RANDOM() LIMIT 1) as description,
  (ABS(RANDOM()) % 50 + 1) as quantite,
  ROUND((ABS(RANDOM()) % 4990 + 10) * 1.0, 2) as prix_unitaire,
  CASE (ABS(RANDOM()) % 100)
    WHEN 0,1,2,3,4,5,6,7,8,9 THEN 5.5
    WHEN 10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29 THEN 10.0
    ELSE 20.0
  END as taux_tva,
  ROUND(quantite * prix_unitaire, 2) as montant_ht,
  ROUND(quantite * prix_unitaire * taux_tva / 100, 2) as montant_tva,
  ROUND(quantite * prix_unitaire * (1 + taux_tva / 100), 2) as montant_ttc
FROM ligne_ids;

-- ============================================================================
-- MISE À JOUR DES MONTANTS FACTURES
-- ============================================================================

UPDATE facture
SET 
  montant_ht = (SELECT COALESCE(SUM(montant_ht), 0) FROM ligne_facture WHERE facture_id = facture.facture_id),
  montant_tva = (SELECT COALESCE(SUM(montant_tva), 0) FROM ligne_facture WHERE facture_id = facture.facture_id),
  montant_ttc = (SELECT COALESCE(SUM(montant_ttc), 0) FROM ligne_facture WHERE facture_id = facture.facture_id);

-- ============================================================================
-- STATISTIQUES FINALES
-- ============================================================================

SELECT '=== STATISTIQUES ===' as info;
SELECT 'Clients' as "Table", COUNT(*) as Nombre FROM client
UNION ALL
SELECT 'Factures', COUNT(*) FROM facture
UNION ALL
SELECT 'Lignes facture', COUNT(*) FROM ligne_facture;
```

---

## ⚙️ Étape 3 : Créer la Base SQLite

### Windows (PowerShell)

```powershell
# Se placer dans le dossier du projet
cd ensemblistes-guide

# Exécuter le script SQL (prend 20-60 secondes)
Get-Content sql\setup_database.sql | sqlite3 data\facturation.db

# Vérifier
sqlite3 data\facturation.db "SELECT COUNT(*) as nb_clients FROM client;"
```

### Linux/WSL/macOS (Bash)

```bash
# Se placer dans le dossier du projet
cd ensemblistes-guide

# Exécuter le script SQL (prend 20-60 secondes)
sqlite3 data/facturation.db < sql/setup_database.sql

# Vérifier
sqlite3 data/facturation.db "SELECT COUNT(*) as nb_clients FROM client;"
```

**Sortie attendue** :
```
nb_clients
5000
```

---

## 🦆 Étape 4 : Créer la Base DuckDB

### Option A : Copier depuis SQLite (Recommandée)

Créez un fichier `sql/setup_duckdb.sql` :

```sql
-- ============================================================================
-- CRÉATION BASE DUCKDB DEPUIS SQLITE
-- ============================================================================

-- Charger l'extension SQLite
INSTALL sqlite;
LOAD sqlite;

-- Attacher la base SQLite
ATTACH 'data/facturation.db' AS sqlite_db (TYPE sqlite);

-- Copier les tables
CREATE TABLE client AS SELECT * FROM sqlite_db.client;
CREATE TABLE facture AS SELECT * FROM sqlite_db.facture;
CREATE TABLE ligne_facture AS SELECT * FROM sqlite_db.ligne_facture;

-- Créer les index
CREATE INDEX idx_facture_client ON facture(client_id);
CREATE INDEX idx_facture_date ON facture(date_facture);
CREATE INDEX idx_facture_statut ON facture(statut);
CREATE INDEX idx_ligne_facture ON ligne_facture(facture_id);
CREATE INDEX idx_client_ville ON client(ville);

-- Détacher SQLite
DETACH sqlite_db;

-- Statistiques
SELECT '=== STATISTIQUES DUCKDB ===' as info;
SELECT 'Clients' as "Table", COUNT(*) as Nombre FROM client
UNION ALL
SELECT 'Factures', COUNT(*) FROM facture
UNION ALL
SELECT 'Lignes facture', COUNT(*) FROM ligne_facture;
```

**Exécuter** :

**Windows** :
```powershell
Get-Content sql\setup_duckdb.sql | duckdb data\facturation.duckdb
```

**Linux/WSL/macOS** :
```bash
duckdb data/facturation.duckdb < sql/setup_duckdb.sql
```

### Option B : Exécuter le même script SQL

DuckDB supporte aussi le SQL SQLite, donc vous pouvez réutiliser `setup_database.sql` :

```bash
duckdb data/facturation.duckdb < sql/setup_database.sql
```

---

## ✅ Étape 5 : Vérification Complète

### Script de Vérification

Créez `sql/verify.sql` :

```sql
-- ============================================================================
-- VÉRIFICATION DES DONNÉES
-- ============================================================================

.timer on

SELECT '=== NOMBRE DE LIGNES ===' as info;

SELECT 'Clients' as "Table", COUNT(*) as Nombre FROM client
UNION ALL
SELECT 'Factures', COUNT(*) FROM facture
UNION ALL
SELECT 'Lignes facture', COUNT(*) FROM ligne_facture;

SELECT '' as info;
SELECT '=== RÉPARTITION PAR VILLE ===' as info;

SELECT 
    ville,
    COUNT(*) as nb_clients
FROM client
GROUP BY ville
ORDER BY nb_clients DESC
LIMIT 10;

SELECT '' as info;
SELECT '=== RÉPARTITION PAR STATUT ===' as info;

SELECT 
    statut,
    COUNT(*) as nb_factures,
    ROUND(SUM(montant_ttc), 2) as ca_total
FROM facture
GROUP BY statut
ORDER BY nb_factures DESC;

SELECT '' as info;
SELECT '=== TOP 10 PRODUITS ===' as info;

SELECT 
    description,
    COUNT(*) as nb_ventes,
    ROUND(SUM(montant_ttc), 2) as ca_total
FROM ligne_facture
GROUP BY description
ORDER BY ca_total DESC
LIMIT 10;
```

**Exécuter sur SQLite** :
```bash
sqlite3 data/facturation.db < sql/verify.sql
```

**Exécuter sur DuckDB** :
```bash
duckdb data/facturation.duckdb < sql/verify.sql
```

---

## 📊 Résultats Attendus

### Nombre de lignes

```
Table             | Nombre
------------------|--------
Clients           | 5000
Factures          | 150000
Lignes facture    | ~500000
```

### Répartition par statut

```
statut    | nb_factures | ca_total
----------|-------------|-------------
PAYEE     | ~97500      | ~XXX millions
EMISE     | ~37500      | ~XXX millions
BROUILLON | ~7500       | ~XXX millions
ANNULEE   | ~7500       | ~XXX millions
```

### Tailles de fichiers

```
SQLite  : 50-100 Mo
DuckDB  : 20-40 Mo (compression columnar)
```

---

## 🔧 Dépannage

### Erreur : "no such table"

**Cause** : Script SQL n'a pas été exécuté correctement

**Solution** :
```bash
# Supprimer la base corrompue
rm data/facturation.db

# Ré-exécuter
sqlite3 data/facturation.db < sql/setup_database.sql
```

### Erreur : "extension not found" (DuckDB)

**Cause** : Extension SQLite pas installée

**Solution** :
```sql
-- Dans DuckDB
INSTALL sqlite;
LOAD sqlite;
```

### Script très lent (>5 minutes)

**Cause** : Machine peu puissante ou disque lent

**Solutions** :
- Attendre (normal jusqu'à 5 minutes sur machines lentes)
- Réduire le nombre de lignes dans le script
- Utiliser un SSD si possible

### Erreur : "database is locked"

**Cause** : Autre processus utilise la base

**Solution** :
```bash
# Fermer tous les shells SQLite/DuckDB ouverts
# Puis ré-exécuter
```

---

## ⏭️ Prochaine Étape

Bases de données créées ? Parfait !

👉 Passez à [01-concept-ensembliste.md](01-concept-ensembliste.md) pour commencer l'apprentissage.

---

**Données générées avec succès ! 🎉**
