# 04 - INTERSECT : Trouver les Similitudes

## 🎯 Objectifs

À la fin de ce chapitre, vous serez capable de :

- ✅ Utiliser **INTERSECT** pour identifier les données communes
- ✅ Détecter les **clients fidèles** et récurrents
- ✅ Valider la **cohérence** entre sources de données
- ✅ Analyser les **opportunités de cross-sell**

**Durée estimée : 25 minutes**

---

## ⚠️ Note sur les exemples SQL

Les exemples utilisent la **syntaxe DuckDB** avec `YEAR()` et `MONTH()`.

**Pour SQLite** : Remplacez `YEAR(date)` → `strftime('%Y', date)` et `MONTH(date)` → `strftime('%m', date)`

📘 Fichiers adaptés disponibles : voir **[SQL_VERSIONS.md](SQL_VERSIONS.md)**

---

## 📚 Théorie : INTERSECT

### Définition

**INTERSECT** retourne uniquement les lignes présentes **à la fois** dans l'ensemble A **ET** dans l'ensemble B.

```
Ensemble A        Ensemble B        A INTERSECT B
┌─────────┐      ┌─────────┐       ┌─────────┐
│  1, 2   │      │  2, 3   │       │    2    │
│  3, 4   │      │  4, 5   │       │    4    │
└─────────┘      └─────────┘       └─────────┘
```

### Syntaxe

```sql
SELECT colonnes FROM table1
INTERSECT
SELECT colonnes FROM table2;
```

### Caractéristiques

- ✅ **Dédoublonne automatiquement** (comme DISTINCT)
- ✅ Trouve les **éléments communs**
- ⚠️ **Sensible à l'ordre** des colonnes
- 🎯 **Validation de cohérence** entre sources

---

## 🧪 Cas d'usage 1 : Clients Fidèles

### Problématique métier

**Question** : Quels clients ont acheté à la fois en 2024 ET en 2025 ?

**Enjeu** : Identifier les **clients fidèles** pour programmes de rétention.

### Solution avec INTERSECT

```sql
-- Clients actifs en 2024
SELECT DISTINCT 
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

-- Clients actifs en 2025
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025
  AND f.statut = 'PAYEE';
```

### Exécution et mesure

**SQLite** :
```bash
sqlite3 facturation.db
.timer on
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

**Résultat attendu** : 200-500 clients fidèles

### Analyse géographique des fidèles

```sql
WITH clients_fideles AS (
    SELECT DISTINCT c.client_id, c.ville
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
    
    INTERSECT
    
    SELECT DISTINCT c.client_id, c.ville
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
)
SELECT 
    ville,
    COUNT(*) AS nb_clients_fideles
FROM clients_fideles
GROUP BY ville
ORDER BY nb_clients_fideles DESC;
```

**Interprétation** : Villes avec plus de fidélité = maturité du marché.

---

## 🧪 Cas d'usage 2 : Cross-Sell Analysis

### Problématique métier

**Question** : Quels clients ont acheté à la fois des "Ordinateur portable" ET des "Licence logicielle" ?

**Enjeu** : Identifier opportunités de **vente complémentaire**.

### Solution

```sql
-- Clients ayant acheté des ordinateurs
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE lf.description = 'Ordinateur portable'
  AND f.statut = 'PAYEE'

INTERSECT

-- Clients ayant acheté des licences
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE lf.description = 'Licence logicielle'
  AND f.statut = 'PAYEE';
```

**Résultat attendu** : 150-400 clients ayant acheté les deux

### Extension : Triple intersection

```sql
-- Clients ayant acheté Ordinateur + Licence + Support
SELECT DISTINCT c.client_id, c.nom, c.prenom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE lf.description = 'Ordinateur portable' AND f.statut = 'PAYEE'

INTERSECT

SELECT DISTINCT c.client_id, c.nom, c.prenom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE lf.description = 'Licence logicielle' AND f.statut = 'PAYEE'

INTERSECT

SELECT DISTINCT c.client_id, c.nom, c.prenom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE lf.description = 'Service support' AND f.statut = 'PAYEE';
```

**Interprétation** : Ces clients sont des **utilisateurs complets** de votre écosystème.

---

## 🧪 Cas d'usage 3 : Cohérence Multi-Sources

### Problématique métier

**Question** : Quelles villes ont à la fois des clients ET des factures payées ?

**Enjeu** : Valider la **cohérence** des données.

### Solution

```sql
-- Villes avec clients
SELECT DISTINCT ville
FROM client

INTERSECT

-- Villes avec factures payées
SELECT DISTINCT c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE';
```

**Résultat attendu** : 15-18 villes (quasi toutes)

### Variante : Villes sans activité

```sql
-- Villes SANS factures (inverse avec EXCEPT)
SELECT DISTINCT ville FROM client
EXCEPT
SELECT DISTINCT c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE';
```

**Si résultat > 0** : Villes dormantes nécessitant action commerciale.

---

## 🧪 Cas d'usage 4 : Clients Récurrents par Trimestre

### Problématique métier

**Question** : Quels clients ont acheté à la fois en Q1 ET en Q4 2024 ?

**Enjeu** : Identifier clients **non-saisonniers**, actifs toute l'année.

### Solution

```sql
-- Clients Q1 2024
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-01-01'
  AND f.date_facture <= '2024-03-31'

INTERSECT

-- Clients Q4 2024
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-10-01'
  AND f.date_facture <= '2024-12-31';
```

**Résultat attendu** : 100-300 clients réguliers

### Analyse avec volume

```sql
WITH clients_reguliers AS (
    SELECT DISTINCT c.client_id
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE f.statut = 'PAYEE'
      AND f.date_facture >= '2024-01-01'
      AND f.date_facture <= '2024-03-31'
    
    INTERSECT
    
    SELECT DISTINCT c.client_id
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE f.statut = 'PAYEE'
      AND f.date_facture >= '2024-10-01'
      AND f.date_facture <= '2024-12-31'
)
SELECT 
    c.client_id,
    c.nom,
    c.prenom,
    COUNT(f.facture_id) AS nb_factures_2024,
    ROUND(SUM(f.montant_ttc), 2) AS ca_2024
FROM clients_reguliers cr
INNER JOIN client c ON cr.client_id = c.client_id
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom
ORDER BY ca_2024 DESC
LIMIT 20;
```

---

## 🧪 Cas d'usage 5 : Produits Universels

### Problématique métier

**Question** : Quels produits sont vendus dans toutes les grandes villes (Paris, Lyon, Marseille) ?

**Enjeu** : Identifier les produits **universels** vs régionaux.

### Solution

```sql
-- Produits vendus à Paris
SELECT DISTINCT lf.description
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris'
  AND f.statut = 'PAYEE'

INTERSECT

-- Produits vendus à Lyon
SELECT DISTINCT lf.description
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Lyon'
  AND f.statut = 'PAYEE'

INTERSECT

-- Produits vendus à Marseille
SELECT DISTINCT lf.description
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Marseille'
  AND f.statut = 'PAYEE';
```

**Résultat attendu** : 10-20 produits universels

### Produits régionaux (inverse)

```sql
-- Produits UNIQUEMENT à Paris (pas à Lyon ni Marseille)
SELECT DISTINCT lf.description
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris' AND f.statut = 'PAYEE'

EXCEPT

(
    SELECT DISTINCT lf.description
    FROM ligne_facture lf
    INNER JOIN facture f ON lf.facture_id = f.facture_id
    INNER JOIN client c ON f.client_id = c.client_id
    WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE'
    
    UNION
    
    SELECT DISTINCT lf.description
    FROM ligne_facture lf
    INNER JOIN facture f ON lf.facture_id = f.facture_id
    INNER JOIN client c ON f.client_id = c.client_id
    WHERE c.ville = 'Marseille' AND f.statut = 'PAYEE'
);
```

---

## 📊 Benchmark INTERSECT

### Test de performance

```sql
-- Test 1 : INTERSECT simple
SELECT DISTINCT ville 
FROM client 
WHERE ville IN ('Paris', 'Lyon', 'Marseille')

INTERSECT

SELECT DISTINCT ville 
FROM client 
WHERE ville IN ('Lyon', 'Marseille', 'Toulouse');
```

**SQLite** : _______ ms  
**DuckDB** : _______ ms

```sql
-- Test 2 : INTERSECT avec jointure
SELECT DISTINCT c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'

INTERSECT

SELECT DISTINCT c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE';
```

**SQLite** : _______ secondes  
**DuckDB** : _______ secondes

**Analyse attendue** : DuckDB devrait être **2-5x plus rapide**.

---

## 🆚 INTERSECT vs JOIN INNER

### Comparaison

**INTERSECT** :
```sql
SELECT client_id, nom FROM client WHERE ville = 'Paris'
INTERSECT
SELECT client_id, nom FROM client WHERE YEAR(date_creation) = 2024;
```

**INNER JOIN équivalent** :
```sql
SELECT DISTINCT t1.client_id, t1.nom
FROM (SELECT client_id, nom FROM client WHERE ville = 'Paris') t1
INNER JOIN (SELECT client_id, nom FROM client WHERE YEAR(date_creation) = 2024) t2
  ON t1.client_id = t2.client_id AND t1.nom = t2.nom;
```

| Critère | INTERSECT | INNER JOIN |
|---------|-----------|------------|
| **Lisibilité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Performance** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Flexibilité** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Cas d'usage** | Ensembles identiques | Jointures complexes |

**Recommandation** : Utilisez **INTERSECT** quand vous comparez des ensembles de même structure.

---

## ⚠️ Pièges à éviter

### Piège 1 : Ordre des colonnes

```sql
-- ❌ MAUVAIS : Ordre différent
SELECT client_id, nom FROM client
INTERSECT
SELECT nom, client_id FROM client;
-- Résultat vide ou incorrect !

-- ✅ BON
SELECT client_id, nom FROM client
INTERSECT
SELECT client_id, nom FROM client;
```

### Piège 2 : Types incompatibles

```sql
-- ⚠️ ATTENTION
SELECT client_id FROM client        -- INTEGER
INTERSECT
SELECT montant_ttc FROM facture;    -- REAL
-- Conversion implicite, résultats imprévisibles
```

### Piège 3 : INTERSECT multiple mal interprété

```sql
-- A INTERSECT B INTERSECT C signifie:
-- Éléments présents dans A ET B ET C (tous les trois)

SELECT ville FROM client WHERE code_postal LIKE '75%'   -- Paris
INTERSECT
SELECT ville FROM client WHERE code_postal LIKE '69%'   -- Lyon
INTERSECT
SELECT ville FROM client WHERE code_postal LIKE '13%';  -- Marseille
-- Résultat : VIDE (aucune ville ne peut avoir 3 codes postaux différents)
```

### Piège 4 : Confusion avec IN

```sql
-- INTERSECT : Compare des lignes complètes
SELECT client_id, nom FROM client WHERE ville = 'Paris'
INTERSECT
SELECT client_id, nom FROM client WHERE ville = 'Lyon';
-- Compare (ID, nom) complet

-- IN : Compare seulement une colonne
SELECT client_id, nom FROM client 
WHERE client_id IN (SELECT client_id FROM facture);
-- Compare seulement client_id
```

---

## 🔧 Optimisations

### 1. Ajouter des index

```sql
CREATE INDEX IF NOT EXISTS idx_facture_date_statut 
ON facture(date_facture, statut);

CREATE INDEX IF NOT EXISTS idx_ligne_description 
ON ligne_facture(description);
```

**Gain attendu** : 3-10x plus rapide.

### 2. Filtrer avant INTERSECT

```sql
-- ❌ LENT : INTERSECT sur gros ensembles
SELECT client_id, nom FROM client
INTERSECT
SELECT client_id, nom FROM client;

-- ✅ RAPIDE : Filtrer d'abord
SELECT client_id, nom 
FROM client 
WHERE ville IN ('Paris', 'Lyon')  -- Réduction du volume

INTERSECT

SELECT client_id, nom 
FROM client 
WHERE YEAR(date_creation) >= 2024;
```

### 3. Utiliser EXISTS si une seule colonne

```sql
-- Si vous ne comparez qu'une colonne, EXISTS est plus rapide
-- Au lieu de :
SELECT client_id FROM client WHERE ville = 'Paris'
INTERSECT
SELECT client_id FROM facture;

-- Préférez :
SELECT c.client_id 
FROM client c
WHERE c.ville = 'Paris'
  AND EXISTS (SELECT 1 FROM facture f WHERE f.client_id = c.client_id);
```

---

## 🎓 Exercices pratiques

### Exercice 1 : Clients multi-produits

**Question** : Trouvez les clients ayant acheté au moins 5 produits différents.

<details>
<summary>💡 Indice</summary>

Utilisez GROUP BY HAVING puis INTERSECT pour affiner.

</details>

<details>
<summary>✅ Solution</summary>

```sql
SELECT c.client_id, c.nom, c.prenom, COUNT(DISTINCT lf.description) AS nb_produits
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom
HAVING COUNT(DISTINCT lf.description) >= 5
ORDER BY nb_produits DESC;
```

</details>

### Exercice 2 : Mois universels

**Question** : Quels mois ont eu des ventes dans toutes les grandes villes (Paris, Lyon, Marseille) ?

<details>
<summary>✅ Solution</summary>

```sql
SELECT DISTINCT MONTH(f.date_facture) AS mois
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris' AND f.statut = 'PAYEE'

INTERSECT

SELECT DISTINCT MONTH(f.date_facture)
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE'

INTERSECT

SELECT DISTINCT MONTH(f.date_facture)
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Marseille' AND f.statut = 'PAYEE'

ORDER BY mois;
```

</details>

### Exercice 3 : Clients VIP fidèles

**Question** : Clients ayant un CA >100K€ à la fois en 2024 ET 2025.

<details>
<summary>✅ Solution</summary>

```sql
SELECT c.client_id, c.nom, c.prenom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom
HAVING SUM(f.montant_ttc) > 100000

INTERSECT

SELECT c.client_id, c.nom, c.prenom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom
HAVING SUM(f.montant_ttc) > 100000;
```

</details>

---

## 📝 Checklist INTERSECT

Avant d'utiliser INTERSECT :

- [ ] Même nombre et ordre de colonnes dans A et B
- [ ] Types de données compatibles
- [ ] Ai-je besoin de toutes les colonnes ? (optimisation)
- [ ] Puis-je filtrer avant INTERSECT ?
- [ ] Index sur colonnes de WHERE et JOIN
- [ ] INTERSECT approprié ou JOIN INNER meilleur ?

---

## 📊 Tableau récapitulatif

| Usage | INTERSECT | EXISTS | INNER JOIN |
|-------|-----------|--------|------------|
| **Trouver éléments communs** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Comparer ensembles** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **Performance** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Lisibilité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## ⏭️ Prochaine étape

Vous maîtrisez maintenant INTERSECT pour trouver les similitudes !

👉 Passez à [05-comparaison-complete.md](05-comparaison-complete.md) pour combiner les 3 opérations.

---

**Excellent ! Vous savez identifier les données communes. 🎯**
