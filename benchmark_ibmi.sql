-- ============================================================================
-- BENCHMARK OPÉRATIONS ENSEMBLISTES - VERSION IBM i (DB2)
-- ============================================================================
-- Syntaxe adaptée pour IBM i / DB2 for i
-- Différences principales avec SQLite/DuckDB:
-- - EXTRACT(YEAR FROM x) devient YEAR(x)
-- - EXTRACT(MONTH FROM x) devient MONTH(x)
-- - Schéma: FACTURATN.table_name
-- ============================================================================

-- Instructions d'exécution:
-- ACS Run SQL Scripts: Options → Show Elapsed Time
-- Exécuter requête par requête (sélectionner + F5)
-- Noter les temps dans la barre de statut

-- ============================================================================
-- SÉRIE 1 : POOL COMPLET - IBM i
-- ============================================================================

-- QUERY 1: EXCEPT - Factures Paris vs autres villes
SELECT 
    f.facture_id, 
    f.client_id, 
    f.montant_ttc, 
    f.statut,
    f.date_facture
FROM FACTURATN.facture f
INNER JOIN FACTURATN.client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris'
EXCEPT
SELECT 
    f.facture_id, 
    f.client_id, 
    f.montant_ttc, 
    f.statut,
    f.date_facture
FROM FACTURATN.facture f
INNER JOIN FACTURATN.client c ON f.client_id = c.client_id
WHERE c.ville != 'Paris';

-- QUERY 2: UNION ALL - Factures 2024 et 2025
SELECT 
    facture_id, 
    client_id, 
    date_facture, 
    montant_ttc, 
    statut,
    'Année 2024' AS source
FROM FACTURATN.facture
WHERE YEAR(date_facture) = 2024
UNION ALL
SELECT 
    facture_id, 
    client_id, 
    date_facture, 
    montant_ttc, 
    statut,
    'Année 2025' AS source
FROM FACTURATN.facture
WHERE YEAR(date_facture) = 2025;

-- QUERY 3: INTERSECT - Clients avec PAYEE ET EMISE
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom, 
    c.ville
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
INTERSECT
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom, 
    c.ville
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE f.statut = 'EMISE';

-- QUERY 4: EXCEPT - Produits 2024 mais pas 2025
SELECT DISTINCT lf.description
FROM FACTURATN.ligne_facture lf
INNER JOIN FACTURATN.facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2024
EXCEPT
SELECT DISTINCT lf.description
FROM FACTURATN.ligne_facture lf
INNER JOIN FACTURATN.facture f ON lf.facture_id = f.facture_id
WHERE YEAR(f.date_facture) = 2025;

-- QUERY 5: UNION ALL - Top clients 2024 et 2025
SELECT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.ville,
    SUM(f.montant_ttc) AS ca_total,
    2024 AS annee
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
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
    2025 AS annee
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE YEAR(f.date_facture) = 2025 
  AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom, c.ville
HAVING SUM(f.montant_ttc) > 50000;

-- ============================================================================
-- SÉRIE 2 : AVEC WHERE LIMITANT - IBM i
-- ============================================================================

-- QUERY 1: EXCEPT - Factures >10K Paris vs Lyon
SELECT 
    f.facture_id, 
    f.numero_facture,
    f.client_id, 
    f.montant_ttc
FROM FACTURATN.facture f
INNER JOIN FACTURATN.client c ON f.client_id = c.client_id
WHERE c.ville = 'Paris' 
  AND f.montant_ttc > 10000
  AND YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE'
EXCEPT
SELECT 
    f.facture_id, 
    f.numero_facture,
    f.client_id, 
    f.montant_ttc
FROM FACTURATN.facture f
INNER JOIN FACTURATN.client c ON f.client_id = c.client_id
WHERE c.ville = 'Lyon'
  AND f.montant_ttc > 10000
  AND YEAR(f.date_facture) = 2024
  AND f.statut = 'PAYEE';

-- QUERY 2: UNION ALL - Q4 2024
SELECT 
    facture_id, 
    numero_facture,
    client_id, 
    montant_ttc, 
    statut, 
    date_facture
FROM FACTURATN.facture
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
    date_facture
FROM FACTURATN.facture
WHERE statut = 'EMISE'
  AND date_facture >= '2024-10-01'
  AND date_facture <= '2024-12-31';

-- QUERY 3: INTERSECT - Clients VIP avec produits premium
SELECT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.ville
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND YEAR(f.date_facture) IN (2024, 2025)
  AND c.ville IN ('Paris', 'Lyon', 'Marseille')
GROUP BY c.client_id, c.nom, c.prenom, c.email, c.ville
HAVING SUM(f.montant_ttc) > 100000
INTERSECT
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email,
    c.ville
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
INNER JOIN FACTURATN.ligne_facture lf ON f.facture_id = lf.facture_id
WHERE lf.description IN ('Ordinateur portable', 'Licence logicielle', 'Service support', 'Hébergement cloud')
  AND YEAR(f.date_facture) IN (2024, 2025)
  AND f.statut = 'PAYEE'
  AND c.ville IN ('Paris', 'Lyon', 'Marseille');

-- QUERY 4: EXCEPT - Factures orphelines
SELECT 
    f.facture_id, 
    f.numero_facture, 
    f.montant_ttc,
    f.date_facture,
    f.statut
FROM FACTURATN.facture f
WHERE f.statut != 'ANNULEE'
  AND YEAR(f.date_facture) = 2024
  AND MONTH(f.date_facture) BETWEEN 1 AND 6
EXCEPT
SELECT DISTINCT 
    f.facture_id, 
    f.numero_facture, 
    f.montant_ttc,
    f.date_facture,
    f.statut
FROM FACTURATN.facture f
INNER JOIN FACTURATN.ligne_facture lf ON f.facture_id = lf.facture_id
WHERE f.statut != 'ANNULEE'
  AND YEAR(f.date_facture) = 2024
  AND MONTH(f.date_facture) BETWEEN 1 AND 6;

-- QUERY 5: UNION ALL - Analyse TVA par taux
SELECT 
    lf.taux_tva,
    COUNT(DISTINCT f.facture_id) as nb_factures,
    COUNT(lf.ligne_id) as nb_lignes,
    ROUND(SUM(lf.montant_ht), 2) as total_ht,
    ROUND(SUM(lf.montant_tva), 2) as total_tva
FROM FACTURATN.ligne_facture lf
INNER JOIN FACTURATN.facture f ON lf.facture_id = f.facture_id
WHERE lf.taux_tva = 20.0
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024
GROUP BY lf.taux_tva
UNION ALL
SELECT 
    lf.taux_tva,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ht), 2),
    ROUND(SUM(lf.montant_tva), 2)
FROM FACTURATN.ligne_facture lf
INNER JOIN FACTURATN.facture f ON lf.facture_id = f.facture_id
WHERE lf.taux_tva = 10.0
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024
GROUP BY lf.taux_tva
UNION ALL
SELECT 
    lf.taux_tva,
    COUNT(DISTINCT f.facture_id),
    COUNT(lf.ligne_id),
    ROUND(SUM(lf.montant_ht), 2),
    ROUND(SUM(lf.montant_tva), 2)
FROM FACTURATN.ligne_facture lf
INNER JOIN FACTURATN.facture f ON lf.facture_id = f.facture_id
WHERE lf.taux_tva = 5.5
  AND f.statut = 'PAYEE'
  AND YEAR(f.date_facture) = 2024
GROUP BY lf.taux_tva;

-- QUERY 6: INTERSECT - Clients récurrents Q1 et Q4
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-01-01'
  AND f.date_facture <= '2024-03-31'
  AND f.montant_ttc > 1000
INTERSECT
SELECT DISTINCT 
    c.client_id, 
    c.nom, 
    c.prenom,
    c.email
FROM FACTURATN.client c
INNER JOIN FACTURATN.facture f ON c.client_id = f.client_id
WHERE f.statut = 'PAYEE'
  AND f.date_facture >= '2024-10-01'
  AND f.date_facture <= '2024-12-31'
  AND f.montant_ttc > 1000;

-- ============================================================================
-- NOTES SPÉCIFIQUES IBM i
-- ============================================================================
-- 
-- 1. Préfixe schéma : Toujours utiliser FACTURATN.table_name
-- 2. Fonctions date : YEAR(), MONTH() au lieu de EXTRACT()
-- 3. ROUND() : Disponible nativement
-- 4. Performance : Vérifier présence des index avec:
--    SELECT * FROM QSYS2.SYSINDEXES WHERE TABLE_SCHEMA = 'FACTURATN'
-- 5. Statistiques : Mettre à jour avec RGZPFM ou ANALYZE
-- 6. Isolation : Par défaut *CHG (commit), peut affecter les perfs
-- 7. Journal : Si actif, peut ralentir les opérations massives
-- 
-- Index recommandés pour IBM i:
-- CREATE INDEX FACTURATN.IDX_FACT_DATE ON FACTURATN.FACTURE(DATE_FACTURE)
-- CREATE INDEX FACTURATN.IDX_FACT_STAT ON FACTURATN.FACTURE(STATUT)
-- CREATE INDEX FACTURATN.IDX_FACT_CLI ON FACTURATN.FACTURE(CLIENT_ID)
-- CREATE INDEX FACTURATN.IDX_CLI_VILLE ON FACTURATN.CLIENT(VILLE)
-- CREATE INDEX FACTURATN.IDX_LIG_FACT ON FACTURATN.LIGNE_FACTURE(FACTURE_ID)
-- ============================================================================
