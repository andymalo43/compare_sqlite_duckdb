# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an educational project comparing **DuckDB** and **SQLite** performance for SQL set operations (EXCEPT, UNION ALL, INTERSECT). The project demonstrates DuckDB's analytical capabilities through hands-on exercises using a fictional invoicing database.

**Language**: French (documentation, comments, variable names)
**Target audience**: SQL learners and data engineers
**Dataset**: ~10M rows (100K clients, 3M invoices, ~10M invoice lines)

## Database Setup

### Initial Setup
Run the database setup script to generate test data:

```bash
# Linux/WSL/macOS
chmod +x setup-database.sh
./setup-database.sh

# Windows PowerShell
.\setup-database.ps1
```

This creates:
- `data/facturation.db` (SQLite database)
- `data/facturation.duckdb` (DuckDB database)
- `data/setup_database.sql` (generated SQL script)

The script generates:
- 100,000 clients across 18 French cities
- 3,000,000 invoices (2020-2025)
- ~10,000,000 invoice lines with 25 different products
- Realistic data with proper indexes

### Database Schema

**client** (100,000 rows):
- client_id, nom, prenom, email, telephone, adresse
- ville, code_postal, pays, date_creation

**facture** (3,000,000 rows):
- facture_id, client_id, numero_facture
- date_facture, date_echeance
- montant_ht, montant_tva, montant_ttc
- statut: BROUILLON | EMISE | PAYEE | ANNULEE

**ligne_facture** (~10,000,000 rows):
- ligne_id, facture_id, numero_ligne
- description, quantite, prix_unitaire
- taux_tva (5.5%, 10%, 20%), montant_ht, montant_tva, montant_ttc

### Performance Indexes
Already created by setup script:
- idx_facture_client (facture.client_id)
- idx_facture_date (facture.date_facture)
- idx_facture_statut (facture.statut)
- idx_ligne_facture (ligne_facture.facture_id)
- idx_client_ville (client.ville)

## Running Benchmarks

### CLI Execution

**SQLite**:
```bash
sqlite3 data/facturation.db
.timer on
.mode column
.headers on
.read benchmark_01_pool_complet.sql
```

**DuckDB**:
```bash
duckdb data/facturation.duckdb
.timer on
.read benchmark_01_pool_complet.sql
```

### Automated Benchmark Script

```bash
chmod +x run_benchmark.sh
./run_benchmark.sh
```

This runs both benchmark series (pool_complet and where_limite) on SQLite and DuckDB, saving results to `benchmark_results_YYYYMMDD_HHMMSS.txt`.

**Features**:
- Validates prerequisites (sqlite3, duckdb, bc)
- Checks database files exist in `data/` directory
- Extracts each query individually using pattern matching
- Measures execution time with nanosecond precision
- Shows detailed error messages if queries fail
- Generates summary statistics (success rate, average times, speedup factor)

## Benchmark Files Structure

**benchmark_01_pool_complet.sql**: 10 queries without WHERE filtering (full dataset scan)
- Tests raw performance on 3M invoices
- Expected duration: 10-120s per query depending on operation

**benchmark_02_where_limite.sql**: 10 queries with aggressive WHERE filtering
- Demonstrates impact of query optimization and indexes
- Expected speedup: 10-50x faster than pool_complet

**comparaison_pools_complete.sql**: Advanced P1/P2/BOTH pattern queries (8 queries)
- Shows how to compare two data pools and categorize results

**benchmark_ibmi.sql**: IBM i / DB2 adapted versions (12 queries)
- Uses YEAR() instead of EXTRACT(YEAR FROM ...)

**comparaison_pools_ibmi.sql**: IBM i version of pool comparison (6 queries)

## Query Pattern: P1/P2/BOTH

The advanced pattern used throughout shows how to categorize set operation results:

```sql
-- Shows which items are in Pool 1 only, Pool 2 only, or in both
SELECT *, 'P1' as source FROM pool1
EXCEPT
SELECT *, 'P1' as source FROM pool2

UNION ALL

SELECT *, 'P2' as source FROM pool2
EXCEPT
SELECT *, 'P2' as source FROM pool1

UNION ALL

SELECT *, 'BOTH' as source FROM pool1
INTERSECT
SELECT *, 'BOTH' as source FROM pool2
```

This pattern is fundamental to understanding data differences between environments, time periods, or categories.

## Performance Expectations

| Operation | SQLite | DuckDB | Speedup |
|-----------|--------|--------|---------|
| EXCEPT (full scan) | 40-160s | 5-30s | 5-10x |
| UNION ALL (full scan) | 20-80s | 2-15s | 8-15x |
| INTERSECT (full scan) | 40-120s | 4-25s | 8-12x |
| With WHERE filtering | 2-15s | 0.1-2s | 10-50x |

**Key insight**: DuckDB excels at analytical workloads (OLAP) due to columnar storage and vectorization. SQLite is better for transactional workloads (OLTP).

## Documentation Structure

**Learning path** (numbered 00-07):
1. **00-setup.md**: Environment configuration
2. **01-concept-ensembliste.md**: Set theory fundamentals
3. **02-except-differences.md**: EXCEPT operation
4. **03-union-consolidation.md**: UNION ALL operation
5. **04-intersect-similitudes.md**: INTERSECT operation
6. **05-comparaison-complete.md**: Advanced P1/P2/BOTH pattern
7. **06-optimisation-where.md**: WHERE clause optimization
8. **07-benchmark-performance.md**: Performance benchmarking

**Setup guides**:
- **INSTALL.md**: SQLite/DuckDB installation
- **DBEAVER.md**: DBeaver GUI setup
- **DUCKDB-UI.md**: Web-based DuckDB UI
- **MANUAL-SETUP.md**: Manual database setup steps

## Common Use Cases

The benchmarks demonstrate real-world scenarios:

**Data auditing**:
- Compare PROD vs DEV environments
- Detect orphaned records
- Verify data synchronization

**Business analysis**:
- Identify churned customers (active in 2024 but not 2025)
- Compare product catalogs across time periods
- Customer segmentation

**Financial reconciliation**:
- Account reconciliation
- VAT analysis by rate
- Anomaly detection

**Geographic analysis**:
- Regional performance comparison
- Identify exclusive markets

## Working with This Codebase

### When modifying SQL queries:
- Test on both SQLite and DuckDB
- For IBM i compatibility, use `YEAR(date)` instead of `EXTRACT(YEAR FROM date)`
- Always include performance expectations in comments
- Document the business use case for each query

### When modifying setup scripts:
- Data generation is **deterministic** using mathematical formulas based on IDs (RANDOM() only in old version, now fully deterministic for reproducibility)
- Each entity has unique attributes based on its ID (e.g., `(id * prime_number) % range`)
- Maintain volume targets: 100K clients, 3M invoices, ~10M lines
- Preserve the date range: 2020-2025
- Keep 4 invoice statuses: BROUILLON (~1%), EMISE (~25%), PAYEE (~69%), ANNULEE (~5%)
- Keep 3 VAT rates: 5.5% (~10%), 10% (~20%), 20% (~70%)
- **CRITICAL**: SQLite doesn't support:
  - Comma-separated WHEN clauses: use `WHEN expr <= N` instead
  - Column alias references in same SELECT: repeat expression or use subqueries

### Naming conventions:
- SQL files: lowercase with underscores (benchmark_01_pool_complet.sql)
- Documentation: UPPERCASE or numbered (README.md, 01-concept-ensembliste.md)
- Database files: facturation.db / facturation.duckdb
- French terms used consistently: facture (invoice), client (customer), ligne (line item)

## Educational Context

This is a pedagogical project. When working with it:
- Maintain clear, commented SQL that explains the "why" not just the "what"
- Performance metrics help learners understand database engine differences
- French language is intentional for the target audience
- Real-world use cases make abstract concepts concrete
