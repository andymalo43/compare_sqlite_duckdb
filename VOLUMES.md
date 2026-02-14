# Volumétrie des données de test

## Résumé

Ce document décrit les volumes de données générées pour les benchmarks DuckDB vs SQLite.

## Volumes actuels (mise à jour 2026-02-15)

### Tables

| Table | Lignes | Description |
|-------|--------|-------------|
| **client** | 100 000 | Clients répartis sur 18 villes françaises |
| **facture** | 3 000 000 | Factures de 2020 à 2025 (6 ans) |
| **ligne_facture** | 24 000 000 | Lignes de facture (moyenne: 8 lignes/facture) |

### Tailles des fichiers

| Base de données | Taille | Compression |
|----------------|---------|-------------|
| **SQLite** (`facturation.db`) | 2.4 GB | Aucune |
| **DuckDB** (`facturation.duckdb`) | 850 MB | ~65% (stockage columnar) |

### Répartition des données

**Statuts des factures** (distribution déterministe):
- BROUILLON: ~1% (~30K factures)
- ANNULEE: ~5% (~150K factures)
- EMISE: ~25% (~750K factures)
- PAYEE: ~69% (~2.07M factures)

**Taux de TVA** (lignes de facture):
- 5.5%: ~10% des lignes (~2.4M)
- 10.0%: ~20% des lignes (~4.8M)
- 20.0%: ~70% des lignes (~16.8M)

**Villes** (clients):
- 18 villes françaises (Paris, Lyon, Marseille, etc.)
- Distribution uniforme: ~5 555 clients par ville

**Période temporelle**:
- Date début: 2020-01-01
- Date fin: 2025-12-31
- Durée: 6 ans (2190 jours)
- Distribution: ~500K factures/an, ~4M lignes/an

## Évolution de la volumétrie

### Version initiale (avant 2026-02-15)

| Table | Lignes | Taille SQLite | Taille DuckDB |
|-------|--------|---------------|---------------|
| client | 5 000 | - | - |
| facture | 150 000 | - | - |
| ligne_facture | ~500 000 | 121 MB | 46 MB |
| **TOTAL** | **~655K** | **121 MB** | **46 MB** |

### Version actuelle (2026-02-15)

| Table | Lignes | Multiplicateur |
|-------|--------|----------------|
| client | 100 000 | **x20** |
| facture | 3 000 000 | **x20** |
| ligne_facture | 24 000 000 | **x48** |
| **TOTAL** | **~27M** | **~x41** |

**Tailles finales**:
- SQLite: 2.4 GB (**x20** vs 121 MB)
- DuckDB: 850 MB (**x18** vs 46 MB)

## Performance de génération

**Temps de génération** (sur machine standard):
- SQLite: ~406 secondes (6min 46s)
- DuckDB: ~10 secondes (copie depuis SQLite via extension)
- **Total**: ~7 minutes

**Optimisations appliquées**:
1. Génération 100% déterministe (pas de RANDOM())
2. CTE récursives optimisées pour gros volumes
3. Index créés APRÈS insertion (gain de performance significatif)
4. Batch processing via cross joins

## Impacts sur les benchmarks

### Temps d'exécution estimés (opérations ensemblistes)

| Opération | SQLite | DuckDB | Speedup |
|-----------|--------|--------|---------|
| **EXCEPT** (full scan) | 40-160s | 5-30s | 5-10x |
| **UNION ALL** (full scan) | 20-80s | 2-15s | 8-15x |
| **INTERSECT** (full scan) | 40-120s | 4-25s | 8-12x |
| **Avec WHERE** (index) | 2-15s | 0.1-2s | 10-50x |

### Recommandations

**Pour les benchmarks**:
- ✅ Toujours utiliser des clauses WHERE pour filtrer les données
- ✅ Vérifier que les index sont bien utilisés (EXPLAIN QUERY PLAN)
- ✅ Comparer les performances sur des pools filtrés (plus réaliste)
- ⚠️ Éviter les full scans sans filtre (trop lent sur 3M factures)

**Pour l'apprentissage**:
- Les volumes actuels sont représentatifs d'une PME réelle
- Les différences de performance DuckDB vs SQLite sont bien visibles
- Les opérations ensemblistes montrent leur coût sur gros volumes
- L'importance des index et du WHERE est évidente

## Génération des données

Pour régénérer les bases de données avec ces volumes:

```bash
# Linux/WSL/macOS
./setup-database.sh

# Windows PowerShell
.\setup-database.ps1
```

Les données sont **100% reproductibles** car la génération est déterministe (basée sur des formules mathématiques, pas de RANDOM()).

## Exemples de requêtes adaptées aux nouveaux volumes

### ✅ BON: Requête filtrée (rapide)

```sql
-- Clients ayant facturé en 2024 mais pas en 2025
SELECT c.nom, c.prenom, c.ville
FROM client c
WHERE c.client_id IN (
  SELECT client_id FROM facture WHERE strftime('%Y', date_facture) = '2024'
  EXCEPT
  SELECT client_id FROM facture WHERE strftime('%Y', date_facture) = '2025'
)
LIMIT 100;
```

**Performance**: 1-3s sur SQLite, 0.1-0.5s sur DuckDB

### ⚠️ LENT: Full scan sans filtre

```sql
-- Tous les clients avec leur total de factures (LENT!)
SELECT c.*, COUNT(f.facture_id) as nb_factures
FROM client c
LEFT JOIN facture f ON c.client_id = f.client_id
GROUP BY c.client_id;
```

**Performance**: 30-60s sur SQLite, 3-10s sur DuckDB

### ✅ OPTIMISÉ: Agrégation avec filtre

```sql
-- Top 10 clients par CA en 2024 (RAPIDE)
SELECT c.nom, c.prenom, SUM(f.montant_ttc) as ca_2024
FROM client c
JOIN facture f ON c.client_id = f.client_id
WHERE strftime('%Y', f.date_facture) = '2024'
  AND f.statut = 'PAYEE'
GROUP BY c.client_id, c.nom, c.prenom
ORDER BY ca_2024 DESC
LIMIT 10;
```

**Performance**: 2-5s sur SQLite, 0.2-1s sur DuckDB

## Notes techniques

### Pourquoi 24M lignes au lieu de 10M ?

Le nombre de lignes par facture est calculé de façon déterministe:
```sql
nb_lignes = ((facture_id * 53) % 15) + 1
```

Cela donne une distribution entre 1 et 15 lignes, avec une moyenne de **8 lignes/facture**.

**Calcul**: 3M factures × 8 lignes/facture = **24M lignes**

### Génération déterministe

Tous les attributs sont calculés par des formules basées sur l'ID:
- Nom: `(id % 20) + 1` → sélection parmi 20 noms
- Ville: `((id * 11) % 18) + 1` → sélection parmi 18 villes
- Date: `date('2020-01-01', '+' || ((id * 73) % 2190) || ' days')`
- Statut: `CASE ((id * 89) % 100) WHEN 0 THEN 'BROUILLON' ...`

**Avantages**:
- Pas de RANDOM() → résultats reproductibles
- Performance: pas d'appels système aléatoires
- Débogage: mêmes données à chaque génération
- Tests: résultats prévisibles

## Support et questions

Pour toute question sur les volumes ou la génération:
1. Consulter `CLAUDE.md` pour la documentation complète
2. Vérifier les scripts `setup-database.sh` ou `setup-database.ps1`
3. Ouvrir une issue sur le dépôt GitHub

---

Dernière mise à jour: 2026-02-15
