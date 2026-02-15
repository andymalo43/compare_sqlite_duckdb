# 06 - Optimisation WHERE : Gains de Performance

## 🎯 Objectifs

À la fin de ce chapitre, vous serez capable de :

- ✅ Comprendre l'**impact du filtrage WHERE** sur les performances
- ✅ Optimiser les requêtes avec **filtres stratégiques**
- ✅ Mesurer les **gains de performance** (8-25x plus rapide)
- ✅ Appliquer les **best practices** d'optimisation

**Durée estimée : 35 minutes**

---

## ⚠️ Note sur les exemples SQL

Les exemples utilisent la **syntaxe DuckDB** avec `YEAR()` et `MONTH()`.

**Pour SQLite** : Remplacez `YEAR(date)` → `strftime('%Y', date)` et `MONTH(date)` → `strftime('%m', date)`

📘 Fichiers adaptés disponibles : voir **[SQL_VERSIONS.md](SQL_VERSIONS.md)**

---

## 📚 Théorie : L'Impact du WHERE

### Principe fondamental

Le filtrage WHERE **réduit le volume de données** traité par les opérations ensemblistes.

```
Sans WHERE:          Avec WHERE:
150K lignes          2K lignes
    ↓                    ↓
EXCEPT/UNION         EXCEPT/UNION
    ↓                    ↓
10 secondes          0.5 secondes
                     (20x plus rapide!)
```

### Facteurs d'optimisation

| Filtre | Réduction Typique | Gain Performance |
|--------|-------------------|------------------|
| **Année** (2024) | 80-90% | 5-10x |
| **Statut** (PAYEE) | 60-70% | 3-5x |
| **Ville** (Paris) | 85-95% | 10-20x |
| **Montant** (>10K) | 90-95% | 10-25x |
| **Combinaison** | 95-99% | 20-50x |

---

## 🧪 Benchmark 1 : Impact du Filtrage Temporel

### Sans filtrage WHERE

```sql
-- LENT : Scan complet de 150K factures
SELECT 
    f.facture_id,
    f.client_id,
    f.montant_ttc,
    f.statut
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris'

EXCEPT

SELECT 
    f.facture_id,
    f.client_id,
    f.montant_ttc,
    f.statut
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Lyon';
```

**Exécutez et notez le temps** :
- SQLite : _______ secondes
- DuckDB : _______ secondes

### Avec filtrage WHERE temporel

```sql
-- RAPIDE : Seulement ~25K factures (année 2024)
SELECT 
    f.facture_id,
    f.client_id,
    f.montant_ttc,
    f.statut
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris'
  AND YEAR(f.date_facture) = 2024  -- Filtrage temporel
  AND f.statut = 'PAYEE'

EXCEPT

SELECT 
    f.facture_id,
    f.client_id,
    f.montant_ttc,
    f.statut
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Lyon'
  AND YEAR(f.date_facture) = 2024  -- Même filtre
  AND f.statut = 'PAYEE';
```

**Exécutez et notez le temps** :
- SQLite : _______ secondes
- DuckDB : _______ secondes

**Calculez le gain** :
- SQLite : Temps_sans / Temps_avec = _______ x plus rapide
- DuckDB : Temps_sans / Temps_avec = _______ x plus rapide

**Gain attendu** : **8-15x plus rapide**

---

## 🧪 Benchmark 2 : Impact du Filtrage par Montant

### Sans filtrage montant

```sql
-- LENT : Traite toutes les factures
SELECT 
    f.facture_id,
    f.numero_facture,
    f.client_id,
    f.montant_ttc
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris'

EXCEPT

SELECT 
    f.facture_id,
    f.numero_facture,
    f.client_id,
    f.montant_ttc
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Lyon';
```

**Temps SQLite** : _______ s  
**Temps DuckDB** : _______ s

### Avec filtrage montant (>10K€)

```sql
-- RAPIDE : Seulement les grosses factures (~2-5%)
SELECT 
    f.facture_id,
    f.numero_facture,
    f.client_id,
    f.montant_ttc
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris'
  AND f.montant_ttc > 10000         -- Filtrage montant
  AND YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE'

EXCEPT

SELECT 
    f.facture_id,
    f.numero_facture,
    f.client_id,
    f.montant_ttc
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Lyon'
  AND f.montant_ttc > 10000         -- Même filtre
  AND YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE';
```

**Temps SQLite** : _______ s  
**Temps DuckDB** : _______ s

**Gain attendu** : **15-30x plus rapide**

---

## 🧪 Benchmark 3 : Filtrage Multi-Critères

### Filtres combinés (effet multiplicatif)

```sql
-- ULTRA-RAPIDE : Filtrage agressif multi-critères
SELECT 
    c.client_id,
    c.nom,
    c.prenom,
    f.montant_ttc
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville IN ('Paris', 'Lyon', 'Marseille')  -- Top 3 villes (~30%)
  AND f.statut = 'PAYEE'                         -- ~65% des factures
  AND YEAR(f.date_facture) = 2024                -- ~20% du total
  AND f.montant_ttc > 5000                       -- ~10% des factures
  AND MONTH(f.date_facture) BETWEEN 10 AND 12    -- Q4 uniquement (~25%)

EXCEPT

SELECT 
    c.client_id,
    c.nom,
    c.prenom,
    f.montant_ttc
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville IN ('Paris', 'Lyon', 'Marseille')
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024
  AND f.montant_ttc > 5000
  AND MONTH(f.date_facture) BETWEEN 1 AND 3;     -- Q1 uniquement
```

**Réduction du volume** :
- 0.30 × 0.65 × 0.20 × 0.10 × 0.25 = **0.001** (0.1% du total!)
- De 150K factures → **~150 factures**

**Temps attendu** : < 0.1 seconde sur DuckDB

**Gain total** : **50-100x plus rapide** qu'une requête non filtrée

---

## 🧪 Cas d'usage : Q4 2024 Optimisé

### Version non optimisée

```sql
-- LENT : Scan de toutes les années
SELECT 
    facture_id,
    client_id,
    montant_ttc,
    statut,
    date_facture
FROM facture
WHERE statut = 'PAYEE'

UNION ALL

SELECT 
    facture_id,
    client_id,
    montant_ttc,
    statut,
    date_facture
FROM facture
WHERE statut = 'EMISE';
```

**Temps SQLite** : _______ s  
**Temps DuckDB** : _______ s  
**Volume traité** : ~150K lignes × 2 = 300K

### Version optimisée (Q4 2024 uniquement)

```sql
-- RAPIDE : Filtrage temporel précis
SELECT 
    facture_id,
    client_id,
    montant_ttc,
    statut,
    date_facture,
    'PAYEE' AS type_analyse
FROM facture
WHERE statut = 'PAYEE'
  AND date_facture >= '2024-10-01'  -- Date exacte (pas YEAR/MONTH)
  AND date_facture <= '2024-12-31'

UNION ALL

SELECT 
    facture_id,
    client_id,
    montant_ttc,
    statut,
    date_facture,
    'EMISE' AS type_analyse
FROM facture
WHERE statut = 'EMISE'
  AND date_facture >= '2024-10-01'
  AND date_facture <= '2024-12-31';
```

**Temps SQLite** : _______ s  
**Temps DuckDB** : _______ s  
**Volume traité** : ~6K lignes (réduction de 98%)

**Gain attendu** : **10-20x plus rapide**

---

## 🔍 Analyse de l'Optimisation

### Comparaison : Plages de dates vs Fonctions

```sql
-- ❌ MOINS RAPIDE : Utilisation de fonctions
WHERE YEAR(f.date_facture) = 2024
  AND MONTH(f.date_facture) BETWEEN 10 AND 12

-- ✅ PLUS RAPIDE : Plages de dates directes
WHERE f.date_facture >= '2024-10-01'
  AND f.date_facture <= '2024-12-31'
```

**Raison** : Les plages permettent l'utilisation d'**index sur date_facture**.

### Test de comparaison

```sql
-- Test 1 : Avec fonctions
SELECT COUNT(*) 
FROM facture
WHERE YEAR(date_facture) = 2024
  AND MONTH(date_facture) = 10;
```

**Temps** : _______ ms

```sql
-- Test 2 : Avec plages
SELECT COUNT(*) 
FROM facture
WHERE date_facture >= '2024-10-01'
  AND date_facture <= '2024-10-31';
```

**Temps** : _______ ms

**Gain attendu** : **2-5x plus rapide** avec plages de dates

---

## 🧪 Cas d'usage : Clients VIP Optimisé

### Version non optimisée

```sql
-- LENT : Calcul CA sur toutes les années
SELECT 
    c.client_id,
    c.nom,
    c.prenom,
    SUM(f.montant_ttc) AS ca_total
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom
HAVING SUM(f.montant_ttc) > 100000

INTERSECT

SELECT 
    c.client_id,
    c.nom,
    c.prenom,
    SUM(f.montant_ttc)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom;
```

**Temps SQLite** : _______ s  
**Temps DuckDB** : _______ s

### Version optimisée (2024-2025 + grandes villes)

```sql
-- RAPIDE : Filtrage multi-critères
SELECT 
    c.client_id,
    c.nom,
    c.prenom,
    SUM(f.montant_ttc) AS ca_total
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND YEAR(f.date_facture) IN (2024, 2025)           -- 2 années récentes
  AND c.ville IN ('Paris', 'Lyon', 'Marseille')      -- Top 3 villes
GROUP BY c.client_id, c.nom, c.prenom
HAVING SUM(f.montant_ttc) > 100000

INTERSECT

SELECT 
    c.client_id,
    c.nom,
    c.prenom,
    SUM(f.montant_ttc)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE f.statut = 'PAYEE'
  AND YEAR(f.date_facture) IN (2024, 2025)
  AND c.ville IN ('Paris', 'Lyon', 'Marseille')
  AND lf.description IN (                             -- Produits stratégiques
      'Ordinateur portable', 
      'Licence logicielle', 
      'Service support',
      'Hébergement cloud'
  )
GROUP BY c.client_id, c.nom, c.prenom;
```

**Temps SQLite** : _______ s  
**Temps DuckDB** : _______ s

**Gain attendu** : **15-25x plus rapide**

---

## 📊 Tableau Récapitulatif des Gains

| Type de Filtre | Réduction Volume | Gain Performance | Cas d'Usage |
|----------------|------------------|------------------|-------------|
| **Année spécifique** | 80-90% | 5-10x | Analyses annuelles |
| **Trimestre/Mois** | 90-95% | 10-20x | Saisonnalité |
| **Statut (PAYEE)** | 30-40% | 2-3x | CA réel |
| **Ville spécifique** | 90-95% | 10-20x | Analyses régionales |
| **Montant >seuil** | 85-95% | 10-25x | Grandes factures |
| **Combinaison 3+** | 95-99% | 20-50x | Analyses ciblées |

---

## 🔧 Best Practices d'Optimisation

### 1. Filtrer le plus tôt possible

```sql
-- ❌ MAUVAIS : Filtrage après l'opération
SELECT * FROM (
    SELECT * FROM facture
    UNION ALL
    SELECT * FROM facture
) WHERE statut = 'PAYEE' AND YEAR(date_facture) = 2024;

-- ✅ BON : Filtrage dans chaque sous-requête
SELECT * FROM facture WHERE statut = 'PAYEE' AND YEAR(date_facture) = 2024
UNION ALL
SELECT * FROM facture WHERE statut = 'PAYEE' AND YEAR(date_facture) = 2024;
```

### 2. Utiliser des index appropriés

```sql
-- Créer des index sur colonnes fréquemment filtrées
CREATE INDEX IF NOT EXISTS idx_facture_date_statut 
ON facture(date_facture, statut);

CREATE INDEX IF NOT EXISTS idx_facture_montant 
ON facture(montant_ttc);

CREATE INDEX IF NOT EXISTS idx_client_ville 
ON client(ville);
```

**Vérification** :
```sql
-- SQLite
EXPLAIN QUERY PLAN 
SELECT * FROM facture WHERE date_facture >= '2024-01-01' AND statut = 'PAYEE';

-- DuckDB
EXPLAIN 
SELECT * FROM facture WHERE date_facture >= '2024-01-01' AND statut = 'PAYEE';
```

**Cherchez** : "USING INDEX" dans le plan d'exécution.

### 3. Préférer IN à OR multiples

```sql
-- ❌ LENT : OR multiples
WHERE ville = 'Paris' OR ville = 'Lyon' OR ville = 'Marseille'

-- ✅ RAPIDE : IN
WHERE ville IN ('Paris', 'Lyon', 'Marseille')
```

**Gain** : **2-3x plus rapide** avec IN.

### 4. Combiner filtres compatibles

```sql
-- ✅ BON : Filtres combinés sur même table
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-01-01'
  AND f.montant_ttc > 1000

-- Index composite idéal :
CREATE INDEX idx_facture_composite ON facture(statut, date_facture, montant_ttc);
```

### 5. Éviter les fonctions sur colonnes indexées

```sql
-- ❌ LENT : Fonction empêche l'utilisation d'index
WHERE YEAR(date_facture) = 2024

-- ✅ RAPIDE : Plage compatible avec index
WHERE date_facture >= '2024-01-01' 
  AND date_facture <= '2024-12-31'
```

---

## 🎓 Exercices Pratiques

### Exercice 1 : Optimiser une requête lente

**Requête de départ (lente)** :
```sql
SELECT c.client_id, c.nom, COUNT(*) AS nb
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
GROUP BY c.client_id, c.nom

EXCEPT

SELECT c.client_id, c.nom, COUNT(*)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'ANNULEE'
GROUP BY c.client_id, c.nom;
```

**Tâche** : Optimisez pour ne traiter que 2024 et statut PAYEE/EMISE.

<details>
<summary>✅ Solution</summary>

```sql
SELECT c.client_id, c.nom, COUNT(*) AS nb
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut IN ('PAYEE', 'EMISE')
  AND YEAR(f.date_facture) = 2024
GROUP BY c.client_id, c.nom

EXCEPT

SELECT c.client_id, c.nom, COUNT(*)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'ANNULEE'
  AND YEAR(f.date_facture) = 2024
GROUP BY c.client_id, c.nom;
```

**Gain attendu** : 8-12x plus rapide

</details>

### Exercice 2 : Calculer le gain réel

Mesurez le gain sur cette requête avant/après optimisation :

**Avant** :
```sql
SELECT ville FROM client
EXCEPT
SELECT c.ville FROM client c
INNER JOIN facture f ON c.client_id = f.client_id;
```

**Après** :
```sql
SELECT ville FROM client WHERE ville IN ('Paris', 'Lyon')
EXCEPT
SELECT c.ville FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE' AND c.ville IN ('Paris', 'Lyon');
```

Calculez : Gain = Temps_avant / Temps_après = _______x

---

## 📝 Checklist Optimisation

Avant d'exécuter une requête ensembliste :

- [ ] Ai-je filtré sur l'année/période ?
- [ ] Ai-je filtré sur le statut (PAYEE) ?
- [ ] Puis-je limiter à certaines villes ?
- [ ] Puis-je filtrer par montant minimum ?
- [ ] Les mêmes filtres sont-ils dans TOUTES les sous-requêtes ?
- [ ] Ai-je des index sur colonnes de filtrage ?
- [ ] Ai-je testé avec EXPLAIN ?

---

## ⏭️ Prochaine étape

Vous maîtrisez l'optimisation avec WHERE !

👉 Finalisez avec [07-benchmark-performance.md](07-benchmark-performance.md) pour des mesures complètes.

---

**Félicitations ! Vos requêtes sont maintenant optimisées. ⚡**
