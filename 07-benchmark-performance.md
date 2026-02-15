# 07 - Benchmark Performance : SQLite vs DuckDB

## 🎯 Objectifs

À la fin de ce chapitre, vous serez capable de :

- ✅ Mesurer précisément les **performances** de chaque opération
- ✅ Comprendre **pourquoi DuckDB est plus rapide**
- ✅ Choisir la **bonne base** selon le cas d'usage
- ✅ Interpréter les **résultats** de benchmarks

**Durée estimée : 30 minutes**

---

## 📊 Méthodologie de Benchmark

### Règles de mesure

1. ✅ **Warm-up** : Exécuter 2-3 fois avant de mesurer
2. ✅ **Moyenne** : Prendre la moyenne de 3 exécutions
3. ✅ **Cache vidé** : Redémarrer la base entre tests majeurs
4. ✅ **Conditions identiques** : Même machine, même moment
5. ✅ **Timer activé** : `.timer on` dans les deux bases

### Configuration de test

```bash
# SQLite
sqlite3 data/facturation.db
.timer on
.mode column
.headers on

# DuckDB
duckdb data/facturation.duckdb
.timer on
```

### ⚠️ Important : Versions SQL Différentes

Ce guide utilise des **exemples de requêtes avec syntaxe DuckDB** (fonction `YEAR()`).

**Pour exécuter sur SQLite**, vous devez remplacer :
- `YEAR(date_facture)` → `strftime('%Y', date_facture)`
- `MONTH(date_facture)` → `strftime('%m', date_facture)`

**Fichiers adaptés déjà disponibles** :
- SQLite : `benchmark_*_sqlite.sql` (avec `strftime()`)
- DuckDB : `benchmark_*.sql` (avec `YEAR()` et `MONTH()`)

📘 Voir **SQL_VERSIONS.md** pour les détails complets des différences de syntaxe.

---

## 🧪 Benchmark 1 : EXCEPT Simple

### Requête de test

**Version DuckDB** (utilise `YEAR()`) :
```sql
-- Clients actifs 2024 mais pas 2025
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

**Version SQLite** (utilise `strftime()`) :
```sql
-- Même requête avec syntaxe SQLite
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

### Résultats à noter

| Exécution | SQLite (s) | DuckDB (s) |
|-----------|------------|------------|
| Run 1     | ______     | ______     |
| Run 2     | ______     | ______     |
| Run 3     | ______     | ______     |
| **Moyenne** | ______   | ______     |

**Speedup DuckDB** : SQLite_avg / DuckDB_avg = _______x

**Attendu** : DuckDB **5-10x plus rapide**

---

## 🧪 Benchmark 2 : UNION ALL Multi-Années

### Requête de test

**Version DuckDB** :
```sql
-- Consolidation 2020-2025 (toutes les années)
SELECT 2020 AS annee, COUNT(*) AS nb, SUM(montant_ttc) AS ca
FROM facture WHERE YEAR(date_facture) = 2020 AND statut = 'PAYEE'

UNION ALL SELECT 2021, COUNT(*), SUM(montant_ttc)
FROM facture WHERE YEAR(date_facture) = 2021 AND statut = 'PAYEE'

UNION ALL SELECT 2022, COUNT(*), SUM(montant_ttc)
FROM facture WHERE YEAR(date_facture) = 2022 AND statut = 'PAYEE'

UNION ALL SELECT 2023, COUNT(*), SUM(montant_ttc)
FROM facture WHERE YEAR(date_facture) = 2023 AND statut = 'PAYEE'

UNION ALL SELECT 2024, COUNT(*), SUM(montant_ttc)
FROM facture WHERE YEAR(date_facture) = 2024 AND statut = 'PAYEE'

UNION ALL SELECT 2025, COUNT(*), SUM(montant_ttc)
FROM facture WHERE YEAR(date_facture) = 2025 AND statut = 'PAYEE'

ORDER BY annee;
```

**Version SQLite** (remplacer `YEAR()` par `strftime()`) :
```sql
SELECT 2020 AS annee, COUNT(*) AS nb, SUM(montant_ttc) AS ca
FROM facture WHERE strftime('%Y', date_facture) = '2020' AND statut = 'PAYEE'

UNION ALL SELECT 2021, COUNT(*), SUM(montant_ttc)
FROM facture WHERE strftime('%Y', date_facture) = '2021' AND statut = 'PAYEE'
-- ... (même pattern pour 2022-2025)
```

### Résultats à noter

| Base de données | Temps moyen (s) |
|-----------------|-----------------|
| SQLite          | ______          |
| DuckDB          | ______          |
| **Speedup**     | _______x        |

**Attendu** : DuckDB **8-15x plus rapide**

💡 **Note** : Pour SQLite, utilisez toujours `strftime('%Y', date_facture) = '2020'` avec des guillemets pour les années.

---

## 🧪 Benchmark 3 : INTERSECT avec Agrégations

### Requête de test

```sql
-- Clients VIP fidèles (>100K en 2024 ET 2025)
SELECT 
    c.client_id,
    c.nom,
    c.prenom,
    SUM(f.montant_ttc) AS ca_total
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024 
  AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom
HAVING SUM(f.montant_ttc) > 100000

INTERSECT

SELECT 
    c.client_id,
    c.nom,
    c.prenom,
    SUM(f.montant_ttc)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025 
  AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom
HAVING SUM(f.montant_ttc) > 100000;
```

### Résultats à noter

| Base de données | Temps moyen (s) |
|-----------------|-----------------|
| SQLite          | ______          |
| DuckDB          | ______          |
| **Speedup**     | _______x        |

**Attendu** : DuckDB **8-12x plus rapide**

💡 **Note** : Avec filtrage WHERE optimisé, les gains peuvent atteindre **10-50x** (voir benchmark_02_where_limite).

---

## 🧪 Benchmark 4 : Pattern Complet (3 Opérations)

### Requête de test

```sql
-- Comparaison complète Paris vs Lyon
WITH pool_paris AS (
    SELECT c.client_id, c.nom, c.prenom
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Paris' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
),
pool_lyon AS (
    SELECT c.client_id, c.nom, c.prenom
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
)
SELECT 'PARIS_ONLY' AS source, * FROM pool_paris
EXCEPT
SELECT 'PARIS_ONLY', * FROM pool_lyon

UNION ALL

SELECT 'LYON_ONLY', * FROM pool_lyon
EXCEPT
SELECT 'LYON_ONLY', * FROM pool_paris

UNION ALL

SELECT 'BOTH', * FROM pool_paris
INTERSECT
SELECT 'BOTH', * FROM pool_lyon

ORDER BY source;
```

### Résultats à noter

| Base de données | Temps moyen (s) |
|-----------------|-----------------|
| SQLite          | ______          |
| DuckDB          | ______          |
| **Speedup**     | _______x        |

**Attendu** : DuckDB **5-12x plus rapide**

💡 **Différence de syntaxe** : Sur SQLite, remplacer `YEAR(f.date_facture) = 2024` par `strftime('%Y', f.date_facture) = '2024'` dans toutes les CTE.

---

## 🧪 Benchmark 5 : Gros Volume (ligne_facture)

### Requête de test

```sql
-- Produits vendus en 2024 mais pas 2025 (scan ~500K lignes)
SELECT DISTINCT 
    lf.description,
    COUNT(*) AS nb_ventes,
    ROUND(SUM(lf.montant_ttc), 2) AS ca_total
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY lf.description

EXCEPT

SELECT DISTINCT 
    lf.description,
    COUNT(*),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY lf.description;
```

### Résultats à noter

| Base de données | Temps moyen (s) |
|-----------------|-----------------|
| SQLite          | ______          |
| DuckDB          | ______          |
| **Speedup**     | _______x        |

**Attendu** : DuckDB **8-20x plus rapide** (volume élevé : ~24M lignes scannées)

💡 **Note** : Sur gros volumes (ligne_facture avec ~24M lignes), les différences de performance sont encore plus marquées.

---

## 📊 Synthèse des Résultats

### Tableau récapitulatif

Remplissez ce tableau avec vos mesures :

| Benchmark | Volume | SQLite (s) | DuckDB (s) | Speedup |
|-----------|--------|------------|------------|---------|
| EXCEPT simple | ~5K lignes | ______ | ______ | ______x |
| UNION ALL multi | ~30K lignes | ______ | ______ | ______x |
| INTERSECT agrégé | ~10K lignes | ______ | ______ | ______x |
| Pattern complet | ~3K lignes | ______ | ______ | ______x |
| Gros volume | ~500K lignes | ______ | ______ | ______x |
| **MOYENNE** | - | ______ | ______ | ______x |

### Graphique de comparaison

```
Temps d'exécution (secondes)
    
15 │                                          
   │  ██████                                  
   │  ██████                                  
10 │  ██████                                  
   │  ██████  ██████                          
   │  ██████  ██████  ██████                  
 5 │  ██████  ██████  ██████  ██████  ██████  
   │  ██████  ██████  ██████  ██████  ██████  
   │  ██  ▓▓  ██  ▓▓  ██  ▓▓  ██  ▓▓  ██  ▓▓  
 0 └──────────────────────────────────────────
    EXCEPT  UNION   INTER  PATTERN VOLUME
    
    ██ SQLite    ▓▓ DuckDB
```

---

## 🔬 Pourquoi DuckDB est Plus Rapide ?

### Architecture vectorisée

**SQLite** : Traitement **ligne par ligne** (row-oriented)
```
Facture 1 → Traiter → Résultat 1
Facture 2 → Traiter → Résultat 2
Facture 3 → Traiter → Résultat 3
...
```

**DuckDB** : Traitement **par blocs vectorisés** (columnar + SIMD)
```
Batch 1000 factures → Traiter en parallèle → 1000 résultats
Batch 1000 factures → Traiter en parallèle → 1000 résultats
...
```

**Gain** : DuckDB traite 1000 lignes dans le temps où SQLite en traite 1.

### Compression columnar

**SQLite** : Stockage ligne par ligne
```
Facture 1: [ID:1, Client:123, Montant:1000, Date:2024-01-15, ...]
Facture 2: [ID:2, Client:456, Montant:2000, Date:2024-01-16, ...]
```

**DuckDB** : Stockage colonne par colonne (compressé)
```
IDs:      [1, 2, 3, 4, ...]       (compressé)
Clients:  [123, 456, 789, ...]    (compressé)
Montants: [1000, 2000, 1500, ...] (compressé)
```

**Avantages** :
- 📦 **Compression** : 50-80% de réduction de taille
- ⚡ **I/O réduit** : Lire seulement les colonnes nécessaires
- 🎯 **Cache efficace** : Données similaires adjacentes

### Parallélisation

**SQLite** : **Mono-thread** (1 cœur CPU)

**DuckDB** : **Multi-thread automatique** (tous les cœurs)
- Sur CPU 8 cœurs : potentiel **8x plus rapide**

### Optimisations OLAP

DuckDB est optimisé pour l'**analytique** (OLAP) :
- ✅ Agrégations (SUM, COUNT, AVG)
- ✅ GROUP BY massifs
- ✅ Opérations ensemblistes
- ✅ Scans de tables complètes

SQLite est optimisé pour le **transactionnel** (OLTP) :
- ✅ INSERT/UPDATE/DELETE rapides
- ✅ Transactions ACID strictes
- ✅ Accès par clé primaire
- ✅ Concurrence multi-utilisateurs

---

## 🆚 Quand Utiliser Quelle Base ?

### Choisir SQLite

| Cas d'usage | Raison |
|-------------|--------|
| **Applications mobiles** | Léger, intégré, aucune dépendance |
| **IoT / Embedded** | Empreinte mémoire minimale |
| **Prototypage rapide** | Déjà inclus avec Python |
| **Fichier unique** | Simplicité de déploiement |
| **Transactionnel** | INSERT/UPDATE intensifs |

**Exemple** : Application mobile de gestion de notes, cache local.

### Choisir DuckDB

| Cas d'usage | Raison |
|-------------|--------|
| **Analytique** | 5-20x plus rapide sur agrégations |
| **Data Science** | Intégration Pandas, Arrow |
| **ETL / Pipelines** | Performance sur gros volumes |
| **Reporting** | Requêtes complexes multi-tables |
| **BI / Dashboards** | Scan de tables massives |

**Exemple** : Analyse de logs, reporting financier, data warehouse local.

### Hybride : SQLite + DuckDB

**Pattern recommandé** :
1. **SQLite** : Stockage transactionnel (CRUD)
2. **DuckDB** : Lecture analytique (SELECT complexes)

```python
# Écrire dans SQLite
import sqlite3
conn = sqlite3.connect('app.db')
conn.execute("INSERT INTO events ...")

# Lire avec DuckDB
import duckdb
duck = duckdb.connect()
duck.execute("SELECT * FROM 'app.db'.events WHERE ...")
```

---

## 📊 Comparaison Complète

| Critère | SQLite | DuckDB | Gagnant |
|---------|--------|--------|---------|
| **SELECT analytique** | ⭐⭐ | ⭐⭐⭐⭐⭐ | DuckDB |
| **INSERT/UPDATE** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | SQLite |
| **Agrégations** | ⭐⭐ | ⭐⭐⭐⭐⭐ | DuckDB |
| **JOIN complexes** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | DuckDB |
| **Opérations ensemblistes** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | DuckDB |
| **Transactions ACID** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | SQLite |
| **Portabilité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | SQLite |
| **Taille binaire** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | SQLite |
| **Empreinte mémoire** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | SQLite |
| **Compression** | ⭐⭐ | ⭐⭐⭐⭐⭐ | DuckDB |
| **Parallélisation** | ⭐ | ⭐⭐⭐⭐⭐ | DuckDB |
| **Communauté** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | SQLite |

---

## 🎯 Recommandations Finales

### Pour l'analytique

**Utilisez DuckDB si** :
- ✅ Requêtes analytiques (GROUP BY, agrégations)
- ✅ Volumes >100K lignes
- ✅ Opérations ensemblistes fréquentes
- ✅ Performance critique
- ✅ Pipelines ETL

**Gains typiques** : **5-20x plus rapide**

### Pour le transactionnel

**Utilisez SQLite si** :
- ✅ Application CRUD (Create, Read, Update, Delete)
- ✅ Embarqué / Mobile / IoT
- ✅ Fichier unique portable
- ✅ Pas de serveur nécessaire
- ✅ Transactions fréquentes

**Avantages** : Simplicité, maturité, omniprésence

### Best of Both Worlds

**Combinez les deux** :
```python
# SQLite pour les écritures
sqlite_conn = sqlite3.connect('data.db')
sqlite_conn.execute("INSERT INTO sales ...")

# DuckDB pour les analyses
duck_conn = duckdb.connect()
report = duck_conn.execute("""
    SELECT 
        region,
        SUM(amount) as total_sales
    FROM 'data.db'.sales
    WHERE date >= '2024-01-01'
    GROUP BY region
""").df()
```

---

## 🎓 Exercice Final : Votre Propre Benchmark

### Mission

Créez votre propre benchmark sur un cas d'usage réel :

1. **Choisissez une requête** de votre quotidien
2. **Mesurez** sur SQLite et DuckDB
3. **Optimisez** avec WHERE
4. **Documentez** les gains

### Template de rapport

```markdown
# Mon Benchmark Personnel

## Requête testée
[Coller votre requête SQL]

## Résultats

| Métrique | SQLite | DuckDB | Gain |
|----------|--------|--------|------|
| Temps (s) | X.XX | Y.YY | Zx |
| Lignes traitées | N | N | - |

## Optimisations appliquées
1. WHERE sur année
2. Filtrage par statut
3. Index ajoutés

## Conclusion
[Vos observations]
```

---

## 📝 Conclusions du Guide

### Ce que vous avez appris

✅ Les **3 opérations ensemblistes** (EXCEPT, UNION ALL, INTERSECT)  
✅ Le **pattern de comparaison complète**  
✅ L'optimisation avec **filtres WHERE** (gains 8-25x)  
✅ Les différences **SQLite vs DuckDB**  
✅ Quand utiliser **quelle base de données**

### Cas d'usage maîtrisés

- 🔍 Détection de churn client
- 📊 Consolidation multi-sources
- 🎯 Analyse de fidélité
- 🔄 Audit PROD vs DEV
- 📈 Analyse de catalogue produits
- 🌍 Comparaisons géographiques

### Gains de performance

| Technique | Gain typique |
|-----------|--------------|
| DuckDB vs SQLite | 5-20x |
| Filtrage WHERE | 10-50x |
| Index appropriés | 3-10x |
| **COMBINÉ** | **50-500x** |

### Différences de syntaxe

| Fonction | DuckDB | SQLite | Compatibilité |
|----------|--------|--------|---------------|
| **Année** | `YEAR(date)` | `strftime('%Y', date)` | SQLite uniquement |
| **Mois** | `MONTH(date)` | `strftime('%m', date)` | SQLite uniquement |
| **Jour** | `DAY(date)` | `strftime('%d', date)` | SQLite uniquement |

**Important** : Les fichiers `*_sqlite.sql` contiennent déjà les conversions nécessaires.

---

## 🚀 Pour Aller Plus Loin

### Ressources complémentaires

- [DuckDB Documentation](https://duckdb.org/docs/)
- [DuckDB Blog - Performance](https://duckdb.org/2021/05/14/sql-on-pandas.html)
- [SQLite vs DuckDB Benchmark](https://duckdblabs.github.io/db-benchmark/)

### Prochains sujets

- **Window Functions** avec DuckDB
- **Parquet & Arrow** pour performance maximale
- **DuckDB + Pandas** pour data science
- **Parallel Processing** avec DuckDB

---

## 🎉 Félicitations !

Vous avez terminé le guide complet des opérations ensemblistes avec DuckDB et SQLite !

Vous êtes maintenant capable de :
- ✅ Utiliser les opérations ensemblistes comme un expert
- ✅ Optimiser vos requêtes pour performances maximales
- ✅ Choisir l'outil approprié selon le contexte
- ✅ Réaliser des audits et analyses complexes

**Continuez à pratiquer et expérimenter ! 🦆**

---

**Merci d'avoir suivi ce guide. Happy querying! 🎓**
