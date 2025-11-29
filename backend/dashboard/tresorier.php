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

class TresorierController {
    private $db;
    private $categorieId;

    public function __construct() {
        $this->db = (new Database())->getConnection();
        $this->categorieId = $this->getCategorieActivitesGeneratrices();
    }

    /**
     * Récupère ou crée la catégorie "Activités Génératrices"
     */
    private function getCategorieActivitesGeneratrices() {
        $stmt = $this->db->prepare("SELECT id FROM categories WHERE nom = 'Activités Génératrices' LIMIT 1");
        $stmt->execute();
        $id = $stmt->fetchColumn();

        if (!$id) {
            $stmt = $this->db->prepare("
                INSERT INTO categories (nom, type, description) 
                VALUES ('Activités Génératrices', 'recette', 'Revenus et dépenses du trésorier')
            ");
            $stmt->execute();
            $id = $this->db->lastInsertId();
        }

        return $id;
    }

    /**
     * Récupère toutes les opérations du trésorier
     */
    public function getAll() {
        try {
            $stmt = $this->db->prepare("
                SELECT 
                    o.id, o.montant, o.date_operation, o.description, o.type, o.created_at,
                    o.categorie_id, o.membre_id,
                    m.nom as membre_nom, m.prenom as membre_prenom,
                    c.nom as categorie_nom
                FROM operations o
                LEFT JOIN membres m ON o.membre_id = m.id
                LEFT JOIN categories c ON o.categorie_id = c.id
                WHERE o.categorie_id = :cat_id
                ORDER BY o.date_operation DESC, o.created_at DESC
            ");
            
            $stmt->execute([':cat_id' => $this->categorieId]);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            error_log("Erreur getAll: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Calcule les statistiques
     */
    public function getStats() {
        try {
            $operations = $this->getAll();
            
            $totalEntrees = 0;
            $totalSorties = 0;
            
            foreach ($operations as $op) {
                $montant = floatval($op['montant'] ?? 0);
                
                if (in_array($op['type'], ['recette', 'entree'])) {
                    $totalEntrees += $montant;
                } elseif (in_array($op['type'], ['depense', 'sortie'])) {
                    $totalSorties += $montant;
                }
            }

            return [
                'total_entrees' => $totalEntrees,
                'total_sorties' => $totalSorties,
                'benefice' => $totalEntrees - $totalSorties,
                'nombre_operations' => count($operations)
            ];
        } catch (Exception $e) {
            error_log("Erreur getStats: " . $e->getMessage());
            return [
                'total_entrees' => 0,
                'total_sorties' => 0,
                'benefice' => 0,
                'nombre_operations' => 0
            ];
        }
    }

    /**
     * Ajoute une nouvelle opération
     */
    public function add($type, $montant, $dateOperation, $description = null) {
        try {
            $stmt = $this->db->prepare("
                INSERT INTO operations (type, categorie_id, montant, date_operation, description, created_at)
                VALUES (:type, :cat_id, :montant, :date_op, :desc, NOW())
            ");
            
            $success = $stmt->execute([
                ':type' => $type,
                ':cat_id' => $this->categorieId,
                ':montant' => $montant,
                ':date_op' => $dateOperation,
                ':desc' => $description
            ]);

            if ($success) {
                return [
                    'success' => true,
                    'message' => 'Opération ajoutée avec succès',
                    'id' => $this->db->lastInsertId()
                ];
            }

            return ['success' => false, 'message' => 'Échec de l\'ajout'];
        } catch (Exception $e) {
            error_log("Erreur add: " . $e->getMessage());
            return ['success' => false, 'message' => 'Erreur: ' . $e->getMessage()];
        }
    }

    /**
     * Modifie une opération existante
     */
    public function update($id, $type, $montant, $dateOperation, $description = null) {
        try {
            // Vérifier que l'opération appartient bien à la catégorie Activités Génératrices
            $stmtCheck = $this->db->prepare("SELECT id FROM operations WHERE id = :id AND categorie_id = :cat_id");
            $stmtCheck->execute([':id' => $id, ':cat_id' => $this->categorieId]);
            
            if (!$stmtCheck->fetch()) {
                return ['success' => false, 'message' => 'Opération non trouvée ou non autorisée'];
            }

            $stmt = $this->db->prepare("
                UPDATE operations 
                SET type = :type, montant = :montant, date_operation = :date_op, description = :desc
                WHERE id = :id AND categorie_id = :cat_id
            ");
            
            $success = $stmt->execute([
                ':id' => $id,
                ':type' => $type,
                ':cat_id' => $this->categorieId,
                ':montant' => $montant,
                ':date_op' => $dateOperation,
                ':desc' => $description
            ]);

            if ($success) {
                return ['success' => true, 'message' => 'Opération modifiée avec succès'];
            }

            return ['success' => false, 'message' => 'Échec de la modification'];
        } catch (Exception $e) {
            error_log("Erreur update: " . $e->getMessage());
            return ['success' => false, 'message' => 'Erreur: ' . $e->getMessage()];
        }
    }

    /**
     * Supprime une opération
     */
    public function delete($id) {
        try {
            $stmt = $this->db->prepare("
                DELETE FROM operations 
                WHERE id = :id AND categorie_id = :cat_id
            ");
            
            $success = $stmt->execute([':id' => $id, ':cat_id' => $this->categorieId]);

            if ($success && $stmt->rowCount() > 0) {
                return ['success' => true, 'message' => 'Opération supprimée avec succès'];
            }

            return ['success' => false, 'message' => 'Opération non trouvée'];
        } catch (Exception $e) {
            error_log("Erreur delete: " . $e->getMessage());
            return ['success' => false, 'message' => 'Erreur: ' . $e->getMessage()];
        }
    }

    /**
     * Récupère l'ID de la catégorie
     */
    public function getCategorieId() {
        return $this->categorieId;
    }
}

// Traitement de la requête
try {
    $controller = new TresorierController();
    $action = $_GET['action'] ?? 'dashboard';

    switch ($action) {
        case 'dashboard':
            $operations = $controller->getAll();
            $stats = $controller->getStats();
            
            echo json_encode([
                'success' => true,
                'data' => [
                    'operations' => $operations,
                    'stats' => $stats,
                    'categorie_id' => $controller->getCategorieId()
                ]
            ], JSON_NUMERIC_CHECK | JSON_UNESCAPED_UNICODE);
            break;

        case 'add':
            $input = json_decode(file_get_contents('php://input'), true);
            $result = $controller->add(
                $input['type'] ?? 'recette',
                $input['montant'] ?? 0,
                $input['date_operation'] ?? date('Y-m-d'),
                $input['description'] ?? null
            );
            echo json_encode($result, JSON_UNESCAPED_UNICODE);
            break;

        case 'update':
            $input = json_decode(file_get_contents('php://input'), true);
            $result = $controller->update(
                $input['id'] ?? 0,
                $input['type'] ?? 'recette',
                $input['montant'] ?? 0,
                $input['date_operation'] ?? date('Y-m-d'),
                $input['description'] ?? null
            );
            echo json_encode($result, JSON_UNESCAPED_UNICODE);
            break;

        case 'delete':
            $id = $_GET['id'] ?? $_POST['id'] ?? 0;
            $result = $controller->delete($id);
            echo json_encode($result, JSON_UNESCAPED_UNICODE);
            break;

        default:
            echo json_encode(['success' => false, 'message' => 'Action inconnue'], JSON_UNESCAPED_UNICODE);
    }

} catch (Exception $e) {
    error_log("Erreur tresorier.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
