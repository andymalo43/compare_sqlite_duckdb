# 02 - EXCEPT : Identifier les Différences

## 🎯 Objectifs

À la fin de ce chapitre, vous serez capable de :

- ✅ Utiliser **EXCEPT** pour détecter des données manquantes
- ✅ Identifier les **clients en churn** (perdus)
- ✅ Réaliser des **audits de synchronisation**
- ✅ Comparer les **performances SQLite vs DuckDB** sur EXCEPT

**Durée estimée : 30 minutes**

---

## ⚠️ Note sur les exemples SQL

Les exemples de ce guide utilisent la **syntaxe DuckDB** avec les fonctions `YEAR()` et `MONTH()`.

**Pour SQLite**, remplacez :
- `YEAR(date_facture)` → `strftime('%Y', date_facture)`
- `MONTH(date_facture)` → `strftime('%m', date_facture)`

**Fichiers SQL prêts à l'emploi** (déjà adaptés) :
- SQLite : `benchmark_*_sqlite.sql`, `comparaison_*_sqlite.sql`
- DuckDB : `benchmark_*.sql`, `comparaison_*.sql`

📘 Voir **[SQL_VERSIONS.md](SQL_VERSIONS.md)** pour tous les détails

---

## 📚 Théorie : EXCEPT

### Définition

**EXCEPT** retourne les lignes présentes dans l'ensemble A mais **absentes** de l'ensemble B.

```
Ensemble A        Ensemble B        A EXCEPT B
┌─────────┐      ┌─────────┐       ┌─────────┐
│  1, 2   │      │  2, 3   │       │    1    │
│  3, 4   │      │  4, 5   │       │         │
└─────────┘      └─────────┘       └─────────┘
```

### Syntaxe

```sql
SELECT colonnes FROM table1
EXCEPT
SELECT colonnes FROM table2;
```

### Caractéristiques

- ✅ **Dédoublonne automatiquement** (comme DISTINCT)
- ⚠️ **Sensible à l'ordre** des colonnes
- ⚠️ **Les colonnes doivent correspondre** en nombre et type
- 🚀 **Plus rapide que NOT IN** sur gros volumes

---

## 🧪 Cas d'usage 1 : Churn Analysis

### Problématique métier

**Question** : Quels clients ont acheté en 2024 mais ne sont pas revenus en 2025 ?

**Enjeu** : Identifier les clients **perdus** pour action commerciale.

### Solution avec EXCEPT

```sql
-- Clients actifs en 2024
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.telephone,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024
  AND f.statut IN ('PAYEE', 'EMISE')

EXCEPT

-- Clients actifs en 2025
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.telephone,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025
  AND f.statut IN ('PAYEE', 'EMISE');
```

### Exécution et mesure

**SQLite** (avec strftime) :
```bash
sqlite3 data/facturation.db
.timer on
.mode column
.headers on
-- Remplacer YEAR() par strftime('%Y', ...) avant d'exécuter
-- Ou utiliser les fichiers *_sqlite.sql
```

**DuckDB** :
```bash
duckdb data/facturation.duckdb
.timer on
-- La syntaxe YEAR() fonctionne directement
```

**Notez les temps** :
- SQLite : _______ secondes
- DuckDB : _______ secondes

**Résultat attendu** : 300-800 clients perdus

### Analyse des résultats

```sql
-- Statistiques sur les clients perdus
WITH clients_perdus AS (
    SELECT DISTINCT c.client_id, c.ville
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE YEAR(f.date_facture) = 2024 AND f.statut IN ('PAYEE', 'EMISE')
    EXCEPT
    SELECT DISTINCT c.client_id, c.ville
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE YEAR(f.date_facture) = 2025 AND f.statut IN ('PAYEE', 'EMISE')
)
SELECT 
    ville,
    COUNT(*) AS nb_clients_perdus
FROM clients_perdus
GROUP BY ville
ORDER BY nb_clients_perdus DESC;
```

**Interprétation** : Identifiez les villes avec le plus de churn pour actions ciblées.

---

## 🧪 Cas d'usage 2 : Produits Abandonnés

### Problématique métier

**Question** : Quels produits étaient vendus en 2024 mais plus en 2025 ?

**Enjeu** : Analyser l'évolution du **catalogue** et identifier produits obsolètes.

### Solution

```sql
-- Produits vendus en 2024
SELECT DISTINCT 
    lf.description AS produit,
    COUNT(DISTINCT f.facture_id) AS nb_factures_2024,
    ROUND(SUM(lf.montant_ttc), 2) AS ca_2024
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE'
GROUP BY lf.description

EXCEPT

-- Produits vendus en 2025
SELECT DISTINCT 
    lf.description AS produit,
    COUNT(DISTINCT f.facture_id) AS nb_factures_2025,
    ROUND(SUM(lf.montant_ttc), 2) AS ca_2025
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025
  AND f.statut = 'PAYEE'
GROUP BY lf.description;
```

**Résultat attendu** : 2-8 produits abandonnés

### Explication

Ces produits peuvent être :
- ❌ **Obsolètes** (remplacés par versions plus récentes)
- 📉 **Non performants** (faibles ventes)
- 🔄 **Saisonniers** (retour possible plus tard)

---

## 🧪 Cas d'usage 3 : Détection d'Anomalies

### Problématique métier

**Question** : Y a-t-il des factures sans lignes de détail ?

**Enjeu** : **Qualité des données** - détecter erreurs de saisie.

### Solution

```sql
-- Toutes les factures non annulées
SELECT 
    facture_id, 
    numero_facture, 
    montant_ttc,
    statut
FROM facture
WHERE statut != 'ANNULEE'
  AND YEAR(date_facture) = 2024

EXCEPT

-- Factures ayant au moins une ligne
SELECT DISTINCT
    f.facture_id, 
    f.numero_facture, 
    f.montant_ttc,
    f.statut
FROM facture f
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE f.statut != 'ANNULEE'
  AND YEAR(f.date_facture) = 2024;
```

**Résultat attendu** : 0 lignes (si qualité OK)

**Si résultat > 0** : Problème de qualité ! Ces factures doivent être :
- ✏️ Complétées avec lignes de détail
- 🗑️ Supprimées si erreur de saisie
- 🔄 Investiguées pour comprendre la cause

---

## 🧪 Cas d'usage 4 : Audit PROD vs DEV

### Problématique métier

**Question** : Quelles données existent en PRODUCTION mais manquent en DEV ?

**Enjeu** : **Synchronisation** des environnements pour tests fiables.

### Solution (simulation)

Nous allons simuler PROD et DEV avec des années différentes :

```sql
-- Simulation PROD (année 2024)
SELECT 
    client_id,
    nom,
    prenom,
    email
FROM client
WHERE YEAR(date_creation) <= 2024

EXCEPT

-- Simulation DEV (année 2025 seulement)
SELECT 
    client_id,
    nom,
    prenom,
    email
FROM client
WHERE YEAR(date_creation) = 2025;
```

### Application réelle

Sur IBM i avec deux bibliothèques :

```sql
-- Clients en PROD mais absents de DEV
SELECT client_id, nom, prenom FROM PROD.client
EXCEPT
SELECT client_id, nom, prenom FROM DEV.client;

-- Clients en DEV mais absents de PROD (données de test)
SELECT client_id, nom, prenom FROM DEV.client
EXCEPT
SELECT client_id, nom, prenom FROM PROD.client;
```

---

## 🧪 Cas d'usage 5 : Villes Sans Activité

### Problématique métier

**Question** : Quelles villes ont des clients enregistrés mais aucune facture payée ?

**Enjeu** : Identifier **marchés dormants** pour actions commerciales.

### Solution

```sql
-- Toutes les villes avec clients
SELECT DISTINCT ville
FROM client

EXCEPT

-- Villes avec au moins une facture payée
SELECT DISTINCT c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE';
```

**Résultat attendu** : 0-3 villes sans activité

### Actions possibles

Si villes sans activité détectées :
1. 📞 **Relance commerciale** ciblée
2. 🎯 **Campagne marketing** locale
3. 🔍 **Analyse** : pourquoi pas de ventes ?
4. 🗑️ **Nettoyage** : supprimer clients inactifs

---

## 📊 Comparaison de Performance

### Benchmark EXCEPT

Exécutez ces requêtes et notez les temps :

```sql
-- Test 1 : EXCEPT simple (petits ensembles)
SELECT DISTINCT ville FROM client WHERE ville IN ('Paris', 'Lyon')
EXCEPT
SELECT DISTINCT ville FROM client WHERE ville IN ('Lyon', 'Marseille');
```

**SQLite** : _______ ms  
**DuckDB** : _______ ms

```sql
-- Test 2 : EXCEPT avec jointures (moyens ensembles)
SELECT DISTINCT c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024 AND c.ville = 'Paris'

EXCEPT

SELECT DISTINCT c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024 AND c.ville = 'Lyon';
```

**SQLite** : _______ ms  
**DuckDB** : _______ ms

```sql
-- Test 3 : EXCEPT massif (gros ensembles)
SELECT facture_id, client_id, montant_ttc 
FROM facture
WHERE YEAR(date_facture) = 2024

EXCEPT

SELECT facture_id, client_id, montant_ttc 
FROM facture
WHERE YEAR(date_facture) = 2025;
```

**SQLite** : _______ secondes  
**DuckDB** : _______ secondes

**Analyse attendue** : DuckDB devrait être **2-10x plus rapide** sur les gros volumes.

---

## ⚠️ Pièges à éviter

### Piège 1 : Ordre des colonnes

```sql
-- ❌ MAUVAIS : Ordre différent
SELECT client_id, nom FROM client
EXCEPT
SELECT nom, client_id FROM client;
-- Compare (ID, nom) vs (nom, ID) → résultats incorrects !

-- ✅ BON : Même ordre
SELECT client_id, nom FROM client
EXCEPT
SELECT client_id, nom FROM client;
```

### Piège 2 : Types différents

```sql
-- ⚠️ ATTENTION : Conversion implicite
SELECT client_id FROM client         -- INTEGER
EXCEPT
SELECT numero_facture FROM facture;  -- TEXT
-- Peut fonctionner mais résultats imprévisibles
```

### Piège 3 : Oublier DISTINCT

```sql
-- EXCEPT dédoublonne automatiquement
SELECT ville FROM client  -- Peut avoir doublons
EXCEPT
SELECT ville FROM client WHERE ville = 'Paris';
-- Résultat : Villes sauf Paris (sans doublons)

-- Si vous voulez les doublons, utilisez NOT IN :
SELECT ville FROM client
WHERE ville NOT IN (SELECT ville FROM client WHERE ville = 'Paris');
```

### Piège 4 : NULL dans les comparaisons

```sql
-- ⚠️ NULL = NULL est FALSE en SQL
-- EXCEPT traite NULL = NULL comme TRUE (comportement spécial)

SELECT email FROM client  -- Peut contenir NULL
EXCEPT
SELECT email FROM client WHERE ville = 'Paris';
-- Les NULL sont comparés correctement
```

---

## 🔧 Optimisations

### 1. Ajouter des index

```sql
-- Améliore drastiquement les performances
CREATE INDEX IF NOT EXISTS idx_facture_date_statut 
ON facture(date_facture, statut);

CREATE INDEX IF NOT EXISTS idx_client_ville 
ON client(ville);
```

**Gain attendu** : 5-20x plus rapide sur requêtes filtrées.

### 2. Filtrer AVANT l'opération

```sql
-- ❌ LENT : Opération sur ensembles complets
SELECT client_id, nom FROM client
EXCEPT
SELECT client_id, nom FROM (
    SELECT DISTINCT c.client_id, c.nom
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE f.statut = 'PAYEE'
);

-- ✅ RAPIDE : Filtrer d'abord
SELECT client_id, nom 
FROM client
WHERE ville IN ('Paris', 'Lyon')  -- Réduction du volume

EXCEPT

SELECT c.client_id, c.nom
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND c.ville IN ('Paris', 'Lyon');  -- Même filtre
```

### 3. Utiliser des CTE pour clarté

```sql
WITH clients_2024 AS (
    SELECT DISTINCT client_id, nom, prenom
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE YEAR(f.date_facture) = 2024
),
clients_2025 AS (
    SELECT DISTINCT client_id, nom, prenom
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE YEAR(f.date_facture) = 2025
)
SELECT * FROM clients_2024
EXCEPT
SELECT * FROM clients_2025;
```

**Avantage** : Lisibilité + possibilité de réutiliser les CTE.

---

## 🎓 Exercices pratiques

### Exercice 1 : Nouveaux clients 2025

**Question** : Identifiez les clients qui ont été créés en 2025 mais n'ont jamais acheté.

<details>
<summary>💡 Indice</summary>

Utilisez EXCEPT entre tous les clients 2025 et les clients avec factures payées.

</details>

<details>
<summary>✅ Solution</summary>

```sql
SELECT client_id, nom, prenom, email
FROM client
WHERE YEAR(date_creation) = 2025

EXCEPT

SELECT DISTINCT c.client_id, c.nom, c.prenom, c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE';
```

</details>

### Exercice 2 : Produits régionaux

**Question** : Quels produits sont vendus à Paris mais jamais à Lyon ?

<details>
<summary>💡 Indice</summary>

EXCEPT entre produits vendus à Paris et produits vendus à Lyon.

</details>

<details>
<summary>✅ Solution</summary>

```sql
SELECT DISTINCT lf.description
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris' AND f.statut = 'PAYEE'

EXCEPT

SELECT DISTINCT lf.description
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE';
```

</details>

### Exercice 3 : Factures sans paiement

**Question** : Identifiez les factures EMISES qui n'ont jamais été PAYEES (impayés).

<details>
<summary>💡 Indice</summary>

EXCEPT entre factures EMISES et factures PAYEES sur le même client.

</details>

<details>
<summary>✅ Solution</summary>

```sql
SELECT numero_facture, client_id, montant_ttc, date_echeance
FROM facture
WHERE statut = 'EMISE'

EXCEPT

SELECT f1.numero_facture, f1.client_id, f1.montant_ttc, f1.date_echeance
FROM facture f1
INNER JOIN facture f2 ON f1.client_id = f2.client_id
WHERE f1.statut = 'EMISE' 
  AND f2.statut = 'PAYEE'
  AND f2.date_facture > f1.date_facture;
```

</details>

---

## 📝 Checklist EXCEPT

Avant d'utiliser EXCEPT, vérifiez :

- [ ] Même nombre de colonnes dans A et B
- [ ] Même ordre des colonnes
- [ ] Types de données compatibles
- [ ] Besoin de DISTINCT ? (automatique avec EXCEPT)
- [ ] Index sur colonnes de WHERE et JOIN
- [ ] Filtrer AVANT l'opération pour réduire le volume

---

## 📊 Tableau récapitulatif

| Critère | EXCEPT | NOT IN | NOT EXISTS |
|---------|--------|--------|------------|
| **Performance (petits volumes)** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Performance (gros volumes)** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| **Lisibilité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **Gestion NULL** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Déduplication** | Automatique | Non | Dépend |

**Recommandation** : Privilégiez **EXCEPT** pour comparaisons ensemblistes.

---

## ⏭️ Prochaine étape

Vous maîtrisez maintenant EXCEPT pour identifier les différences !

👉 Passez à [03-union-consolidation.md](03-union-consolidation.md) pour apprendre à consolider des données.

---

**Bravo ! Vous savez maintenant détecter les différences comme un pro. 🎯**
