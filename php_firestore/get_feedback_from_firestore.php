<?php
// ================================================================
//  get_feedback_from_firestore.php
//  Reads feedback from Firebase Firestore and shows them in PHP.
//  Put this file in: C:\xampp\htdocs\smart_cart_backend\
// ================================================================

header('Content-Type: application/json');

$projectId  = 'smart-cart-90f77';
$collection = 'feedback';
$url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/{$collection}";

$response = @file_get_contents($url);

if ($response === false) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Could not connect to Firestore.']);
    exit;
}

$data = json_decode($response, true);

if (!isset($data['documents'])) {
    echo json_encode(['success' => true, 'count' => 0, 'feedback' => []]);
    exit;
}

$feedbackList = [];

foreach ($data['documents'] as $doc) {
    $fields = $doc['fields'] ?? [];
    $feedbackList[] = [
        'id'           => basename($doc['name']),
        'message'      => $fields['message']['stringValue'] ?? $fields['comment']['stringValue'] ?? '',
        'user_uid'     => $fields['user_uid']['stringValue'] ?? $fields['userId']['stringValue'] ?? '',
        'user_email'   => $fields['user_email']['stringValue'] ?? $fields['email']['stringValue'] ?? '',
        'submitted_at' => $fields['submitted_at']['timestampValue'] ?? $fields['timestamp']['timestampValue'] ?? '',
        'rating'       => $fields['rating']['integerValue'] ?? $fields['rating']['doubleValue'] ?? null,
    ];
}

echo json_encode([
    'success'  => true,
    'count'    => count($feedbackList),
    'feedback' => $feedbackList,
], JSON_PRETTY_PRINT);

// ================================================================
//  HOW TO ALSO SAVE TO MYSQL
// ================================================================
$pdo = new PDO('mysql:host=localhost;dbname=smart_cart', 'root', '');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

foreach ($feedbackList as $fb) {
    $stmt = $pdo->prepare("
        INSERT IGNORE INTO feedback (id, message, user_uid, user_email, rating, submitted_at)
        VALUES (:id, :message, :user_uid, :user_email, :rating, :submitted_at)
    ");
    $stmt->execute([
        ':id'           => $fb['id'],
        ':message'      => $fb['message'],
        ':user_uid'     => $fb['user_uid'],
        ':user_email'   => $fb['user_email'],
        ':rating'       => $fb['rating'],
        ':submitted_at' => $fb['submitted_at'],
    ]);
}
