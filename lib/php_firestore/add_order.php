<?php
header('Content-Type: application/json');

$pdo = new PDO('mysql:host=localhost;dbname=smart_cart_db', 'root', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$input = json_decode(file_get_contents('php://input'), true);

if ($input) {
    try {
        try {
            $pdo->exec("ALTER TABLE orders ADD COLUMN user_email VARCHAR(255)");
            $pdo->exec("ALTER TABLE orders ADD COLUMN payment_method VARCHAR(255)");
        } catch(Exception $e) {}

        $stmt = $pdo->prepare("
            INSERT INTO orders (customer_id, user_email, total_amount, payment_method, status, created_at)
            VALUES (:customer_id, :user_email, :total_amount, :payment_method, :status, :created_at)
        ");
        
        $stmt->execute([
            ':customer_id'    => $input['userEmail'] ?? '',
            ':user_email'     => $input['userEmail'] ?? '',
            ':total_amount'   => $input['totalAmount'] ?? 0.0,
            ':payment_method' => $input['paymentMethod'] ?? 'Cash',
            ':status'         => 'Completed',
            ':created_at'     => date('Y-m-d H:i:s')
        ]);
        
        $order_id = $pdo->lastInsertId();
        
        echo json_encode(['success' => true, 'order_id' => (string)$order_id]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'error' => 'Invalid data']);
}
?>
