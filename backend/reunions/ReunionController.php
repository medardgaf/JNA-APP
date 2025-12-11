<?php
// api/reunions/ReunionController.php
ini_set('display_errors', 1);
error_reporting(E_ALL);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit(0);
}
require_once __DIR__ . '/../config/database.php';

class ReunionController {
    private $db;

    public function __construct() {
        $this->db = (new Database())->getConnection();
    }

    // GET ?action=all
    public function getAll() {
        header("Content-Type: application/json; charset=utf-8");
        $dateFrom = $_GET['date_from'] ?? null;
        $dateTo   = $_GET['date_to'] ?? null;
        $type     = $_GET['type_reunion'] ?? null;

        $where = [];
        $params = [];

        if ($dateFrom) { $where[] = "r.date_reunion >= ?"; $params[] = $dateFrom; }
        if ($dateTo)   { $where[] = "r.date_reunion <= ?"; $params[] = $dateTo; }
        if ($type)     { $where[] = "r.type_reunion = ?"; $params[] = $type; }

        $whereSql = count($where) ? "WHERE " . implode(" AND ", $where) : "";

        $sql = "
            SELECT r.*, COALESCE(m.nom_complet, '') AS created_by_name
            FROM reunions r
            LEFT JOIN membres m ON r.created_by = m.id
            $whereSql
            ORDER BY r.date_reunion DESC, r.created_at DESC
        ";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(["success" => true, "data" => $rows]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }

    // POST ?action=add
    public function add() {
        header("Content-Type: application/json; charset=utf-8");
        $input = json_decode(file_get_contents("php://input"), true);

        if (!$input || !isset($input['type_reunion']) || !isset($input['date_reunion'])) {
            echo json_encode(["success" => false, "message" => "Paramètres requis: type_reunion, date_reunion"]);
            return;
        }

        try {
            $this->db->beginTransaction();

            // Insérer la réunion avec les nouveaux champs
            $stmt = $this->db->prepare("
                INSERT INTO reunions (
                    type_reunion, date_reunion, ordre_du_jour, description, lieu,
                    statut_reunion, created_by, created_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
            ");
            $stmt->execute([
                $input['type_reunion'],
                $input['date_reunion'],
                $input['ordre_du_jour'] ?? null,
                $input['description'] ?? null,
                $input['lieu'] ?? null,
                $input['statut_reunion'] ?? 'planifiee',
                isset($input['created_by']) ? intval($input['created_by']) : null
            ]);

            $reunion_id = $this->db->lastInsertId();

            // Générer présences SELON LE TYPE DE RÉUNION
            $this->creerPresences($reunion_id, $input['type_reunion']);

            $this->db->commit();
            echo json_encode(["success" => true, "message" => "Réunion créée", "reunion_id" => $reunion_id]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }

    /**
     * Crée automatiquement les entrées de présence selon le type de réunion
     * NOUVELLE FONCTIONNALITÉ pour gérer les membres du bureau
     */
    private function creerPresences($reunionId, $typeReunion) {
        try {
            $whereClause = "";
            
            switch ($typeReunion) {
                case 'bureau':
                    // Uniquement les membres du bureau actifs
                    $whereClause = "WHERE est_membre_bureau = TRUE AND statut = 'actif'";
                    break;
                case 'generale':
                    // Tous les membres actifs
                    $whereClause = "WHERE statut = 'actif'";
                    break;
                case 'extraordinaire':
                    // Tous les membres (actifs et inactifs)
                    $whereClause = "";
                    break;
                default:
                    // Par défaut : tous les membres
                    $whereClause = "";
            }

            // Récupérer les membres concernés
            $sql = "SELECT id FROM membres $whereClause ORDER BY nom_complet ASC";
            $mSql = $this->db->prepare($sql);
            $mSql->execute();
            $membres = $mSql->fetchAll(PDO::FETCH_ASSOC);

            if (!empty($membres)) {
                $pStmt = $this->db->prepare("
                    INSERT INTO presences_reunion (reunion_id, membre_id, statut, created_at)
                    VALUES (?, ?, 'absent', NOW())
                ");
                foreach ($membres as $m) {
                    $pStmt->execute([$reunionId, $m['id']]);
                }
            }
        } catch (Exception $e) {
            error_log("Erreur creerPresences: " . $e->getMessage());
        }
    }

    // GET ?action=details&id=XX
    public function getDetails() {
        header("Content-Type: application/json; charset=utf-8");
        if (!isset($_GET['id'])) { echo json_encode(["success" => false, "message" => "ID manquant"]); return; }
        $id = intval($_GET['id']);

        try {
            $r = $this->db->prepare("
                SELECT r.*, COALESCE(m.nom_complet,'') AS created_by_name
                FROM reunions r
                LEFT JOIN membres m ON r.created_by = m.id
                WHERE r.id = ?
            ");
            $r->execute([$id]);
            $reunion = $r->fetch(PDO::FETCH_ASSOC);
            if (!$reunion) { echo json_encode(["success" => false, "message" => "Réunion introuvable"]); return; }

            $s = $this->db->prepare("
                SELECT 
                    SUM(CASE WHEN statut = 'present' THEN 1 ELSE 0 END) AS presents,
                    SUM(CASE WHEN statut = 'absent' THEN 1 ELSE 0 END) AS absents,
                    SUM(CASE WHEN statut = 'excuse' THEN 1 ELSE 0 END) AS excuses,
                    SUM(CASE WHEN statut = 'retard' THEN 1 ELSE 0 END) AS retards,
                    COUNT(*) AS total
                FROM presences_reunion
                WHERE reunion_id = ?
            ");
            $s->execute([$id]);
            $stats = $s->fetch(PDO::FETCH_ASSOC);

            echo json_encode(["success" => true, "reunion" => $reunion, "stats" => $stats]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }

    // GET ?action=details_full&id=XX  (renvoie aussi participation)
    public function getDetailsFull() {
        header("Content-Type: application/json; charset=utf-8");
        if (!isset($_GET['id'])) { echo json_encode(["success" => false, "message" => "ID manquant"]); return; }
        $id = intval($_GET['id']);

        try {
            $r = $this->db->prepare("
                SELECT r.*, COALESCE(m.nom_complet,'') AS created_by_name
                FROM reunions r
                LEFT JOIN membres m ON r.created_by = m.id
                WHERE r.id = ?
            ");
            $r->execute([$id]);
            $reunion = $r->fetch(PDO::FETCH_ASSOC);
            if (!$reunion) { echo json_encode(["success" => false, "message" => "Réunion introuvable"]); return; }

            $s = $this->db->prepare("
                SELECT 
                    SUM(CASE WHEN statut = 'present' THEN 1 ELSE 0 END) AS presents,
                    SUM(CASE WHEN statut = 'absent' THEN 1 ELSE 0 END) AS absents,
                    SUM(CASE WHEN statut = 'excuse' THEN 1 ELSE 0 END) AS excuses,
                    SUM(CASE WHEN statut = 'retard' THEN 1 ELSE 0 END) AS retards,
                    COUNT(*) AS total
                FROM presences_reunion
                WHERE reunion_id = ?
            ");
            $s->execute([$id]);
            $stats = $s->fetch(PDO::FETCH_ASSOC);

            $total = intval($stats['total'] ?? 0);
            $presents = intval($stats['presents'] ?? 0);
            $percent = $total > 0 ? round(($presents / $total) * 100, 2) : 0;

            echo json_encode(["success" => true, "reunion" => $reunion, "stats" => $stats, "participation" => $percent]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }

    // GET ?action=list_presence&id=XX[&statut=...]
    public function listPresence() {
        header("Content-Type: application/json; charset=utf-8");
        if (!isset($_GET['id'])) { echo json_encode(["success" => false, "message" => "id manquant"]); return; }
        $id = intval($_GET['id']);
        $statut = $_GET['statut'] ?? null;

        try {
            $sql = "
                SELECT p.id, p.reunion_id, p.membre_id, p.statut, p.heure_arrivee, p.commentaire, p.created_at,
                       COALESCE(m.nom_complet, '') AS nom_complet,
                       COALESCE(m.telephone, '') AS telephone
                FROM presences_reunion p
                LEFT JOIN membres m ON p.membre_id = m.id
                WHERE p.reunion_id = ?
            ";
            $params = [$id];
            if ($statut) {
                $sql .= " AND p.statut = ?";
                $params[] = $statut;
            }
            $sql .= " ORDER BY COALESCE(m.nom_complet,'') ASC";

            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode(["success" => true, "data" => $rows]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }

    // POST ?action=update_presence (avec heure_arrivee et commentaire)
    public function updatePresence() {
        header("Content-Type: application/json; charset=utf-8");
        $input = json_decode(file_get_contents("php://input"), true);
        if (!$input || !isset($input['reunion_id']) || !isset($input['membre_id']) || !isset($input['statut'])) {
            echo json_encode(["success" => false, "message" => "Paramètres manquants: reunion_id, membre_id, statut"]);
            return;
        }

        $allowed = ['present', 'absent', 'excuse', 'retard'];
        if (!in_array($input['statut'], $allowed)) {
            echo json_encode(["success" => false, "message" => "Statut invalide"]);
            return;
        }

        try {
            $stmt = $this->db->prepare("
                UPDATE presences_reunion 
                SET statut = ?, heure_arrivee = ?, commentaire = ?
                WHERE reunion_id = ? AND membre_id = ?
            ");
            $stmt->execute([
                $input['statut'],
                $input['heure_arrivee'] ?? null,
                $input['commentaire'] ?? null,
                intval($input['reunion_id']),
                intval($input['membre_id'])
            ]);
            echo json_encode(["success" => true, "message" => "Statut mis à jour"]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }

    // POST ?action=bulk_update_presence
    public function bulkUpdatePresence() {
        header("Content-Type: application/json; charset=utf-8");
        $input = json_decode(file_get_contents("php://input"), true);

        if (!$input || !isset($input['reunion_id']) || !isset($input['updates']) || !is_array($input['updates'])) {
            echo json_encode(["success" => false, "message" => "Paramètres invalides"]);
            return;
        }

        $reunion_id = intval($input['reunion_id']);
        $updates = $input['updates'];
        $allowed = ['present', 'absent', 'excuse', 'retard'];

        try {
            $this->db->beginTransaction();
            $stmt = $this->db->prepare("
                UPDATE presences_reunion 
                SET statut = ?, heure_arrivee = ?, commentaire = ?
                WHERE reunion_id = ? AND membre_id = ?
            ");
            foreach ($updates as $u) {
                if (!isset($u['membre_id']) || !isset($u['statut'])) continue;
                if (!in_array($u['statut'], $allowed)) continue;
                $stmt->execute([
                    $u['statut'],
                    $u['heure_arrivee'] ?? null,
                    $u['commentaire'] ?? null,
                    $reunion_id,
                    intval($u['membre_id'])
                ]);
            }
            $this->db->commit();
            echo json_encode(["success" => true, "message" => "Présences mises à jour"]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }

    // GET ?action=export_excel&id=XX
    public function exportExcel() {
        if (!isset($_GET['id'])) { echo "ID manquant"; return; }
        $id = intval($_GET['id']);

        header("Content-Type: application/vnd.ms-excel; charset=utf-8");
        header("Content-Disposition: attachment; filename=presence_reunion_{$id}.xls");

        echo "Nom\tTéléphone\tStatut\tHeure Arrivée\tCommentaire\n";

        $sql = "
            SELECT COALESCE(m.nom_complet,'') AS nom_complet, 
                   COALESCE(m.telephone,'') AS telephone, 
                   p.statut,
                   COALESCE(p.heure_arrivee, '') AS heure_arrivee,
                   COALESCE(p.commentaire, '') AS commentaire
            FROM presences_reunion p
            LEFT JOIN membres m ON m.id = p.membre_id
            WHERE p.reunion_id = ?
            ORDER BY COALESCE(m.nom_complet,'') ASC
        ";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);

        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            echo "{$row['nom_complet']}\t{$row['telephone']}\t{$row['statut']}\t{$row['heure_arrivee']}\t{$row['commentaire']}\n";
        }
    }

    // DELETE ?action=delete&id=XX
    public function delete() {
        header("Content-Type: application/json; charset=utf-8");
        if (!isset($_GET['id'])) { echo json_encode(["success" => false, "message" => "ID manquant"]); return; }
        $id = intval($_GET['id']);

        try {
            $stmt = $this->db->prepare("DELETE FROM reunions WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(["success" => true, "message" => "Réunion supprimée"]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }

    // GET ?action=stats_membre&membre_id=XX (NOUVELLE FONCTIONNALITÉ)
    public function getStatsMembre() {
        header("Content-Type: application/json; charset=utf-8");
        if (!isset($_GET['membre_id'])) {
            echo json_encode(["success" => false, "message" => "membre_id manquant"]);
            return;
        }
        $membreId = intval($_GET['membre_id']);

        try {
            $stmt = $this->db->prepare("
                SELECT 
                    COUNT(*) as total_reunions,
                    SUM(CASE WHEN statut = 'present' THEN 1 ELSE 0 END) as presents,
                    SUM(CASE WHEN statut = 'absent' THEN 1 ELSE 0 END) as absents,
                    SUM(CASE WHEN statut = 'excuse' THEN 1 ELSE 0 END) as excuses,
                    SUM(CASE WHEN statut = 'retard' THEN 1 ELSE 0 END) as retards
                FROM presences_reunion
                WHERE membre_id = ?
            ");
            
            $stmt->execute([$membreId]);
            $stats = $stmt->fetch(PDO::FETCH_ASSOC);

            echo json_encode(["success" => true, "data" => ["stats" => $stats]]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => $e->getMessage()]);
        }
    }
}

// ROUTER
$controller = new ReunionController();
$action = $_GET['action'] ?? null;
if (!$action) { echo json_encode(["success" => false, "message" => "Action manquante"]); exit; }

switch ($action) {
    case 'all': $controller->getAll(); break;
    case 'add': if ($_SERVER['REQUEST_METHOD'] === 'POST') $controller->add(); else echo json_encode(["success" => false, "message" => "POST requis"]); break;
    case 'details': $controller->getDetails(); break;
    case 'details_full': $controller->getDetailsFull(); break;
    case 'list_presence': $controller->listPresence(); break;
    case 'update_presence': if ($_SERVER['REQUEST_METHOD'] === 'POST') $controller->updatePresence(); else echo json_encode(["success" => false, "message" => "POST requis"]); break;
    case 'bulk_update_presence': if ($_SERVER['REQUEST_METHOD'] === 'POST') $controller->bulkUpdatePresence(); else echo json_encode(["success" => false, "message" => "POST requis"]); break;
    case 'export_excel': $controller->exportExcel(); break;
    case 'stats_membre': $controller->getStatsMembre(); break; // NOUVEAU
    case 'delete': if ($_SERVER['REQUEST_METHOD'] === 'DELETE') $controller->delete(); else $controller->delete(); break;
    default: echo json_encode(["success" => false, "message" => "Action inconnue"]); break;
}
