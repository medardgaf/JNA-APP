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

    // Récupérer l'ID de la catégorie "Activités Génératrices"
    $stmt = $db->prepare("SELECT id FROM categories WHERE nom = 'Activités Génératrices' LIMIT 1");
    $stmt->execute();
    $categorieId = $stmt->fetchColumn();

    if (!$categorieId) {
        throw new Exception('Catégorie "Activités Génératrices" non trouvée');
    }

    // Récupérer toutes les opérations
    $stmt = $db->prepare("
        SELECT 
            o.id,
            o.type,
            o.montant,
            o.date_operation,
            o.description,
            o.created_at,
            c.nom as categorie_nom
        FROM operations o
        LEFT JOIN categories c ON o.categorie_id = c.id
        WHERE o.categorie_id = :cat_id
        ORDER BY o.date_operation DESC
    ");
    
    $stmt->execute([':cat_id' => $categorieId]);
    $operations = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Nom du fichier
    $filename = "activites_generatrices_" . date('Y-m-d_His') . ".csv";

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
        'Date',
        'Description',
        'Catégorie',
        'Date de création'
    ], ';');

    // Calculer les totaux
    $totalEntrees = 0;
    $totalSorties = 0;

    // Données
    foreach ($operations as $op) {
        $montant = floatval($op['montant']);
        
        if (in_array($op['type'], ['recette', 'entree'])) {
            $totalEntrees += $montant;
            $typeLabel = 'Revenu';
        } else {
            $totalSorties += $montant;
            $typeLabel = 'Dépense';
        }

        fputcsv($output, [
            $op['id'],
            $typeLabel,
            number_format($montant, 0, ',', ' '),
            date('d/m/Y', strtotime($op['date_operation'])),
            $op['description'] ?? '',
            $op['categorie_nom'] ?? '',
            date('d/m/Y H:i', strtotime($op['created_at']))
        ], ';');
    }

    // Ligne vide
    fputcsv($output, [], ';');

    // Totaux
    fputcsv($output, ['', 'TOTAL REVENUS', number_format($totalEntrees, 0, ',', ' '), '', '', '', ''], ';');
    fputcsv($output, ['', 'TOTAL DÉPENSES', number_format($totalSorties, 0, ',', ' '), '', '', '', ''], ';');
    fputcsv($output, ['', 'BÉNÉFICE', number_format($totalEntrees - $totalSorties, 0, ',', ' '), '', '', '', ''], ';');

    fclose($output);
    exit;

} catch (Exception $e) {
    error_log("Erreur export_tresorier.php: " . $e->getMessage());
    http_response_code(500);
    header('Content-Type: application/json; charset=UTF-8');
    echo json_encode([
        'success' => false,
        'message' => 'Erreur: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
