# 01 - Comprendre les Opérations Ensemblistes

## 🎯 Objectifs

À la fin de ce chapitre, vous serez capable de :

- ✅ Comprendre la **théorie des ensembles** appliquée au SQL
- ✅ Différencier **EXCEPT**, **UNION ALL** et **INTERSECT**
- ✅ Identifier les **cas d'usage** de chaque opération
- ✅ Visualiser les résultats avec des **diagrammes de Venn**

**Durée estimée : 20 minutes**

---

## ⚠️ Note sur les exemples SQL

Les exemples utilisent la **syntaxe DuckDB** avec `YEAR()` et `MONTH()`.

**Pour SQLite** : Remplacez `YEAR(date)` → `strftime('%Y', date)` et `MONTH(date)` → `strftime('%m', date)`

📘 Fichiers adaptés disponibles : voir **[SQL_VERSIONS.md](SQL_VERSIONS.md)**

---

## 📚 Théorie des ensembles

### Qu'est-ce qu'un ensemble en SQL ?

Un **ensemble** est un groupe de lignes retourné par une requête SELECT.

```sql
-- Ensemble A : Tous les clients de Paris
SELECT client_id, nom, prenom 
FROM client 
WHERE ville = 'Paris';

-- Ensemble B : Tous les clients de Lyon
SELECT client_id, nom, prenom 
FROM client 
WHERE ville = 'Lyon';
```

### Les 3 opérations fondamentales

| Opération | Symbole Math | SQL | Résultat |
|-----------|--------------|-----|----------|
| **Différence** | A - B | A EXCEPT B | Éléments dans A mais pas dans B |
| **Union** | A ∪ B | A UNION ALL B | Tous les éléments de A et B |
| **Intersection** | A ∩ B | A INTERSECT B | Éléments présents dans A ET B |

---

## 🔵 Diagrammes de Venn

### EXCEPT (Différence)

```
    ╔════════════╗
    ║ A EXCEPT B ║
    ║ ░░░░░░     ║╔═══════╗
    ║ ░░░░░░     ║║   B   ║
    ║ ░░░░░░     ║║       ║
    ╚════════════╝╚═══════╝
     Zone colorée = résultat
```

**Retourne** : Lignes dans A mais **absentes** de B

### UNION ALL (Union complète)

```
    ╔════════════╗
    ║ A UNION B  ║
    ║ ░░░░░░░░░░ ║╔═══════╗
    ║ ░░░░░░░░░░ ║║░░░░░░░║
    ║ ░░░░░░░░░░ ║║░░░░░░░║
    ╚════════════╝╚═══════╝
     Tout est coloré = résultat
```

**Retourne** : **Toutes** les lignes de A et B (avec doublons possibles)

### INTERSECT (Intersection)

```
    ╔════════════╗
    ║     A      ║
    ║         ░░ ║╔═══════╗
    ║         ░░ ║║░░  B  ║
    ║            ║║       ║
    ╚════════════╝╚═══════╝
     Zone de chevauchement = résultat
```

**Retourne** : Lignes présentes **à la fois** dans A et B

---

## 🧪 Exemples concrets

### Préparation

Ouvrez deux shells (un pour chaque base) :

**Terminal 1 - SQLite :**
```bash
cd data
sqlite3 facturation.db
.timer on
.mode column
.headers on
```

**Terminal 2 - DuckDB :**
```bash
cd data
duckdb facturation.duckdb
.timer on
.mode line
```

### Exemple 1 : EXCEPT - Clients perdus

**Question métier** : Quels clients ont acheté en 2024 mais pas en 2025 ?

```sql
-- Clients actifs en 2024
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

-- Clients actifs en 2025
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

**Résultat attendu :**
```
client_id | nom      | prenom | ville
----------|----------|--------|----------
123       | Dupont   | Jean   | Paris
456       | Martin   | Sophie | Lyon
789       | Bernard  | Luc    | Marseille
...
(~300-800 clients perdus)
```

**Interprétation** : Ce sont les clients **en churn** (perdus) - action commerciale nécessaire !

### Exemple 2 : UNION ALL - Consolidation annuelle

**Question métier** : Quel est le CA total sur 2024 et 2025 ?

```sql
-- CA 2024
SELECT 
    2024 AS annee,
    COUNT(*) AS nb_factures,
    ROUND(SUM(montant_ttc), 2) AS ca_total
FROM facture
WHERE YEAR(date_facture) = 2024
  AND statut = 'PAYEE'

UNION ALL

-- CA 2025
SELECT 
    2025 AS annee,
    COUNT(*) AS nb_factures,
    ROUND(SUM(montant_ttc), 2) AS ca_total
FROM facture
WHERE YEAR(date_facture) = 2025
  AND statut = 'PAYEE';
```

**Résultat attendu :**
```
annee | nb_factures | ca_total
------|-------------|------------
2024  | 24567      | 125678900.50
2025  | 3456       | 18234567.75
```

**Interprétation** : Vision consolidée multi-années pour reporting.

### Exemple 3 : INTERSECT - Clients fidèles

**Question métier** : Quels clients ont acheté en 2024 ET 2025 ?

```sql
-- Clients 2024
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE'

INTERSECT

-- Clients 2025
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025
  AND f.statut = 'PAYEE';
```

**Résultat attendu :**
```
client_id | nom     | prenom  | email
----------|---------|---------|----------------------
234       | Petit   | Marie   | marie.petit@example.com
567       | Robert  | Paul    | paul.robert@example.com
...
(~200-500 clients fidèles)
```

**Interprétation** : Ces clients sont **fidèles** - programme de rétention à maintenir !

---

## 📊 Comparaison des performances

### Test simple

Exécutez cette requête dans les deux bases :

```sql
-- Compter les factures par statut
SELECT statut, COUNT(*) AS nb
FROM facture
GROUP BY statut;
```

**Notez les temps :**
- SQLite : _______ secondes
- DuckDB : _______ secondes

**Vous devriez constater** : DuckDB est souvent **2-5x plus rapide** sur les agrégations.

---

## 🎯 Cas d'usage métier

### EXCEPT - Détection de différences

| Scénario | Ensemble A | Ensemble B | Objectif |
|----------|------------|------------|----------|
| **Churn analysis** | Clients 2024 | Clients 2025 | Identifier clients perdus |
| **Audit PROD/DEV** | Données PROD | Données DEV | Trouver incohérences |
| **Migration** | Table source | Table cible | Vérifier complétude |
| **Catalogues** | Produits 2024 | Produits 2025 | Produits abandonnés |

### UNION ALL - Consolidation

| Scénario | Ensemble A | Ensemble B | Objectif |
|----------|------------|------------|----------|
| **Reporting** | Ventes Q1 | Ventes Q2 | CA semestriel |
| **Multi-sources** | Base Paris | Base Lyon | Vue nationale |
| **Historique** | Archive 2023 | Archive 2024 | Analyse temporelle |
| **Segments** | Clients VIP | Clients standards | Vue globale |

### INTERSECT - Similitudes

| Scénario | Ensemble A | Ensemble B | Objectif |
|----------|------------|------------|----------|
| **Fidélité** | Clients 2024 | Clients 2025 | Clients récurrents |
| **Cross-sell** | Acheteurs produit A | Acheteurs produit B | Opportunités |
| **Cohérence** | Référentiel 1 | Référentiel 2 | Données synchronisées |
| **Qualité** | Données validées | Données importées | Taux de réussite |

---

## 🔍 Différences clés

### UNION vs UNION ALL

```sql
-- UNION : Élimine les doublons (plus lent)
SELECT ville FROM client WHERE ville = 'Paris'
UNION
SELECT ville FROM client WHERE ville = 'Paris';
-- Résultat : 1 ligne 'Paris'

-- UNION ALL : Garde les doublons (plus rapide)
SELECT ville FROM client WHERE ville = 'Paris'
UNION ALL
SELECT ville FROM client WHERE ville = 'Paris';
-- Résultat : 2 lignes 'Paris'
```

**Recommandation** : Utilisez **UNION ALL** sauf si vous devez absolument dédoublonner.

### EXCEPT vs NOT IN

```sql
-- EXCEPT (recommandé pour grands volumes)
SELECT client_id FROM client
EXCEPT
SELECT client_id FROM facture;

-- NOT IN (plus lent sur gros volumes)
SELECT client_id FROM client
WHERE client_id NOT IN (SELECT client_id FROM facture);
```

**Performance** : EXCEPT est généralement **2-10x plus rapide** grâce aux optimisations.

---

## 🧠 Règles importantes

### 1. Compatibilité des colonnes

```sql
-- ✅ CORRECT : Même nombre et type de colonnes
SELECT client_id, nom FROM client
UNION ALL
SELECT client_id, nom FROM client;

-- ❌ ERREUR : Nombre de colonnes différent
SELECT client_id, nom FROM client
UNION ALL
SELECT client_id FROM client;
```

### 2. Ordre des colonnes

```sql
-- ⚠️ ATTENTION : L'ordre compte !
SELECT client_id, nom FROM client
EXCEPT
SELECT nom, client_id FROM client;
-- Peut retourner des résultats inattendus
```

### 3. Types de données

```sql
-- ✅ CORRECT : Types compatibles
SELECT client_id FROM client      -- INTEGER
UNION ALL
SELECT facture_id FROM facture;   -- INTEGER

-- ⚠️ RISQUÉ : Conversion implicite
SELECT client_id FROM client      -- INTEGER
UNION ALL
SELECT numero_facture FROM facture; -- TEXT
-- SQLite convertit, DuckDB peut être plus strict
```

---

## 🎓 Exercices pratiques

### Exercice 1 : Villes uniques

**Question** : Quelles villes ont des clients mais aucune facture payée ?

<details>
<summary>💡 Indice</summary>

Utilisez EXCEPT entre toutes les villes et les villes avec factures payées.

</details>

<details>
<summary>✅ Solution</summary>

```sql
SELECT DISTINCT ville FROM client
EXCEPT
SELECT DISTINCT c.ville 
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE';
```

</details>

### Exercice 2 : Produits communs

**Question** : Quels produits ont été vendus à la fois à Paris ET à Lyon ?

<details>
<summary>💡 Indice</summary>

Utilisez INTERSECT entre produits vendus à Paris et produits vendus à Lyon.

</details>

<details>
<summary>✅ Solution</summary>

```sql
SELECT DISTINCT lf.description
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris' AND f.statut = 'PAYEE'

INTERSECT

SELECT DISTINCT lf.description
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE';
```

</details>

### Exercice 3 : Consolidation CA

**Question** : Affichez le CA mensuel de 2024 en une seule table (12 lignes).

<details>
<summary>💡 Indice</summary>

Utilisez 12 SELECT avec UNION ALL, un par mois.

</details>

<details>
<summary>✅ Solution</summary>

```sql
SELECT 1 AS mois, 'Janvier' AS nom, SUM(montant_ttc) AS ca
FROM facture 
WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 1 AND statut = 'PAYEE'

UNION ALL

SELECT 2, 'Février', SUM(montant_ttc)
FROM facture 
WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 2 AND statut = 'PAYEE'

-- ... répéter pour mois 3-12 ...

UNION ALL

SELECT 12, 'Décembre', SUM(montant_ttc)
FROM facture 
WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 12 AND statut = 'PAYEE'

ORDER BY mois;
```

</details>

---

## 📝 Points clés à retenir

| Opération | Quand l'utiliser | Performance | Déduplication |
|-----------|------------------|-------------|---------------|
| **EXCEPT** | Trouver différences, churn, anomalies | Moyenne | Automatique |
| **UNION ALL** | Consolider, combiner sources | Rapide | Non |
| **UNION** | Combiner + dédoublonner | Lente | Oui |
| **INTERSECT** | Trouver similitudes, cohérence | Moyenne | Automatique |

### Mnémotechnique

- **EXCEPT** = **EX**clusion (ce qui manque dans B)
- **UNION** = **UNI**fication (tout ensemble)
- **INTERSECT** = **INTER**section (zone commune)

---

## 🔧 Commandes utiles

### SQLite

```sql
-- Activer le timer
.timer on

-- Format colonnes
.mode column
.headers on

-- Sauvegarder résultat
.output resultats.txt
SELECT ...;
.output stdout
```

### DuckDB

```sql
-- Activer le timer
.timer on

-- Export CSV
COPY (SELECT ...) TO 'resultats.csv' (HEADER, DELIMITER ',');

-- Statistiques table
SELECT * FROM information_schema.tables WHERE table_name = 'facture';
```

---

## ⏭️ Prochaine étape

Maintenant que vous comprenez les concepts de base, passons à la pratique !

👉 Continuez avec [02-except-differences.md](02-except-differences.md) pour maîtriser l'opération EXCEPT.

---

## 📚 Ressources

- [Wikipedia - Set Operations (SQL)](https://en.wikipedia.org/wiki/Set_operations_(SQL))
- [DuckDB - Set Operations](https://duckdb.org/docs/sql/query_syntax/setops)
- [SQLite - Compound SELECT](https://www.sqlite.org/lang_select.html#compound_select_statements)

---

**Vous avez compris les bases ? Excellent ! 🎓**
