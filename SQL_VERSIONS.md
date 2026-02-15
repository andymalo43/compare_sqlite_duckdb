# Versions des Fichiers SQL

## 📝 Organisation des fichiers

Ce projet contient plusieurs versions des scripts SQL pour assurer la compatibilité avec différentes bases de données.

### 🎯 Fichiers par plateforme

| Version | Fichiers | Compatibilité | Utilisation |
|---------|----------|---------------|-------------|
| **Standard (DuckDB)** | `benchmark_*.sql`<br/>`comparaison_*.sql` | ✅ DuckDB<br/>⚠️ SQLite (erreurs YEAR/MONTH) | Scripts originaux avec fonctions SQL standard |
| **SQLite** | `*_sqlite.sql` | ✅ SQLite<br/>✅ DuckDB (compatible aussi) | Versions adaptées avec strftime() |
| **IBM i / DB2** | `*_ibmi.sql` | ✅ IBM i<br/>✅ DB2<br/>⚠️ SQLite/DuckDB | Versions pour systèmes IBM |

## 🔍 Différences principales

### Fonction YEAR() et MONTH()

**DuckDB et IBM i :**
```sql
WHERE YEAR(date_facture) = 2024
  AND MONTH(date_facture) = 3
```

**SQLite :**
```sql
WHERE strftime('%Y', date_facture) = '2024'
  AND strftime('%m', date_facture) = '03'
```

### Pourquoi deux versions ?

1. **SQLite** ne supporte pas les fonctions `YEAR()` et `MONTH()`
2. **DuckDB** supporte les deux syntaxes (YEAR() et strftime())
3. Les versions `_sqlite.sql` utilisent strftime() pour compatibilité maximale

## 📂 Liste complète des fichiers

### Benchmarks - Version DuckDB (originale)

- `benchmark_01_pool_complet.sql` - 10 requêtes sans WHERE filtrant
- `benchmark_02_where_limite.sql` - 10 requêtes avec WHERE optimisé
- `comparaison_pools_complete.sql` - 8 requêtes pattern P1/P2/BOTH

### Benchmarks - Version SQLite

- `benchmark_01_pool_complet_sqlite.sql` - Version SQLite du pool complet
- `benchmark_02_where_limite_sqlite.sql` - Version SQLite avec WHERE
- `comparaison_pools_complete_sqlite.sql` - Version SQLite des comparaisons

### Benchmarks - Version IBM i

- `benchmark_ibmi.sql` - 12 requêtes adaptées IBM i
- `comparaison_pools_ibmi.sql` - 6 requêtes pattern P1/P2/BOTH pour IBM i

## 🚀 Utilisation recommandée

### Pour SQLite

```bash
# Utiliser les versions _sqlite
sqlite3 data/facturation.db
.timer on
.mode column
.headers on
.read benchmark_01_pool_complet_sqlite.sql
```

### Pour DuckDB

```bash
# Utiliser les versions standard (sans suffixe)
duckdb data/facturation.duckdb
.timer on
.read benchmark_01_pool_complet.sql
```

### Pour IBM i

```bash
# Utiliser les versions _ibmi
# Via ACS Run SQL Scripts ou STRSQL
```

## ⚙️ Script run_benchmark.sh

Le script `run_benchmark.sh` utilise automatiquement les bonnes versions :
- **SQLite** : Versions `*_sqlite.sql`
- **DuckDB** : Versions standard

```bash
./run_benchmark.sh
```

Le script détecte automatiquement quelle version utiliser pour chaque base de données.

## 🔄 Maintenir les fichiers synchronisés

Lorsque vous modifiez une requête :

1. **Modifier la version DuckDB** (fichier sans suffixe)
2. **Regénérer la version SQLite** :

```bash
# Script de régénération (à créer si besoin)
./generate_sqlite_versions.sh
```

Ou manuellement :
```bash
# Copier et adapter
cp benchmark_01_pool_complet.sql benchmark_01_pool_complet_sqlite.sql

# Remplacer YEAR() par strftime()
sed -i "s/YEAR(date_facture)/strftime('%Y', date_facture)/g" benchmark_01_pool_complet_sqlite.sql
sed -i "s/MONTH(date_facture)/strftime('%m', date_facture)/g" benchmark_01_pool_complet_sqlite.sql
```

## 📝 Notes importantes

### Comportement de strftime()

SQLite retourne des **chaînes de caractères** avec strftime() :

```sql
-- SQLite
strftime('%Y', date_facture) = '2024'  -- ✅ Correct (chaîne)
strftime('%Y', date_facture) = 2024    -- ⚠️ Faux (comparaison chaîne vs int)

-- DuckDB
YEAR(date_facture) = 2024              -- ✅ Correct (entier)
```

### Compatibilité croisée

Les fichiers `*_sqlite.sql` fonctionnent aussi sur DuckDB car :
- DuckDB supporte strftime()
- DuckDB convertit automatiquement '2024' = 2024

Donc **les versions SQLite sont universelles** (SQLite + DuckDB).

### Performance

Aucune différence de performance significative entre :
- `YEAR(date_facture) = 2024` (DuckDB)
- `strftime('%Y', date_facture) = '2024'` (SQLite/DuckDB)

Les deux utilisent les index correctement.

## 🎓 Pour l'apprentissage

**Débutants** : Utilisez les versions adaptées à votre base
**Avancés** : Comparez les différentes syntaxes pour comprendre les dialectes SQL

## ❓ FAQ

**Q: Pourquoi ne pas tout convertir en strftime() ?**
R: Les fichiers originaux démontrent la syntaxe SQL standard. Les versions _sqlite montrent les adaptations nécessaires.

**Q: Les versions _sqlite sont-elles plus lentes ?**
R: Non, performance identique avec les index appropriés.

**Q: Puis-je utiliser les fichiers DuckDB sur SQLite ?**
R: Non, vous aurez des erreurs "no such function: YEAR". Utilisez les versions _sqlite.

**Q: Puis-je utiliser les fichiers SQLite sur DuckDB ?**
R: Oui, DuckDB supporte strftime() et la conversion automatique.

## 📊 Résumé

| Base de données | Fichiers à utiliser | Pourquoi |
|-----------------|---------------------|----------|
| **SQLite** | `*_sqlite.sql` | Pas de fonction YEAR() native |
| **DuckDB** | `*.sql` ou `*_sqlite.sql` | Supporte les deux syntaxes |
| **IBM i / DB2** | `*_ibmi.sql` | Syntaxe spécifique IBM |

---

**Conseil** : En cas de doute, utilisez les versions `*_sqlite.sql` qui fonctionnent partout.
