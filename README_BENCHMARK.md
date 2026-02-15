# Benchmark des Opérations Ensemblistes

Ce dossier contient des scripts SQL pour benchmarker les performances des opérations ensemblistes (EXCEPT, UNION ALL, INTERSECT) sur trois plateformes de bases de données.

## 📁 Fichiers

### Versions SQL par base de données

**DuckDB (versions standard)** :
- `benchmark_01_pool_complet.sql` - Requêtes sans filtrage WHERE (volume maximal)
- `benchmark_02_where_limite.sql` - Requêtes avec WHERE limitant (volume optimisé)
- `comparaison_pools_complete.sql` - Pattern P1/P2/BOTH avancé

**SQLite (versions adaptées avec strftime())** :
- `benchmark_01_pool_complet_sqlite.sql` - Version SQLite du pool complet
- `benchmark_02_where_limite_sqlite.sql` - Version SQLite avec WHERE
- `comparaison_pools_complete_sqlite.sql` - Version SQLite des comparaisons

**IBM i / DB2** :
- `benchmark_ibmi.sql` - Version adaptée pour IBM i
- `comparaison_pools_ibmi.sql` - Comparaisons pour IBM i

**Scripts d'automatisation** :
- `run_benchmark.sh` - Script d'automatisation des tests (SQLite/DuckDB) - utilise automatiquement les bonnes versions
- `README_BENCHMARK.md` - Ce fichier

📘 **Documentation complète** : Voir **SQL_VERSIONS.md** pour les différences de syntaxe entre les versions

## 🎯 Objectifs

1. Comparer les performances EXCEPT vs UNION ALL vs INTERSECT
2. Démontrer l'impact du filtrage WHERE sur les temps d'exécution
3. Comparer IBM i (DB2) vs SQLite vs DuckDB

## 📊 Structure des benchmarks

### Série 1 : Pool complet (10 requêtes)
- Aucun filtrage WHERE significatif
- Volume traité : 3M factures, ~24M lignes
- Temps attendus : 40-160 secondes selon opération (SQLite), 5-30s (DuckDB)

### Série 2 : Avec WHERE limitant (10 requêtes)
- Filtrage agressif sur date, montant, ville, statut
- Volume traité : Variable selon filtres (50K-500K lignes typique)
- Temps attendus : 2-15 secondes (SQLite), 0.1-2s (DuckDB)
- **Gain attendu : 10-50x plus rapide**

## 🚀 Exécution manuelle

### SQLite

**IMPORTANT** : Utilisez les versions `*_sqlite.sql` qui contiennent `strftime()` au lieu de `YEAR()`

```bash
# Activer le timer
sqlite3 data/facturation.db

.timer on
.mode column
.headers on

# Exécuter série 1 (version SQLite)
.read benchmark_01_pool_complet_sqlite.sql

# Exécuter série 2 (version SQLite)
.read benchmark_02_where_limite_sqlite.sql

# Comparaison pools (version SQLite)
.read comparaison_pools_complete_sqlite.sql
```

### DuckDB

**IMPORTANT** : Utilisez les versions standard (sans suffixe) qui contiennent `YEAR()` et `MONTH()`

```bash
# Activer le timer
duckdb data/facturation.duckdb

.timer on

# Exécuter série 1 (version standard)
.read benchmark_01_pool_complet.sql

# Exécuter série 2 (version standard)
.read benchmark_02_where_limite.sql

# Comparaison pools (version standard)
.read comparaison_pools_complete.sql
```

**Syntaxe** : Les fichiers DuckDB utilisent `YEAR(date_facture) = 2024` tandis que les fichiers SQLite utilisent `strftime('%Y', date_facture) = '2024'`. Voir **SQL_VERSIONS.md** pour plus de détails.

### IBM i (DB2)

#### Méthode 1 : ACS Run SQL Scripts

1. Ouvrir IBM i Access Client Solutions
2. Run SQL Scripts
3. Options → Show Elapsed Time (activer)
4. Ouvrir `benchmark_01_pool_complet.sql`
5. Exécuter requête par requête (sélectionner + F5)
6. Noter les temps dans la barre de statut

#### Méthode 2 : STRSQL (ligne de commande)

```sql
-- Se connecter
STRSQL

-- Copier/coller chaque requête manuellement
-- Le temps s'affiche en bas de l'écran après exécution
```

#### Méthode 3 : DB2 CLI (si disponible)

```bash
db2 connect to FACTURATN user FACTUSR
db2 -tvf benchmark_01_pool_complet.sql
db2 -tvf benchmark_02_where_limite.sql
```

## 🤖 Exécution automatisée

```bash
# Rendre le script exécutable
chmod +x run_benchmark.sh

# Lancer le benchmark complet
./run_benchmark.sh

# Les résultats sont sauvegardés dans:
# benchmark_results_YYYYMMDD_HHMMSS.txt
```

**Le script utilise automatiquement les bonnes versions** :
- ✅ **SQLite** : Versions `*_sqlite.sql` avec `strftime()`
- ✅ **DuckDB** : Versions standard avec `YEAR()` et `MONTH()`
- ✅ Extrait et exécute chaque requête individuellement
- ✅ Mesure les temps avec précision nanoseconde
- ✅ Génère un rapport de synthèse avec speedup

**Note**: Le script automatisé ne supporte que SQLite et DuckDB. Pour IBM i, exécutez manuellement via ACS.

## 📈 Interprétation des résultats

### Performances attendues (en secondes)

| Opération          | IBM i    | SQLite   | DuckDB  |
|--------------------|----------|----------|---------|
| **SÉRIE 1 (pool complet - 3M factures, 24M lignes)** |
| EXCEPT simple      | 100-300s | 40-160s  | 5-30s   |
| UNION ALL simple   | 60-180s  | 20-80s   | 2-15s   |
| INTERSECT simple   | 80-240s  | 40-120s  | 4-25s   |
| EXCEPT complexe    | 200-600s | 100-300s | 10-60s  |
| **SÉRIE 2 (avec WHERE - volumes filtrés)** |
| EXCEPT filtré      | 5-20s    | 2-15s    | 0.1-2s  |
| UNION ALL filtré   | 3-15s    | 1-10s    | 0.05-1s |
| INTERSECT filtré   | 4-18s    | 2-12s    | 0.1-1.5s|

### Facteurs de performance

**DuckDB (le plus rapide)**
- Vectorisation SIMD
- Compression columnar
- Optimisations OLAP
- **Cas d'usage** : Analytique, BI, data science

**SQLite (équilibre)**
- Optimisé pour lecture
- Mono-thread
- Léger et portable
- **Cas d'usage** : Applications mobiles, IoT, prototypage

**IBM i / DB2 (robuste)**
- Optimisé pour transactionnel
- Multi-utilisateurs
- Haute disponibilité
- **Cas d'usage** : ERP, production, applications critiques

## 🔍 Requêtes démonstrées

### EXCEPT (différence)
1. Factures Paris vs autres villes
2. Produits vendus en 2024 mais pas 2025
3. Clients avec PAYEE mais jamais EMISE
4. Clients actifs 2024 perdus en 2025
5. Factures orphelines (sans lignes détail)
6. Nouveaux clients 2025 (absents de 2024)

### UNION ALL (consolidation)
1. Factures 2024 + 2025
2. Top clients par CA multi-années
3. Analyse CA mensuel 2024 (12 mois)
4. Analyse TVA par taux consolidée
5. Top produits par région (3 villes)

### INTERSECT (intersection)
1. Clients avec PAYEE ET EMISE
2. Villes avec clients ET factures
3. Produits achetés par VIP ET réguliers
4. Clients VIP avec produits premium
5. Clients récurrents Q1 ET Q4
6. Cross-sell (Ordinateur ET Licence)

## 💡 Optimisations démontrées

### Impact du WHERE

| Technique                  | Gain moyen |
|----------------------------|------------|
| Filtrage temporel (année)  | 15-30x     |
| Filtrage montant (>seuil)  | 10-20x     |
| Filtrage ville spécifique  | 20-40x     |
| Combinaison multi-critères | 25-50x     |

### Index recommandés

```sql
-- Critiques pour performance
CREATE INDEX idx_facture_date ON facture(date_facture);
CREATE INDEX idx_facture_statut ON facture(statut);
CREATE INDEX idx_facture_client ON facture(client_id);
CREATE INDEX idx_client_ville ON client(ville);
CREATE INDEX idx_ligne_facture ON ligne_facture(facture_id);
```

## 📝 Notation des résultats

### Format du fichier de résultats

```csv
database;query;duration_seconds
SQLite;1;2.456
DuckDB;1;0.321
SQLite;2;1.234
...
```

### Calcul du speedup

```python
# Exemple : DuckDB vs SQLite sur Query 1
speedup = temps_sqlite / temps_duckdb
# Si SQLite = 2.456s et DuckDB = 0.321s
# speedup = 2.456 / 0.321 = 7.65x plus rapide
```

## 🎓 Cas d'usage métier

Chaque requête illustre un cas d'usage réel :

- **Audit qualité** : Factures sans lignes, anomalies
- **Analyse commerciale** : Top clients, produits, régions
- **Fidélisation** : Clients récurrents, churn
- **Comptabilité** : Analyse TVA, déclarations
- **Stratégie** : Cross-sell, nouveaux clients, croissance

## ⚠️ Notes importantes

1. **Versions SQL** : Utilisez toujours les fichiers adaptés à votre base de données (voir SQL_VERSIONS.md)
   - SQLite → `*_sqlite.sql` (avec `strftime()`)
   - DuckDB → fichiers standard (avec `YEAR()` et `MONTH()`)
   - IBM i → `*_ibmi.sql` (syntaxe DB2)
2. **Index** : Performance dépend fortement de la présence d'index appropriés
3. **Volume** : Résultats basés sur 100K clients, 3M factures, ~24M lignes
4. **Variabilité** : Les temps peuvent varier selon CPU, RAM, I/O disque
5. **Cache** : Exécuter 2-3 fois pour des mesures stables (warm cache)

## 🔧 Troubleshooting

### Erreur "no such function: YEAR" sur SQLite
→ **Solution** : Utilisez les fichiers `*_sqlite.sql` au lieu des fichiers standard
→ Les fichiers SQLite utilisent `strftime()` au lieu de `YEAR()` et `MONTH()`
→ Voir **SQL_VERSIONS.md** pour les détails

### Erreur de syntaxe sur IBM i
→ Remplacer `EXTRACT(YEAR FROM date)` par `YEAR(date)`
→ Vérifier les guillemets simples vs doubles
→ Utiliser les fichiers `*_ibmi.sql`

### Requête trop lente
→ Vérifier présence des index (voir section optimisations)
→ Réduire le volume avec WHERE plus restrictif
→ Vérifier statistiques à jour : `ANALYZE TABLE`

### Fichier de résultats vide
→ Vérifier permissions d'écriture
→ Vérifier que les bases de données existent dans `data/`
→ Vérifier que les bons fichiers SQL sont utilisés
→ Lancer en mode verbose : `bash -x run_benchmark.sh`

## 📚 Ressources

- [Documentation DuckDB](https://duckdb.org/docs/)
- [SQLite Query Planner](https://www.sqlite.org/queryplanner.html)
- [IBM DB2 Performance](https://www.ibm.com/docs/en/i/7.5?topic=performance-sql)

## 🤝 Contribution

Pour ajouter de nouvelles requêtes :
1. Respecter le format commentaire `-- QUERY X:`
2. Documenter l'objectif et le volume attendu
3. Tester sur les 3 plateformes
4. Documenter les performances observées
