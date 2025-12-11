-- ================================================================
-- MIGRATION: Ajout du statut membre bureau et amélioration réunions
-- Date: 2025-12-11
-- ================================================================

-- ÉTAPE 0: Vérifier la structure actuelle (à exécuter d'abord)
-- ================================================================
-- Décommentez et exécutez ces lignes pour voir la structure actuelle:
-- SHOW COLUMNS FROM reunions;
-- SHOW COLUMNS FROM presences_reunion;
-- SHOW COLUMNS FROM membres;

-- 1. Ajouter le champ est_membre_bureau à la table membres
-- ================================================================
ALTER TABLE membres 
ADD COLUMN est_membre_bureau BOOLEAN DEFAULT FALSE;

-- Optionnel: Mettre à jour les membres existants si nécessaire
-- Décommentez et modifiez les IDs selon vos besoins:
-- UPDATE membres SET est_membre_bureau = TRUE WHERE id IN (1, 2, 3);

-- 2. Ajouter les colonnes manquantes à la table reunions
-- ================================================================
-- Note: Nous n'utilisons pas AFTER car nous ne connaissons pas les noms exacts des colonnes

-- Ajouter description si elle n'existe pas
ALTER TABLE reunions 
ADD COLUMN description TEXT;

-- Ajouter type_reunion si elle n'existe pas (bureau, generale, extraordinaire)
ALTER TABLE reunions 
ADD COLUMN type_reunion ENUM('bureau', 'generale', 'extraordinaire') DEFAULT 'generale';

-- Ajouter statut_reunion si elle n'existe pas (planifiee, en_cours, terminee, annulee)
ALTER TABLE reunions 
ADD COLUMN statut_reunion ENUM('planifiee', 'en_cours', 'terminee', 'annulee') DEFAULT 'planifiee';

-- Ajouter lieu si elle n'existe pas
ALTER TABLE reunions 
ADD COLUMN lieu VARCHAR(255);

-- Ajouter updated_at si elle n'existe pas
ALTER TABLE reunions 
ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- 3. Ajouter les colonnes manquantes à la table presences_reunion
-- ================================================================

-- Ajouter heure_arrivee si elle n'existe pas
ALTER TABLE presences_reunion 
ADD COLUMN heure_arrivee TIME;

-- Ajouter commentaire si elle n'existe pas
ALTER TABLE presences_reunion 
ADD COLUMN commentaire TEXT;

-- 4. Modifier le statut pour inclure 'retard' si nécessaire
-- ================================================================
-- Note: Cette commande peut échouer si la colonne statut a déjà ces valeurs
-- ALTER TABLE presences_reunion 
-- MODIFY COLUMN statut ENUM('present', 'absent', 'excuse', 'retard') DEFAULT 'absent';

-- 5. Ajouter une contrainte unique pour éviter les doublons
-- ================================================================
-- Note: Cela échouera si vous avez déjà des doublons
-- Vérifiez d'abord avec: SELECT reunion_id, membre_id, COUNT(*) FROM presences_reunion GROUP BY reunion_id, membre_id HAVING COUNT(*) > 1;

-- ALTER TABLE presences_reunion 
-- ADD UNIQUE KEY unique_presence (reunion_id, membre_id);

-- 6. Vérification des modifications
-- ================================================================
-- Exécutez ces requêtes pour vérifier que tout est en place:

-- SHOW COLUMNS FROM membres LIKE 'est_membre_bureau';
-- SHOW COLUMNS FROM reunions;
-- SHOW COLUMNS FROM presences_reunion;

-- ================================================================
-- FIN DE LA MIGRATION
-- ================================================================
