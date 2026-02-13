# Benchmark des Opérations Ensemblistes

Ce dossier contient des scripts SQL pour benchmarker les performances des opérations ensemblistes (EXCEPT, UNION ALL, INTERSECT) sur trois plateformes de bases de données.

## 📁 Fichiers

- `benchmark_01_pool_complet.sql` - Requêtes sans filtrage WHERE (volume maximal)
- `benchmark_02_where_limite.sql` - Requêtes avec WHERE limitant (volume optimisé)
- `run_benchmark.sh` - Script d'automatisation des tests (SQLite/DuckDB)
- `README_BENCHMARK.md` - Ce fichier

## 🎯 Objectifs

1. Comparer les performances EXCEPT vs UNION ALL vs INTERSECT
2. Démontrer l'impact du filtrage WHERE sur les temps d'exécution
3. Comparer IBM i (DB2) vs SQLite vs DuckDB

## 📊 Structure des benchmarks

### Série 1 : Pool complet (10 requêtes)
- Aucun filtrage WHERE significatif
- Volume traité : 150K factures, 500K lignes
- Temps attendus : 2-25 secondes selon opération

### Série 2 : Avec WHERE limitant (10 requêtes)  
- Filtrage agressif sur date, montant, ville, statut
- Volume traité : 2K-30K lignes selon requête
- Temps attendus : 0.1-5 secondes
- **Gain attendu : 8-25x plus rapide**

## 🚀 Exécution manuelle

### SQLite

```bash
# Activer le timer
sqlite3 facturation.db

.timer on

# Exécuter série 1
.read benchmark_01_pool_complet.sql

# Exécuter série 2
.read benchmark_02_where_limite.sql
```

### DuckDB

```bash
# Activer le timer
duckdb facturation.duckdb

.timer on

# Exécuter série 1
.read benchmark_01_pool_complet.sql

# Exécuter série 2
.read benchmark_02_where_limite.sql
```

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

**Note**: Le script automatisé ne supporte que SQLite et DuckDB. Pour IBM i, exécutez manuellement via ACS.

## 📈 Interprétation des résultats

### Performances attendues (en secondes)

| Opération          | IBM i   | SQLite | DuckDB |
|--------------------|---------|--------|--------|
| **SÉRIE 1 (pool complet)** |
| EXCEPT simple      | 5-15    | 2-8    | 0.5-2  |
| UNION ALL simple   | 3-8     | 1-4    | 0.2-1  |
| INTERSECT simple   | 4-12    | 2-6    | 0.3-1.5|
| EXCEPT complexe    | 10-25   | 5-15   | 1-4    |
| **SÉRIE 2 (avec WHERE)** |
| EXCEPT filtré      | 0.5-2   | 0.2-0.8| 0.05-0.3|
| UNION ALL filtré   | 0.3-1.2 | 0.1-0.5| 0.02-0.2|
| INTERSECT filtré   | 0.3-1.5 | 0.2-0.7| 0.05-0.4|

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
| Filtrage temporel (année)  | 10-15x     |
| Filtrage montant (>seuil)  | 8-12x      |
| Filtrage ville spécifique  | 12-20x     |
| Combinaison multi-critères | 15-25x     |

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

1. **IBM i** : Les fonctions `EXTRACT(YEAR FROM ...)` doivent être remplacées par `YEAR(...)` pour DB2
2. **Index** : Performance dépend fortement de la présence d'index appropriés
3. **Volume** : Résultats basés sur 5K clients, 150K factures, ~500K lignes
4. **Variabilité** : Les temps peuvent varier selon CPU, RAM, I/O disque
5. **Cache** : Exécuter 2-3 fois pour des mesures stables (warm cache)

## 🔧 Troubleshooting

### Erreur de syntaxe sur IBM i
→ Remplacer `EXTRACT(YEAR FROM date)` par `YEAR(date)`
→ Vérifier les guillemets simples vs doubles

### Requête trop lente
→ Vérifier présence des index (voir section optimisations)
→ Réduire le volume avec WHERE plus restrictif
→ Vérifier statistiques à jour : `ANALYZE TABLE`

### Fichier de résultats vide
→ Vérifier permissions d'écriture
→ Vérifier que les bases de données existent
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
