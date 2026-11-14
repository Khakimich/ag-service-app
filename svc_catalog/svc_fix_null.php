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


// записи, у которых пропала услуга (service_name = NULL) → привязать к новой услуге по названию из журнала сайта
include '/home/khakimjon/web/job.autogrom.ru/public_html/vendor/config.php';
$db = null; foreach (get_defined_vars() as $v) if ($v instanceof PDO) { $db = $v; break; }
$local = [];
foreach ($db->query("SELECT booking_id, title FROM ag_mb_booking_services ORDER BY pos DESC")->fetchAll(PDO::FETCH_ASSOC) as $r) $local[$r['booking_id']] = $r['title'];
$bk = json_decode(@file_get_contents('/root/svc_backup_20261114_062549.json'), true) ?: [];
[$code, $d] = req('GET', 'services-admin'); $new = $d['services'] ?? [];
function best($title, $new) { $b = null; $bs = -1; foreach ($new as $n) { similar_text(norm($title), norm($n['title']), $p); if ($p > $bs) { $bs = $p; $b = $n; } } return [$b, round($bs)]; }
[$c2, $sp] = req('GET', 'specialists-admin'); $specs = $sp['specialists'] ?? [];
$paths = []; $from = strtotime('2026-01-01'); $to = strtotime('+180 days');
foreach ($specs as $m) for ($t = $from; $t <= $to; $t += 86400) $paths[$m['id'] . date('Ymd', $t)] = 'bookings?specialist_id=' . $m['id'] . '&date=' . date('Y-m-d', $t);
echo "Проверяю записи (" . count($paths) . " запросов)...\n";
$lost = [];
foreach (multi_get($paths) as $r) foreach (($r['bookings'] ?? []) as $b) if (empty($b['service_name'])) $lost[$b['id']] = $b;
echo "Записей без услуги: " . count($lost) . "\n";
$plan = []; $unk = 0;
foreach ($lost as $b) {
  $old = $local[$b['id']] ?? null;
  if ($old === null) { $unk++; echo "  ? " . substr($b['scheduled_at'],0,16) . " " . $b['customer_name'] . " [" . $b['status'] . "] — старое название неизвестно\n"; continue; }
  [$n, $p] = best($old, $new);
  $plan[] = [$b, $n];
  echo "  " . substr($b['scheduled_at'],0,16) . " " . $b['customer_name'] . " [" . $b['status'] . "]: «$old» → «" . $n['title'] . "» ($p%)\n";
}
if ($apply === false) { echo "\nПробный режим. Для привязки: php svc_fix_null.php --apply\n"; return; }
$ok = 0;
foreach ($plan as [$b, $n]) { [$c, , $raw] = req('PATCH', 'bookings/' . $b['id'], ['service_id' => $n['id']]); if ($c < 300) $ok++; else echo "  не удалось " . $b['id'] . " ($c): " . substr($raw, 0, 90) . "\n"; }
echo "Привязано: $ok из " . count($plan) . "\n";
