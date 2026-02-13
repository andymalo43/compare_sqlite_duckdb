-- ============================================================================
-- BENCHMARK OPÉRATIONS ENSEMBLISTES - SÉRIE 2 : AVEC WHERE LIMITANT
-- ============================================================================
-- Objectif: Tester les performances EXCEPT, UNION ALL, INTERSECT avec filtrage
-- Démontrer l'impact du WHERE sur la réduction du volume traité
-- 
-- Instructions d'exécution:
-- IBM i    : STRSQL ou ACS Run SQL Scripts
-- SQLite   : sqlite3 facturation.db < benchmark_02_where_limite.sql
-- DuckDB   : duckdb facturation.duckdb < benchmark_02_where_limite.sql
-- ============================================================================

-- Activer le timing
-- SQLite: .timer on
-- DuckDB: .timer on
-- IBM i:  Menu -> Options -> Show Elapsed Time


-- ============================================================================
-- QUERY 1: EXCEPT - Factures >10K€ Paris vs Lyon (filtrage agressif)
-- ============================================================================
-- Objectif: Comparer les grosses factures entre 2 villes spécifiques
-- Volume traité: ~2-3K factures (vs 150K sans WHERE)
-- Réduction: 95% du volume éliminé par WHERE
-- Performance attendue: 10-50x plus rapide que sans filtrage

SELECT 
    f.facture_id, 
    f.numero_facture,
    f.client_id, 
    f.montant_ttc,
    c.nom AS nom_client,
    c.prenom AS prenom_client
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris' 
  AND f.montant_ttc > 10000
  AND YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE'

EXCEPT

SELECT 
    f.facture_id, 
    f.numero_facture,
    f.client_id, 
    f.montant_ttc,
    c.nom AS nom_client,
    c.prenom AS prenom_client
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Lyon'
  AND f.montant_ttc > 10000
  AND YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE';

-- Volume attendu: 50-150 factures
-- Performance: IBM i (0.5-2s), SQLite (0.2-0.8s), DuckDB (0.05-0.3s)
-- Gain vs sans WHERE: ~10-20x plus rapide


-- ============================================================================
-- QUERY 2: UNION ALL - Q4 2024 PAYEE + EMISE seulement (période limitée)
-- ============================================================================
-- Objectif: Analyser uniquement le dernier trimestre
-- Volume traité: ~12-15K factures (vs 150K sans WHERE)
-- Réduction: 90% du volume éliminé
-- Démontre l'efficacité du filtrage temporel

SELECT 
    facture_id, 
    numero_facture,
    client_id, 
    montant_ttc, 
    statut, 
    date_facture,
    'PAYEE' AS type_analyse
FROM facture
WHERE statut = 'PAYEE'
  AND date_facture >= '2024-10-01'
  AND date_facture <= '2024-12-31'

UNION ALL

SELECT 
    facture_id, 
    numero_facture,
    client_id, 
    montant_ttc, 
    statut, 
    date_facture,
    'EMISE' AS type_analyse
FROM facture
WHERE statut = 'EMISE'
  AND date_facture >= '2024-10-01'
  AND date_facture <= '2024-12-31';

-- Volume attendu: ~6K lignes (3K par statut)
-- Performance: IBM i (0.8-3s), SQLite (0.3-1.2s), DuckDB (0.08-0.4s)
-- Gain vs sans WHERE: ~5-10x plus rapide


-- ============================================================================
-- QUERY 3: INTERSECT - Clients VIP avec produits premium (multi-critères)
-- ============================================================================
-- Objectif: Croiser segments clients et achats spécifiques
-- Volume traité: ~5-10K lignes client + facture
-- Réduction: Filtres multiples (CA, année, produits)
-- Requête métier complexe mais très optimisée

SELECT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND YEAR(f.date_facture) IN (2024, 2025)
  AND c.ville IN ('Paris', 'Lyon', 'Marseille')  -- Grandes villes seulement
GROUP BY c.client_id, c.nom, c.prenom, c.email, c.ville
HAVING SUM(f.montant_ttc) > 100000

INTERSECT

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE lf.description IN ('Ordinateur portable', 'Licence logicielle', 'Service support', 'Hébergement cloud')
  AND YEAR(f.date_facture) IN (2024, 2025)
  AND f.statut = 'PAYEE'
  AND c.ville IN ('Paris', 'Lyon', 'Marseille');

-- Volume attendu: 20-80 clients VIP
-- Performance: IBM i (1-4s), SQLite (0.5-2s), DuckDB (0.1-0.6s)
-- Gain vs sans WHERE: ~15-25x plus rapide


-- ============================================================================
-- QUERY 4: EXCEPT - Détection anomalies qualité (factures orphelines)
-- ============================================================================
-- Objectif: Identifier factures sans lignes détail (erreur de saisie)
-- Volume traité: ~30K factures 2024 (vs 150K total)
-- Filtrage: Année spécifique + exclusion annulées
-- Cas d'usage: Audit qualité mensuel

SELECT 
    f.facture_id, 
    f.numero_facture, 
    f.montant_ttc,
    f.date_facture,
    f.statut
FROM facture f
WHERE f.statut != 'ANNULEE'
  AND YEAR(f.date_facture) = 2024
  AND MONTH(f.date_facture) BETWEEN 1 AND 6  -- Premier semestre seulement

EXCEPT

SELECT DISTINCT 
    f.facture_id, 
    f.numero_facture, 
    f.montant_ttc,
    f.date_facture,
    f.statut
FROM facture f
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE f.statut != 'ANNULEE'
  AND YEAR(f.date_facture) = 2024
  AND MONTH(f.date_facture) BETWEEN 1 AND 6;

-- Volume attendu: 0-5 factures anomales (si qualité OK)
-- Performance: IBM i (0.8-3.5s), SQLite (0.4-1.5s), DuckDB (0.1-0.5s)
-- Gain vs sans WHERE: ~8-15x plus rapide


-- ============================================================================
-- QUERY 5: UNION ALL - Analyse TVA consolidée par taux (agrégation ciblée)
-- ============================================================================
-- Objectif: Calculer CA HT et TVA par taux pour déclaration fiscale
-- Volume traité: ~100K lignes facture 2024 PAYEE (vs 500K total)
-- Filtrage: Année + statut + taux spécifiques
-- Sortie: 3 lignes agrégées (1 par taux TVA)

SELECT 
    lf.taux_tva,
    '20.0%' AS libelle_tva,
    COUNT(DISTINCT f.facture_id) as nb_factures,
    COUNT(lf.ligne_id) as nb_lignes,
    ROUND(SUM(lf.montant_ht), 2) as total_ht,
    ROUND(SUM(lf.montant_tva), 2) as total_tva,
    ROUND(SUM(lf.montant_ttc), 2) as total_ttc
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE lf.taux_tva = 20.0
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024
  AND MONTH(f.date_facture) BETWEEN 1 AND 12  -- Année complète
GROUP BY lf.taux_tva

UNION ALL

SELECT 
    lf.taux_tva,
    '10.0%' AS libelle_tva,
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
  AND MONTH(f.date_facture) BETWEEN 1 AND 12
GROUP BY lf.taux_tva

UNION ALL

SELECT 
    lf.taux_tva,
    '5.5%' AS libelle_tva,
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
  AND MONTH(f.date_facture) BETWEEN 1 AND 12
GROUP BY lf.taux_tva;

-- Volume attendu: 3 lignes de résultat
-- Performance: IBM i (2-6s), SQLite (1-3s), DuckDB (0.2-1s)
-- Gain vs sans WHERE: ~6-12x plus rapide


-- ============================================================================
-- QUERY 6: INTERSECT - Clients récurrents Q1 ET Q4 (fidélité annuelle)
-- ============================================================================
-- Objectif: Identifier clients ayant acheté début ET fin d'année
-- Volume traité: ~15K factures (2 trimestres vs année complète)
-- Filtrage: Périodes précises + statut PAYEE
-- Métrique de rétention client

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.telephone
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-01-01'
  AND f.date_facture <= '2024-03-31'
  AND f.montant_ttc > 1000  -- Achats significatifs seulement

INTERSECT

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.telephone
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-10-01'
  AND f.date_facture <= '2024-12-31'
  AND f.montant_ttc > 1000;

-- Volume attendu: 200-500 clients fidèles
-- Performance: IBM i (0.6-2.5s), SQLite (0.3-1.2s), DuckDB (0.08-0.5s)
-- Gain vs sans WHERE: ~12-20x plus rapide


-- ============================================================================
-- QUERY 7: EXCEPT - Nouveaux clients 2025 (absents de 2024)
-- ============================================================================
-- Objectif: Mesurer la croissance de la base client
-- Volume traité: ~25-30K factures (2 années distinctes)
-- Filtrage: Années séparées + statut actif
-- KPI croissance commercial

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.ville,
    c.date_creation
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025
  AND f.statut IN ('PAYEE', 'EMISE')

EXCEPT

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.ville,
    c.date_creation
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024
  AND f.statut IN ('PAYEE', 'EMISE');

-- Volume attendu: 300-800 nouveaux clients
-- Performance: IBM i (1-4s), SQLite (0.5-2s), DuckDB (0.1-0.7s)
-- Gain vs sans WHERE: ~10-18x plus rapide


-- ============================================================================
-- QUERY 8: UNION ALL - Top produits par segment géographique (ciblé)
-- ============================================================================
-- Objectif: Identifier best-sellers par région (Paris, Lyon, Marseille)
-- Volume traité: ~50-70K lignes (3 villes vs toutes)
-- Filtrage: Villes spécifiques + année + statut
-- Analyse régionale pour stratégie commerciale

-- Paris
SELECT 
    c.ville,
    lf.description AS produit,
    COUNT(lf.ligne_id) AS nb_ventes,
    ROUND(SUM(lf.montant_ttc), 2) AS ca_ttc
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024
GROUP BY c.ville, lf.description
HAVING COUNT(lf.ligne_id) >= 10  -- Minimum 10 ventes

UNION ALL

-- Lyon
SELECT 
    c.ville,
    lf.description,
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Lyon'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024
GROUP BY c.ville, lf.description
HAVING COUNT(lf.ligne_id) >= 10

UNION ALL

-- Marseille
SELECT 
    c.ville,
    lf.description,
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Marseille'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024
GROUP BY c.ville, lf.description
HAVING COUNT(lf.ligne_id) >= 10

ORDER BY ville, ca_ttc DESC;

-- Volume attendu: 60-150 lignes (20-50 par ville)
-- Performance: IBM i (2-7s), SQLite (1-3.5s), DuckDB (0.3-1.2s)
-- Gain vs sans WHERE: ~8-15x plus rapide


-- ============================================================================
-- QUERY 9: INTERSECT - Cross-sell : Clients "Ordinateur" ET "Licence"
-- ============================================================================
-- Objectif: Identifier opportunités de vente complémentaire
-- Volume traité: ~80-100K lignes filtrées (vs 500K total)
-- Filtrage: Produits spécifiques + période récente
-- Stratégie commerciale ciblée

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.telephone
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE lf.description = 'Ordinateur portable'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) IN (2024, 2025)

INTERSECT

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.telephone
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
INNER JOIN ligne_facture lf ON f.facture_id = lf.facture_id
WHERE lf.description = 'Licence logicielle'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) IN (2024, 2025);

-- Volume attendu: 150-400 clients
-- Performance: IBM i (1.5-5s), SQLite (0.7-2.5s), DuckDB (0.15-0.8s)
-- Gain vs sans WHERE: ~10-18x plus rapide


-- ============================================================================
-- QUERY 10: EXCEPT - Clients inactifs Q3 2024 (risque churn)
-- ============================================================================
-- Objectif: Détecter clients actifs Q1-Q2 mais absents Q3
-- Volume traité: ~12-15K factures (trimestres ciblés)
-- Filtrage: Périodes précises pour early warning
-- Action commerciale préventive

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.telephone,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut IN ('PAYEE', 'EMISE')
  AND f.date_facture >= '2024-01-01'
  AND f.date_facture <= '2024-06-30'  -- Q1 + Q2
  AND f.montant_ttc > 500

EXCEPT

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.telephone,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut IN ('PAYEE', 'EMISE')
  AND f.date_facture >= '2024-07-01'
  AND f.date_facture <= '2024-09-30';  -- Q3

-- Volume attendu: 200-600 clients à risque
-- Performance: IBM i (0.8-3s), SQLite (0.4-1.5s), DuckDB (0.1-0.6s)
-- Gain vs sans WHERE: ~12-22x plus rapide


-- ============================================================================
-- COMPARAISON PERFORMANCES : POOL COMPLET vs WHERE LIMITANT
-- ============================================================================
--
-- Opération Type    | Sans WHERE  | Avec WHERE  | Gain Performance
-- ------------------|-------------|-------------|------------------
-- EXCEPT simple     | 5-15s       | 0.5-2s      | 10-15x
-- UNION ALL simple  | 3-8s        | 0.3-1.2s    | 8-12x
-- INTERSECT simple  | 4-12s       | 0.3-1.5s    | 12-20x
-- EXCEPT complexe   | 10-25s      | 1-5s        | 10-18x
-- UNION ALL multi   | 8-18s       | 1-3.5s      | 8-15x
-- INTERSECT +JOIN   | 10-25s      | 1-5s        | 15-25x
--
-- Facteurs d'optimisation WHERE:
-- 1. Filtrage temporel (YEAR, MONTH, dates) = +60-80% gain
-- 2. Filtrage statut (PAYEE, EMISE) = +30-50% gain
-- 3. Filtrage montant (> seuil) = +40-70% gain
-- 4. Filtrage géographique (ville) = +20-40% gain
-- 5. Combinaison de filtres = gains multiplicatifs
--
-- Best practices WHERE pour ensemblistes:
-- - Placer les filtres AVANT l'opération ensembliste
-- - Utiliser index sur colonnes de WHERE (date, statut, montant)
-- - Combiner plusieurs critères pour réduction maximale
-- - Préférer plages de dates précises vs fonctions (YEAR, MONTH)
-- - Éviter les OR multiples, préférer IN (...)
-- ============================================================================
