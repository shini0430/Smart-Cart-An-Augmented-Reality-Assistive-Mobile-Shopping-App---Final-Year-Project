<?php
// ================================================================
//  get_users_from_firestore.php
//  Reads user profiles from Firebase Firestore.
//  Put this file in: C:\xampp\htdocs\smart_cart_backend\
// ================================================================

header('Content-Type: application/json');

$projectId  = 'smart-cart-90f77';
$collection = 'users';
$url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/{$collection}";

$response = @file_get_contents($url);

if ($response === false) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Could not connect to Firestore.']);
    exit;
}

$data = json_decode($response, true);

if (!isset($data['documents'])) {
    echo json_encode(['success' => true, 'count' => 0, 'users' => []]);
    exit;
}

$users = [];

foreach ($data['documents'] as $doc) {
    $fields = $doc['fields'] ?? [];
    $users[] = [
        'uid'         => $fields['uid']['stringValue'] ?? basename($doc['name']),
        'name'        => $fields['name']['stringValue'] ?? '',
        'email'       => $fields['email']['stringValue'] ?? '',
        'phone'       => $fields['phone']['stringValue'] ?? $fields['phoneNumber']['stringValue'] ?? '',
        'address'     => $fields['address']['stringValue'] ?? '',
        'registered'  => $fields['registered_at']['timestampValue'] ?? '',
    ];
}

echo json_encode([
    'success' => true,
    'count'   => count($users),
    'users'   => $users,
], JSON_PRETTY_PRINT);

// ================================================================
//  HOW TO ALSO SAVE TO MYSQL
// ================================================================
$pdo = new PDO('mysql:host=localhost;dbname=smart_cart', 'root', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

foreach ($users as $user) {
    $stmt = $pdo->prepare("
        INSERT IGNORE INTO users (uid, name, email, phone, address, registered_at)
        VALUES (:uid, :name, :email, :phone, :address, :registered_at)
    ");
    $stmt->execute([
        ':uid'           => $user['uid'],
        ':name'          => $user['name'],
        ':email'         => $user['email'],
        ':phone'         => $user['phone'],
        ':address'       => $user['address'],
        ':registered_at' => $user['registered'],
    ]);
}
