-- ============================================================================
-- BENCHMARK OPÉRATIONS ENSEMBLISTES - SÉRIE 1 : POOL COMPLET
-- ============================================================================
-- Objectif: Tester les performances EXCEPT, UNION ALL, INTERSECT sans filtrage
-- Base: Tables client (5K), facture (150K), ligne_facture (~500K lignes)
--
-- Instructions d'exécution:
-- IBM i    : STRSQL ou ACS Run SQL Scripts
-- SQLite   : sqlite3 facturation.db < benchmark_01_pool_complet.sql
-- DuckDB   : duckdb facturation.duckdb < benchmark_01_pool_complet.sql
-- ============================================================================

-- Activer le timing (syntaxe adaptée selon la plateforme)
-- SQLite: .timer on
-- DuckDB: .timer on
-- IBM i:  Menu -> Options -> Show Elapsed Time

-- ============================================================================
-- QUERY 1: EXCEPT - Factures clients parisiens vs non-parisiens
-- ============================================================================
-- Objectif: Identifier les factures uniques aux clients parisiens
-- Volume attendu: ~15-20K factures (10-13% du total)
-- Complexité: Jointure + opération ensembliste sur grand volume

SELECT 
    f.facture_id, 
    f.client_id, 
    f.montant_ttc, 
    f.statut,
    f.date_facture
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris'

EXCEPT

SELECT 
    f.facture_id, 
    f.client_id, 
    f.montant_ttc, 
    f.statut,
    f.date_facture
FROM facture f
INNER JOIN client c ON f.client_id = c.client_id
WHERE c.ville != 'Paris';

-- Note: Cette requête scanne ~150K factures avec 2 jointures
-- Performance attendue: IBM i (5-15s), SQLite (2-8s), DuckDB (0.5-2s)


-- ============================================================================
-- QUERY 2: UNION ALL - Consolidation factures 2024 et 2025
-- ============================================================================
-- Objectif: Combiner toutes les factures de 2024 et 2025
-- Volume attendu: ~50-60K factures (doublons possibles si facture sur 2 ans)
-- Complexité: Scan de table complet avec extraction année

SELECT 
    facture_id, 
    client_id, 
    date_facture, 
    montant_ttc, 
    statut,
    'Année 2024' AS source
FROM facture
WHERE YEAR(date_facture) = 2024

UNION ALL

SELECT 
    facture_id, 
    client_id, 
    date_facture, 
    montant_ttc, 
    statut,
    'Année 2025' AS source
FROM facture
WHERE YEAR(date_facture) = 2025;

-- Note: UNION ALL ne dédoublonne pas, très rapide
-- Performance attendue: IBM i (3-8s), SQLite (1-4s), DuckDB (0.2-1s)


-- ============================================================================
-- QUERY 3: INTERSECT - Clients ayant factures PAYEE ET EMISE
-- ============================================================================
-- Objectif: Trouver les clients avec au moins 1 facture PAYEE ET 1 EMISE
-- Volume attendu: ~2-3K clients (40-60% du total)
-- Complexité: Jointure + agrégation implicite + intersection

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom, 
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'

INTERSECT

SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom, 
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'EMISE';

-- Note: INTERSECT nécessite tri/hash pour déduplication
-- Performance attendue: IBM i (4-12s), SQLite (2-6s), DuckDB (0.3-1.5s)


-- ============================================================================
-- QUERY 4: EXCEPT - Produits vendus en 2024 mais pas en 2025
-- ============================================================================
-- Objectif: Identifier les produits qui ne se vendent plus
-- Volume attendu: ~5-10 produits (sur 25 possibles)
-- Complexité: Scan de ~500K lignes de facture avec jointure temporelle

SELECT DISTINCT 
    lf.description,
    COUNT(*) OVER (PARTITION BY lf.description) AS nb_ventes_2024
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024

EXCEPT

SELECT DISTINCT 
    lf.description,
    COUNT(*) OVER (PARTITION BY lf.description) AS nb_ventes_2025
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025;

-- Note: Jointure sur table massive (ligne_facture)
-- Performance attendue: IBM i (8-20s), SQLite (4-12s), DuckDB (0.8-3s)


-- ============================================================================
-- QUERY 5: UNION ALL - Top clients par CA 2024 et 2025
-- ============================================================================
-- Objectif: Lister tous les gros clients (>50K€) de 2024 et 2025
-- Volume attendu: ~200-400 lignes (avec doublons si client présent 2 ans)
-- Complexité: Agrégation + jointure + UNION ALL

SELECT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.ville,
    SUM(f.montant_ttc) AS ca_total,
    2024 AS annee,
    COUNT(f.facture_id) AS nb_factures
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024 
  AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom, c.ville
HAVING SUM(f.montant_ttc) > 50000

UNION ALL

SELECT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.ville,
    SUM(f.montant_ttc) AS ca_total,
    2025 AS annee,
    COUNT(f.facture_id) AS nb_factures
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025 
  AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom, c.ville
HAVING SUM(f.montant_ttc) > 50000;

-- Note: Double agrégation + UNION ALL simple
-- Performance attendue: IBM i (6-15s), SQLite (3-9s), DuckDB (0.5-2.5s)


-- ============================================================================
-- QUERY 6: INTERSECT - Villes avec clients ET factures payées
-- ============================================================================
-- Objectif: Villes ayant des clients actifs (au moins 1 facture payée)
-- Volume attendu: ~15-18 villes (sur 18 possibles)
-- Complexité: Scan client + jointure + déduplication

SELECT DISTINCT c.ville
FROM client c

INTERSECT

SELECT DISTINCT c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE';

-- Note: Opération légère, peu de lignes en sortie
-- Performance attendue: IBM i (2-6s), SQLite (1-3s), DuckDB (0.2-0.8s)


-- ============================================================================
-- QUERY 7: EXCEPT - Analyse statuts - Clients avec PAYEE mais jamais EMISE
-- ============================================================================
-- Objectif: Clients payant directement sans passer par émission
-- Volume attendu: ~1-2K clients
-- Complexité: Double scan avec jointure + EXCEPT

SELECT DISTINCT 
    c.client_id,
    c.nom,
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'

EXCEPT

SELECT DISTINCT 
    c.client_id,
    c.nom,
    c.prenom,
    c.email
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'EMISE';

-- Note: Scan complet des factures pour chaque statut
-- Performance attendue: IBM i (5-12s), SQLite (2-7s), DuckDB (0.4-2s)


-- ============================================================================
-- QUERY 8: UNION ALL - Analyse mensuelle CA 2024
-- ============================================================================
-- Objectif: CA mensuel sur toute l'année 2024 (12 requêtes unifiées)
-- Volume attendu: 12 lignes (1 par mois)
-- Complexité: 12 agrégations distinctes + UNION ALL

SELECT 
    1 AS mois,
    'Janvier' AS nom_mois,
    COUNT(facture_id) AS nb_factures,
    SUM(montant_ttc) AS ca_ttc
FROM facture
WHERE YEAR(date_facture) = 2024 
  AND MONTH(date_facture) = 1
  AND statut = 'PAYEE'

UNION ALL SELECT 2, 'Février', COUNT(*), SUM(montant_ttc) FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 2 AND statut = 'PAYEE'
UNION ALL SELECT 3, 'Mars', COUNT(*), SUM(montant_ttc) FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 3 AND statut = 'PAYEE'
UNION ALL SELECT 4, 'Avril', COUNT(*), SUM(montant_ttc) FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 4 AND statut = 'PAYEE'
UNION ALL SELECT 5, 'Mai', COUNT(*), SUM(montant_ttc) FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 5 AND statut = 'PAYEE'
UNION ALL SELECT 6, 'Juin', COUNT(*), SUM(montant_ttc) FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 6 AND statut = 'PAYEE'
UNION ALL SELECT 7, 'Juillet', COUNT(*), SUM(montant_ttc) FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 7 AND statut = 'PAYEE'
UNION ALL SELECT 8, 'Août', COUNT(*), SUM(montant_ttc) FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 8 AND statut = 'PAYEE'
UNION ALL SELECT 9, 'Septembre', COUNT(*), SUM(montant_ttc) FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 9 AND statut = 'PAYEE'
UNION ALL SELECT 10, 'Octobre', COUNT(*), SUM(montant_ttc) FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 10 AND statut = 'PAYEE'
UNION ALL SELECT 11, 'Novembre', COUNT(*), SUM(montant_ttc) FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 11 AND statut = 'PAYEE'
UNION ALL SELECT 12, 'Décembre', COUNT(*), SUM(montant_ttc) FROM facture WHERE YEAR(date_facture) = 2024 AND MONTH(date_facture) = 12 AND statut = 'PAYEE';

-- Note: 12 scans de la table facture, mais UNION ALL sans dédup
-- Performance attendue: IBM i (8-18s), SQLite (4-10s), DuckDB (0.6-2.5s)


-- ============================================================================
-- QUERY 9: INTERSECT - Produits achetés par top clients ET clients réguliers
-- ============================================================================
-- Objectif: Produits populaires dans tous les segments
-- Volume attendu: ~8-12 produits
-- Complexité: Double agrégation avec seuils + intersection

SELECT DISTINCT lf.description
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN (
    SELECT client_id
    FROM facture
    WHERE statut = 'PAYEE' AND YEAR(date_facture) >= 2024
    GROUP BY client_id
    HAVING SUM(montant_ttc) > 100000
) AS top_clients ON f.client_id = top_clients.client_id
WHERE f.statut = 'PAYEE'

INTERSECT

SELECT DISTINCT lf.description
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
INNER JOIN (
    SELECT client_id
    FROM facture
    WHERE statut = 'PAYEE' AND YEAR(date_facture) >= 2024
    GROUP BY client_id
    HAVING SUM(montant_ttc) BETWEEN 10000 AND 50000
) AS regular_clients ON f.client_id = regular_clients.client_id
WHERE f.statut = 'PAYEE';

-- Note: Sous-requêtes + jointures multiples + intersection
-- Performance attendue: IBM i (10-25s), SQLite (5-15s), DuckDB (1-4s)


-- ============================================================================
-- QUERY 10: EXCEPT - Clients 2024 perdus en 2025
-- ============================================================================
-- Objectif: Détection de churn - clients actifs en 2024 mais absents en 2025
-- Volume attendu: ~500-1000 clients
-- Complexité: Scan temporel + EXCEPT

SELECT DISTINCT 
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2024
  AND f.statut IN ('PAYEE', 'EMISE')

EXCEPT

SELECT DISTINCT 
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025
  AND f.statut IN ('PAYEE', 'EMISE');

-- Note: Indicateur clé de rétention client
-- Performance attendue: IBM i (6-14s), SQLite (3-8s), DuckDB (0.5-2.5s)


-- ============================================================================
-- RÉSUMÉ DES PERFORMANCES ATTENDUES (en secondes)
-- ============================================================================
--
-- Opération        | IBM i (DB2) | SQLite  | DuckDB
-- -----------------|-------------|---------|--------
-- EXCEPT simple    | 5-15        | 2-8     | 0.5-2
-- UNION ALL simple | 3-8         | 1-4     | 0.2-1
-- INTERSECT simple | 4-12        | 2-6     | 0.3-1.5
-- EXCEPT complexe  | 10-25       | 5-15    | 1-4
-- UNION ALL multi  | 8-18        | 4-10    | 0.6-2.5
-- INTERSECT +CTE   | 10-25       | 5-15    | 1-4
--
-- Facteurs de performance:
-- - Index sur (client_id, date_facture, statut) critiques
-- - IBM i: I/O disque, pas de vectorisation
-- - SQLite: Mono-thread, optimisé pour lectures
-- - DuckDB: Vectorisation SIMD, compression columnar
-- ============================================================================
