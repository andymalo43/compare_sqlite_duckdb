# ============================================================================
# Script PowerShell : Génération des données de test
# ============================================================================
# Génère 100K clients, 3M factures, ~10M lignes de facture
# Utilise SQLite natif (pas de Python requis)
# ============================================================================

param(
    [string]$OutputPath = ".\data"
)

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "GÉNÉRATION DES DONNÉES DE TEST - SQLITE + DUCKDB" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier sqlite3
try {
    $sqliteVersion = sqlite3 -version
    Write-Host "✓ SQLite détecté : $sqliteVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ SQLite non trouvé. Installez-le depuis https://sqlite.org/download.html" -ForegroundColor Red
    exit 1
}

# Vérifier duckdb
try {
    $duckdbCheck = duckdb -version
    Write-Host "✓ DuckDB détecté" -ForegroundColor Green
} catch {
    Write-Host "❌ DuckDB non trouvé. Installez-le depuis https://duckdb.org/" -ForegroundColor Red
    exit 1
}

# Créer le dossier data
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

$sqliteDb = Join-Path $OutputPath "facturation.db"
$duckdbDb = Join-Path $OutputPath "facturation.duckdb"

Write-Host ""
Write-Host "📁 Création des bases de données..." -ForegroundColor Yellow
Write-Host "  - SQLite  : $sqliteDb"
Write-Host "  - DuckDB  : $duckdbDb"
Write-Host ""

# ============================================================================
# Créer le script SQL de génération
# ============================================================================

$setupSQL = @"
-- ============================================================================
-- Script de génération de données de test
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

-- Index pour performance
CREATE INDEX idx_facture_client ON facture(client_id);
CREATE INDEX idx_facture_date ON facture(date_facture);
CREATE INDEX idx_facture_statut ON facture(statut);
CREATE INDEX idx_ligne_facture ON ligne_facture(facture_id);
CREATE INDEX idx_client_ville ON client(ville);

-- ============================================================================
-- DONNÉES - CLIENTS (5000)
-- ============================================================================
-- Génération avec séquences et données prédéfinies
"@

# Ajouter la génération SQL des clients
$setupSQL += "`n-- Insertion clients...`n"

# On génère du SQL pur pour insérer les données
# Version simplifiée avec moins de variété mais pure SQL

$setupSQL += @"

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
  numbers(n) AS (
    VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)
  ),
  client_ids(id) AS (
    SELECT n1.n + (n2.n-1)*10 + (n3.n-1)*100 + (n4.n-1)*1000
    FROM numbers n1, numbers n2, numbers n3, numbers n4
    WHERE n1.n + (n2.n-1)*10 + (n3.n-1)*100 + (n4.n-1)*1000 <= 5000
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
  date('2020-01-01', '+' || ((c.id * 13) % 1800) || ' days')
FROM client_ids c;

-- ============================================================================
-- DONNÉES - FACTURES (150000)
-- ============================================================================

WITH RECURSIVE
  statuts(statut, poids) AS (
    VALUES ('BROUILLON', 5),('EMISE', 25),('PAYEE', 65),('ANNULEE', 5)
  ),
  numbers(n) AS (
    VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)
  ),
  facture_ids(id) AS (
    SELECT n1.n + (n2.n-1)*10 + (n3.n-1)*100 + (n4.n-1)*1000 + (n5.n-1)*10000 + (n6.n-1)*100000
    FROM numbers n1, numbers n2, numbers n3, numbers n4, numbers n5, numbers n6
    WHERE n1.n + (n2.n-1)*10 + (n3.n-1)*100 + (n4.n-1)*1000 + (n5.n-1)*10000 + (n6.n-1)*100000 <= 150000
  )
INSERT INTO facture (facture_id, client_id, numero_facture, date_facture, date_echeance,
                      montant_ht, montant_tva, montant_ttc, statut)
SELECT
  id,
  ((id * 123) % 5000 + 1),
  'FAC-' || strftime('%Y', date('2020-01-01', '+' || ((id * 17) % 2190) || ' days')) ||
    '-' || printf('%06d', id),
  date('2020-01-01', '+' || ((id * 17) % 2190) || ' days'),
  date(date('2020-01-01', '+' || ((id * 17) % 2190) || ' days'), '+' || (((id * 19) % 4 + 1) * 15) || ' days'),
  0, 0, 0,
  CASE ((id * 37) % 100)
    WHEN  0 THEN 'BROUILLON'
    WHEN 95 THEN 'ANNULEE'
    ELSE CASE
      WHEN ((id * 41) % 100) <= 24 THEN 'EMISE'
      ELSE 'PAYEE'
    END
  END
FROM facture_ids;

-- ============================================================================
-- DONNÉES - LIGNES FACTURE (~500000)
-- ============================================================================

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
  taux(tva, freq) AS (
    VALUES (5.5, 10), (10.0, 20), (20.0, 70)
  ),
  factures_expanded AS (
    SELECT
      facture_id,
      ((facture_id * 23) % 15 + 1) as nb_lignes
    FROM facture
  ),
  lines_per_facture AS (
    SELECT 
      f.facture_id,
      n.n as numero_ligne
    FROM factures_expanded f
    CROSS JOIN (
      SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
      UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
      UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
    ) n
    WHERE n.n <= f.nb_lignes
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
  (SELECT description FROM (SELECT description, ROW_NUMBER() OVER () as rn FROM produits) WHERE rn = ((l.ligne_id * 7) % 25) + 1),
  ((l.ligne_id * 11) % 50 + 1),
  ROUND(((l.ligne_id * 131) % 4990 + 10) * 1.0, 2),
  CASE
    WHEN ((l.ligne_id * 17) % 100) <= 9 THEN 5.5
    WHEN ((l.ligne_id * 17) % 100) <= 29 THEN 10.0
    ELSE 20.0
  END,
  ROUND(((l.ligne_id * 11) % 50 + 1) * ROUND(((l.ligne_id * 131) % 4990 + 10) * 1.0, 2), 2),
  ROUND(((l.ligne_id * 11) % 50 + 1) * ROUND(((l.ligne_id * 131) % 4990 + 10) * 1.0, 2) *
    CASE WHEN ((l.ligne_id * 17) % 100) <= 9 THEN 5.5 WHEN ((l.ligne_id * 17) % 100) <= 29 THEN 10.0 ELSE 20.0 END / 100, 2),
  ROUND(((l.ligne_id * 11) % 50 + 1) * ROUND(((l.ligne_id * 131) % 4990 + 10) * 1.0, 2) *
    (1 + CASE WHEN ((l.ligne_id * 17) % 100) <= 9 THEN 5.5 WHEN ((l.ligne_id * 17) % 100) <= 29 THEN 10.0 ELSE 20.0 END / 100), 2)
FROM ligne_ids l;

-- ============================================================================
-- MISE À JOUR MONTANTS FACTURES
-- ============================================================================

UPDATE facture
SET 
  montant_ht = (SELECT COALESCE(SUM(montant_ht), 0) FROM ligne_facture WHERE facture_id = facture.facture_id),
  montant_tva = (SELECT COALESCE(SUM(montant_tva), 0) FROM ligne_facture WHERE facture_id = facture.facture_id),
  montant_ttc = (SELECT COALESCE(SUM(montant_ttc), 0) FROM ligne_facture WHERE facture_id = facture.facture_id);

-- ============================================================================
-- STATISTIQUES
-- ============================================================================

SELECT 'Clients:' as Table, COUNT(*) as Nombre FROM client
UNION ALL
SELECT 'Factures:', COUNT(*) FROM facture
UNION ALL
SELECT 'Lignes facture:', COUNT(*) FROM ligne_facture;

"@

# Sauvegarder le script SQL
$setupSQLPath = Join-Path $OutputPath "setup_database.sql"
$setupSQL | Out-File -FilePath $setupSQLPath -Encoding UTF8

Write-Host "📝 Script SQL généré : $setupSQLPath" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Exécuter sur SQLite
# ============================================================================

Write-Host "💾 Création de la base SQLite..." -ForegroundColor Yellow

# Supprimer si existe
if (Test-Path $sqliteDb) {
    Remove-Item $sqliteDb
}

# Exécuter le script
$sw = [Diagnostics.Stopwatch]::StartNew()
Get-Content $setupSQLPath | sqlite3 $sqliteDb
$sw.Stop()

Write-Host "  ✅ SQLite créée en $($sw.Elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Copier vers DuckDB
# ============================================================================

Write-Host "🦆 Création de la base DuckDB..." -ForegroundColor Yellow

# Supprimer si existe
if (Test-Path $duckdbDb) {
    Remove-Item $duckdbDb
}

# Script pour DuckDB (copie depuis SQLite)
$duckdbCopySQL = @"
INSTALL sqlite;
LOAD sqlite;

-- Copier depuis SQLite
ATTACH '$sqliteDb' AS sqlite_db (TYPE sqlite);

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
"@

$duckdbCopySQL | duckdb $duckdbDb

Write-Host "  ✅ DuckDB créée" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Vérification
# ============================================================================

Write-Host "✔️  VÉRIFICATION" -ForegroundColor Cyan
Write-Host ""

# SQLite
$sqliteStats = "SELECT 'SQLite - Clients: ' || COUNT(*) FROM client; 
                SELECT 'SQLite - Factures: ' || COUNT(*) FROM facture;
                SELECT 'SQLite - Lignes: ' || COUNT(*) FROM ligne_facture;" | sqlite3 $sqliteDb

Write-Host $sqliteStats -ForegroundColor Green

# DuckDB  
$duckdbStats = "SELECT 'DuckDB - Clients: ' || COUNT(*) FROM client; 
                SELECT 'DuckDB - Factures: ' || COUNT(*) FROM facture;
                SELECT 'DuckDB - Lignes: ' || COUNT(*) FROM ligne_facture;" | duckdb $duckdbDb

Write-Host $duckdbStats -ForegroundColor Green

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "✨ GÉNÉRATION TERMINÉE AVEC SUCCÈS !" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 Fichiers créés :" -ForegroundColor Yellow
Write-Host "  - $sqliteDb"
Write-Host "  - $duckdbDb"
Write-Host "  - $setupSQLPath"
Write-Host ""
Write-Host "⏭️  Prochaine étape : Consultez 01-concept-ensembliste.md" -ForegroundColor Cyan
