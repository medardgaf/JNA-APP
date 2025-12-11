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

    // Récupérer tous les membres actifs
    $stmt = $db->prepare("
        SELECT 
            id,
            username,
            nom,
            prenom,
            nom_complet,
            telephone,
            role,
            statut,
            date_adhesion,
            date_debut_arriere,
            statut_arriere,
            montant_arriere
        FROM membres
        WHERE statut = 'actif'
        ORDER BY nom ASC, prenom ASC
    ");
    
    $stmt->execute();
    $membres = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Nom du fichier
    $filename = "membres_" . date('Y-m-d_His') . ".csv";

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
        'Username',
        'Nom',
        'Prénom',
        'Nom Complet',
        'Téléphone',
        'Rôle',
        'Statut',
        'Date Adhésion',
        'Date Début Arriéré',
        'Statut Arriéré',
        'Montant Arriéré (FCFA)'
    ], ';');

    // Compteurs
    $totalMembres = count($membres);
    $totalEnArriere = 0;
    $totalMontantArriere = 0;

    // Données
    foreach ($membres as $membre) {
        // Compter les membres en arriéré
        if ($membre['statut_arriere'] === 'en_arriere') {
            $totalEnArriere++;
            $totalMontantArriere += floatval($membre['montant_arriere'] ?? 0);
        }

        fputcsv($output, [
            $membre['id'],
            $membre['username'] ?? '',
            $membre['nom'] ?? '',
            $membre['prenom'] ?? '',
            $membre['nom_complet'] ?? '',
            $membre['telephone'] ?? '',
            ucfirst($membre['role'] ?? 'membre'),
            ucfirst($membre['statut'] ?? 'actif'),
            $membre['date_adhesion'] ? date('d/m/Y', strtotime($membre['date_adhesion'])) : '',
            $membre['date_debut_arriere'] ? date('d/m/Y', strtotime($membre['date_debut_arriere'])) : '',
            $membre['statut_arriere'] === 'en_arriere' ? 'En Arriéré' : 'À Jour',
            number_format(floatval($membre['montant_arriere'] ?? 0), 0, ',', ' ')
        ], ';');
    }

    // Ligne vide
    fputcsv($output, [], ';');

    // Statistiques
    fputcsv($output, ['STATISTIQUES'], ';');
    fputcsv($output, ['Total Membres Actifs', $totalMembres, '', '', '', '', '', '', '', '', '', ''], ';');
    fputcsv($output, ['Membres en Arriéré', $totalEnArriere, '', '', '', '', '', '', '', '', '', ''], ';');
    fputcsv($output, ['Membres à Jour', $totalMembres - $totalEnArriere, '', '', '', '', '', '', '', '', '', ''], ';');
    fputcsv($output, ['Total Montant Arriéré', '', '', '', '', '', '', '', '', '', '', number_format($totalMontantArriere, 0, ',', ' ')], ';');

    fclose($output);
    exit;

} catch (Exception $e) {
    error_log("Erreur export_membres.php: " . $e->getMessage());
    http_response_code(500);
    header('Content-Type: application/json; charset=UTF-8');
    echo json_encode([
        'success' => false,
        'message' => 'Erreur: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
