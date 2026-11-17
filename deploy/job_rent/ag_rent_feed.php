<?php
/* AG_RENT1 — список машин «AG Гараж» для приложения AG Service (без авторизации).
 * Показываются свободные машины и машины в аренде (с пометкой); скрытые и на ремонте — нет.
 * Госномер наружу не отдаём.
 */
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Cache-Control: no-cache, max-age=0');

try {
    require_once __DIR__ . '/config.php';
    require_once __DIR__ . '/includes/ag_rent_lib.php';
    if (!isset($pdo) || !($pdo instanceof PDO)) throw new RuntimeException('db');
    ag_rent_table($pdo);
    $rows = $pdo->query("SELECT * FROM ag_rent_cars WHERE status IN ('available','rented') ORDER BY status='rented', sort_order, id DESC")->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode([
        'ok' => true,
        'classes' => AG_RENT_CLASSES,
        'cars' => array_map('ag_rent_public', $rows),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('AG RENT feed: ' . $e->getMessage());
    http_response_code(500);
    echo '{"ok":false,"cars":[]}';
}
