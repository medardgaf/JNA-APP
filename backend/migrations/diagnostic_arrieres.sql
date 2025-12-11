-- Script de diagnostic pour vérifier les arriérés
-- Exécutez ces requêtes dans phpMyAdmin pour comprendre le problème

-- 1. Vérifier les membres avec date_debut_arriere
SELECT 
    id,
    nom_complet,
    date_debut_arriere,
    montant_arriere,
    statut_arriere,
    statut
FROM membres
WHERE date_debut_arriere IS NOT NULL 
AND date_debut_arriere != ''
ORDER BY nom_complet;

-- 2. Vérifier si la table historiques_arriere existe et contient des données
SELECT 
    ha.*,
    m.nom_complet
FROM historiques_arriere ha
LEFT JOIN membres m ON ha.membre_id = m.id
LIMIT 20;

-- 3. Compter le total des arriérés par source
SELECT 
    'Membres avec date_debut_arriere' as source,
    COUNT(*) as nombre,
    COALESCE(SUM(montant_arriere), 0) as montant_total
FROM membres
WHERE statut = 'actif' 
AND date_debut_arriere IS NOT NULL 
AND date_debut_arriere != ''

UNION ALL

SELECT 
    'Historiques arriere' as source,
    COUNT(DISTINCT membre_id) as nombre,
    COALESCE(SUM(montant_du), 0) as montant_total
FROM historiques_arriere;
