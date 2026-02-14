#!/bin/bash
# ============================================================================
# Script Bash : Génération des données de test
# ============================================================================
# Génère 100K clients, 3M factures, ~10M lignes de facture
# Utilise SQLite natif (pas de Python requis)
# Compatible WSL/Linux/macOS
# ============================================================================

set -e

OUTPUT_PATH="${1:-./data}"

echo "============================================================================"
echo "GÉNÉRATION DES DONNÉES DE TEST - SQLITE + DUCKDB"
echo "============================================================================"
echo ""

# Vérifier sqlite3
if ! command -v sqlite3 &> /dev/null; then
    echo "❌ SQLite non trouvé. Installez-le:"
    echo "   Ubuntu/Debian: sudo apt install sqlite3"
    echo "   macOS: brew install sqlite3"
    exit 1
fi

SQLITE_VERSION=$(sqlite3 -version | awk '{print $1}')
echo "✓ SQLite détecté : $SQLITE_VERSION"

# Vérifier duckdb
if ! command -v duckdb &> /dev/null; then
    echo "❌ DuckDB non trouvé. Installez-le depuis https://duckdb.org/"
    exit 1
fi

echo "✓ DuckDB détecté"

# Créer le dossier data
mkdir -p "$OUTPUT_PATH"

SQLITE_DB="$OUTPUT_PATH/facturation.db"
DUCKDB_DB="$OUTPUT_PATH/facturation.duckdb"

echo ""
echo "📁 Création des bases de données..."
echo "  - SQLite  : $SQLITE_DB"
echo "  - DuckDB  : $DUCKDB_DB"
echo ""

# ============================================================================
# Créer le script SQL de génération
# ============================================================================

SETUP_SQL="$OUTPUT_PATH/setup_database.sql"

cat > "$SETUP_SQL" << 'EOSQL'
-- ============================================================================
-- Script de génération de données de test - HAUTE VOLUMÉTRIE
-- ============================================================================
-- 100K clients, 3M factures, ~10M lignes de facture
-- Utilise génération déterministe sans RANDOM() pour performance
-- ============================================================================

-- Nettoyage
DROP TABLE IF EXISTS ligne_facture;
DROP TABLE IF EXISTS facture;
DROP TABLE IF EXISTS client;

-- ============================================================================
-- SCHÉMA
-- ============================================================================

CREATE TABLE client (
    client_id INTEGER PRIMARY KEY,
    nom TEXT NOT NULL,
    prenom TEXT NOT NULL,
    email TEXT,
    telephone TEXT,
    adresse TEXT,
    ville TEXT,
    code_postal TEXT,
    pays TEXT,
    date_creation DATE NOT NULL
);

CREATE TABLE facture (
    facture_id INTEGER PRIMARY KEY,
    client_id INTEGER NOT NULL,
    numero_facture TEXT UNIQUE NOT NULL,
    date_facture DATE NOT NULL,
    date_echeance DATE NOT NULL,
    montant_ht REAL NOT NULL,
    montant_tva REAL NOT NULL,
    montant_ttc REAL NOT NULL,
    statut TEXT NOT NULL CHECK (statut IN ('BROUILLON', 'EMISE', 'PAYEE', 'ANNULEE')),
    FOREIGN KEY (client_id) REFERENCES client(client_id)
);

CREATE TABLE ligne_facture (
    ligne_id INTEGER PRIMARY KEY,
    facture_id INTEGER NOT NULL,
    numero_ligne INTEGER NOT NULL,
    description TEXT NOT NULL,
    quantite REAL NOT NULL,
    prix_unitaire REAL NOT NULL,
    taux_tva REAL NOT NULL,
    montant_ht REAL NOT NULL,
    montant_tva REAL NOT NULL,
    montant_ttc REAL NOT NULL,
    FOREIGN KEY (facture_id) REFERENCES facture(facture_id),
    UNIQUE (facture_id, numero_ligne)
);

-- ============================================================================
-- DONNÉES - CLIENTS (100 000)
-- ============================================================================
-- Génération par batch pour performance

WITH RECURSIVE
  noms(nom) AS (
    VALUES ('Martin'),('Bernard'),('Dubois'),('Thomas'),('Robert'),
           ('Richard'),('Petit'),('Durand'),('Leroy'),('Moreau'),
           ('Simon'),('Laurent'),('Lefebvre'),('Michel'),('Garcia'),
           ('David'),('Bertrand'),('Roux'),('Vincent'),('Fournier')
  ),
  prenoms(prenom) AS (
    VALUES ('Jean'),('Pierre'),('Marie'),('Sophie'),('Luc'),
           ('Anne'),('Paul'),('Julie'),('Marc'),('Céline'),
           ('François'),('Isabelle'),('Jacques'),('Nathalie'),
           ('Philippe'),('Sylvie'),('Antoine'),('Catherine'),
           ('Nicolas'),('Valérie')
  ),
  villes(ville, code_base) AS (
    VALUES ('Paris','75'),('Lyon','69'),('Marseille','13'),
           ('Toulouse','31'),('Nice','06'),('Nantes','44'),
           ('Bordeaux','33'),('Lille','59'),('Rennes','35'),
           ('Strasbourg','67'),('Montpellier','34'),('Grenoble','38'),
           ('Dijon','21'),('Angers','49'),('Nîmes','30'),
           ('Villeurbanne','69'),('Le Mans','72'),('Aix-en-Provence','13')
  ),
  -- Génération de 100 000 IDs (10x10x10x10x10)
  numbers(n) AS (
    VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)
  ),
  client_ids(id) AS (
    SELECT n1.n + n2.n*10 + n3.n*100 + n4.n*1000 + n5.n*10000 + 1
    FROM numbers n1, numbers n2, numbers n3, numbers n4, numbers n5
    WHERE n1.n + n2.n*10 + n3.n*100 + n4.n*1000 + n5.n*10000 + 1 <= 100000
  )
INSERT INTO client
SELECT
  c.id,
  (SELECT nom FROM (SELECT nom, ROW_NUMBER() OVER () as rn FROM noms) WHERE rn = (c.id % 20) + 1),
  (SELECT prenom FROM (SELECT prenom, ROW_NUMBER() OVER () as rn FROM prenoms) WHERE rn = ((c.id * 7) % 20) + 1),
  lower((SELECT prenom FROM (SELECT prenom, ROW_NUMBER() OVER () as rn FROM prenoms) WHERE rn = ((c.id * 7) % 20) + 1)) || '.' ||
    lower((SELECT nom FROM (SELECT nom, ROW_NUMBER() OVER () as rn FROM noms) WHERE rn = (c.id % 20) + 1)) || '.' || c.id || '@example.com',
  '0' || ((c.id * 7) % 7 + 1) || substr(printf('%08d', (c.id * 12345) % 100000000), 1, 8),
  ((c.id * 123) % 999 + 1) || ' rue de la Paix',
  (SELECT ville FROM (SELECT ville, ROW_NUMBER() OVER () as rn FROM villes) WHERE rn = ((c.id * 11) % 18) + 1),
  printf('%05d', (c.id * 456) % 95000 + 1000),
  'France',
  date('2020-01-01', '+' || ((c.id * 13) % 2190) || ' days')
FROM client_ids c;

-- ============================================================================
-- DONNÉES - FACTURES (3 000 000)
-- ============================================================================
-- Génération déterministe basée sur facture_id (pas de RANDOM)
-- Batch processing pour optimiser la performance

WITH RECURSIVE
  numbers(n) AS (
    VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)
  ),
  facture_ids(id) AS (
    SELECT n1.n + n2.n*10 + n3.n*100 + n4.n*1000 + n5.n*10000 + n6.n*100000 + n7.n*1000000 + 1
    FROM numbers n1, numbers n2, numbers n3, numbers n4, numbers n5, numbers n6, numbers n7
    WHERE n1.n + n2.n*10 + n3.n*100 + n4.n*1000 + n5.n*10000 + n6.n*100000 + n7.n*1000000 + 1 <= 3000000
  )
INSERT INTO facture (facture_id, client_id, numero_facture, date_facture, date_echeance,
                      montant_ht, montant_tva, montant_ttc, statut)
SELECT
  id,
  -- Client ID déterministe (1-100000)
  ((id * 97) % 100000) + 1,
  -- Numéro de facture avec année déterministe
  'FAC-' || strftime('%Y', date('2020-01-01', '+' || ((id * 73) % 2190) || ' days')) || '-' || printf('%07d', id),
  -- Date facture déterministe (2020-2025)
  date('2020-01-01', '+' || ((id * 73) % 2190) || ' days'),
  -- Date échéance (15-60 jours après facture)
  date(date('2020-01-01', '+' || ((id * 73) % 2190) || ' days'), '+' || (((id * 37) % 4 + 1) * 15) || ' days'),
  -- Montants initialisés à 0 (calculés après insertion lignes)
  0, 0, 0,
  -- Statut déterministe: ~1% BROUILLON, ~5% ANNULEE, ~25% EMISE, ~69% PAYEE
  CASE ((id * 89) % 100)
    WHEN 0 THEN 'BROUILLON'
    ELSE CASE
      WHEN ((id * 89) % 100) <= 5 THEN 'ANNULEE'
      WHEN ((id * 89) % 100) <= 30 THEN 'EMISE'
      ELSE 'PAYEE'
    END
  END
FROM facture_ids;

-- ============================================================================
-- DONNÉES - LIGNES FACTURE (~10 000 000)
-- ============================================================================
-- Chaque facture a entre 1 et 15 lignes (moyenne ~3.3 lignes)
-- Total estimé: 3M * 3.3 = ~10M lignes

WITH RECURSIVE
  produits(description) AS (
    VALUES
      ('Ordinateur portable'),('Souris sans fil'),('Clavier mécanique'),
      ('Écran 27"'),('Webcam HD'),('Casque audio'),('Imprimante laser'),
      ('Disque dur SSD'),('Câble HDMI'),('Hub USB'),('Tapis de souris'),
      ('Lampe LED bureau'),('Chaise ergonomique'),('Bureau ajustable'),
      ('Station d''accueil'),('Tablette graphique'),('Licence logicielle'),
      ('Service support'),('Formation utilisateur'),('Maintenance matériel'),
      ('Hébergement cloud'),('Sauvegarde cloud'),('Antivirus entreprise'),
      ('Suite bureautique'),('Logiciel comptabilité')
  ),
  -- Génération déterministe du nombre de lignes par facture (1-15)
  factures_expanded AS (
    SELECT
      facture_id,
      ((facture_id * 53) % 15) + 1 as nb_lignes
    FROM facture
  ),
  -- Expansion des lignes
  numbers_15(n) AS (
    VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)
  ),
  lines_per_facture AS (
    SELECT
      f.facture_id,
      n.n as numero_ligne
    FROM factures_expanded f
    INNER JOIN numbers_15 n ON n.n <= f.nb_lignes
  ),
  ligne_ids AS (
    SELECT
      ROW_NUMBER() OVER () as ligne_id,
      facture_id,
      numero_ligne
    FROM lines_per_facture
  )
INSERT INTO ligne_facture
SELECT
  l.ligne_id,
  l.facture_id,
  l.numero_ligne,
  -- Produit déterministe (25 produits)
  (SELECT description FROM (SELECT description, ROW_NUMBER() OVER () as rn FROM produits) WHERE rn = ((l.ligne_id * 7) % 25) + 1),
  -- Quantité déterministe (1-50)
  ((l.ligne_id * 11) % 50) + 1,
  -- Prix unitaire déterministe (10-5000 €)
  ROUND(((l.ligne_id * 131) % 4990 + 10) * 1.0, 2),
  -- Taux TVA déterministe: ~10% à 5.5%, ~20% à 10%, ~70% à 20%
  CASE
    WHEN ((l.ligne_id * 17) % 100) < 10 THEN 5.5
    WHEN ((l.ligne_id * 17) % 100) < 30 THEN 10.0
    ELSE 20.0
  END,
  -- Montant HT = quantité * prix_unitaire
  ROUND(
    (((l.ligne_id * 11) % 50) + 1) *
    ROUND(((l.ligne_id * 131) % 4990 + 10) * 1.0, 2),
  2),
  -- Montant TVA = montant_ht * taux_tva / 100
  ROUND(
    (((l.ligne_id * 11) % 50) + 1) *
    ROUND(((l.ligne_id * 131) % 4990 + 10) * 1.0, 2) *
    (CASE WHEN ((l.ligne_id * 17) % 100) < 10 THEN 5.5 WHEN ((l.ligne_id * 17) % 100) < 30 THEN 10.0 ELSE 20.0 END / 100),
  2),
  -- Montant TTC = montant_ht + montant_tva
  ROUND(
    (((l.ligne_id * 11) % 50) + 1) *
    ROUND(((l.ligne_id * 131) % 4990 + 10) * 1.0, 2) *
    (1 + (CASE WHEN ((l.ligne_id * 17) % 100) < 10 THEN 5.5 WHEN ((l.ligne_id * 17) % 100) < 30 THEN 10.0 ELSE 20.0 END / 100)),
  2)
FROM ligne_ids l;

-- ============================================================================
-- MISE À JOUR MONTANTS FACTURES
-- ============================================================================
-- Calcul des totaux par facture à partir des lignes

UPDATE facture
SET
  montant_ht = (SELECT COALESCE(SUM(montant_ht), 0) FROM ligne_facture WHERE facture_id = facture.facture_id),
  montant_tva = (SELECT COALESCE(SUM(montant_tva), 0) FROM ligne_facture WHERE facture_id = facture.facture_id),
  montant_ttc = (SELECT COALESCE(SUM(montant_ttc), 0) FROM ligne_facture WHERE facture_id = facture.facture_id);

-- ============================================================================
-- CRÉATION DES INDEX (après insertion pour performance)
-- ============================================================================

CREATE INDEX idx_facture_client ON facture(client_id);
CREATE INDEX idx_facture_date ON facture(date_facture);
CREATE INDEX idx_facture_statut ON facture(statut);
CREATE INDEX idx_ligne_facture ON ligne_facture(facture_id);
CREATE INDEX idx_client_ville ON client(ville);

-- ============================================================================
-- STATISTIQUES
-- ============================================================================

SELECT 'Clients:' as "Table", COUNT(*) as Nombre FROM client
UNION ALL
SELECT 'Factures:', COUNT(*) FROM facture
UNION ALL
SELECT 'Lignes facture:', COUNT(*) FROM ligne_facture;
EOSQL

echo "📝 Script SQL généré : $SETUP_SQL"
echo ""

# ============================================================================
# Exécuter sur SQLite
# ============================================================================

echo "💾 Création de la base SQLite..."

# Supprimer si existe
rm -f "$SQLITE_DB"

# Exécuter le script avec mesure du temps
START_TIME=$(date +%s)
sqlite3 "$SQLITE_DB" < "$SETUP_SQL"
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo "  ✅ SQLite créée en ${ELAPSED}s"
echo ""

# ============================================================================
# Copier vers DuckDB
# ============================================================================

echo "🦆 Création de la base DuckDB..."

# Supprimer si existe
rm -f "$DUCKDB_DB"

# Script pour DuckDB (copie depuis SQLite)
cat > "$OUTPUT_PATH/duckdb_copy.sql" << EOSQL
INSTALL sqlite;
LOAD sqlite;

-- Copier depuis SQLite
ATTACH '$SQLITE_DB' AS sqlite_db (TYPE sqlite);

CREATE TABLE client AS SELECT * FROM sqlite_db.client;
CREATE TABLE facture AS SELECT * FROM sqlite_db.facture;
CREATE TABLE ligne_facture AS SELECT * FROM sqlite_db.ligne_facture;

-- Créer les index
CREATE INDEX idx_facture_client ON facture(client_id);
CREATE INDEX idx_facture_date ON facture(date_facture);
CREATE INDEX idx_facture_statut ON facture(statut);
CREATE INDEX idx_ligne_facture ON ligne_facture(facture_id);
CREATE INDEX idx_client_ville ON client(ville);

-- Statistiques
SELECT 'Clients:' as "Table", COUNT(*) as Nombre FROM client
UNION ALL
SELECT 'Factures:', COUNT(*) FROM facture
UNION ALL
SELECT 'Lignes facture:', COUNT(*) FROM ligne_facture;
EOSQL

duckdb "$DUCKDB_DB" < "$OUTPUT_PATH/duckdb_copy.sql"

echo "  ✅ DuckDB créée"
echo ""

# ============================================================================
# Vérification
# ============================================================================

echo "✔️  VÉRIFICATION"
echo ""

# SQLite
echo "SELECT 'SQLite - Clients: ' || COUNT(*) FROM client; 
      SELECT 'SQLite - Factures: ' || COUNT(*) FROM facture;
      SELECT 'SQLite - Lignes: ' || COUNT(*) FROM ligne_facture;" | sqlite3 "$SQLITE_DB"

# DuckDB  
echo "SELECT 'DuckDB - Clients: ' || COUNT(*) FROM client; 
      SELECT 'DuckDB - Factures: ' || COUNT(*) FROM facture;
      SELECT 'DuckDB - Lignes: ' || COUNT(*) FROM ligne_facture;" | duckdb "$DUCKDB_DB"

echo ""
echo "============================================================================"
echo "✨ GÉNÉRATION TERMINÉE AVEC SUCCÈS !"
echo "============================================================================"
echo ""
echo "📁 Fichiers créés :"
echo "  - $SQLITE_DB"
echo "  - $DUCKDB_DB"
echo "  - $SETUP_SQL"
echo ""
echo "⏭️  Prochaine étape : Consultez 01-concept-ensembliste.md"
