# 🦆 Guide Pratique : Opérations Ensemblistes avec DuckDB et SQLite

![DuckDB](https://img.shields.io/badge/DuckDB-FFF000?style=for-the-badge&logo=duckdb&logoColor=black)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)

## 📚 Vue d'ensemble

Ce guide vous accompagne dans la découverte et la maîtrise des **opérations ensemblistes SQL** (EXCEPT, UNION ALL, INTERSECT) à travers une série d'exercices pratiques comparant **DuckDB** et **SQLite**.

### 🎯 Objectifs pédagogiques

À la fin de ce parcours, vous serez capable de :

1. ✅ Comprendre les 3 opérations ensemblistes et leurs cas d'usage
2. ✅ Identifier quand utiliser EXCEPT vs UNION ALL vs INTERSECT
3. ✅ Comparer les performances DuckDB vs SQLite sur des volumes réalistes
4. ✅ Optimiser vos requêtes avec des filtres WHERE stratégiques
5. ✅ Réaliser des audits de données et détections d'anomalies
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

## 🚀 Démarrage rapide

### Prérequis

- Python 3.8+
- 2 Go d'espace disque
- 4 Go de RAM minimum

### Installation en 3 commandes

```bash
# 1. Installer DuckDB et SQLite
pip install duckdb

# 2. Cloner ou télécharger ce dépôt
git clone <repo-url> ou télécharger le ZIP

# 3. Lancer la configuration
cd ensemblistes-guide
python setup_databases.py
```

### Vérification

```bash
# Doit afficher : ✅ SQLite : 5000 clients, 150000 factures
# Doit afficher : ✅ DuckDB : 5000 clients, 150000 factures
python verify_setup.py
```

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

## 📊 Jeu de données

### Schéma de la base

```
client (5 000 lignes)
├── client_id
├── nom, prenom, email
├── ville, code_postal
└── date_creation

facture (150 000 lignes)
├── facture_id
├── client_id → client
├── numero_facture
├── date_facture, date_echeance
├── montant_ht, montant_tva, montant_ttc
└── statut (BROUILLON, EMISE, PAYEE, ANNULEE)

ligne_facture (~500 000 lignes)
├── ligne_id
├── facture_id → facture
├── description (25 produits différents)
├── quantite, prix_unitaire
└── montant_ht, montant_tva, montant_ttc
```

### Caractéristiques

- **Volume** : ~500K lignes au total
- **Période** : 2020-2025 (5 ans)
- **Villes** : 18 villes françaises
- **Produits** : 25 produits IT/services
- **CA moyen** : 10K-200K€ par facture

## 🛠️ Outils fournis

### Scripts Python

- `setup_databases.py` - Génération des données de test
- `verify_setup.py` - Vérification de l'installation
- `benchmark.py` - Mesure automatique des performances
- `compare_results.py` - Comparaison des résultats

### Scripts SQL

- `benchmark_01_pool_complet.sql` - 10 requêtes sans filtrage
- `benchmark_02_where_limite.sql` - 10 requêtes optimisées
- `comparaison_pools_complete.sql` - Pattern de comparaison complète

### Documentation

- 8 fichiers Markdown progressifs
- Présentation PowerPoint (DuckDB_Operations_Ensemblistes.pptx)
- README_BENCHMARK.md - Guide benchmark détaillé

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

## 📚 Ressources complémentaires

### Documentation officielle

- [DuckDB Documentation](https://duckdb.org/docs/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [Set Operations (Wikipedia)](https://en.wikipedia.org/wiki/Set_operations_(SQL))

### Lectures recommandées

- "SQL Performance Explained" - Markus Winand
- "The Art of PostgreSQL" - Dimitri Fontaine (principes applicables)
- [DuckDB Blog](https://duckdb.org/news/) - Dernières optimisations

### Communautés

- [DuckDB Discord](https://discord.duckdb.org/)
- [SQLite Forum](https://sqlite.org/forum/)
- [r/SQL](https://reddit.com/r/SQL)

## 🤝 Contributions

Ce guide est conçu pour être pédagogique et évolutif. Les contributions sont bienvenues :

- 🐛 Signaler des erreurs ou imprécisions
- 📝 Améliorer les explications
- 💡 Proposer de nouveaux cas d'usage
- 🚀 Ajouter des optimisations

## 📝 Licence

Ce guide est fourni à des fins éducatives. Les données générées sont fictives.

## 🎓 Auteurs & Crédits

Créé pour démontrer la puissance de DuckDB en analytique et l'utilité des opérations ensemblistes en SQL.

---

## ⏭️ Prochaines étapes

**Prêt à démarrer ?**

👉 Commencez par [00-setup.md](00-setup.md) pour configurer votre environnement

**Déjà configuré ?**

👉 Plongez dans [01-concept-ensembliste.md](01-concept-ensembliste.md) pour comprendre les bases

---

**Bon apprentissage ! 🎓🦆**
