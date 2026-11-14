<?php
// Перенос записей клиентов со старых услуг на новые из Excel и удаление старых услуг.
// php svc_move_old.php          — пробный: показывает, какие записи и куда переедут
// php svc_move_old.php --apply  — переносит записи и удаляет старые услуги
$apply = in_array('--apply', $argv, true);
define('AG_SERVICE_INTERNAL', true);
$key = trim((string)require '/home/khakimjon/web/job.autogrom.ru/public_html/ag_service_bridge_secret.php');
const BASE = 'https://api.autogrom-group.com/api/business/job-bridge/';
function req($m, $p, $body = null) {
    global $key;
    $c = curl_init(BASE . $p);
    $h = ['Accept: application/json', 'X-AG-Job-Key: ' . $key];
    if ($body !== null) { $h[] = 'Content-Type: application/json'; curl_setopt($c, CURLOPT_POSTFIELDS, json_encode($body)); }
    curl_setopt_array($c, [CURLOPT_RETURNTRANSFER => 1, CURLOPT_CUSTOMREQUEST => $m, CURLOPT_HTTPHEADER => $h, CURLOPT_TIMEOUT => 30]);
    $r = curl_exec($c); $code = curl_getinfo($c, CURLINFO_HTTP_CODE); curl_close($c);
    return [$code, json_decode((string)$r, true), (string)$r];
}
function multi_get(array $paths) {
    global $key; $out = [];
    foreach (array_chunk($paths, 20, true) as $chunk) {
        $mh = curl_multi_init(); $hs = [];
        foreach ($chunk as $k => $p) {
            $c = curl_init(BASE . $p);
            curl_setopt_array($c, [CURLOPT_RETURNTRANSFER => 1, CURLOPT_HTTPHEADER => ['X-AG-Job-Key: ' . $key], CURLOPT_TIMEOUT => 30]);
            curl_multi_add_handle($mh, $c); $hs[$k] = $c;
        }
        do { $st = curl_multi_exec($mh, $run); if ($run) curl_multi_select($mh, 1); } while ($run && $st == CURLM_OK);
        foreach ($hs as $k => $c) { $out[$k] = json_decode((string)curl_multi_getcontent($c), true); curl_multi_remove_handle($mh, $c); curl_close($c); }
        curl_multi_close($mh);
    }
    return $out;
}
function norm($t) { return preg_replace('/[^а-яa-z0-9 ]/u', '', mb_strtolower(str_replace('ё', 'е', $t))); }

$keep = [];
foreach (json_decode(file_get_contents(__DIR__ . '/catalog_import.json'), true)['items'] as $i) $keep[mb_strtolower(trim($i['title']))] = 1;
[$code, $d] = req('GET', 'services-admin');
$all = $d['services'] ?? [];
if (count($all) < 300) { echo "Список услуг не получен ($code)\n"; return; }
$new = []; $old = [];
$oldByTitle = [];
foreach ($all as $s) { if (isset($keep[mb_strtolower(trim($s['title']))])) $new[] = $s; else { $old[$s['id']] = $s; $oldByTitle[mb_strtolower(trim($s['title']))] = $s['id']; } }
echo "Новых услуг: " . count($new) . ", старых: " . count($old) . "\n";

// подбор новой услуги для каждой старой
function target($s, $new) {
    $best = null; $bs = -1; $a = norm($s['title']);
    foreach ($new as $n) { similar_text($a, norm($n['title']), $p); if ($p > $bs) { $bs = $p; $best = $n; } }
    return [$best, round($bs)];
}

// записи клиентов: по каждому мастеру и дню
[$c2, $sp] = req('GET', 'specialists-admin');
$specs = $sp['specialists'] ?? $sp['data'] ?? [];
$paths = [];
$from = strtotime('2026-01-01'); $to = strtotime('+180 days');
foreach ($specs as $m) for ($t = $from; $t <= $to; $t += 86400) $paths[$m['id'] . date('Ymd', $t)] = 'bookings?specialist_id=' . $m['id'] . '&date=' . date('Y-m-d', $t);
echo "Мастеров: " . count($specs) . ", проверяю дней: " . count($paths) . " (пара минут)...\n";
$found = [];
foreach (multi_get($paths) as $r) foreach (($r['bookings'] ?? $r['data'] ?? []) as $b) {
    $sid = $oldByTitle[mb_strtolower(trim((string)($b['service_name'] ?? '')))] ?? null;
    if ($sid && isset($old[$sid])) $found[$b['id']] = $b + ['_sid' => $sid];
}
echo "Записей на старые услуги: " . count($found) . "\n";
$map = [];
foreach ($found as $b) {
    $sid = $b['_sid'];
    if (isset($map[$sid]) === false) $map[$sid] = target($old[$sid], $new);
    [$t, $p] = $map[$sid];
    echo "  " . substr($b['scheduled_at'], 0, 10) . " " . ($b['customer_name'] ?? '') . ": «" . $old[$sid]['title'] . "» → «" . $t['title'] . "» ($p%)" . ($b['status'] === 'cancelled' ? " [отменена]" : "") . "\n";
}
if ($apply === false) { echo "\nПробный режим. Для переноса и удаления: php svc_move_old.php --apply\n"; return; }

file_put_contents('/root/svc_backup_before_move_' . date('Ymd_His') . '.json', json_encode(['services' => $all, 'bookings' => array_values($found)], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
$moved = 0; $fail = [];
foreach ($found as $b) {
    [$t] = $map[$b['_sid']];
    [$c, , $raw] = req('PATCH', 'bookings/' . $b['id'], ['service_id' => $t['id']]);
    if ($c < 300) $moved++; else $fail[] = $b['id'] . " ($c): " . substr($raw, 0, 100);
}
echo "Перенесено записей: $moved, не удалось: " . count($fail) . "\n" . implode("\n", $fail) . "\n";
$del = 0; $left = [];
foreach ($old as $s) { [$c, , $raw] = req('DELETE', 'services-admin/' . $s['id']); if ($c < 300) $del++; else $left[] = $s['title'] . " ($c)"; }
@array_map('unlink', glob('/home/khakimjon/web/job.autogrom.ru/private/ag_cache/svc_*.json'));
echo "Удалено старых услуг: $del, осталось: " . count($left) . "\n" . implode("\n", $left) . "\n";
