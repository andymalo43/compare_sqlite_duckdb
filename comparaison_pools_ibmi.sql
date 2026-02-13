-- ============================================================================
-- COMPARAISON COMPLÈTE ENTRE DEUX POOLS - VERSION IBM i (DB2)
-- ============================================================================
-- Pattern: 'P1_ONLY', * FROM (P1 EXCEPT P2)
--     UNION 'P2_ONLY', * FROM (P2 EXCEPT P1)
--     UNION 'BOTH', * FROM (P1 INTERSECT P2)
--
-- Syntaxe adaptée pour IBM i / DB2 for i
-- ============================================================================


-- ============================================================================
-- EXEMPLE 1 : Comparaison clients Paris vs Lyon (Version IBM i)
-- ============================================================================

SELECT 
    'PARIS_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville,
    c.code_postal
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
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
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
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
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
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
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
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
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
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
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE c.ville = 'Lyon' AND f.statut = 'PAYEE'

ORDER BY source, client_id;


-- ============================================================================
-- EXEMPLE 2 : Comparaison produits 2024 vs 2025 (Version IBM i)
-- ============================================================================

SELECT 
    '2024_ONLY' AS source,
    lf.description AS produit,
    COUNT(DISTINCT f.facture_id) AS nb_factures,
    COUNT(lf.ligne_id) AS nb_ventes,
    ROUND(SUM(lf.montant_ttc), 2) AS ca_total
FROM FACTURATN.ligne_facture lf
INNER JOIN FACTURATN.facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY lf.description

EXCEPT

SELECT 
    '2024_ONLY' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM FACTURATN.ligne_facture lf
INNER JOIN FACTURATN.facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY lf.description

UNION ALL

SELECT 
    '2025_ONLY' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM FACTURATN.ligne_facture lf
INNER JOIN FACTURATN.facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY lf.description

EXCEPT

SELECT 
    '2025_ONLY' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM FACTURATN.ligne_facture lf
INNER JOIN FACTURATN.facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY lf.description

UNION ALL

SELECT 
    'BOTH_YEARS' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM FACTURATN.ligne_facture lf
INNER JOIN FACTURATN.facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024 AND f.statut = 'PAYEE'
GROUP BY lf.description

INTERSECT

SELECT 
    'BOTH_YEARS' AS source,
    lf.description,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ttc), 2)
FROM FACTURATN.ligne_facture lf
INNER JOIN FACTURATN.facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025 AND f.statut = 'PAYEE'
GROUP BY lf.description

ORDER BY source, ca_total DESC;


-- ============================================================================
-- EXEMPLE 3 : Comparaison Q1 vs Q4 avec CTE (Version IBM i)
-- ============================================================================

WITH pool_q1 AS (
    SELECT 
        c.client_id,
        c.nom,
        c.prenom,
        c.email,
        COUNT(f.facture_id) AS nb_factures,
        ROUND(SUM(f.montant_ttc), 2) AS ca_total
    FROM FACTURATN.client c
    INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
    WHERE f.statut = 'PAYEE'
      AND f.date_facture >= '2024-01-01'
      AND f.date_facture <= '2024-03-31'
    GROUP BY c.client_id, c.nom, c.prenom, c.email
),
pool_q4 AS (
    SELECT 
        c.client_id,
        c.nom,
        c.prenom,
        c.email,
        COUNT(f.facture_id) AS nb_factures,
        ROUND(SUM(f.montant_ttc), 2) AS ca_total
    FROM FACTURATN.client c
    INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
    WHERE f.statut = 'PAYEE'
      AND f.date_facture >= '2024-10-01'
      AND f.date_facture <= '2024-12-31'
    GROUP BY c.client_id, c.nom, c.prenom, c.email
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

-- Les deux trimestres
SELECT 'BOTH_QUARTERS' AS source, * FROM pool_q1
INTERSECT
SELECT 'BOTH_QUARTERS' AS source, * FROM pool_q4

ORDER BY source, ca_total DESC;


-- ============================================================================
-- EXEMPLE 4 : Audit PROD vs DEV (Multi-bibliothèques IBM i)
-- ============================================================================
-- Suppose deux bibliothèques: FACTPROD et FACTDEV

SELECT 
    'PROD_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM FACTPROD.client c

EXCEPT

SELECT 
    'PROD_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM FACTDEV.client c

UNION ALL

SELECT 
    'DEV_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM FACTDEV.client c

EXCEPT

SELECT 
    'DEV_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM FACTPROD.client c

UNION ALL

SELECT 
    'SYNCHRONIZED' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM FACTPROD.client c

INTERSECT

SELECT 
    'SYNCHRONIZED' AS source,
    c.client_id,
    c.nom,
    c.prenom,
    c.email,
    c.ville
FROM FACTDEV.client c

ORDER BY source, client_id;


-- ============================================================================
-- EXEMPLE 5 : Avec statistiques agrégées (Version IBM i)
-- ============================================================================

WITH comparison_data AS (
    -- Paris only
    SELECT 
        'PARIS_ONLY' AS source,
        c.client_id,
        c.nom,
        COUNT(f.facture_id) AS nb_factures,
        ROUND(SUM(f.montant_ttc), 2) AS ca_total
    FROM FACTURATN.client c
    INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Paris' 
      AND f.statut = 'PAYEE' 
      AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    EXCEPT
    
    SELECT 
        'PARIS_ONLY' AS source,
        c.client_id,
        c.nom,
        COUNT(f.facture_id),
        ROUND(SUM(f.montant_ttc), 2)
    FROM FACTURATN.client c
    INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Lyon' 
      AND f.statut = 'PAYEE' 
      AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    UNION ALL
    
    -- Lyon only
    SELECT 
        'LYON_ONLY' AS source,
        c.client_id,
        c.nom,
        COUNT(f.facture_id),
        ROUND(SUM(f.montant_ttc), 2)
    FROM FACTURATN.client c
    INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Lyon' 
      AND f.statut = 'PAYEE' 
      AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    EXCEPT
    
    SELECT 
        'LYON_ONLY' AS source,
        c.client_id,
        c.nom,
        COUNT(f.facture_id),
        ROUND(SUM(f.montant_ttc), 2)
    FROM FACTURATN.client c
    INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Paris' 
      AND f.statut = 'PAYEE' 
      AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    UNION ALL
    
    -- Both cities
    SELECT 
        'BOTH' AS source,
        c.client_id,
        c.nom,
        COUNT(f.facture_id),
        ROUND(SUM(f.montant_ttc), 2)
    FROM FACTURATN.client c
    INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Paris' 
      AND f.statut = 'PAYEE' 
      AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
    
    INTERSECT
    
    SELECT 
        'BOTH' AS source,
        c.client_id,
        c.nom,
        COUNT(f.factures_id),
        ROUND(SUM(f.montant_ttc), 2)
    FROM FACTURATN.client c
    INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
    WHERE c.ville = 'Lyon' 
      AND f.statut = 'PAYEE' 
      AND YEAR(f.date_facture) = 2024
    GROUP BY c.client_id, c.nom
)
-- Statistiques par catégorie
SELECT 
    source,
    COUNT(*) AS nb_clients,
    SUM(nb_factures) AS total_factures,
    ROUND(SUM(ca_total), 2) AS total_ca,
    ROUND(AVG(ca_total), 2) AS ca_moyen,
    ROUND(MIN(ca_total), 2) AS ca_min,
    ROUND(MAX(ca_total), 2) AS ca_max
FROM comparison_data
GROUP BY source
ORDER BY source;


-- ============================================================================
-- EXEMPLE 6 : Version optimisée avec index hints (IBM i)
-- ============================================================================
-- Utilise les index existants pour améliorer les performances

SELECT 
    'PARIS_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE c.ville = 'Paris' 
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024
  -- Index hints pour optimisation
  -- WITH NC (No Cache) si needed

EXCEPT

SELECT 
    'PARIS_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE c.ville = 'Lyon'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

UNION ALL

SELECT 
    'LYON_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE c.ville = 'Lyon'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

EXCEPT

SELECT 
    'LYON_ONLY' AS source,
    c.client_id,
    c.nom,
    c.prenom
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE c.ville = 'Paris'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

UNION ALL

SELECT 
    'BOTH' AS source,
    c.client_id,
    c.nom,
    c.prenom
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE c.ville = 'Paris'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

INTERSECT

SELECT 
    'BOTH' AS source,
    c.client_id,
    c.nom,
    c.prenom
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE c.ville = 'Lyon'
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024

ORDER BY source, client_id;


-- ============================================================================
-- TEMPLATE GÉNÉRIQUE POUR IBM i
-- ============================================================================

/*
WITH pool_1 AS (
    SELECT 
        colonne1,
        colonne2,
        COUNT(*) as metric1,
        SUM(valeur) as metric2
    FROM FACTURATN.table_source
    WHERE <CONDITION_P1>
    GROUP BY colonne1, colonne2
),
pool_2 AS (
    SELECT 
        colonne1,
        colonne2,
        COUNT(*) as metric1,
        SUM(valeur) as metric2
    FROM FACTURATN.table_source
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
*/


-- ============================================================================
-- NOTES SPÉCIFIQUES IBM i
-- ============================================================================
--
-- Performance tips:
-- 1. Créer index sur colonnes de filtrage (ville, date_facture, statut)
-- 2. Mettre à jour statistiques: ANALYZE TABLE ou RGZPFM
-- 3. Vérifier plan d'exécution: Visual Explain dans ACS
-- 4. Tester isolation level si problèmes de locks
--
-- Optimisations DB2:
-- 1. Utiliser FETCH FIRST n ROWS pour tests
-- 2. Partitionner si volumes très importants (>1M lignes)
-- 3. Considérer les vues matérialisées pour pools réutilisés
-- 4. Monitorer avec QSYS2.ACTIVE_JOB_INFO
--
-- Différences vs SQLite/DuckDB:
-- 1. YEAR() au lieu de EXTRACT(YEAR FROM ...)
-- 2. Préfixe schéma obligatoire: FACTURATN.table
-- 3. ROUND() fonctionne directement
-- 4. Pas de support natif pour LIMIT (utiliser FETCH FIRST)
--
-- Monitoring:
-- SELECT * FROM TABLE(QSYS2.ACTIVE_JOB_INFO()) 
-- WHERE JOB_NAME LIKE '%QZDASOINIT%';
-- ============================================================================
