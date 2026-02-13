# Guide : Utiliser DuckDB UI (Interface Web)

## 🎯 Objectif

Utiliser **DuckDB UI** - une interface web moderne pour exécuter et visualiser les requêtes DuckDB directement dans le navigateur.

---

## 📥 Installation de DuckDB UI

### Option 1 : Via npm (Recommandée)

```bash
# Installer Node.js si pas déjà fait
# Windows: https://nodejs.org/
# WSL/Linux: 
sudo apt install nodejs npm -y

# Installer DuckDB UI globalement
npm install -g @duckdb/duckdb-wasm-app

# Ou localement dans le projet
npm install @duckdb/duckdb-wasm-app
```

### Option 2 : Utiliser l'Interface Web Officielle

**Aucune installation requise !**

1. Aller sur https://shell.duckdb.org/
2. Interface web prête à l'emploi
3. Charger votre base de données

### Option 3 : DuckDB Extension VSCode

```bash
# Installer VSCode
# Puis installer l'extension "DuckDB SQL Tools"
# Depuis le marketplace VSCode
```

---

## 🚀 Méthode 1 : Interface Web Officielle (shell.duckdb.org)

### Étape 1 : Charger la Base de Données

**Option A : Charger depuis fichier local**

1. Aller sur https://shell.duckdb.org/
2. Cliquer sur **"Upload Files"** (📁)
3. Sélectionner `data/facturation.duckdb`
4. La base est maintenant accessible

**Option B : Charger via SQLite**

```sql
-- Dans le shell DuckDB
INSTALL sqlite;
LOAD sqlite;

-- Attacher la base SQLite (si elle est accessible via URL)
ATTACH 'facturation.db' AS sqlite_db (TYPE sqlite);

-- Lister les tables
SHOW TABLES;
```

### Étape 2 : Exécuter des Requêtes

**Interface** :
- Zone de saisie en haut
- Bouton ▶️ **"Run"** ou `Ctrl+Enter`
- Résultats en dessous (tableau formaté)
- **Timer automatique** affiché en bas à droite

**Exemple** :
```sql
-- Simple requête de test
SELECT COUNT(*) as nb_clients FROM client;

-- Résultat avec temps : ⏱ Executed in 0.012s
```

### Étape 3 : Benchmark EXCEPT

```sql
-- ============================================================================
-- BENCHMARK : EXCEPT - Clients perdus 2024→2025
-- ============================================================================

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE'

EXCEPT

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025
  AND f.statut = 'PAYEE';
```

**Cliquer sur ▶️ Run**

**Résultat** : Le temps s'affiche automatiquement (ex: `⏱ 0.234s`)

---

## 🚀 Méthode 2 : Serveur Local avec DuckDB Shell

### Installation

```bash
# Installer DuckDB CLI si pas déjà fait (voir INSTALL.md)

# Vérifier l'installation
duckdb --version
```

### Lancer le Shell Interactif

```bash
# Ouvrir la base de données
duckdb data/facturation.duckdb
```

**Interface** :
```
v1.0.0
Enter ".help" for usage hints.
D 
```

### Activer le Timer

```sql
-- Dans le shell DuckDB
.timer on
.mode line
```

### Exécuter des Benchmarks

```sql
-- Requête avec timer actif
SELECT COUNT(*) FROM client;

-- Affiche :
-- Run Time: real 0.002 user 0.000000 sys 0.001000
```

### Charger un Script SQL

```bash
# Depuis le terminal
duckdb data/facturation.duckdb < sql/benchmark_01_pool_complet.sql

# Ou dans le shell DuckDB
D .read sql/benchmark_01_pool_complet.sql
```

---

## 🚀 Méthode 3 : VSCode avec Extension DuckDB

### Installation de l'Extension

1. Ouvrir VSCode
2. `Ctrl+Shift+X` → Extensions
3. Chercher **"DuckDB SQL Tools"**
4. Cliquer sur **Install**

### Configuration

1. `Ctrl+Shift+P` → **"DuckDB: New Connection"**
2. Sélectionner `data/facturation.duckdb`
3. Nom de connexion : `facturation`

### Exécuter des Requêtes

**Créer un fichier SQL** :

1. Créer `benchmark_test.sql`
2. Écrire la requête :

```sql
-- Activer le timing
.timer on

-- Requête de test
SELECT 
    ville,
    COUNT(*) as nb_clients
FROM client
GROUP BY ville
ORDER BY nb_clients DESC
LIMIT 10;
```

3. Clic droit → **"Run on Active Connection"**
4. Résultats s'affichent dans le panneau de droite
5. **Temps affiché** en bas de la fenêtre

### Avantages VSCode

- ✅ **Auto-complétion** des tables et colonnes
- ✅ **Syntax highlighting** avancé
- ✅ **Multi-fenêtres** pour comparer SQLite vs DuckDB
- ✅ **Git integration** pour versionner les scripts
- ✅ **Résultats exportables** en CSV/JSON

---

## 📊 Interface Web Avancée avec Python (Optionnel)

### Streamlit + DuckDB

**Installation** :
```bash
pip install streamlit duckdb pandas plotly
```

**Script `duckdb_ui.py`** :

```python
import streamlit as st
import duckdb
import pandas as pd
import time

st.set_page_config(page_title="DuckDB Benchmark UI", layout="wide")

st.title("🦆 DuckDB Benchmark Interface")

# Connexion
@st.cache_resource
def get_connection():
    return duckdb.connect('data/facturation.duckdb')

conn = get_connection()

# Zone de requête
st.subheader("📝 SQL Query")
query = st.text_area("Enter your SQL query:", height=200, value="""
SELECT 
    ville,
    COUNT(*) as nb_clients,
    ROUND(AVG(montant_ttc), 2) as ca_moyen
FROM client c
JOIN facture f USING (client_id)
WHERE f.statut = 'PAYEE'
GROUP BY ville
ORDER BY nb_clients DESC
LIMIT 10;
""")

if st.button("▶️ Execute Query"):
    try:
        # Mesurer le temps
        start = time.time()
        result = conn.execute(query).df()
        duration = time.time() - start
        
        # Afficher le résultat
        st.success(f"⏱ Executed in {duration:.3f}s")
        st.dataframe(result, use_container_width=True)
        
        # Visualisation si colonnes numériques
        numeric_cols = result.select_dtypes(include=['number']).columns
        if len(numeric_cols) > 0:
            st.subheader("📊 Visualization")
            chart_col = st.selectbox("Select column to chart:", numeric_cols)
            st.bar_chart(result.set_index(result.columns[0])[chart_col])
            
    except Exception as e:
        st.error(f"Error: {e}")

# Statistiques de la base
st.sidebar.subheader("📊 Database Stats")
stats = conn.execute("""
    SELECT 'Clients' as table_name, COUNT(*) as count FROM client
    UNION ALL
    SELECT 'Factures', COUNT(*) FROM facture
    UNION ALL
    SELECT 'Lignes facture', COUNT(*) FROM ligne_facture
""").df()
st.sidebar.dataframe(stats)
```

**Lancement** :
```bash
streamlit run duckdb_ui.py
```

**Résultat** : Interface web sur http://localhost:8501

---

## 📈 Workflow de Benchmark avec DuckDB UI

### Scénario : Comparer SQLite vs DuckDB

**Étape 1 : Préparer deux fenêtres**

- **Fenêtre 1** : DuckDB UI (https://shell.duckdb.org/)
- **Fenêtre 2** : Votre éditeur SQL préféré pour SQLite

**Étape 2 : Exécuter la même requête**

**DuckDB UI** :
```sql
.timer on

SELECT COUNT(*) FROM facture WHERE YEAR(date_facture) = 2024;
-- Temps : ⏱ 0.015s
```

**SQLite** :
```bash
sqlite3 data/facturation.db
.timer on
SELECT COUNT(*) FROM facture WHERE strftime('%Y', date_facture) = '2024';
-- Run Time: real 0.234 user 0.120000 sys 0.089000
```

**Étape 3 : Documenter**

| Requête | SQLite | DuckDB | Speedup |
|---------|--------|--------|---------|
| COUNT avec YEAR | 0.234s | 0.015s | **15.6x** |

---

## 🎨 Fonctionnalités Avancées

### 1. Export de Résultats

**DuckDB Shell** :
```sql
-- Export CSV
COPY (SELECT * FROM client LIMIT 100) TO 'results/clients.csv' (HEADER, DELIMITER ',');

-- Export Parquet (ultra-compressé)
COPY (SELECT * FROM facture) TO 'results/factures.parquet' (FORMAT PARQUET);

-- Export JSON
COPY (SELECT * FROM client LIMIT 10) TO 'results/clients.json';
```

### 2. Visualisation des Plans d'Exécution

```sql
EXPLAIN
SELECT c.nom, COUNT(*) as nb_factures
FROM client c
JOIN facture f ON c.client_id = f.client_id
GROUP BY c.nom
ORDER BY nb_factures DESC
LIMIT 10;
```

**Résultat** : Arbre d'exécution avec coûts estimés

### 3. Analyse de Performance

```sql
-- Activer le profiling
PRAGMA enable_profiling;

-- Exécuter une requête
SELECT ... ;

-- Voir le profil
PRAGMA profiling_output;
```

### 4. Comparaison Visuelle SQLite vs DuckDB

**Créer une table de comparaison** :

```sql
-- Dans DuckDB
CREATE TABLE benchmark_results (
    query_name VARCHAR,
    sqlite_time DOUBLE,
    duckdb_time DOUBLE
);

INSERT INTO benchmark_results VALUES
    ('EXCEPT simple', 2.45, 0.32),
    ('UNION ALL', 1.23, 0.18),
    ('INTERSECT', 3.56, 0.45);

-- Analyse
SELECT 
    query_name,
    sqlite_time,
    duckdb_time,
    ROUND(sqlite_time / duckdb_time, 2) as speedup
FROM benchmark_results
ORDER BY speedup DESC;
```

---

## 🔧 Configuration Optimale

### DuckDB Shell : Fichier `.duckdbrc`

Créer `~/.duckdbrc` (Linux/WSL) ou `C:\Users\VotreNom\.duckdbrc` (Windows) :

```sql
.timer on
.mode line
.maxrows 100
.width auto

-- Charger les extensions courantes
INSTALL sqlite;
LOAD sqlite;
```

### VSCode : Configuration Optimale

**settings.json** :
```json
{
    "duckdb.defaultConnection": "data/facturation.duckdb",
    "duckdb.queryResultsLimit": 1000,
    "duckdb.enableTimer": true,
    "editor.formatOnSave": true
}
```

---

## 📊 Dashboard de Benchmark

### Script PowerShell pour Générer un Rapport HTML

```powershell
# benchmark-report.ps1

$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Benchmark Results</title>
    <style>
        body { font-family: Arial; margin: 40px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        .fast { background-color: #d4edda; }
        .slow { background-color: #f8d7da; }
    </style>
</head>
<body>
    <h1>🦆 Benchmark SQLite vs DuckDB</h1>
    <table>
        <tr>
            <th>Query</th>
            <th>SQLite (s)</th>
            <th>DuckDB (s)</th>
            <th>Speedup</th>
        </tr>
        <tr class="fast">
            <td>EXCEPT simple</td>
            <td>2.45</td>
            <td>0.32</td>
            <td><strong>7.7x</strong></td>
        </tr>
        <!-- Ajouter vos résultats ici -->
    </table>
</body>
</html>
"@

$html | Out-File -FilePath "benchmark-report.html"
Start-Process "benchmark-report.html"
```

---

## 🎓 Cas d'Usage : Benchmark Complet

### Script Bash Automatisé

```bash
#!/bin/bash
# benchmark-auto.sh

echo "=== Benchmark DuckDB ==="

QUERIES=(
    "SELECT COUNT(*) FROM client"
    "SELECT COUNT(*) FROM facture WHERE YEAR(date_facture) = 2024"
    "SELECT ville, COUNT(*) FROM client GROUP BY ville"
)

for query in "${QUERIES[@]}"; do
    echo "Query: $query"
    echo ".timer on
    $query" | duckdb data/facturation.duckdb
    echo ""
done
```

---

## 📚 Ressources

- [DuckDB Shell Docs](https://duckdb.org/docs/api/cli)
- [DuckDB Web Shell](https://shell.duckdb.org/)
- [DuckDB VSCode Extension](https://marketplace.visualstudio.com/items?itemName=evidence-dev.sqltools-duckdb-driver)
- [Streamlit](https://streamlit.io/)

---

## ⏭️ Prochaine Étape

Interface web configurée ? Parfait !

👉 Retournez à `01-concept-ensembliste.md` pour commencer les benchmarks

---

**DuckDB UI prête ! Vous avez maintenant une interface moderne pour vos analyses. 🎨**
