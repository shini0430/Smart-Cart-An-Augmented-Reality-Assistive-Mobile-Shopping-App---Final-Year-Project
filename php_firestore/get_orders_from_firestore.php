<?php
// ================================================================
//  get_orders_from_firestore.php
//  Reads orders from Firebase Firestore and shows them in PHP.
//  Put this file in: C:\xampp\htdocs\smart_cart_backend\
// ================================================================

header('Content-Type: application/json');

// ---------------------------------------------------------------
// 1. YOUR FIREBASE PROJECT ID
//    Find it: Firebase Console -> Project Settings -> General
// ---------------------------------------------------------------
$projectId = 'smart-cart-90f77';

// ---------------------------------------------------------------
// 2. FIRESTORE REST API URL
//    No login needed if Firestore rules allow read.
//    (See bottom of this file to make Firestore publicly readable)
// ---------------------------------------------------------------
$collection = 'orders';
$url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/{$collection}";

// ---------------------------------------------------------------
// 3. FETCH FROM FIRESTORE
// ---------------------------------------------------------------
$response = @file_get_contents($url);

if ($response === false) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Could not connect to Firestore. Check your internet or Firestore rules.']);
    exit;
}

$data = json_decode($response, true);

if (!isset($data['documents'])) {
    echo json_encode(['success' => true, 'count' => 0, 'orders' => []]);
    exit;
}

// ---------------------------------------------------------------
// 4. PARSE FIRESTORE DOCUMENTS INTO SIMPLE PHP ARRAY
// ---------------------------------------------------------------
$orders = [];

foreach ($data['documents'] as $doc) {
    $fields = $doc['fields'] ?? [];

    // Helper: extract value from Firestore field type
    $get = function($field) {
        if (!$field) return null;
        return $field['stringValue']
            ?? $field['doubleValue']
            ?? $field['integerValue']
            ?? $field['booleanValue']
            ?? $field['timestampValue']
            ?? null;
    };

    // Parse items array
    $items = [];
    if (isset($fields['items']['arrayValue']['values'])) {
        foreach ($fields['items']['arrayValue']['values'] as $itemVal) {
            $itemFields = $itemVal['mapValue']['fields'] ?? [];
            $items[] = [
                'name'     => $itemFields['name']['stringValue'] ?? '',
                'price'    => $itemFields['price']['doubleValue'] ?? $itemFields['price']['integerValue'] ?? 0,
                'quantity' => $itemFields['quantity']['integerValue'] ?? 1,
            ];
        }
    }

    $orders[] = [
        'order_id'       => basename($doc['name']),   // Firestore document ID
        'user_id'        => $get($fields['userId'] ?? null),
        'user_email'     => $get($fields['userEmail'] ?? null),
        'total_amount'   => $get($fields['totalAmount'] ?? null),
        'payment_method' => $get($fields['paymentMethod'] ?? null),
        'status'         => $get($fields['status'] ?? null),
        'timestamp'      => $get($fields['timestamp'] ?? null),
        'items'          => $items,
    ];
}

// ---------------------------------------------------------------
// 5. OUTPUT AS JSON (or save to MySQL — see below)
// ---------------------------------------------------------------
echo json_encode([
    'success' => true,
    'count'   => count($orders),
    'orders'  => $orders,
], JSON_PRETTY_PRINT);


// ================================================================
//  HOW TO ALSO SAVE TO MYSQL
//  Uncomment this block if you want to insert into MySQL too.
// ================================================================
$pdo = new PDO('mysql:host=localhost;dbname=smart_cart', 'root', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

foreach ($orders as $order) {
    // Insert order
    $stmt = $pdo->prepare("
        INSERT IGNORE INTO orders (order_id, user_email, total_amount, payment_method, status, created_at)
        VALUES (:order_id, :user_email, :total_amount, :payment_method, :status, :created_at)
    ");
    $stmt->execute([
        ':order_id'       => $order['order_id'],
        ':user_email'     => $order['user_email'],
        ':total_amount'   => $order['total_amount'],
        ':payment_method' => $order['payment_method'],
        ':status'         => $order['status'],
        ':created_at'     => $order['timestamp'],
    ]);
}


// ================================================================
//  FIRESTORE RULES — Allow public read (for testing)
//  In Firebase Console -> Firestore -> Rules, set:
//
//  rules_version = '2';
//  service cloud.firestore {
//    match /databases/{database}/documents {
//      match /orders/{orderId} {
//        allow read: if true;   // allow public read
//        allow write: if request.auth != null;
//      }
//    }
//  }
// ================================================================
