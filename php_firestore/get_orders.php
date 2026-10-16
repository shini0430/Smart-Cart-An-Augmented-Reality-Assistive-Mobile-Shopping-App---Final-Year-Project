<?php
header('Content-Type: application/json');

$pdo = new PDO('mysql:host=localhost;dbname=smart_cart_db', 'root', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$user_email = $_GET['email'] ?? '';

if ($user_email) {
    try {
        $stmt = $pdo->prepare("SELECT * FROM orders WHERE user_email = :email OR customer_id = :email ORDER BY created_at DESC");
        $stmt->execute([':email' => $user_email]);
        
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode(['success' => true, 'orders' => $orders]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'error' => 'Email required']);
}
?>
