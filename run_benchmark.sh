#!/bin/bash
# ============================================================================
# Script de benchmark automatisé des opérations ensemblistes
# Exécute les requêtes SQL sur IBM i, SQLite et DuckDB
# Mesure et compare les temps d'exécution
# ============================================================================

set -e  # Arrêt en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SQLITE_DB="facturation.db"
DUCKDB_DB="facturation.duckdb"
RESULTS_FILE="benchmark_results_$(date +%Y%m%d_%H%M%S).txt"

echo "============================================================================"
echo "BENCHMARK DES OPÉRATIONS ENSEMBLISTES"
echo "Date: $(date)"
echo "============================================================================"
echo ""

# ============================================================================
# Fonction pour extraire et exécuter une requête SQL d'un fichier
# ============================================================================
extract_and_run_query() {
    local sql_file=$1
    local query_name=$2
    local db_command=$3
    local db_name=$4
    
    # Extraire la requête spécifique du fichier SQL
    awk "/QUERY.*${query_name}:/,/^-- Performance|^-- Volume/" "$sql_file" | \
        grep -v "^--" | \
        grep -v "^$" > "/tmp/temp_query_${query_name}.sql"
    
    if [ ! -s "/tmp/temp_query_${query_name}.sql" ]; then
        echo "  ⚠️  Requête ${query_name} introuvable"
        return 1
    fi
    
    # Exécuter et mesurer le temps
    echo -n "  ${db_name}: "
    local start_time=$(date +%s.%N)
    
    if eval "$db_command" < "/tmp/temp_query_${query_name}.sql" > /dev/null 2>&1; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc)
        printf "${GREEN}%.3fs${NC}\n" "$duration"
        echo "$db_name;$query_name;$duration" >> "$RESULTS_FILE"
    else
        echo -e "${RED}ERREUR${NC}"
        echo "$db_name;$query_name;ERROR" >> "$RESULTS_FILE"
    fi
    
    rm -f "/tmp/temp_query_${query_name}.sql"
}

# ============================================================================
# SÉRIE 1 : POOL COMPLET
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}SÉRIE 1 : BENCHMARK POOL COMPLET (sans WHERE limitant)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

SQL_FILE_1="benchmark_01_pool_complet.sql"

if [ ! -f "$SQL_FILE_1" ]; then
    echo -e "${RED}Fichier ${SQL_FILE_1} introuvable${NC}"
    exit 1
fi

# En-tête du fichier de résultats
echo "database;query;duration_seconds" > "$RESULTS_FILE"

# Liste des requêtes à tester (Série 1)
queries_pool=(
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
    "10"
)

for query in "${queries_pool[@]}"; do
    echo -e "${YELLOW}Query ${query}:${NC}"
    
    # SQLite
    if [ -f "$SQLITE_DB" ]; then
        extract_and_run_query "$SQL_FILE_1" "$query" "sqlite3 $SQLITE_DB" "SQLite"
    else
        echo "  ⚠️  Base SQLite introuvable"
    fi
    
    # DuckDB
    if [ -f "$DUCKDB_DB" ]; then
        extract_and_run_query "$SQL_FILE_1" "$query" "duckdb $DUCKDB_DB" "DuckDB"
    else
        echo "  ⚠️  Base DuckDB introuvable"
    fi
    
    # IBM i - nécessite configuration spécifique
    # Décommenté si vous avez accès à IBM i
    # extract_and_run_query "$SQL_FILE_1" "$query" "db2 -tvf" "IBM_i"
    
    echo ""
done

echo ""

# ============================================================================
# SÉRIE 2 : AVEC WHERE LIMITANT
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}SÉRIE 2 : BENCHMARK AVEC WHERE LIMITANT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

SQL_FILE_2="benchmark_02_where_limite.sql"

if [ ! -f "$SQL_FILE_2" ]; then
    echo -e "${RED}Fichier ${SQL_FILE_2} introuvable${NC}"
    exit 1
fi

# Liste des requêtes à tester (Série 2)
queries_where=(
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
    "10"
)

for query in "${queries_where[@]}"; do
    echo -e "${YELLOW}Query ${query} (filtered):${NC}"
    
    # SQLite
    if [ -f "$SQLITE_DB" ]; then
        extract_and_run_query "$SQL_FILE_2" "$query" "sqlite3 $SQLITE_DB" "SQLite"
    else
        echo "  ⚠️  Base SQLite introuvable"
    fi
    
    # DuckDB
    if [ -f "$DUCKDB_DB" ]; then
        extract_and_run_query "$SQL_FILE_2" "$query" "duckdb $DUCKDB_DB" "DuckDB"
    else
        echo "  ⚠️  Base DuckDB introuvable"
    fi
    
    # IBM i
    # extract_and_run_query "$SQL_FILE_2" "$query" "db2 -tvf" "IBM_i"
    
    echo ""
done

# ============================================================================
# GÉNÉRATION DU RAPPORT
# ============================================================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}RAPPORT DE SYNTHÈSE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Calculer les moyennes par base de données
echo "Résultats sauvegardés dans: $RESULTS_FILE"
echo ""

# Afficher un résumé
echo "Temps moyens par base (en secondes):"
echo "------------------------------------"

for db in "SQLite" "DuckDB"; do
    avg=$(awk -F';' -v db="$db" '$1==db && $3!="ERROR" {sum+=$3; count++} END {if(count>0) print sum/count; else print "N/A"}' "$RESULTS_FILE")
    printf "%-10s : %s\n" "$db" "$avg"
done

echo ""
echo "Détails complets disponibles dans: $RESULTS_FILE"
echo ""
echo -e "${GREEN}Benchmark terminé avec succès !${NC}"
