-- ============================================================================
-- REQUÊTES DE COMPARAISON COMPLÈTE ENTRE DEUX POOLS
-- ============================================================================
-- Pattern: Afficher TOUTES les différences et similitudes entre P1 et P2
-- Format: 'SOURCE', * FROM données
-- 
-- Résultat en 3 catégories:
-- - 'P1_ONLY' : Lignes présentes uniquement dans P1
-- - 'P2_ONLY' : Lignes présentes uniquement dans P2  
-- - 'BOTH'    : Lignes présentes dans P1 ET P2
-- ============================================================================


-- ============================================================================
-- EXEMPLE 1 : Comparaison clients Paris vs Lyon
-- ============================================================================
-- Objectif: Comparer les profils clients entre deux villes
-- Identifier les clients uniques à chaque ville et les similitudes

SELECT 
    'PARIS_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.code_postal
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Paris' AND f.statut = 'PAYEE'

EXCEPT

SELECT 
    'PARIS_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.code_postal
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE'

UNION ALL

SELECT 
    'LYON_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.code_postal
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE'

EXCEPT

SELECT 
    'LYON_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.code_postal
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Paris' AND f.statut = 'PAYEE'

UNION ALL

SELECT 
    'BOTH_CITIES' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.code_postal
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Paris' AND f.statut = 'PAYEE'

INTERSECT

SELECT 
    'BOTH_CITIES' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.code_postal
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE'

ORDER BY source, client_id;


-- ============================================================================
-- EXEMPLE 2 : Comparaison produits vendus 2024 vs 2025
-- ============================================================================
-- Objectif: Analyser l'évolution du catalogue entre deux années
-- Identifier produits abandonnés, nouveaux, et récurrents

SELECT 
    '2024_ONLY' AS source,
    lf.description AS produit,
    COUNT(DISTINCT f.facture_id) AS nb_factures,
    COUNT(lf.ligne_id) AS nb_ventes,
    ROUND(SUM(lf.montant_ttc), 2) AS ca_total
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY lf.description

EXCEPT

SELECT 
    '2024_ONLY' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY lf.description

UNION ALL

SELECT 
    '2025_ONLY' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY lf.description

EXCEPT

SELECT 
    '2025_ONLY' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY lf.description

UNION ALL

SELECT 
    'BOTH_YEARS' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY lf.description

INTERSECT

SELECT 
    'BOTH_YEARS' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM ligne_facture lf
INNER JOIN facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY lf.description

ORDER BY source, ca_total DESC;


-- ============================================================================
-- EXEMPLE 3 : Comparaison profils clients VIP (>100K) vs Standard (10K-100K)
-- ============================================================================
-- Objectif: Analyser les différences de comportement d'achat
-- Identifier clients communs aux deux segments (upgrade/downgrade)

SELECT 
    'VIP_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.ville,
    SUM(f.montant_ttc) AS ca_total,
    COUNT(f.facture_id) AS nb_factures
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE' 
  AND YEAR(f.date_facture) = 2024
GROUP BY c.client_id, c.nom, c.prenom, c.ville
HAVING SUM(f.montant_ttc) > 100000

EXCEPT

SELECT 
    'VIP_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.ville,
    SUM(f.montant_ttc),
    COUNT(f.facture_id)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE' 
  AND YEAR(f.date_facture) = 2024
GROUP BY c.client_id, c.nom, c.prenom, c.ville
HAVING SUM(f.montant_ttc) BETWEEN 10000 AND 100000

UNION ALL

SELECT 
    'STANDARD_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.ville,
    SUM(f.montant_ttc),
    COUNT(f.facture_id)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE' 
  AND YEAR(f.date_facture) = 2024
GROUP BY c.client_id, c.nom, c.prenom, c.ville
HAVING SUM(f.montant_ttc) BETWEEN 10000 AND 100000

EXCEPT

SELECT 
    'STANDARD_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.ville,
    SUM(f.montant_ttc),
    COUNT(f.facture_id)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE' 
  AND YEAR(f.date_facture) = 2024
GROUP BY c.client_id, c.nom, c.prenom, c.ville
HAVING SUM(f.montant_ttc) > 100000

UNION ALL

SELECT 
    'BOTH_SEGMENTS' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.ville,
    SUM(f.montant_ttc),
    COUNT(f.facture_id)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE' 
  AND YEAR(f.date_facture) = 2024
GROUP BY c.client_id, c.nom, c.prenom, c.ville
HAVING SUM(f.montant_ttc) > 100000

INTERSECT

SELECT 
    'BOTH_SEGMENTS' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.ville,
    SUM(f.montant_ttc),
    COUNT(f.facture_id)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE' 
  AND YEAR(f.date_facture) = 2024
GROUP BY c.client_id, c.nom, c.prenom, c.ville
HAVING SUM(f.montant_ttc) BETWEEN 10000 AND 100000

ORDER BY source, ca_total DESC;


-- ============================================================================
-- EXEMPLE 4 : Comparaison Q1 vs Q4 2024 - Analyse saisonnalité
-- ============================================================================
-- Objectif: Comparer les comportements d'achat entre début et fin d'année
-- Identifier clients saisonniers vs clients réguliers

SELECT 
    'Q1_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    COUNT(f.facture_id) AS nb_factures,
    ROUND(SUM(f.montant_ttc), 2) AS ca_total
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-01-01'
  AND f.date_facture <= '2024-03-31'
GROUP BY c.client_id, c.nom, c.prenom, c.email

EXCEPT

SELECT 
    'Q1_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    COUNT(f.facture_id),
    ROUND(SUM(f.montant_ttc), 2)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-10-01'
  AND f.date_facture <= '2024-12-31'
GROUP BY c.client_id, c.nom, c.prenom, c.email

UNION ALL

SELECT 
    'Q4_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    COUNT(f.facture_id),
    ROUND(SUM(f.montant_ttc), 2)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-10-01'
  AND f.date_facture <= '2024-12-31'
GROUP BY c.client_id, c.nom, c.prenom, c.email

EXCEPT

SELECT 
    'Q4_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    COUNT(f.facture_id),
    ROUND(SUM(f.montant_ttc), 2)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-01-01'
  AND f.date_facture <= '2024-03-31'
GROUP BY c.client_id, c.nom, c.prenom, c.email

UNION ALL

SELECT 
    'BOTH_QUARTERS' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    COUNT(f.facture_id),
    ROUND(SUM(f.montant_ttc), 2)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-01-01'
  AND f.date_facture <= '2024-03-31'
GROUP BY c.client_id, c.nom, c.prenom, c.email

INTERSECT

SELECT 
    'BOTH_QUARTERS' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    COUNT(f.facture_id),
    ROUND(SUM(f.montant_ttc), 2)
FROM client c
INNER JOIN facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-10-01'
  AND f.date_facture <= '2024-12-31'
GROUP BY c.client_id, c.nom, c.prenom, c.email

ORDER BY source, ca_total DESC;


-- ============================================================================
-- EXEMPLE 5 : Comparaison environnements PROD vs DEV (Audit qualité)
-- ============================================================================
-- Objectif: Identifier les différences de données entre environnements
-- Critical pour migration, synchronisation, tests

-- Note: Cette requête suppose deux schémas/bases différents
-- Adapter selon votre configuration (prod.table vs dev.table)

-- Version générique (même base, simulation avec années différentes)
SELECT 
    'PROD_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.date_creation
FROM client c
WHERE YEAR(c.date_creation) <= 2024

EXCEPT

SELECT 
    'PROD_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.date_creation
FROM client c
WHERE YEAR(c.date_creation) = 2025

UNION ALL

SELECT 
    'DEV_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.date_creation
FROM client c
WHERE YEAR(c.date_creation) = 2025

EXCEPT

SELECT 
    'DEV_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.date_creation
FROM client c
WHERE YEAR(c.date_creation) <= 2024

UNION ALL

SELECT 
    'SYNCHRONIZED' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.date_creation
FROM client c
WHERE YEAR(c.date_creation) <= 2024

INTERSECT

SELECT 
    'SYNCHRONIZED' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.date_creation
FROM client c
WHERE YEAR(c.date_creation) = 2025

ORDER BY source, client_id;


-- ============================================================================
-- EXEMPLE 6 : VERSION AVEC CTE (Plus lisible et maintenable)
-- ============================================================================
-- Pattern recommandé pour requêtes complexes
-- Améliore la lisibilité et permet réutilisation des pools

WITH pool_paris AS (
    SELECT 
        c.client_id,
        c.nom,
        c.prenom,
        c.email,
        c.ville,
        COUNT(f.facture_id) AS nb_factures,
        ROUND(SUM(f.montant_ttc), 2) AS ca_total
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Paris' 
      AND f.statut = 'PAYEE'
      AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom, c.prenom, c.email, c.ville
),
pool_lyon AS (
    SELECT 
        c.client_id,
        c.nom,
        c.prenom,
        c.email,
        c.ville,
        COUNT(f.facture_id) AS nb_factures,
        ROUND(SUM(f.montant_ttc), 2) AS ca_total
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Lyon' 
      AND f.statut = 'PAYEE'
      AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom, c.prenom, c.email, c.ville
)
-- Pool Paris uniquement
SELECT 'PARIS_ONLY' AS source, * FROM pool_paris
EXCEPT
SELECT 'PARIS_ONLY' AS source, * FROM pool_lyon

UNION ALL

-- Pool Lyon uniquement
SELECT 'LYON_ONLY' AS source, * FROM pool_lyon
EXCEPT
SELECT 'LYON_ONLY' AS source, * FROM pool_paris

UNION ALL

-- Intersection (clients présents dans les deux)
SELECT 'BOTH_CITIES' AS source, * FROM pool_paris
INTERSECT
SELECT 'BOTH_CITIES' AS source, * FROM pool_lyon

ORDER BY source, ca_total DESC;


-- ============================================================================
-- EXEMPLE 7 : Avec statistiques agrégées par source
-- ============================================================================
-- Version avancée qui ajoute des métriques par catégorie

WITH comparison_result AS (
    -- Paris only
    SELECT 
        'PARIS_ONLY' AS source,
        c.client_id,
        c.nom,
        COUNT(f.facture_id) AS nb_factures,
        ROUND(SUM(f.montant_ttc), 2) AS ca_total
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Paris' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    EXCEPT
    
    SELECT 
        'PARIS_ONLY' AS source,
        c.client_id,
        c.nom,
        COUNT(f.facture_id),
        ROUND(SUM(f.montant_ttc), 2)
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    UNION ALL
    
    -- Lyon only
    SELECT 
        'LYON_ONLY' AS source,
        c.client_id,
        c.nom,
        COUNT(f.facture_id),
        ROUND(SUM(f.montant_ttc), 2)
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    EXCEPT
    
    SELECT 
        'LYON_ONLY' AS source,
        c.client_id,
        c.nom,
        COUNT(f.facture_id),
        ROUND(SUM(f.montant_ttc), 2)
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Paris' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    UNION ALL
    
    -- Both
    SELECT 
        'BOTH' AS source,
        c.client_id,
        c.nom,
        COUNT(f.facture_id),
        ROUND(SUM(f.montant_ttc), 2)
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Paris' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    INTERSECT
    
    SELECT 
        'BOTH' AS source,
        c.client_id,
        c.nom,
        COUNT(f.facture_id),
        ROUND(SUM(f.montant_ttc), 2)
    FROM client c
    INNER JOIN facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE' AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
)
-- Résumé par source
SELECT 
    source,
    COUNT(*) AS nb_clients,
    SUM(nb_factures) AS total_factures,
    ROUND(SUM(ca_total), 2) AS total_ca,
    ROUND(AVG(ca_total), 2) AS ca_moyen,
    ROUND(MIN(ca_total), 2) AS ca_min,
    ROUND(MAX(ca_total), 2) AS ca_max
FROM comparison_result
GROUP BY source
ORDER BY source;


-- ============================================================================
-- EXEMPLE 8 : Pattern générique réutilisable (Template)
-- ============================================================================
-- Remplacer P1_CONDITION et P2_CONDITION par vos critères

/*
WITH pool_1 AS (
    SELECT 
        -- Colonnes à comparer
        colonne1,
        colonne2,
        colonne3,
        -- Métriques
        COUNT(*) as metric1,
        SUM(valeur) as metric2
    FROM table_source
    WHERE <P1_CONDITION>  -- Ex: ville = 'Paris' AND annee = 2024
    GROUP BY colonne1, colonne2, colonne3
),
pool_2 AS (
    SELECT 
        colonne1,
        colonne2,
        colonne3,
        COUNT(*) as metric1,
        SUM(valeur) as metric2
    FROM table_source
    WHERE <P2_CONDITION>  -- Ex: ville = 'Lyon' AND annee = 2024
    GROUP BY colonne1, colonne2, colonne3
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
*/


-- ============================================================================
-- NOTES D'UTILISATION
-- ============================================================================
--
-- Performance:
-- - Ces requêtes sont intensives (3 opérations ensemblistes par requête)
-- - Sur gros volumes, privilégier les CTE pour meilleure lisibilité
-- - Index CRITIQUES sur colonnes de WHERE et JOIN
-- - Exécuter en heures creuses si possible
--
-- Interprétation des résultats:
-- - 'P1_ONLY' : Éléments à ajouter/manquants dans P2
-- - 'P2_ONLY' : Éléments à ajouter/manquants dans P1
-- - 'BOTH'/'OK' : Éléments synchronisés/cohérents
--
-- Cas d'usage:
-- - Audit de synchronisation (PROD vs DEV)
-- - Analyse de migration de données
-- - Détection de drift entre environnements
-- - Comparaison de comportements entre segments
-- - Analyse d'évolution temporelle
--
-- Optimisations possibles:
-- - Ajouter des index sur colonnes de comparaison
-- - Limiter avec LIMIT si scan exploratoire
-- - Utiliser EXPLAIN ANALYZE pour optimiser
-- - Matérialiser les pools si réutilisés souvent
-- ============================================================================
