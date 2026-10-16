<?php
header('Content-Type: application/json');

$pdo = new PDO('mysql:host=localhost;dbname=smart_cart_db', 'root', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$input = json_decode(file_get_contents('php://input'), true);

if ($input) {
    try {
        $stmt = $pdo->prepare("
            INSERT INTO feedback (id, message, user_uid, user_email, rating, submitted_at)
            VALUES (:id, :message, :user_uid, :user_email, :rating, :submitted_at)
        ");
        
        $stmt->execute([
            ':id'           => uniqid('FB_'),
            ':message'      => $input['message'] ?? '',
            ':user_uid'     => $input['user_uid'] ?? '',
            ':user_email'   => $input['user_email'] ?? '',
            ':rating'       => 0,
            ':submitted_at' => date('Y-m-d H:i:s')
        ]);
        
        echo json_encode(['success' => true]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'error' => 'Invalid data']);
}
?>
