# Guide : DuckDB UI Extension (Interface Web Officielle)

## 🎯 Objectif

Utiliser **DuckDB UI** - l'interface web officielle intégrée à DuckDB via l'extension `ui` pour exécuter, visualiser et benchmarker vos requêtes SQL.

**Nouveauté DuckDB v1.2.1+** : Interface notebook complète disponible nativement !

---

## 📥 Installation de DuckDB avec UI

### Prérequis

- **DuckDB CLI** v1.2.1 ou supérieur
- Connexion Internet (première fois uniquement pour télécharger l'extension)

### Vérification de la version

```bash
duckdb --version
```

**Requis** : v1.2.1 minimum

Si version antérieure, consultez [INSTALL.md](INSTALL.md) pour mettre à jour.

---

## 🚀 Méthode 1 : Lancement Rapide depuis CLI

### Option A : Ligne de commande (Recommandée)

**Windows PowerShell** :
```powershell
duckdb -ui
```

**Linux/WSL/macOS** :
```bash
duckdb -ui
```

**Ce qui se passe automatiquement** :
1. ✅ DuckDB vérifie si l'extension `ui` est installée
2. ✅ Télécharge l'extension si nécessaire (première fois uniquement)
3. ✅ Démarre un serveur HTTP local sur `http://localhost:4213`
4. ✅ Ouvre votre navigateur par défaut

**Résultat** : Interface DuckDB UI s'ouvre dans votre navigateur !

### Option B : Avec une base existante

**Ouvrir une base spécifique** :

**Windows** :
```powershell
duckdb data\facturation.duckdb -ui
```

**Linux/WSL/macOS** :
```bash
duckdb data/facturation.duckdb -ui
```

**Avantage** : Vos données sont immédiatement disponibles dans l'interface.

---

## 🚀 Méthode 2 : Lancement depuis SQL

### Dans le shell DuckDB

```bash
duckdb data/facturation.duckdb
```

**Puis dans le shell** :
```sql
-- Installer l'extension (si pas déjà fait)
INSTALL ui;

-- Charger l'extension
LOAD ui;

-- Démarrer l'interface
CALL start_ui();
```

**Sortie** :
```
┌───────────────────────────────────┐
│ UI available at http://localhost:4213
│ Opening browser...
└───────────────────────────────────┘
```

### Alternative : Serveur sans ouvrir le navigateur

```sql
-- Démarrer seulement le serveur
CALL start_ui_server();

-- Obtenir l'URL
SELECT get_ui_url();
```

**Résultat** :
```
┌─────────────────────────┐
│     get_ui_url()        │
├─────────────────────────┤
│ http://localhost:4213   │
└─────────────────────────┘
```

Puis ouvrez manuellement `http://localhost:4213` dans votre navigateur.

---

## 🎨 Interface DuckDB UI

### Vue d'ensemble

L'interface se divise en plusieurs zones :

```
┌─────────────┬───────────────────────────────────┬──────────────┐
│             │                                   │              │
│  Databases  │       SQL Notebook               │   Settings   │
│  (Sidebar)  │       (Center)                   │   (Right)    │
│             │                                   │              │
│  • client   │  Cell 1:                         │  • Export    │
│  • facture  │  SELECT COUNT(*) FROM client;    │  • Share     │
│  • ligne_   │  ┌──────────┐                    │  • Format    │
│    facture  │  │  5000    │                    │              │
│             │  └──────────┘                    │              │
│             │                                   │              │
│             │  Cell 2:                         │              │
│             │  SELECT * FROM facture LIMIT 10; │              │
│             │  [Table Results]                 │              │
│             │                                   │              │
└─────────────┴───────────────────────────────────┴──────────────┘
```

### 1. Sidebar Gauche : Bases de Données

- 📁 **Attached Databases** : Liste des bases chargées
- 📊 **Tables** : Cliquer pour voir le schéma
- 🔍 **Preview** : Aperçu rapide des données (LIMIT 10)

### 2. Zone Centrale : Notebook SQL

- **Cells SQL** : Éditeur avec syntaxe highlighting
- **Résultats** : Affichage tableau interactif
- **Timer automatique** : ⏱️ Temps d'exécution affiché
- **Auto-complétion** : Tables et colonnes

### 3. Panneau Droit : Actions

- **Export** : CSV, JSON, Clipboard
- **Visualizations** : Graphiques (barres, lignes, etc.)
- **Format SQL** : Auto-formattage du code

---

## 📊 Utilisation pour les Benchmarks

### Activer le Timer (Automatique)

**Le timer est activé par défaut** dans DuckDB UI !

Chaque requête affiche :
```
✓ Executed in 0.234s
```

### Exemple 1 : Benchmark EXCEPT

**Créer un nouveau notebook** :
1. Cliquer sur **"+ New Cell"**
2. Écrire la requête :

```sql
-- Clients perdus 2024→2025
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

3. Exécuter avec **Cmd+Enter** (Mac) ou **Ctrl+Enter** (Windows/Linux)
4. **Temps affiché automatiquement** : `✓ Executed in 0.234s`

### Exemple 2 : Comparer avec SQLite

**Terminal 1 - DuckDB UI** (déjà ouvert)

**Terminal 2 - SQLite CLI** :
```bash
sqlite3 data/facturation.db
.timer on

-- Même requête que ci-dessus
```

**Comparer les temps** :
- DuckDB UI : `✓ Executed in 0.234s`
- SQLite CLI : `Run Time: real 1.567 user 0.890000 sys 0.567000`

**Speedup** : 1.567 / 0.234 = **6.7x plus rapide** !

---

## 🗂️ Fonctionnalités Avancées

### 1. Charger des Données Supplémentaires

```sql
-- Depuis un fichier CSV
CREATE TABLE ventes AS 
SELECT * FROM read_csv('data/ventes.csv');

-- Depuis Parquet
CREATE TABLE stats AS 
SELECT * FROM read_parquet('data/stats.parquet');

-- Depuis une URL
CREATE TABLE remote AS 
SELECT * FROM read_csv('https://example.com/data.csv');
```

**Résultat** : Tables apparaissent immédiatement dans la sidebar.

### 2. Visualisations Intégrées

**Créer un graphique** :

```sql
-- Requête pour graphique
SELECT 
    ville,
    COUNT(*) as nb_clients
FROM client
GROUP BY ville
ORDER BY nb_clients DESC
LIMIT 10;
```

**Après exécution** :
1. Cliquer sur l'icône **📊 Visualize**
2. Choisir le type : **Bar Chart**
3. X-axis : `ville`
4. Y-axis : `nb_clients`

**Résultat** : Graphique interactif !

### 3. Export de Résultats

**Options d'export** :
- **📋 Clipboard** : Copier/coller direct
- **💾 CSV** : Téléchargement fichier
- **📄 JSON** : Format structuré
- **📊 Parquet** : Format optimisé

**Exemple** :
```sql
-- Exporter vers CSV
COPY (
    SELECT ville, COUNT(*) as nb
    FROM client
    GROUP BY ville
) TO 'results/stats_ville.csv' (HEADER, DELIMITER ',');
```

### 4. Notebooks Sauvegardés

**Les notebooks sont persistants** :
- Sauvegardés automatiquement dans `~/.duckdb/extension_data/ui/ui.db`
- Retrouvez vos requêtes à la prochaine ouverture
- Organisez vos analyses en notebooks séparés

### 5. Multi-Cellules

**Organiser votre workflow** :

```sql
-- Cell 1 : Préparation
CREATE TEMP TABLE stats_temp AS
SELECT ville, COUNT(*) as nb FROM client GROUP BY ville;

-- Cell 2 : Analyse
SELECT * FROM stats_temp WHERE nb > 100 ORDER BY nb DESC;

-- Cell 3 : Visualisation
SELECT ville, nb FROM stats_temp ORDER BY nb DESC LIMIT 10;
```

**Avantage** : Exécution séquentielle ou sélective.

---

## ⚙️ Configuration Avancée

### Changer le Port par Défaut

```sql
-- Avant de lancer l'UI
SET ui_port = 8080;
CALL start_ui();
```

**Accès** : `http://localhost:8080`

### Mode Serveur Uniquement

```sql
-- Démarrer sans ouvrir le navigateur
CALL start_ui_server();
```

**Utilité** : Environnements serveur sans interface graphique.

### Configuration via Variables d'Environnement

**Windows PowerShell** :
```powershell
$env:ui_port = "8080"
duckdb -ui
```

**Linux/WSL/macOS** :
```bash
export ui_port=8080
duckdb -ui
```

### Intervalle de Polling

L'UI vérifie les changements de base toutes les 284ms par défaut :

```sql
-- Ajuster l'intervalle (en millisecondes)
SET ui_polling_interval = 500;

-- Désactiver (non recommandé)
SET ui_polling_interval = 0;
```

---

## 🔒 Sécurité et Données

### Données 100% Locales

**Par défaut** :
- ✅ Toutes les requêtes exécutées localement
- ✅ Aucune donnée envoyée sur Internet
- ✅ Serveur HTTP local uniquement (`localhost`)

**Assets UI** :
- Interface chargée depuis `https://ui.duckdb.org`
- Seulement HTML/CSS/JavaScript (pas vos données)

### Mode Hors-Ligne (Futur)

DuckDB travaille sur un mode hors-ligne complet.

**Actuellement** : Première connexion Internet requise pour télécharger l'extension.

---

## 📈 Workflow de Benchmark Complet

### Scénario : Comparer 5 Requêtes

**Étape 1 : Créer un notebook "Benchmarks"**

**Cell 1 : EXCEPT Simple**
```sql
-- Benchmark 1
SELECT DISTINCT c.client_id, c.nom
FROM client c
JOIN facture f USING (client_id)
WHERE YEAR(f.date_facture) = 2024
EXCEPT
SELECT DISTINCT c.client_id, c.nom
FROM client c
JOIN facture f USING (client_id)
WHERE YEAR(f.date_facture) = 2025;
```
**Temps** : `✓ Executed in 0.234s`

**Cell 2 : UNION ALL Multi-Années**
```sql
-- Benchmark 2
SELECT 2024 as annee, COUNT(*) as nb, SUM(montant_ttc) as ca
FROM facture WHERE YEAR(date_facture) = 2024
UNION ALL
SELECT 2025, COUNT(*), SUM(montant_ttc)
FROM facture WHERE YEAR(date_facture) = 2025;
```
**Temps** : `✓ Executed in 0.156s`

**Cell 3 : INTERSECT Agrégé**
```sql
-- Benchmark 3
SELECT c.client_id, c.nom, SUM(f.montant_ttc) as ca
FROM client c
JOIN facture f USING (client_id)
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom
HAVING SUM(f.montant_ttc) > 100000
INTERSECT
SELECT c.client_id, c.nom, SUM(f.montant_ttc)
FROM client c
JOIN facture f USING (client_id)
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom
HAVING SUM(f.montant_ttc) > 100000;
```
**Temps** : `✓ Executed in 0.421s`

**Cell 4 : Tableau Récapitulatif**
```sql
-- Résumé Benchmarks
SELECT 'DuckDB UI' as platform,
       'EXCEPT simple' as query,
       0.234 as time_seconds
UNION ALL
SELECT 'DuckDB UI', 'UNION ALL', 0.156
UNION ALL
SELECT 'DuckDB UI', 'INTERSECT', 0.421;
```

**Cell 5 : Visualisation**
```sql
-- Graphique comparatif
SELECT 
    query,
    time_seconds
FROM (VALUES
    ('EXCEPT', 0.234),
    ('UNION ALL', 0.156),
    ('INTERSECT', 0.421)
) as t(query, time_seconds);
```

**→ Créer un bar chart avec ces résultats**

---

## 🔧 Dépannage

### Erreur : "UI already running"

**Cause** : Une autre instance DuckDB utilise déjà l'extension UI.

**Solution** :
```bash
# Trouver le processus
ps aux | grep duckdb

# Terminer le processus
kill <PID>

# Ou simplement fermer l'autre terminal
```

### Le Navigateur ne S'ouvre Pas

**Solution** :
```sql
-- Récupérer l'URL manuellement
SELECT get_ui_url();

-- Ouvrir manuellement dans le navigateur
-- http://localhost:4213
```

### Erreur : "No catalog + schema named 'memory.main'"

**Cause** : Tentative d'utiliser UI sur une base en lecture seule.

**Solution** :
```bash
# Utiliser une base modifiable ou en mémoire
duckdb :memory: -ui

# Ou créer une nouvelle base
duckdb new_database.duckdb -ui
```

### Extension Non Trouvée

**Cause** : Problème de téléchargement de l'extension.

**Solution** :
```sql
-- Forcer l'installation
FORCE INSTALL ui;
LOAD ui;
CALL start_ui();
```

---

## 📚 Comparaison avec Autres Méthodes

| Méthode | Avantages | Inconvénients |
|---------|-----------|---------------|
| **DuckDB UI** | ✅ Interface moderne<br>✅ Timer auto<br>✅ Visualisations<br>✅ Notebooks | ⚠️ Requiert navigateur |
| **DBeaver** | ✅ Multi-bases<br>✅ ERD visuel<br>✅ Export Excel | ⚠️ Installation lourde |
| **CLI** | ✅ Léger<br>✅ Scriptable<br>✅ Rapide | ⚠️ Pas de visualisation |
| **VSCode** | ✅ Intégration IDE<br>✅ Git | ⚠️ Configuration extensions |

---

## 📖 Ressources

### Documentation Officielle

- [DuckDB UI Extension](https://duckdb.org/docs/stable/core_extensions/ui)
- [DuckDB Local UI Announcement](https://duckdb.org/2025/03/12/duckdb-ui)
- [MotherDuck UI Guide](https://motherduck.com/docs/ui)

### GitHub

- [DuckDB UI Repository](https://github.com/duckdb/duckdb-ui)
- [Report Issues](https://github.com/duckdb/duckdb-ui/issues)

---

## ⏭️ Prochaine Étape

Interface DuckDB UI configurée ? Excellent !

### Pour commencer les benchmarks

👉 Retournez à [01-concept-ensembliste.md](01-concept-ensembliste.md) pour apprendre les opérations ensemblistes.

### Pour comparer avec SQLite

👉 Ouvrez un terminal séparé avec SQLite et comparez les temps !

---

**DuckDB UI prête ! Interface moderne pour vos analyses SQL. 🦆✨**
