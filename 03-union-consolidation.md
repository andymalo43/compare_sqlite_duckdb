# 03 - UNION ALL : Consolider les Données

## 🎯 Objectifs

À la fin de ce chapitre, vous serez capable de :

- ✅ Comprendre la différence entre **UNION** et **UNION ALL**
- ✅ Consolider des données de **sources multiples**
- ✅ Optimiser les requêtes avec **UNION ALL**
- ✅ Mesurer l'impact de la **déduplication**

**Durée estimée : 25 minutes**

---

## ⚠️ Note sur les exemples SQL

Les exemples utilisent la **syntaxe DuckDB** avec `YEAR()` et `MONTH()`.

**Pour SQLite** : Remplacez `YEAR(date)` → `strftime('%Y', date)` et `MONTH(date)` → `strftime('%m', date)`

📘 Fichiers adaptés disponibles : voir **[SQL_VERSIONS.md](SQL_VERSIONS.md)**

---

## 📚 Théorie : UNION vs UNION ALL

### UNION ALL - Tout conserver

**UNION ALL** combine tous les résultats de A et B, **avec les doublons**.

```
Ensemble A        Ensemble B        A UNION ALL B
┌─────────┐      ┌─────────┐       ┌─────────┐
│  1, 2   │      │  2, 3   │       │  1, 2   │
│  3      │      │  4      │       │  3, 2   │
│         │      │         │       │  3, 4   │
└─────────┘      └─────────┘       └─────────┘
```

### UNION - Dédoublonner

**UNION** combine A et B et **élimine les doublons**.

```
Ensemble A        Ensemble B        A UNION B
┌─────────┐      ┌─────────┐       ┌─────────┐
│  1, 2   │      │  2, 3   │       │  1, 2   │
│  3      │      │  4      │       │  3, 4   │
│         │      │         │       └─────────┘
└─────────┘      └─────────┘       (Pas de doublon 2)
```

### Comparaison

| Critère | UNION | UNION ALL |
|---------|-------|-----------|
| **Doublons** | ❌ Éliminés | ✅ Conservés |
| **Performance** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Tri implicite** | Oui (pour dédup) | Non |
| **Usage** | Rare | Fréquent |

**Recommandation** : Utilisez **UNION ALL** par défaut, sauf besoin explicite de déduplication.

---

## 🧪 Cas d'usage 1 : Consolidation Multi-Années

### Problématique métier

**Question** : Quel est le CA total sur 2024 et 2025 combinés ?

**Enjeu** : Vue **consolidée** pour reporting multi-périodes.

### Solution avec UNION ALL

```sql
-- CA 2024
SELECT 
    2024 AS annee,
    'CA 2024' AS periode,
    COUNT(*) AS nb_factures,
    ROUND(SUM(montant_ht), 2) AS ca_ht,
    ROUND(SUM(montant_tva), 2) AS ca_tva,
    ROUND(SUM(montant_ttc), 2) AS ca_ttc
FROM facture
WHERE YEAR(date_facture) = 2024
  AND statut = 'PAYEE'

UNION ALL

-- CA 2025
SELECT 
    2025 AS annee,
    'CA 2025' AS periode,
    COUNT(*) AS nb_factures,
    ROUND(SUM(montant_ht), 2) AS ca_ht,
    ROUND(SUM(montant_tva), 2) AS ca_tva,
    ROUND(SUM(montant_ttc), 2) AS ca_ttc
FROM facture
WHERE YEAR(date_facture) = 2025
  AND statut = 'PAYEE'

ORDER BY annee;
```

### Exécution

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
- SQLite : _______ ms
- DuckDB : _______ ms

**Résultat attendu** :
```
annee | periode   | nb_factures | ca_ht        | ca_tva      | ca_ttc
------|-----------|-------------|--------------|-------------|-------------
2024  | CA 2024   | 24567       | 98234567.50  | 19646913.50 | 117881481.00
2025  | CA 2025   | 3456        | 15678901.25  | 3135780.25  | 18814681.50
```

### Variante : CA Total

```sql
SELECT 
    'TOTAL 2024-2025' AS periode,
    SUM(nb_factures) AS total_factures,
    ROUND(SUM(ca_ttc), 2) AS ca_total
FROM (
    SELECT COUNT(*) AS nb_factures, SUM(montant_ttc) AS ca_ttc
    FROM facture WHERE YEAR(date_facture) = 2024 AND statut = 'PAYEE'
    
    UNION ALL
    
    SELECT COUNT(*), SUM(montant_ttc)
    FROM facture WHERE YEAR(date_facture) = 2025 AND statut = 'PAYEE'
) AS consolidation;
```

---

## 🧪 Cas d'usage 2 : Consolidation Mensuelle

### Problématique métier

**Question** : Afficher le CA mensuel de 2024 en une seule table.

**Enjeu** : Vue **temporelle** pour analyse de saisonnalité.

### Solution (version complète 12 mois)

```sql
SELECT 1 AS mois, 'Janvier' AS nom_mois, 
       COUNT(*) AS nb_factures, 
       ROUND(SUM(montant_ttc), 2) AS ca_ttc
FROM facture 
WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 1 AND statut = 'PAYEE'

UNION ALL SELECT 2, 'Février', COUNT(*), ROUND(SUM(montant_ttc), 2)
FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 2 AND statut = 'PAYEE'

UNION ALL SELECT 3, 'Mars', COUNT(*), ROUND(SUM(montant_ttc), 2)
FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 3 AND statut = 'PAYEE'

UNION ALL SELECT 4, 'Avril', COUNT(*), ROUND(SUM(montant_ttc), 2)
FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 4 AND statut = 'PAYEE'

UNION ALL SELECT 5, 'Mai', COUNT(*), ROUND(SUM(montant_ttc), 2)
FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 5 AND statut = 'PAYEE'

UNION ALL SELECT 6, 'Juin', COUNT(*), ROUND(SUM(montant_ttc), 2)
FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 6 AND statut = 'PAYEE'

UNION ALL SELECT 7, 'Juillet', COUNT(*), ROUND(SUM(montant_ttc), 2)
FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 7 AND statut = 'PAYEE'

UNION ALL SELECT 8, 'Août', COUNT(*), ROUND(SUM(montant_ttc), 2)
FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 8 AND statut = 'PAYEE'

UNION ALL SELECT 9, 'Septembre', COUNT(*), ROUND(SUM(montant_ttc), 2)
FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 9 AND statut = 'PAYEE'

UNION ALL SELECT 10, 'Octobre', COUNT(*), ROUND(SUM(montant_ttc), 2)
FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 10 AND statut = 'PAYEE'

UNION ALL SELECT 11, 'Novembre', COUNT(*), ROUND(SUM(montant_ttc), 2)
FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 11 AND statut = 'PAYEE'

UNION ALL SELECT 12, 'Décembre', COUNT(*), ROUND(SUM(montant_ttc), 2)
FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 12 AND statut = 'PAYEE'

ORDER BY mois;
```

**Résultat attendu** : 12 lignes avec CA mensuel

### Analyse visuelle

Vous pouvez exporter le résultat et créer un graphique :

```sql
-- DuckDB : Export CSV
COPY (
    SELECT 1 AS mois, 'Janvier' AS nom_mois, COUNT(*) AS nb, ROUND(SUM(montant_ttc), 2) AS ca
    FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 1 AND statut = 'PAYEE'
    -- ... répéter pour tous les mois ...
) TO 'ca_mensuel_2024.csv' (HEADER, DELIMITER ',');
```

---

## 🧪 Cas d'usage 3 : Consolidation TVA

### Problématique métier

**Question** : Calculer le total par taux de TVA pour la déclaration fiscale.

**Enjeu** : **Conformité fiscale** et reporting comptable.

### Solution

```sql
-- TVA 20%
SELECT 
    20.0 AS taux_tva,
    'Taux normal' AS libelle,
    COUNT(DISTINCT f.facture_id) AS nb_factures,
    COUNT(lf.ligne_id) AS nb_lignes,
    ROUND(SUM(lf.montant_ht), 2) AS base_ht,
    ROUND(SUM(lf.montant_tva), 2) AS montant_tva,
    ROUND(SUM(lf.montant_ttc), 2) AS total_ttc
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE lf.taux_tva = 20.0
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

UNION ALL

-- TVA 10%
SELECT 
    10.0 AS taux_tva,
    'Taux intermédiaire' AS libelle,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ht), 2),
    ROUND(SUM(lf.montant_tva), 2),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE lf.taux_tva = 10.0
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

UNION ALL

-- TVA 5.5%
SELECT 
    5.5 AS taux_tva,
    'Taux réduit' AS libelle,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ht), 2),
    ROUND(SUM(lf.montant_tva), 2),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE lf.taux_tva = 5.5
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

ORDER BY taux_tva DESC;
```

**Résultat attendu** :
```
taux_tva | libelle              | base_ht      | montant_tva   | total_ttc
---------|----------------------|--------------|---------------|-------------
20.0     | Taux normal          | 85234567.00  | 17046913.40   | 102281480.40
10.0     | Taux intermédiaire   | 8456789.00   | 845678.90     | 9302467.90
5.5      | Taux réduit          | 4543211.00   | 249876.61     | 4793087.61
```

---

## 🧪 Cas d'usage 4 : Top Clients Multi-Années

### Problématique métier

**Question** : Qui sont les top 20 clients sur 2024 et 2025 combinés ?

**Enjeu** : Identifier les **clients stratégiques** sur période étendue.

### Solution

```sql
-- Top clients 2024
SELECT 
    c.client_id,
    c.nom,
    c.prenom,
    c.ville,
    2024 AS annee,
    COUNT(f.facture_id) AS nb_factures,
    ROUND(SUM(f.montant_ttc), 2) AS ca_ttc
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom, c.ville
HAVING SUM(f.montant_ttc) > 50000

UNION ALL

-- Top clients 2025
SELECT 
    c.client_id,
    c.nom,
    c.prenom,
    c.ville,
    2025 AS annee,
    COUNT(f.facture_id),
    ROUND(SUM(f.montant_ttc), 2)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025
  AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom, c.ville
HAVING SUM(f.montant_ttc) > 50000

ORDER BY ca_ttc DESC
LIMIT 20;
```

**Analyse** : Un même client peut apparaître 2 fois (une fois par année) si top client les 2 années.

### Variante : Agréger par client

```sql
SELECT 
    client_id,
    nom,
    prenom,
    ville,
    SUM(nb_factures) AS total_factures,
    ROUND(SUM(ca_ttc), 2) AS ca_total
FROM (
    -- 2024
    SELECT c.client_id, c.nom, c.prenom, c.ville, 
           COUNT(f.facture_id) AS nb_factures,
           SUM(f.montant_ttc) AS ca_ttc
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
    GROUP BY c.client_id, c.nom, c.prenom, c.ville
    
    UNION ALL
    
    -- 2025
    SELECT c.client_id, c.nom, c.prenom, c.ville,
           COUNT(f.facture_id),
           SUM(f.montant_ttc)
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
    GROUP BY c.client_id, c.nom, c.prenom, c.ville
) AS consolidation
GROUP BY client_id, nom, prenom, ville
ORDER BY ca_total DESC
LIMIT 20;
```

---

## 🧪 Cas d'usage 5 : Consolidation Géographique

### Problématique métier

**Question** : CA par région (3 grandes villes vs reste) ?

**Enjeu** : Analyse **géographique** pour stratégie d'expansion.

### Solution

```sql
-- Paris
SELECT 
    'Paris' AS region,
    COUNT(DISTINCT c.client_id) AS nb_clients,
    COUNT(f.facture_id) AS nb_factures,
    ROUND(SUM(f.montant_ttc), 2) AS ca_ttc
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Paris'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

UNION ALL

-- Lyon
SELECT 
    'Lyon' AS region,
    COUNT(DISTINCT c.client_id),
    COUNT(f.facture_id),
    ROUND(SUM(f.montant_ttc), 2)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Lyon'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

UNION ALL

-- Marseille
SELECT 
    'Marseille' AS region,
    COUNT(DISTINCT c.client_id),
    COUNT(f.facture_id),
    ROUND(SUM(f.montant_ttc), 2)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Marseille'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

UNION ALL

-- Autres
SELECT 
    'Autres villes' AS region,
    COUNT(DISTINCT c.client_id),
    COUNT(f.facture_id),
    ROUND(SUM(f.montant_ttc), 2)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville NOT IN ('Paris', 'Lyon', 'Marseille')
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

ORDER BY ca_ttc DESC;
```

---

## 📊 UNION vs UNION ALL : Benchmark

### Test de performance

```sql
-- Test 1 : UNION ALL (avec doublons)
SELECT ville FROM client WHERE ville IN ('Paris', 'Lyon')
UNION ALL
SELECT ville FROM client WHERE ville IN ('Lyon', 'Marseille');
```

**Temps SQLite** : _______ ms  
**Temps DuckDB** : _______ ms  
**Lignes retournées** : ~1000-2000 (avec doublons de Lyon)

```sql
-- Test 2 : UNION (sans doublons)
SELECT ville FROM client WHERE ville IN ('Paris', 'Lyon')
UNION
SELECT ville FROM client WHERE ville IN ('Lyon', 'Marseille');
```

**Temps SQLite** : _______ ms  
**Temps DuckDB** : _______ ms  
**Lignes retournées** : ~700-1000 (Lyon dédoublonné)

**Analyse attendue** : UNION ALL est **2-5x plus rapide** que UNION.

### Test sur gros volume

```sql
-- UNION ALL : ~50K lignes
SELECT facture_id, montant_ttc FROM facture WHERE YEAR(date_facture) = 2024
UNION ALL
SELECT facture_id, montant_ttc FROM facture WHERE YEAR(date_facture) = 2025;
```

**Temps SQLite** : _______ secondes  
**Temps DuckDB** : _______ secondes

```sql
-- UNION : déduplication sur ~50K lignes
SELECT facture_id, montant_ttc FROM facture WHERE YEAR(date_facture) = 2024
UNION
SELECT facture_id, montant_ttc FROM facture WHERE YEAR(date_facture) = 2025;
```

**Temps SQLite** : _______ secondes  
**Temps DuckDB** : _______ secondes

**Différence attendue** : UNION peut être **5-10x plus lent**.

---

## ⚠️ Pièges à éviter

### Piège 1 : Oublier ORDER BY global

```sql
-- ❌ MAUVAIS : ORDER BY dans sous-requête (ignoré)
(SELECT nom FROM client WHERE ville = 'Paris' ORDER BY nom)
UNION ALL
(SELECT nom FROM client WHERE ville = 'Lyon' ORDER BY nom);
-- Les ORDER BY internes sont ignorés !

-- ✅ BON : ORDER BY après UNION ALL
SELECT nom, ville FROM client WHERE ville = 'Paris'
UNION ALL
SELECT nom, ville FROM client WHERE ville = 'Lyon'
ORDER BY ville, nom;
```

### Piège 2 : Types incompatibles

```sql
-- ⚠️ ATTENTION
SELECT client_id, 'Client' FROM client  -- INTEGER, TEXT
UNION ALL
SELECT montant_ttc, 'Montant' FROM facture;  -- REAL, TEXT
-- SQLite convertit, mais résultats imprévisibles
```

### Piège 3 : Colonnes mal alignées

```sql
-- ❌ MAUVAIS
SELECT nom, prenom FROM client
UNION ALL
SELECT prenom, nom FROM client;  -- Ordre inversé !

-- ✅ BON
SELECT nom, prenom FROM client
UNION ALL
SELECT nom, prenom FROM client;
```

### Piège 4 : Utiliser UNION par défaut

```sql
-- ❌ INEFFICACE : UNION dédoublonne inutilement
SELECT ville FROM client WHERE YEAR(date_creation) = 2024
UNION  -- Déduplication coûteuse
SELECT ville FROM client WHERE YEAR(date_creation) = 2025;

-- ✅ OPTIMAL : UNION ALL si pas besoin de dédup
SELECT ville FROM client WHERE YEAR(date_creation) = 2024
UNION ALL
SELECT ville FROM client WHERE YEAR(date_creation) = 2025;
```

---

## 🔧 Optimisations

### 1. Minimiser le nombre de UNION ALL

```sql
-- ❌ LENT : 12 requêtes séparées
SELECT * FROM facture WHERE MONTH(date_facture) = 1
UNION ALL
SELECT * FROM facture WHERE MONTH(date_facture) = 2
-- ... 10 autres mois

-- ✅ RAPIDE : Une seule requête avec GROUP BY
SELECT 
    MONTH(date_facture) AS mois,
    COUNT(*) AS nb_factures,
    SUM(montant_ttc) AS ca_ttc
FROM facture
WHERE YEAR(date_facture) = 2024
GROUP BY MONTH(date_facture)
ORDER BY mois;
```

### 2. Filtrer dans les sous-requêtes

```sql
-- ❌ LENT : Filtrage après UNION ALL
SELECT * FROM (
    SELECT * FROM facture
    UNION ALL
    SELECT * FROM facture
) WHERE statut = 'PAYEE';

-- ✅ RAPIDE : Filtrer avant
SELECT * FROM facture WHERE statut = 'PAYEE'
UNION ALL
SELECT * FROM facture WHERE statut = 'PAYEE';
```

### 3. Utiliser des CTE pour lisibilité

```sql
WITH ca_2024 AS (
    SELECT 'Q1' AS trimestre, SUM(montant_ttc) AS ca
    FROM facture
    WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) BETWEEN 1 AND 3
    UNION ALL
    SELECT 'Q2', SUM(montant_ttc)
    FROM facture
    WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) BETWEEN 4 AND 6
    -- ... Q3, Q4
)
SELECT * FROM ca_2024
ORDER BY trimestre;
```

---

## 🎓 Exercices pratiques

### Exercice 1 : CA par statut

**Question** : Affichez le CA pour chaque statut de facture (4 lignes).

<details>
<summary>✅ Solution</summary>

```sql
SELECT 'BROUILLON' AS statut, COUNT(*) AS nb, SUM(montant_ttc) AS ca
FROM facture WHERE statut = 'BROUILLON'
UNION ALL
SELECT 'EMISE', COUNT(*), SUM(montant_ttc)
FROM facture WHERE statut = 'EMISE'
UNION ALL
SELECT 'PAYEE', COUNT(*), SUM(montant_ttc)
FROM facture WHERE statut = 'PAYEE'
UNION ALL
SELECT 'ANNULEE', COUNT(*), SUM(montant_ttc)
FROM facture WHERE statut = 'ANNULEE'
ORDER BY ca DESC;
```

</details>

### Exercice 2 : Top produits multi-villes

**Question** : Top 10 produits vendus à Paris + Lyon + Marseille combinés.

<details>
<summary>✅ Solution</summary>

```sql
SELECT 
    description,
    SUM(quantite) AS quantite_totale,
    ROUND(SUM(montant_ttc), 2) AS ca_total
FROM (
    SELECT lf.description, lf.quantite, lf.montant_ttc
    FROM ligne_facture lf
    INNER JOIN facture f ON lf.facture_id = f.facture_id
    INNER JOIN client c ON f.client_id = c.client_id
    WHERE c.ville = 'Paris' AND f.statut = 'PAYEE'
    
    UNION ALL
    
    SELECT lf.description, lf.quantite, lf.montant_ttc
    FROM ligne_facture lf
    INNER JOIN facture f ON lf.facture_id = f.facture_id
    INNER JOIN client c ON f.client_id = c.client_id
    WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE'
    
    UNION ALL
    
    SELECT lf.description, lf.quantite, lf.montant_ttc
    FROM ligne_facture lf
    INNER JOIN facture f ON lf.facture_id = f.facture_id
    INNER JOIN client c ON f.client_id = c.client_id
    WHERE c.ville = 'Marseille' AND f.statut = 'PAYEE'
) AS ventes_consolidees
GROUP BY description
ORDER BY ca_total DESC
LIMIT 10;
```

</details>

---

## 📝 Checklist UNION ALL

Avant d'utiliser UNION ALL :

- [ ] Ai-je vraiment besoin de combiner plusieurs sources ?
- [ ] Puis-je utiliser GROUP BY au lieu de UNION ALL ?
- [ ] UNION ALL ou UNION ? (privilégier UNION ALL)
- [ ] Même structure de colonnes partout ?
- [ ] ORDER BY global à la fin ?
- [ ] Filtrage dans chaque sous-requête ?

---

## ⏭️ Prochaine étape

Vous maîtrisez la consolidation avec UNION ALL !

👉 Passez à [04-intersect-similitudes.md](04-intersect-similitudes.md) pour trouver les données communes.

---

**Félicitations ! Vous savez consolider des données comme un pro. 📊**
