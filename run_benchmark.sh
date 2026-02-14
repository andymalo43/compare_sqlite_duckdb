#!/bin/bash
# ============================================================================
# Script de benchmark automatisé des opérations ensemblistes
# Exécute les requêtes SQL sur IBM i, SQLite et DuckDB
# Mesure et compare les temps d'exécution
# ============================================================================

set -e  # Arrêt en cas d'erreur

# Force l'utilisation du point comme séparateur décimal
export LC_NUMERIC=C

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SQLITE_DB="data/facturation.db"
DUCKDB_DB="data/facturation.duckdb"
RESULTS_FILE="benchmark_results_$(date +%Y%m%d_%H%M%S).txt"

echo "============================================================================"
echo "BENCHMARK DES OPÉRATIONS ENSEMBLISTES"
echo "Date: $(date)"
echo "============================================================================"
echo ""

# Vérification des prérequis
echo "Vérification des prérequis..."

if ! command -v sqlite3 &> /dev/null; then
    echo -e "${RED}❌ SQLite non trouvé. Installez-le d'abord.${NC}"
    exit 1
fi

if ! command -v duckdb &> /dev/null; then
    echo -e "${RED}❌ DuckDB non trouvé. Installez-le d'abord.${NC}"
    exit 1
fi

if ! command -v bc &> /dev/null; then
    echo -e "${RED}❌ bc non trouvé. Installez-le: sudo apt install bc${NC}"
    exit 1
fi

if [ ! -f "$SQLITE_DB" ]; then
    echo -e "${RED}❌ Base SQLite introuvable: $SQLITE_DB${NC}"
    echo "Exécutez d'abord: ./setup-database.sh"
    exit 1
fi

if [ ! -f "$DUCKDB_DB" ]; then
    echo -e "${RED}❌ Base DuckDB introuvable: $DUCKDB_DB${NC}"
    echo "Exécutez d'abord: ./setup-database.sh"
    exit 1
fi

echo -e "${GREEN}✓ SQLite détecté: $(sqlite3 --version | awk '{print $1}')${NC}"
echo -e "${GREEN}✓ DuckDB détecté${NC}"
echo -e "${GREEN}✓ Bases de données trouvées${NC}"
echo ""

# ============================================================================
# Fonction pour extraire et exécuter une requête SQL d'un fichier
# ============================================================================
extract_and_run_query() {
    local sql_file=$1
    local query_name=$2
    local db_command=$3
    local db_name=$4
    local temp_file="/tmp/temp_query_${db_name}_${query_name}_$$.sql"

    # Extraire la requête spécifique du fichier SQL
    # Cherche après "-- QUERY X:" et extrait jusqu'à la prochaine query ou fin
    sed -n "/^-- QUERY ${query_name}:/,/^-- QUERY [0-9]/{
        /^-- QUERY ${query_name}:/d
        /^-- QUERY [0-9]/d
        /^--/d
        /^$/d
        p
    }" "$sql_file" > "$temp_file"

    if [ ! -s "$temp_file" ]; then
        echo -e "  ${db_name}: ${RED}⚠️  Requête introuvable${NC}"
        rm -f "$temp_file"
        return 1
    fi

    # Exécuter et mesurer le temps
    echo -n "  ${db_name}: "
    local start_time=$(date +%s.%N)

    local error_file="/tmp/error_${db_name}_${query_name}_$$.txt"
    if eval "$db_command" < "$temp_file" > /dev/null 2> "$error_file"; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc)
        printf "${GREEN}%.3fs${NC}\n" "$duration"
        echo "$db_name;$query_name;$duration" >> "$RESULTS_FILE"
    else
        echo -e "${RED}ERREUR${NC}"
        if [ -s "$error_file" ]; then
            echo -e "    ${RED}Détails: $(head -n 1 "$error_file")${NC}"
        fi
        echo "$db_name;$query_name;ERROR" >> "$RESULTS_FILE"
    fi

    rm -f "$temp_file" "$error_file"
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

# Compter les erreurs
echo "Statistiques d'exécution:"
echo "-------------------------"
for db in "SQLite" "DuckDB"; do
    total=$(grep -c "^$db;" "$RESULTS_FILE" || true)
    errors=$(grep -c "^$db;.*;ERROR$" "$RESULTS_FILE" || true)
    success=$((total - errors))
    printf "%-10s : %d/%d requêtes réussies\n" "$db" "$success" "$total"
done
echo ""

# Afficher les temps moyens
echo "Temps moyens par base (en secondes):"
echo "-------------------------------------"

for db in "SQLite" "DuckDB"; do
    avg=$(awk -F';' -v db="$db" '$1==db && $3!="ERROR" {sum+=$3; count++} END {if(count>0) printf "%.3f", sum/count; else print "N/A"}' "$RESULTS_FILE")
    printf "%-10s : %s\n" "$db" "$avg"
done

echo ""

# Calculer le speedup
sqlite_avg=$(awk -F';' '$1=="SQLite" && $3!="ERROR" {sum+=$3; count++} END {if(count>0) print sum/count; else print 0}' "$RESULTS_FILE")
duckdb_avg=$(awk -F';' '$1=="DuckDB" && $3!="ERROR" {sum+=$3; count++} END {if(count>0) print sum/count; else print 0}' "$RESULTS_FILE")

if [ $(echo "$duckdb_avg > 0" | bc) -eq 1 ] && [ $(echo "$sqlite_avg > 0" | bc) -eq 1 ]; then
    speedup=$(echo "scale=2; $sqlite_avg / $duckdb_avg" | bc)
    echo -e "${GREEN}DuckDB est ${speedup}x plus rapide que SQLite en moyenne${NC}"
    echo ""
fi

echo "Détails complets disponibles dans: $RESULTS_FILE"
echo ""
echo -e "${GREEN}✨ Benchmark terminé avec succès !${NC}"
