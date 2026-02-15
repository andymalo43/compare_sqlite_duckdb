# 🦆 Guide Pratique : Opérations Ensemblistes avec DuckDB et SQLite

![DuckDB](https://img.shields.io/badge/DuckDB-FFF000?style=for-the-badge&logo=duckdb&logoColor=black)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)

## 📚 Vue d'ensemble

Ce guide vous accompagne dans la découverte et la maîtrise des **opérations ensemblistes SQL** (EXCEPT, UNION ALL, INTERSECT) à travers une série d'exercices pratiques comparant **DuckDB** et **SQLite**.

### 🎯 Objectifs pédagogiques

À la fin de ce parcours, vous serez capable de :

1. ✅ Comprendre les **3 opérations ensemblistes** et leurs cas d'usage
2. ✅ Identifier quand utiliser EXCEPT vs UNION ALL vs INTERSECT
3. ✅ Comparer les **performances DuckDB vs SQLite** sur des volumes réalistes
4. ✅ Optimiser vos requêtes avec des **filtres WHERE** stratégiques (gains 8-25x)
5. ✅ Réaliser des **audits de données** et détections d'anomalies
6. ✅ Comprendre pourquoi DuckDB excelle en analytique

### 🗂️ Structure du guide

Ce parcours est découpé en **8 étapes progressives** :

| Étape | Fichier | Durée | Niveau |
|-------|---------|-------|--------|
| 0️⃣ | [00-setup.md](00-setup.md) | 15 min | Débutant |
| 1️⃣ | [01-concept-ensembliste.md](01-concept-ensembliste.md) | 20 min | Débutant |
| 2️⃣ | [02-except-differences.md](02-except-differences.md) | 30 min | Intermédiaire |
| 3️⃣ | [03-union-consolidation.md](03-union-consolidation.md) | 25 min | Intermédiaire |
| 4️⃣ | [04-intersect-similitudes.md](04-intersect-similitudes.md) | 25 min | Intermédiaire |
| 5️⃣ | [05-comparaison-complete.md](05-comparaison-complete.md) | 40 min | Avancé |
| 6️⃣ | [06-optimisation-where.md](06-optimisation-where.md) | 35 min | Avancé |
| 7️⃣ | [07-benchmark-performance.md](07-benchmark-performance.md) | 30 min | Avancé |

**Durée totale estimée : 3h30**

---

## 🚀 Démarrage rapide

### Prérequis

- **SQLite** 3.35+ (généralement pré-installé)
- **DuckDB** 0.9.0+ (CLI)
- 4 Go d'espace disque (bases: 2.4 GB SQLite + 850 MB DuckDB)
- 8 Go de RAM minimum (16 Go recommandé)

### Installation en 2 étapes

**Étape 1 : Installer les outils**

Consultez **[INSTALL.md](INSTALL.md)** pour les instructions complètes :
- Windows PowerShell
- WSL/Linux Bash
- macOS

**Étape 2 : Générer les données**

**3 méthodes au choix** :

#### Méthode A : Script automatique (Recommandée)

**Windows** :
```powershell
.\setup-database.ps1
```

**Linux/WSL/macOS** :
```bash
chmod +x setup-database.sh
./setup-database.sh
```

#### Méthode B : SQL Manuel

```bash
# Télécharger le script SQL de génération
# Puis exécuter :
sqlite3 data/facturation.db < setup_database.sql

# Pour DuckDB
duckdb data/facturation.duckdb < setup_duckdb.sql
```

#### Méthode C : Importer vos propres données

Adaptez le schéma fourni à vos données existantes.

---

## 📖 Parcours d'apprentissage recommandé

### Pour les débutants SQL

**Commencez par :**
1. [00-setup.md](00-setup.md) - Configuration de l'environnement
2. [01-concept-ensembliste.md](01-concept-ensembliste.md) - Comprendre les bases
3. [02-except-differences.md](02-except-differences.md) - Première opération simple

**Puis continuez avec :**
4. [03-union-consolidation.md](03-union-consolidation.md)
5. [04-intersect-similitudes.md](04-intersect-similitudes.md)

### Pour les utilisateurs SQL confirmés

**Démarrez directement par :**
1. [00-setup.md](00-setup.md) - Configuration rapide
2. [05-comparaison-complete.md](05-comparaison-complete.md) - Pattern avancé
3. [06-optimisation-where.md](06-optimisation-where.md) - Optimisations
4. [07-benchmark-performance.md](07-benchmark-performance.md) - Benchmarks

### Pour les data engineers

**Focus sur :**
1. [05-comparaison-complete.md](05-comparaison-complete.md) - Audits de données
2. [06-optimisation-where.md](06-optimisation-where.md) - Performance tuning
3. [07-benchmark-performance.md](07-benchmark-performance.md) - Scalabilité

---

## 🎓 Ce que vous allez apprendre

### Concepts théoriques

- **Théorie des ensembles** appliquée au SQL
- **Différence** entre UNION et UNION ALL
- **Cas d'usage** métier de chaque opération
- **Optimisations** de requêtes analytiques

### Compétences pratiques

- Détecter des **données manquantes** entre environnements
- Identifier des **clients churned** (perdus)
- Analyser l'**évolution temporelle** de catalogues produits
- Comparer des **performances** entre moteurs SQL
- Réaliser des **audits qualité** de données

### Technologies comparées

| Critère | SQLite | DuckDB | Gagnant |
|---------|--------|--------|---------|
| **Analytique** | ⭐⭐ | ⭐⭐⭐⭐⭐ | DuckDB |
| **Transactionnel** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | SQLite |
| **Performance OLAP** | ⭐⭐ | ⭐⭐⭐⭐⭐ | DuckDB |
| **Simplicité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | SQLite |
| **Portabilité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | SQLite |
| **Compression** | ⭐⭐ | ⭐⭐⭐⭐⭐ | DuckDB |

---

## 📊 Jeu de données

### Schéma de la base

```
client (100 000 lignes)
├── client_id
├── nom, prenom, email
├── ville, code_postal
└── date_creation

facture (3 000 000 lignes)
├── facture_id
├── client_id → client
├── numero_facture
├── date_facture, date_echeance
├── montant_ht, montant_tva, montant_ttc
└── statut (BROUILLON, EMISE, PAYEE, ANNULEE)

ligne_facture (~24 000 000 lignes)
├── ligne_id
├── facture_id → facture
├── description (25 produits différents)
├── quantite, prix_unitaire
└── montant_ht, montant_tva, montant_ttc
```

### Caractéristiques

- **Volume** : ~27M lignes au total (100K clients, 3M factures, 24M lignes)
- **Période** : 2020-2025 (6 ans, 2190 jours)
- **Villes** : 18 villes françaises
- **Produits** : 25 produits IT/services
- **CA moyen** : Variable selon facture (génération déterministe)

---

## 🛠️ Outils et Interfaces

### Option 1 : Ligne de Commande (CLI)

⚠️ **Important** : Utilisez les fichiers SQL adaptés à votre base de données :
- **SQLite** → `*_sqlite.sql` (avec `strftime()`)
- **DuckDB** → `*.sql` (avec `YEAR()` et `MONTH()`)

📘 Voir **[SQL_VERSIONS.md](SQL_VERSIONS.md)** pour les détails complets

**SQLite** :
```bash
sqlite3 data/facturation.db
.timer on
.mode column
.headers on
.read benchmark_01_pool_complet_sqlite.sql
```

**DuckDB** :
```bash
duckdb data/facturation.duckdb
.timer on
.read benchmark_01_pool_complet.sql
```

### Option 2 : DBeaver (Interface Graphique)

**Guide complet** : [DBEAVER.md](DBEAVER.md)

- ✅ Interface visuelle professionnelle
- ✅ Timer automatique intégré
- ✅ Export de résultats
- ✅ Plan d'exécution visuel

### Option 3 : DuckDB UI (Interface Web)

**Guide complet** : [DUCKDB-UI.md](DUCKDB-UI.md)

- ✅ Interface web moderne
- ✅ Aucune installation (version web)
- ✅ Timer intégré
- ✅ Parfait pour DuckDB

---

## 📁 Fichiers SQL Fournis

### Scripts de benchmark - Versions par base de données

**DuckDB (standard)** :
| Fichier | Description | Requêtes |
|---------|-------------|----------|
| `benchmark_01_pool_complet.sql` | Sans filtrage WHERE (YEAR/MONTH) | 10 |
| `benchmark_02_where_limite.sql` | Avec WHERE optimisé (YEAR/MONTH) | 10 |
| `comparaison_pools_complete.sql` | Pattern P1/P2/BOTH (YEAR/MONTH) | 8 |

**SQLite (avec strftime)** :
| Fichier | Description | Requêtes |
|---------|-------------|----------|
| `benchmark_01_pool_complet_sqlite.sql` | Sans filtrage WHERE (strftime) | 10 |
| `benchmark_02_where_limite_sqlite.sql` | Avec WHERE optimisé (strftime) | 10 |
| `comparaison_pools_complete_sqlite.sql` | Pattern P1/P2/BOTH (strftime) | 8 |

**IBM i / DB2** :
| Fichier | Description | Requêtes |
|---------|-------------|----------|
| `benchmark_ibmi.sql` | Version IBM i / DB2 | 12 |
| `comparaison_pools_ibmi.sql` | Version IBM i | 6 |

📘 **Documentation détaillée** : [SQL_VERSIONS.md](SQL_VERSIONS.md)

### Scripts de configuration

| Fichier | Description |
|---------|-------------|
| `setup_database.sql` | Génération données (généré) |
| `setup-database.ps1` | Wrapper PowerShell |
| `setup-database.sh` | Wrapper Bash |
| `run_benchmark.sh` | Script automatisé (utilise les bonnes versions) |

---

## 🎯 Cas d'usage métier

Les opérations ensemblistes sont essentielles pour :

### 🔍 Audit & Qualité
- Comparer PROD vs DEV
- Détecter données orphelines
- Vérifier synchronisation

### 📈 Analyse commerciale
- Identifier clients perdus (churn)
- Comparer produits 2024 vs 2025
- Segmentation client

### 💰 Finance
- Réconciliation de comptes
- Analyse TVA par taux
- Détection d'anomalies

### 🌍 Analyse géographique
- Comparer performances régionales
- Identifier marchés exclusifs
- Expansion géographique

---

## 📚 Ressources complémentaires

### Documentation officielle

- [DuckDB Documentation](https://duckdb.org/docs/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [Set Operations (Wikipedia)](https://en.wikipedia.org/wiki/Set_operations_(SQL))

### Fichiers importants du projet

- **[SQL_VERSIONS.md](SQL_VERSIONS.md)** - Guide des versions SQL (SQLite/DuckDB/IBM i)
- **[README_BENCHMARK.md](README_BENCHMARK.md)** - Guide des benchmarks
- **[VOLUMES.md](VOLUMES.md)** - Documentation de la volumétrie
- **[CHANGELOG.md](CHANGELOG.md)** - Historique des versions

### Lectures recommandées

- "SQL Performance Explained" - Markus Winand
- [DuckDB Blog](https://duckdb.org/news/) - Dernières optimisations
- [Modern SQL](https://modern-sql.com/) - Fonctionnalités SQL modernes

### Communautés

- [DuckDB Discord](https://discord.duckdb.org/)
- [SQLite Forum](https://sqlite.org/forum/)
- [r/SQL](https://reddit.com/r/SQL)

---

## 🤝 Contributions

Ce guide est conçu pour être pédagogique et évolutif. Les améliorations sont bienvenues :

- 🐛 Signaler des erreurs ou imprécisions
- 📝 Améliorer les explications
- 💡 Proposer de nouveaux cas d'usage
- 🚀 Ajouter des optimisations

---

## 📝 Structure des fichiers

```
ensemblistes-guide/
├── README.md                           # Ce fichier
├── INSTALL.md                          # Installation SQLite/DuckDB
├── DBEAVER.md                          # Guide DBeaver
├── DUCKDB-UI.md                        # Guide DuckDB UI
│
├── 00-setup.md                         # Configuration environnement
├── 01-concept-ensembliste.md           # Théorie de base
├── 02-except-differences.md            # Opération EXCEPT
├── 03-union-consolidation.md           # Opération UNION ALL
├── 04-intersect-similitudes.md         # Opération INTERSECT
├── 05-comparaison-complete.md          # Pattern avancé
├── 06-optimisation-where.md            # Optimisations
├── 07-benchmark-performance.md         # Benchmarks
│
├── sql/
│   ├── benchmark_01_pool_complet.sql
│   ├── benchmark_02_where_limite.sql
│   ├── benchmark_ibmi.sql
│   ├── comparaison_pools_complete.sql
│   └── comparaison_pools_ibmi.sql
│
├── scripts/
│   ├── setup-database.ps1              # PowerShell
│   └── setup-database.sh               # Bash
│
└── data/
    ├── facturation.db                  # SQLite
    ├── facturation.duckdb              # DuckDB
    └── setup_database.sql              # Généré
```

---

## ⏭️ Prochaines étapes

**Prêt à démarrer ?**

### Nouveaux utilisateurs

1. 📖 Lisez [INSTALL.md](INSTALL.md) pour installer SQLite et DuckDB
2. 🔧 Suivez [00-setup.md](00-setup.md) pour configurer l'environnement
3. 🎓 Commencez par [01-concept-ensembliste.md](01-concept-ensembliste.md)

### Utilisateurs expérimentés

1. ⚡ Installation rapide via [INSTALL.md](INSTALL.md)
2. 🚀 Générez les données : `./setup-database.sh`
3. 🎯 Direction [05-comparaison-complete.md](05-comparaison-complete.md)

---

## 🎓 Licence

Ce guide est fourni à des fins éducatives. Les données générées sont fictives.

---

**Bon apprentissage ! 🎓🦆**

*Créé pour démontrer la puissance de DuckDB en analytique et l'utilité des opérations ensemblistes en SQL.*
