<?php
ini_set('display_errors', 0);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();

    // Récupérer toutes les opérations avec les informations de catégorie et membre
    $stmt = $db->prepare("
        SELECT 
            o.id,
            o.type,
            o.montant,
            o.date_operation,
            o.description,
            o.created_at,
            c.nom as categorie_nom,
            CONCAT(COALESCE(m.nom, ''), ' ', COALESCE(m.prenom, '')) as membre_nom
        FROM operations o
        LEFT JOIN categories c ON o.categorie_id = c.id
        LEFT JOIN membres m ON o.membre_id = m.id
        ORDER BY o.date_operation DESC, o.created_at DESC
    ");
    
    $stmt->execute();
    $operations = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Nom du fichier
    $filename = "operations_" . date('Y-m-d_His') . ".csv";

    // Headers pour le téléchargement
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    header('Pragma: no-cache');
    header('Expires: 0');

    // Ouvrir le flux de sortie
    $output = fopen('php://output', 'w');

    // BOM UTF-8 pour Excel
    fprintf($output, chr(0xEF).chr(0xBB).chr(0xBF));

    // En-têtes du CSV
    fputcsv($output, [
        'ID',
        'Type',
        'Montant (FCFA)',
        'Date Opération',
        'Description',
        'Catégorie',
        'Membre',
        'Date de Création'
    ], ';');

    // Calculer les totaux
    $totalEntrees = 0;
    $totalSorties = 0;
    $totalRecettes = 0;
    $totalDepenses = 0;

    // Données
    foreach ($operations as $op) {
        $montant = floatval($op['montant']);
        
        // Déterminer le type et calculer les totaux
        if (in_array($op['type'], ['recette', 'entree'])) {
            $totalEntrees += $montant;
            $totalRecettes += $montant;
            $typeLabel = 'Recette';
        } else {
            $totalSorties += $montant;
            $totalDepenses += $montant;
            $typeLabel = 'Dépense';
        }

        fputcsv($output, [
            $op['id'],
            $typeLabel,
            number_format($montant, 0, ',', ' '),
            date('d/m/Y', strtotime($op['date_operation'])),
            $op['description'] ?? '',
            $op['categorie_nom'] ?? '',
            trim($op['membre_nom']) ?: '',
            date('d/m/Y H:i', strtotime($op['created_at']))
        ], ';');
    }

    // Ligne vide
    fputcsv($output, [], ';');

    // Totaux
    fputcsv($output, ['', 'TOTAL RECETTES', number_format($totalRecettes, 0, ',', ' '), '', '', '', '', ''], ';');
    fputcsv($output, ['', 'TOTAL DÉPENSES', number_format($totalDepenses, 0, ',', ' '), '', '', '', '', ''], ';');
    fputcsv($output, ['', 'SOLDE', number_format($totalRecettes - $totalDepenses, 0, ',', ' '), '', '', '', '', ''], ';');

    fclose($output);
    exit;

} catch (Exception $e) {
    error_log("Erreur export_operations.php: " . $e->getMessage());
    http_response_code(500);
    header('Content-Type: application/json; charset=UTF-8');
    echo json_encode([
        'success' => false,
        'message' => 'Erreur: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
