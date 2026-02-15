# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).

## [2.0.0] - 2026-02-15

### 🚀 Ajouté

- **VOLUMES.md** : Documentation complète de la volumétrie (évolution, performance, recommandations)
- **CHANGELOG.md** : Suivi des versions et modifications
- Génération 100% déterministe (suppression de tous les `RANDOM()`)
- Index créés après insertion pour optimiser le temps de génération
- Documentation des formules mathématiques de génération déterministe

### 📈 Changé - BREAKING CHANGES

**Volumes de données (x20+) :**
- Clients : 5 000 → **100 000** (x20)
- Factures : 150 000 → **3 000 000** (x20)
- Lignes de facture : ~500 000 → **~24 000 000** (x48)

**Tailles de fichiers :**
- SQLite : 121 MB → **2.4 GB** (x20)
- DuckDB : 46 MB → **850 MB** (x18)

**Temps de génération :**
- Script setup : 20-60s → **~7 minutes** (406s SQLite + 10s DuckDB)

**Prérequis système :**
- RAM minimum : 4 GB → **8 GB** (16 GB recommandé)
- Disque requis : 2 GB → **4 GB**

**Estimations de performance ajustées :**

| Opération | Ancienne estim. (SQLite) | Nouvelle estim. (SQLite) | Ancien (DuckDB) | Nouveau (DuckDB) |
|-----------|-------------------------|--------------------------|-----------------|------------------|
| EXCEPT (full scan) | 2-8s | **40-160s** | 0.5-2s | **5-30s** |
| UNION ALL (full scan) | 1-4s | **20-80s** | 0.2-1s | **2-15s** |
| INTERSECT (full scan) | 2-6s | **40-120s** | 0.3-1.5s | **4-25s** |
| Avec WHERE (filtré) | 0.2-0.8s | **2-15s** | 0.02-0.3s | **0.1-2s** |

**Gains d'optimisation WHERE :**
- Avant : 8-25x plus rapide
- Maintenant : **10-50x plus rapide** (grâce au volume accru)

### 📝 Mis à jour

**Documentation alignée avec nouveaux volumes :**
- `README.md` : Prérequis, volumes, caractéristiques
- `00-setup.md` : Tous les chiffres, statistiques attendues
- `README_BENCHMARK.md` : Estimations de performance, temps d'exécution
- `MANUAL-SETUP.md` : Durées, tailles de fichiers, troubleshooting
- `CLAUDE.md` : Dataset, performance expectations, working guidelines

**Scripts de setup :**
- `setup-database.sh` : Génération optimisée pour 100K/3M/24M
- `setup-database.ps1` : Version PowerShell synchronisée
- `.gitignore` : Ajout de `data/*.db` pour exclure les grosses bases

### 🔧 Optimisé

- **Génération déterministe** : Plus besoin de `RANDOM()`, résultats reproductibles
- **Performance génération** : Index créés APRÈS insertion des données
- **CTE récursives** : Optimisées pour gérer 3M+ lignes
- **Compression DuckDB** : ~65% de compression (850 MB vs 2.4 GB SQLite)

### 💡 Pourquoi ces changements ?

**Objectifs atteints :**
1. ✅ Volumes réalistes d'une base de production PME
2. ✅ Différences de performance DuckDB vs SQLite bien visibles
3. ✅ Importance des index et du WHERE évidente sur gros volumes
4. ✅ Benchmarks représentatifs de cas d'usage réels
5. ✅ Données reproductibles (génération déterministe)

**Impact pédagogique :**
- Les apprenants voient l'impact réel des opérations ensemblistes sur gros volumes
- L'importance de l'optimisation (WHERE, index) est concrète
- Les différences OLAP (DuckDB) vs OLTP (SQLite) sont claires

## [1.0.0] - Date initiale

### Ajouté

- Documentation complète (00-setup.md à 07-benchmark-performance.md)
- Scripts SQL de benchmark (pool_complet, where_limite, ibmi, comparaison)
- Scripts de setup (PowerShell et Bash)
- Interfaces : guides DBeaver et DuckDB UI
- Données de test : 5K clients, 150K factures, 500K lignes

---

## Migration depuis v1.0.0

Si vous utilisez la version 1.0.0 et souhaitez migrer vers 2.0.0 :

### Option 1 : Régénérer les données (Recommandée)

```bash
# Supprimer anciennes bases
rm data/*.db data/*.duckdb

# Régénérer avec nouveaux volumes
./setup-database.sh

# Durée : ~7 minutes
```

### Option 2 : Garder les anciennes données

Si vous souhaitez conserver les petits volumes (5K/150K/500K) :

1. Ne pas exécuter `setup-database.sh`
2. Garder vos bases existantes
3. Adapter les estimations de performance en conséquence
4. Note : La documentation fait référence aux nouveaux volumes

### Recommandations

**Pour l'apprentissage :**
- ✅ Utiliser les **nouveaux volumes** (v2.0.0) : plus représentatif
- Les différences de performance sont plus visibles
- Meilleure préparation aux cas réels

**Pour tests rapides :**
- Vous pouvez créer vos propres scripts avec volumes réduits
- Modifier les constantes dans `setup-database.sh` :
  - Ligne ~150 : `<= 100000` → `<= 5000` (clients)
  - Ligne ~178 : `<= 3000000` → `<= 150000` (factures)

---

## Support

Pour toute question sur cette version :
1. Consulter `VOLUMES.md` pour les détails de volumétrie
2. Consulter `CLAUDE.md` pour les guidelines du projet
3. Vérifier que vos prérequis système sont suffisants (8 GB RAM, 4 GB disque)

---

**Merci d'utiliser ce guide ! 🦆**
