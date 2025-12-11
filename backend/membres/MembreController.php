<?php
// ======================================================
//   CONTROLLER MEMBRES – VERSION COMPLÈTE AVEC UPDATE
// ======================================================

ini_set('display_errors', 1);
error_reporting(E_ALL);

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../config/database.php';

class MembreController {
    private $db;

    public function __construct() {
        try {
            $this->db = (new Database())->getConnection();
        } catch (Exception $e) {
            $this->sendError(500, "Erreur de connexion à la base de données: " . $e->getMessage());
        }
    }

    private function sendError($code, $message) {
        http_response_code($code);
        echo json_encode([
            "success" => false,
            "message" => $message
        ]);
        exit();
    }

    private function sendSuccess($data = null, $message = "") {
        $response = ["success" => true];
        if ($message) $response["message"] = $message;
        if ($data) $response["data"] = $data;
        
        http_response_code(200);
        echo json_encode($response);
        exit();
    }

    // ------------------------------------------------------
    // GET ALL - Sans le PIN pour la sécurité
    // ------------------------------------------------------
    public function getAll() {
        try {
            $stmt = $this->db->prepare("
                SELECT 
                    id,
                    username,
                    nom,
                    prenom,
                    nom_complet,
                    telephone,
                    role,
                    statut,
                    est_membre_bureau,
                    date_adhesion,
                    date_debut_arriere,
                    statut_arriere,
                    montant_arriere
                FROM membres
                WHERE statut = 'actif'
                ORDER BY nom ASC, prenom ASC
            ");

            $stmt->execute();
            $members = $stmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                "success" => true,
                "data" => [
                    "membres" => $members,
                    "count"   => count($members)
                ]
            ]);

        } catch (Exception $e) {
            echo json_encode([
                "success" => false, 
                "message" => "Erreur lors de la récupération des membres: " . $e->getMessage()
            ]);
        }
    }

    // ------------------------------------------------------
    // GET ONE - Sans le PIN pour la sécurité
    // ------------------------------------------------------
    public function getMembre($id) {
        try {
            if (empty($id) || !is_numeric($id) || $id <= 0) {
                echo json_encode([
                    "success" => false,
                    "message" => "ID de membre invalide"
                ]);
                return;
            }

            $stmt = $this->db->prepare("
                SELECT 
                    id,
                    username,
                    nom,
                    prenom,
                    nom_complet,
                    telephone,
                    role,
                    statut,
                    est_membre_bureau,
                    date_adhesion,
                    date_debut_arriere,
                    statut_arriere,
                    montant_arriere
                FROM membres 
                WHERE id = :id 
                LIMIT 1
            ");
            
            $stmt->execute([':id' => intval($id)]);
            $membre = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$membre) {
                echo json_encode([
                    "success" => false, 
                    "message" => "Membre introuvable avec l'ID: " . $id
                ]);
                return;
            }

            echo json_encode([
                "success" => true,
                "data" => [
                    "membre" => $membre
                ]
            ]);

        } catch (Exception $e) {
            echo json_encode([
                "success" => false, 
                "message" => "Erreur serveur: " . $e->getMessage()
            ]);
        }
    }

    // ------------------------------------------------------
    // GET PIN - Méthode SÉCURISÉE pour récupérer uniquement le PIN
    // ------------------------------------------------------
    public function getPin($id) {
        try {
            if (empty($id) || !is_numeric($id) || $id <= 0) {
                echo json_encode([
                    "success" => false,
                    "message" => "ID de membre invalide"
                ]);
                return;
            }

            $stmt = $this->db->prepare("
                SELECT code_pin
                FROM membres 
                WHERE id = :id 
                LIMIT 1
            ");
            
            $stmt->execute([':id' => intval($id)]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$result || !isset($result['code_pin'])) {
                echo json_encode([
                    "success" => false, 
                    "message" => "Membre introuvable ou PIN non défini"
                ]);
                return;
            }

            echo json_encode([
                "success" => true,
                "data" => [
                    "code_pin" => $result['code_pin']
                ]
            ]);

        } catch (Exception $e) {
            echo json_encode([
                "success" => false, 
                "message" => "Erreur serveur: " . $e->getMessage()
            ]);
        }
    }

    // ------------------------------------------------------
    // GET BUREAU MEMBERS - NOUVELLE MÉTHODE
    // ------------------------------------------------------
    public function getBureauMembers() {
        try {
            $stmt = $this->db->prepare("
                SELECT 
                    id,
                    username,
                    nom,
                    prenom,
                    nom_complet,
                    telephone,
                    role,
                    statut
                FROM membres
                WHERE est_membre_bureau = TRUE AND statut = 'actif'
                ORDER BY nom ASC, prenom ASC
            ");

            $stmt->execute();
            $members = $stmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                "success" => true,
                "data" => [
                    "membres" => $members,
                    "count"   => count($members)
                ]
            ]);

        } catch (Exception $e) {
            echo json_encode([
                "success" => false, 
                "message" => "Erreur lors de la récupération des membres du bureau: " . $e->getMessage()
            ]);
        }
    }

    // ------------------------------------------------------
    // CREATE
    // ------------------------------------------------------
    public function create() {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            
            if (json_last_error() !== JSON_ERROR_NONE) {
                echo json_encode([
                    "success" => false,
                    "message" => "Données JSON invalides"
                ]);
                return;
            }

            if (!isset($data["username"]) || !isset($data["nom"]) || 
                !isset($data["prenom"]) || !isset($data["code_pin"])) {
                echo json_encode([
                    "success" => false,
                    "message" => "Champs obligatoires manquants"
                ]);
                return;
            }

            if (strlen($data["code_pin"]) != 4 || !is_numeric($data["code_pin"])) {
                echo json_encode([
                    "success" => false,
                    "message" => "Le code PIN doit contenir exactement 4 chiffres"
                ]);
                return;
            }

            $nom_complet = trim($data["prenom"] . " " . $data["nom"]);
            $statut_arriere = empty($data["date_debut_arriere"]) ? "a_jour" : "en_arriere";

            $stmt = $this->db->prepare("
                INSERT INTO membres (
                    username, nom, prenom, nom_complet, telephone, code_pin, 
                    role, statut, est_membre_bureau, date_adhesion, date_debut_arriere, 
                    statut_arriere, montant_arriere
                ) VALUES (
                    :username, :nom, :prenom, :nom_complet, :telephone, :code_pin,
                    :role, :statut, :est_membre_bureau, NOW(), :date_debut_arriere,
                    :statut_arriere, :montant_arriere
                )
            ");

            $result = $stmt->execute([
                ':username' => trim($data["username"]),
                ':nom' => trim($data["nom"]),
                ':prenom' => trim($data["prenom"]),
                ':nom_complet' => $nom_complet,
                ':telephone' => $data["telephone"] ?? null,
                ':code_pin' => $data["code_pin"],
                ':role' => $data["role"] ?? "membre",
                ':statut' => $data["statut"] ?? "actif",
                ':est_membre_bureau' => isset($data["est_membre_bureau"]) ? ($data["est_membre_bureau"] ? 1 : 0) : 0,
                ':date_debut_arriere' => $data["date_debut_arriere"] ?? null,
                ':statut_arriere' => $statut_arriere,
                ':montant_arriere' => floatval($data["montant_arriere"] ?? 0.00)
            ]);

            if ($result) {
                $newId = $this->db->lastInsertId();
                http_response_code(201);
                echo json_encode([
                    "success" => true,
                    "data" => [
                        "id" => $newId,
                        "nom_complet" => $nom_complet
                    ],
                    "message" => "Membre créé avec succès"
                ]);
            } else {
                echo json_encode([
                    "success" => false,
                    "message" => "Erreur lors de la création du membre"
                ]);
            }

        } catch (Exception $e) {
            echo json_encode([
                "success" => false,
                "message" => "Erreur: " . $e->getMessage()
            ]);
        }
    }

    // ------------------------------------------------------
    // UPDATE - NOUVELLE MÉTHODE AJOUTÉE
    // ------------------------------------------------------
    public function update() {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            
            if (json_last_error() !== JSON_ERROR_NONE) {
                echo json_encode([
                    "success" => false,
                    "message" => "Données JSON invalides"
                ]);
                return;
            }

            if (!isset($data["id"])) {
                echo json_encode([
                    "success" => false,
                    "message" => "ID du membre manquant"
                ]);
                return;
            }

            // Vérifier si le membre existe
            $checkStmt = $this->db->prepare("SELECT id FROM membres WHERE id = :id");
            $checkStmt->execute([':id' => intval($data["id"])]);
            if (!$checkStmt->fetch()) {
                echo json_encode([
                    "success" => false,
                    "message" => "Membre introuvable"
                ]);
                return;
            }

            // Construction dynamique de la requête UPDATE
            $fields = [];
            $params = [':id' => intval($data["id"])];

            // Champs autorisés à mettre à jour
            $allowedFields = [
                'username', 'nom', 'prenom', 'telephone', 'role', 'statut',
                'date_debut_arriere', 'statut_arriere', 'montant_arriere'
            ];

            foreach ($allowedFields as $field) {
                if (isset($data[$field])) {
                    $fields[] = "$field = :$field";
                    $params[":$field"] = $data[$field];
                }
            }

            // NOUVEAU : Gérer est_membre_bureau
            if (isset($data['est_membre_bureau'])) {
                $fields[] = "est_membre_bureau = :est_membre_bureau";
                $params[':est_membre_bureau'] = $data['est_membre_bureau'] ? 1 : 0;
            }

            // Mettre à jour nom_complet si nom ou prenom est modifié
            if (isset($data['nom']) || isset($data['prenom'])) {
                $nom = $data['nom'] ?? '';
                $prenom = $data['prenom'] ?? '';
                $nom_complet = trim($prenom . ' ' . $nom);
                $fields[] = "nom_complet = :nom_complet";
                $params[':nom_complet'] = $nom_complet;
            }

            if (empty($fields)) {
                echo json_encode([
                    "success" => false,
                    "message" => "Aucune donnée à mettre à jour"
                ]);
                return;
            }

            $sql = "UPDATE membres SET " . implode(', ', $fields) . " WHERE id = :id";
            $stmt = $this->db->prepare($sql);
            $result = $stmt->execute($params);

            if ($result && $stmt->rowCount() > 0) {
                echo json_encode([
                    "success" => true,
                    "message" => "Membre mis à jour avec succès"
                ]);
            } else {
                echo json_encode([
                    "success" => false,
                    "message" => "Aucune modification effectuée"
                ]);
            }

        } catch (Exception $e) {
            echo json_encode([
                "success" => false,
                "message" => "Erreur lors de la mise à jour: " . $e->getMessage()
            ]);
        }
    }

    // ------------------------------------------------------
    // UPDATE PIN
    // ------------------------------------------------------
    public function updatePin() {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            
            if (json_last_error() !== JSON_ERROR_NONE) {
                echo json_encode([
                    "success" => false,
                    "message" => "Données JSON invalides"
                ]);
                return;
            }

            if (!isset($data["id"]) || !isset($data["code_pin"])) {
                echo json_encode([
                    "success" => false,
                    "message" => "ID et code PIN manquants"
                ]);
                return;
            }

            if (strlen($data["code_pin"]) != 4 || !is_numeric($data["code_pin"])) {
                echo json_encode([
                    "success" => false,
                    "message" => "Le code PIN doit contenir exactement 4 chiffres"
                ]);
                return;
            }

            $stmt = $this->db->prepare("UPDATE membres SET code_pin = :code_pin WHERE id = :id");
            $result = $stmt->execute([
                ':code_pin' => $data["code_pin"],
                ':id' => intval($data["id"])
            ]);

            if ($result && $stmt->rowCount() > 0) {
                echo json_encode([
                    "success" => true,
                    "message" => "Code PIN mis à jour avec succès"
                ]);
            } else {
                echo json_encode([
                    "success" => false,
                    "message" => "Membre non trouvé ou aucune modification effectuée"
                ]);
            }

        } catch (Exception $e) {
            echo json_encode([
                "success" => false,
                "message" => "Erreur: " . $e->getMessage()
            ]);
        }
    }

    // ------------------------------------------------------
    // DELETE
    // ------------------------------------------------------
    public function delete() {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            
            if (json_last_error() !== JSON_ERROR_NONE) {
                echo json_encode([
                    "success" => false,
                    "message" => "Données JSON invalides"
                ]);
                return;
            }

            if (!isset($data["id"])) {
                echo json_encode([
                    "success" => false,
                    "message" => "ID du membre manquant"
                ]);
                return;
            }

            $stmt = $this->db->prepare("DELETE FROM membres WHERE id = :id");
            $result = $stmt->execute([':id' => intval($data["id"])]);

            if ($result && $stmt->rowCount() > 0) {
                echo json_encode([
                    "success" => true,
                    "message" => "Membre supprimé avec succès"
                ]);
            } else {
                echo json_encode([
                    "success" => false,
                    "message" => "Membre non trouvé"
                ]);
            }

        } catch (Exception $e) {
            echo json_encode([
                "success" => false,
                "message" => "Erreur: " . $e->getMessage()
            ]);
        }
    }
}

// ======================================================
//   ROUTEUR COMPLET
// ======================================================

try {
    $controller = new MembreController();
    $action = $_GET["action"] ?? null;

    if (!$action) {
        echo json_encode([
            "success" => false, 
            "message" => "Paramètre 'action' manquant"
        ]);
        exit;
    }

    switch ($action) {
        case "all":
            if ($_SERVER["REQUEST_METHOD"] === "GET") {
                $controller->getAll();
            } else {
                http_response_code(405);
                echo json_encode(["success" => false, "message" => "Méthode GET requise"]);
            }
            break;

        case "get":
            if ($_SERVER["REQUEST_METHOD"] === "GET" && isset($_GET["id"])) {
                $id = $_GET["id"];
                $controller->getMembre($id);
            } else {
                http_response_code(400);
                echo json_encode(["success" => false, "message" => "Paramètre 'id' manquant"]);
            }
            break;

        case "get_pin":
            if ($_SERVER["REQUEST_METHOD"] === "GET" && isset($_GET["id"])) {
                $id = $_GET["id"];
                $controller->getPin($id);
            } else {
                http_response_code(400);
                echo json_encode(["success" => false, "message" => "Paramètre 'id' manquant"]);
            }
            break;

        case "get_bureau_members":
            if ($_SERVER["REQUEST_METHOD"] === "GET") {
                $controller->getBureauMembers();
            } else {
                http_response_code(405);
                echo json_encode(["success" => false, "message" => "Méthode GET requise"]);
            }
            break;

        case "create":
            if ($_SERVER["REQUEST_METHOD"] === "POST") {
                $controller->create();
            } else {
                http_response_code(405);
                echo json_encode(["success" => false, "message" => "Méthode POST requise"]);
            }
            break;

        case "update":
            if ($_SERVER["REQUEST_METHOD"] === "POST") {
                $controller->update();
            } else {
                http_response_code(405);
                echo json_encode(["success" => false, "message" => "Méthode POST requise"]);
            }
            break;

        case "update_pin":
            if ($_SERVER["REQUEST_METHOD"] === "POST") {
                $controller->updatePin();
            } else {
                http_response_code(405);
                echo json_encode(["success" => false, "message" => "Méthode POST requise"]);
            }
            break;

        case "delete":
            if ($_SERVER["REQUEST_METHOD"] === "POST") {
                $controller->delete();
            } else {
                http_response_code(405);
                echo json_encode(["success" => false, "message" => "Méthode POST requise"]);
            }
            break;

        default:
            http_response_code(404);
            echo json_encode(["success" => false, "message" => "Action inconnue: $action"]);
            break;
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false, 
        "message" => "Erreur serveur: " . $e->getMessage()
    ]);
}
