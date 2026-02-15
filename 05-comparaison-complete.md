# 05 - Comparaison Complète : Le Pattern Ultime

## 🎯 Objectifs

À la fin de ce chapitre, vous serez capable de :

- ✅ Combiner **EXCEPT + UNION ALL + INTERSECT** en une seule requête
- ✅ Implémenter le pattern **"P1_ONLY, P2_ONLY, BOTH"**
- ✅ Réaliser des **audits complets** de synchronisation
- ✅ Analyser des **évolutions temporelles** complexes

**Durée estimée : 40 minutes**

---

## ⚠️ Note sur les exemples SQL

Les exemples utilisent la **syntaxe DuckDB** avec `YEAR()` et `MONTH()`.

**Pour SQLite** : Remplacez `YEAR(date)` → `strftime('%Y', date)` et `MONTH(date)` → `strftime('%m', date)`

📘 Fichiers adaptés disponibles : voir **[SQL_VERSIONS.md](SQL_VERSIONS.md)**

---

## 📚 Le Pattern de Comparaison Complète

### Concept

Au lieu de lancer 3 requêtes séparées (EXCEPT, EXCEPT inverse, INTERSECT), nous les combinons en **une seule** avec des **indicateurs de source**.

```
'P1_ONLY', * FROM (P1 EXCEPT P2)
UNION ALL
'P2_ONLY', * FROM (P2 EXCEPT P1)
UNION ALL
'BOTH',    * FROM (P1 INTERSECT P2)
```

### Avantages

| Avantage | Description |
|----------|-------------|
| 📊 **Vue 360°** | Toutes les différences ET similitudes en un coup d'œil |
| 🎯 **Indicateur clair** | Colonne `source` permet tri/filtrage facile |
| 🚀 **Une seule exécution** | Plus efficace que 3 requêtes séparées |
| 📈 **Analyse complète** | Détecte churn, nouveaux, fidèles simultanément |

---

## 🧪 Cas d'usage 1 : Analyse de Churn Complète

### Problématique métier

**Question** : Vue complète de l'évolution client 2024→2025 : perdus, nouveaux, fidèles ?

**Enjeu** : **Dashboard complet** de rétention client.

### Solution

```sql
-- Clients 2024 uniquement (perdus en 2025)
SELECT 
    'CHURN_2024' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE'

EXCEPT

SELECT 
    'CHURN_2024' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025
  AND f.statut = 'PAYEE'

UNION ALL

-- Clients 2025 uniquement (nouveaux)
SELECT 
    'NOUVEAUX_2025' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025
  AND f.statut = 'PAYEE'

EXCEPT

SELECT 
    'NOUVEAUX_2025' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE'

UNION ALL

-- Clients présents les 2 années (fidèles)
SELECT 
    'FIDELES' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE'

INTERSECT

SELECT 
    'FIDELES' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025
  AND f.statut = 'PAYEE'

ORDER BY source, ville, nom;
```

### Exécution et analyse

**SQLite** :
```bash
sqlite3 facturation.db
.timer on
.mode column
.headers on
-- Coller la requête
```

**DuckDB** :
```bash
duckdb facturation.duckdb
.timer on
-- Coller la requête
```

**Notez les temps** :
- SQLite : _______ secondes
- DuckDB : _______ secondes

### Statistiques par catégorie

```sql
WITH evolution_clients AS (
    -- [Insérer la requête complète ci-dessus]
)
SELECT 
    source,
    COUNT(*) AS nb_clients,
    COUNT(DISTINCT ville) AS nb_villes
FROM evolution_clients
GROUP BY source
ORDER BY source;
```

**Résultat attendu** :
```
source           | nb_clients | nb_villes
-----------------|------------|----------
CHURN_2024       | 650        | 16
FIDELES          | 320        | 14
NOUVEAUX_2025    | 180        | 10
```

**Interprétation** :
- **Taux de rétention** : 320 / (320 + 650) = 33%
- **Taux de churn** : 650 / (320 + 650) = 67%
- **Nouveaux clients** : 180 (croissance modérée)

---

## 🧪 Cas d'usage 2 : Comparaison Catalogue Produits

### Problématique métier

**Question** : Évolution du catalogue 2024→2025 : produits abandonnés, nouveaux, récurrents ?

**Enjeu** : **Stratégie produit** basée sur données.

### Solution avec métriques

```sql
-- Produits 2024 uniquement (abandonnés)
SELECT 
    'ABANDONNES_2024' AS source,
    lf.description AS produit,
    COUNT(DISTINCT f.facture_id) AS nb_factures,
    ROUND(SUM(lf.montant_ttc), 2) AS ca_ttc
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY lf.description

EXCEPT

SELECT 
    'ABANDONNES_2024' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY lf.description

UNION ALL

-- Produits 2025 uniquement (nouveaux)
SELECT 
    'NOUVEAUX_2025' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY lf.description

EXCEPT

SELECT 
    'NOUVEAUX_2025' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY lf.description

UNION ALL

-- Produits récurrents (les 2 années)
SELECT 
    'RECURRENTS' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY lf.description

INTERSECT

SELECT 
    'RECURRENTS' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY lf.description

ORDER BY source, ca_ttc DESC;
```

**Analyse** : Identifiez les produits à arrêter vs investir.

---

## 🧪 Cas d'usage 3 : Comparaison Géographique

### Problématique métier

**Question** : Comparaison Paris vs Lyon : clients exclusifs et communs ?

**Enjeu** : **Stratégie régionale** et expansion.

### Solution

```sql
-- Clients uniquement à Paris
SELECT 
    'PARIS_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Paris' AND f.statut = 'PAYEE'

EXCEPT

SELECT 
    'PARIS_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE'

UNION ALL

-- Clients uniquement à Lyon
SELECT 
    'LYON_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE'

EXCEPT

SELECT 
    'LYON_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Paris' AND f.statut = 'PAYEE'

UNION ALL

-- Clients présents dans les 2 villes (profils nationaux)
SELECT 
    'BOTH_CITIES' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Paris' AND f.statut = 'PAYEE'

INTERSECT

SELECT 
    'BOTH_CITIES' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE'

ORDER BY source, nom;
```

**Note** : "BOTH_CITIES" indique des clients ayant acheté dans les 2 villes (rares).

---

## 🧪 Cas d'usage 4 : Audit PROD vs DEV

### Problématique métier

**Question** : Synchronisation PROD/DEV : données manquantes, excédentaires, synchronisées ?

**Enjeu** : **Qualité des environnements** de test.

### Solution (simulation avec années)

```sql
-- Données en PROD uniquement (à copier vers DEV)
SELECT 
    'PROD_ONLY' AS source,
    client_id,
    nom,
    prenom,
    email,
    date_creation
FROM client
WHERE YEAR(date_creation) <= 2024

EXCEPT

SELECT 
    'PROD_ONLY' AS source,
    client_id,
    nom,
    prenom,
    email,
    date_creation
FROM client
WHERE YEAR(date_creation) = 2025

UNION ALL

-- Données en DEV uniquement (données de test à nettoyer)
SELECT 
    'DEV_ONLY' AS source,
    client_id,
    nom,
    prenom,
    email,
    date_creation
FROM client
WHERE YEAR(date_creation) = 2025

EXCEPT

SELECT 
    'DEV_ONLY' AS source,
    client_id,
    nom,
    prenom,
    email,
    date_creation
FROM client
WHERE YEAR(date_creation) <= 2024

UNION ALL

-- Données synchronisées (OK)
SELECT 
    'SYNCHRONIZED' AS source,
    client_id,
    nom,
    prenom,
    email,
    date_creation
FROM client
WHERE YEAR(date_creation) <= 2024

INTERSECT

SELECT 
    'SYNCHRONIZED' AS source,
    client_id,
    nom,
    prenom,
    email,
    date_creation
FROM client
WHERE YEAR(date_creation) = 2025

ORDER BY source, client_id;
```

### Version réelle (IBM i)

```sql
-- PROD_ONLY
SELECT 'PROD_ONLY', * FROM PROD.CLIENT
EXCEPT
SELECT 'PROD_ONLY', * FROM DEV.CLIENT

UNION ALL

-- DEV_ONLY
SELECT 'DEV_ONLY', * FROM DEV.CLIENT
EXCEPT
SELECT 'DEV_ONLY', * FROM PROD.CLIENT

UNION ALL

-- SYNCHRONIZED
SELECT 'SYNCHRONIZED', * FROM PROD.CLIENT
INTERSECT
SELECT 'SYNCHRONIZED', * FROM DEV.CLIENT;
```

---

## 🧪 Cas d'usage 5 : Analyse Q1 vs Q4 (Saisonnalité)

### Problématique métier

**Question** : Clients Q1 only, Q4 only, réguliers (both) ?

**Enjeu** : Identifier **saisonnalité** et clients réguliers.

### Solution avec CTE

```sql
WITH pool_q1 AS (
    SELECT 
        c.client_id,
        c.nom,
        c.prenom,
        c.ville,
        COUNT(f.facture_id) AS nb_factures,
        ROUND(SUM(f.montant_ttc), 2) AS ca_ttc
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE f.statut = 'PAYEE'
      AND f.date_facture >= '2024-01-01'
      AND f.date_facture <= '2024-03-31'
    GROUP BY c.client_id, c.nom, c.prenom, c.ville
),
pool_q4 AS (
    SELECT 
        c.client_id,
        c.nom,
        c.prenom,
        c.ville,
        COUNT(f.facture_id) AS nb_factures,
        ROUND(SUM(f.montant_ttc), 2) AS ca_ttc
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE f.statut = 'PAYEE'
      AND f.date_facture >= '2024-10-01'
      AND f.date_facture <= '2024-12-31'
    GROUP BY c.client_id, c.nom, c.prenom, c.ville
)
-- Q1 uniquement
SELECT 'Q1_ONLY' AS source, * FROM pool_q1
EXCEPT
SELECT 'Q1_ONLY' AS source, * FROM pool_q4

UNION ALL

-- Q4 uniquement
SELECT 'Q4_ONLY' AS source, * FROM pool_q4
EXCEPT
SELECT 'Q4_ONLY' AS source, * FROM pool_q1

UNION ALL

-- Les deux trimestres (réguliers)
SELECT 'BOTH_Q1_Q4' AS source, * FROM pool_q1
INTERSECT
SELECT 'BOTH_Q1_Q4' AS source, * FROM pool_q4

ORDER BY source, ca_ttc DESC;
```

**Analyse** :
- **Q1_ONLY** : Clients de début d'année (budget?)
- **Q4_ONLY** : Clients de fin d'année (fin de budget?)
- **BOTH_Q1_Q4** : Clients réguliers non-saisonniers

---

## 📊 Pattern avec Statistiques Agrégées

### Comparaison avec résumé

```sql
WITH comparison_data AS (
    -- Paris only
    SELECT 'PARIS_ONLY' AS source, c.client_id, c.nom, COUNT(f.facture_id) AS nb, SUM(f.montant_ttc) AS ca
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Paris' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    EXCEPT
    SELECT 'PARIS_ONLY', c.client_id, c.nom, COUNT(f.facture_id), SUM(f.montant_ttc)
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    UNION ALL
    
    -- Lyon only
    SELECT 'LYON_ONLY', c.client_id, c.nom, COUNT(f.facture_id), SUM(f.montant_ttc)
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    EXCEPT
    SELECT 'LYON_ONLY', c.client_id, c.nom, COUNT(f.facture_id), SUM(f.montant_ttc)
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Paris' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    UNION ALL
    
    -- Both
    SELECT 'BOTH', c.client_id, c.nom, COUNT(f.facture_id), SUM(f.montant_ttc)
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Paris' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    INTERSECT
    SELECT 'BOTH', c.client_id, c.nom, COUNT(f.facture_id), SUM(f.montant_ttc)
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
)
-- Statistiques par catégorie
SELECT 
    source,
    COUNT(*) AS nb_clients,
    SUM(nb) AS total_factures,
    ROUND(SUM(ca), 2) AS total_ca,
    ROUND(AVG(ca), 2) AS ca_moyen,
    ROUND(MIN(ca), 2) AS ca_min,
    ROUND(MAX(ca), 2) AS ca_max
FROM comparison_data
GROUP BY source
ORDER BY source;
```

**Résultat attendu** :
```
source      | nb_clients | total_factures | total_ca     | ca_moyen    | ca_min  | ca_max
------------|------------|----------------|--------------|-------------|---------|----------
BOTH        | 15         | 234            | 1234567.50   | 82304.50    | 5000.00 | 250000.00
LYON_ONLY   | 187        | 1456           | 5678901.25   | 30369.26    | 500.00  | 180000.00
PARIS_ONLY  | 234        | 2345           | 12345678.90  | 52759.91    | 800.00  | 320000.00
```

---

## 🔧 Template Générique Réutilisable

```sql
WITH pool_1 AS (
    SELECT 
        colonne1,
        colonne2,
        COUNT(*) as metric1,
        SUM(valeur) as metric2
    FROM table_source
    WHERE <CONDITION_P1>
    GROUP BY colonne1, colonne2
),
pool_2 AS (
    SELECT 
        colonne1,
        colonne2,
        COUNT(*) as metric1,
        SUM(valeur) as metric2
    FROM table_source
    WHERE <CONDITION_P2>
    GROUP BY colonne1, colonne2
)
-- P1 uniquement
SELECT 'P1_ONLY' AS source, * FROM pool_1
EXCEPT
SELECT 'P1_ONLY' AS source, * FROM pool_2

UNION ALL

-- P2 uniquement
SELECT 'P2_ONLY' AS source, * FROM pool_2
EXCEPT
SELECT 'P2_ONLY' AS source, * FROM pool_1

UNION ALL

-- Intersection
SELECT 'BOTH' AS source, * FROM pool_1
INTERSECT
SELECT 'BOTH' AS source, * FROM pool_2

ORDER BY source;
```

---

## 📊 Benchmark : Comparaison Complète

### Test de performance

Exécutez la requête de churn complète et notez les temps :

**SQLite** : _______ secondes  
**DuckDB** : _______ secondes

**Différence attendue** : DuckDB devrait être **3-8x plus rapide** grâce à :
- Vectorisation SIMD
- Parallélisation des opérations
- Compression columnar

---

## 🎓 Exercices pratiques

### Exercice 1 : Comparaison Villes Matures vs Émergentes

Créez une comparaison complète entre Paris/Lyon (matures) et autres villes (émergentes).

<details>
<summary>✅ Solution</summary>

```sql
SELECT 'MATURES_ONLY' AS source, c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville IN ('Paris', 'Lyon') AND f.statut = 'PAYEE'
EXCEPT
SELECT 'MATURES_ONLY', c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville NOT IN ('Paris', 'Lyon') AND f.statut = 'PAYEE'

UNION ALL

SELECT 'EMERGENTES_ONLY', c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville NOT IN ('Paris', 'Lyon') AND f.statut = 'PAYEE'
EXCEPT
SELECT 'EMERGENTES_ONLY', c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville IN ('Paris', 'Lyon') AND f.statut = 'PAYEE'

UNION ALL

SELECT 'BOTH', c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville IN ('Paris', 'Lyon') AND f.statut = 'PAYEE'
INTERSECT
SELECT 'BOTH', c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville NOT IN ('Paris', 'Lyon') AND f.statut = 'PAYEE';
```

</details>

---

## 📝 Checklist Pattern Complet

- [ ] CTE pour clarté (pool_1, pool_2)
- [ ] EXCEPT dans les deux sens (P1-P2, P2-P1)
- [ ] INTERSECT pour éléments communs
- [ ] UNION ALL pour combiner les 3 parties
- [ ] Indicateur source clair ('P1_ONLY', 'P2_ONLY', 'BOTH')
- [ ] ORDER BY source pour regroupement
- [ ] Même structure de colonnes partout

---

## ⏭️ Prochaine étape

Vous maîtrisez le pattern de comparaison complète !

👉 Passez à [06-optimisation-where.md](06-optimisation-where.md) pour optimiser les performances.

---

**Bravo ! Vous avez le pattern ultime de comparaison. 🚀**
