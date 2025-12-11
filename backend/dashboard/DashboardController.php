<?php
ini_set('display_errors', 0);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config/database.php';

class DashboardController {
    private $db;

    // Assure-toi que ces IDs correspondent à ta table 'categories'
    const COTIS_MENSUELLES = 1; 
    const AUTRES_COTIS     = 2; 
    const DONS             = 3; 
    const FONDS_SOCIAL     = 4; 
    const ACTIVITES        = 5; 

    public function __construct() {
        $this->db = (new Database())->getConnection();
    }

    private function getTotalByCategorie($catId) {
        $stmt = $this->db->prepare("
            SELECT COALESCE(SUM(montant),0) AS total 
            FROM operations 
            WHERE type = 'recette' AND categorie_id = :cat_id
        ");
        $stmt->execute([":cat_id" => $catId]);
        return (float) $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    }

    public function getStats($role, $membreId = null) {
        // Nettoyage du buffer pour éviter les caractères parasites
        if (ob_get_length()) ob_end_clean();

        try {
            // 1. Stats Globales (Pour Admin/Trésorier)
            $tot_mensuelles = $this->getTotalByCategorie(self::COTIS_MENSUELLES);
            $tot_autres     = $this->getTotalByCategorie(self::AUTRES_COTIS) 
                            + $this->getTotalByCategorie(self::FONDS_SOCIAL) 
                            + $this->getTotalByCategorie(self::ACTIVITES);
            $tot_dons       = $this->getTotalByCategorie(self::DONS);

            // 2. Stats Membres en arriéré - CORRIGÉ
            // Compter les membres actifs qui ont une date_debut_arriere définie
            $stmt = $this->db->prepare("
                SELECT COUNT(*) AS total 
                FROM membres 
                WHERE statut = 'actif' 
                AND date_debut_arriere IS NOT NULL 
                AND date_debut_arriere != ''
            ");
            $stmt->execute();
            $arrieres_count = (int) $stmt->fetch(PDO::FETCH_ASSOC)['total'];

            // 3. Détails Arriérés (Montants) - CORRIGÉ V2
            // Essayer d'abord historiques_arriere, sinon utiliser membres.montant_arriere
            try {
                // Vérifier si la table historiques_arriere existe et a des données
                $stmt = $this->db->prepare("
                    SELECT 
                        COUNT(DISTINCT membre_id) AS total_arrieres, 
                        COALESCE(SUM(montant_du), 0) AS montant_du,
                        COALESCE(SUM(montant_paye), 0) AS montant_paye
                    FROM historiques_arriere
                ");
                $stmt->execute();
                $arr = $stmt->fetch(PDO::FETCH_ASSOC);
                
                // Si historiques_arriere a des données, l'utiliser
                if ($arr && $arr['total_arrieres'] > 0) {
                    $arriere_stats = [
                        "total_arrieres" => (int) ($arr["total_arrieres"] ?? 0),
                        "montant_du"     => (float) ($arr["montant_du"] ?? 0),
                        "montant_paye"   => (float) ($arr["montant_paye"] ?? 0)
                    ];
                } else {
                    // Sinon, utiliser montant_arriere de la table membres
                    $stmt = $this->db->prepare("
                        SELECT 
                            COUNT(*) AS total_arrieres, 
                            COALESCE(SUM(montant_arriere), 0) AS montant_du
                        FROM membres
                        WHERE statut = 'actif' 
                        AND date_debut_arriere IS NOT NULL 
                        AND date_debut_arriere != ''
                    ");
                    $stmt->execute();
                    $arr = $stmt->fetch(PDO::FETCH_ASSOC);
                    $arriere_stats = [
                        "total_arrieres" => (int) ($arr["total_arrieres"] ?? 0),
                        "montant_du"     => (float) ($arr["montant_du"] ?? 0),
                        "montant_paye"   => 0
                    ];
                }
            } catch (Exception $e) {
                // Si erreur (table n'existe pas), utiliser membres.montant_arriere
                $stmt = $this->db->prepare("
                    SELECT 
                        COUNT(*) AS total_arrieres, 
                        COALESCE(SUM(montant_arriere), 0) AS montant_du
                    FROM membres
                    WHERE statut = 'actif' 
                    AND date_debut_arriere IS NOT NULL 
                    AND date_debut_arriere != ''
                ");
                $stmt->execute();
                $arr = $stmt->fetch(PDO::FETCH_ASSOC);
                $arriere_stats = [
                    "total_arrieres" => (int) ($arr["total_arrieres"] ?? 0),
                    "montant_du"     => (float) ($arr["montant_du"] ?? 0),
                    "montant_paye"   => 0
                ];
            }

            // 4. Stats Opérations (Nombre total et volume)
            $stmt = $this->db->prepare("
                SELECT COUNT(*) AS total_operations, 
                       COALESCE(SUM(montant),0) AS montant_operations 
                FROM operations
            ");
            $stmt->execute();
            $ops = $stmt->fetch(PDO::FETCH_ASSOC);
            $operation_stats = [
                "total_operations"   => (int) ($ops["total_operations"] ?? 0),
                "montant_operations" => (float) ($ops["montant_operations"] ?? 0)
            ];

            // 5. Événements à venir (Prochains 5)
            $stmt = $this->db->prepare("
                SELECT id, titre, date_evenement 
                FROM evenements 
                WHERE date_evenement >= CURDATE() 
                ORDER BY date_evenement ASC 
                LIMIT 5
            ");
            $stmt->execute();
            $events = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // --- Construction de la réponse selon le Rôle ---
            $response = ["success" => true];

            // Pour éviter les erreurs null sur le front, on fournit des valeurs par défaut
            $response['arrieres'] = $arrieres_count;
            $response['events'] = $events;
            $response['tot_dons'] = $tot_dons;

            if ($role === 'admin' || $role === 'tresorier') {
                $response['tot_mensuelles'] = $tot_mensuelles;
                $response['tot_autres'] = $tot_autres;
                $response['arriere_stats'] = $arriere_stats;
                $response['operation_stats'] = $operation_stats;
            }
            
            if ($role === 'membre' || $role === 'admin') {
                 // Stats personnelles pour le membre (ou l'admin en tant que membre)
                 if ($membreId) {
                    $stmt = $this->db->prepare("
                        SELECT COALESCE(SUM(montant),0) AS total 
                        FROM operations 
                        WHERE type = 'recette' AND membre_id = :id
                    ");
                    $stmt->execute([":id" => $membreId]);
                    $response['mes_cotisations'] = (float) $stmt->fetch(PDO::FETCH_ASSOC)['total'];
                 } else {
                    $response['mes_cotisations'] = 0;
                 }
            }

            echo json_encode($response);

        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => "Erreur serveur : " . $e->getMessage()]);
        }
    }
}

// ======================================================
//   ROUTEUR
// ======================================================
if (isset($_GET["action"]) && $_GET["action"] === "stats") {
    $role = $_GET["role"] ?? "membre";
    $membreId = $_GET["membre_id"] ?? null;
    (new DashboardController())->getStats($role, $membreId);
} else {
    // Si aucune action n'est précisée, on renvoie quand même les stats par défaut (utile pour le debug)
    // Ou une erreur 400
    (new DashboardController())->getStats("membre", null);
}
?>
