<?php
// Выдача бонусов по старым правилам (до 14.11.2026): пригласившему 300 ₽ за регистрацию друга, другу 100 ₽.
// php ref_backfill.php          — пробный: список, кому сколько
// php ref_backfill.php --apply  — начислить (повторно не начисляет: журнал /root/ref_backfill_done.json)
$apply = in_array('--apply', $argv, true);
define('AG_SERVICE_INTERNAL', true);
$key = trim((string)require '/home/khakimjon/web/job.autogrom.ru/public_html/ag_service_bridge_secret.php');
function api($m, $url, $body = null) { global $key; $c = curl_init('https://api.autogrom-group.com' . $url);
  $h = ['Accept: application/json', 'X-AG-Job-Key: ' . $key]; if ($body !== null) { $h[] = 'Content-Type: application/json'; curl_setopt($c, CURLOPT_POSTFIELDS, json_encode($body, JSON_UNESCAPED_UNICODE)); }
  curl_setopt_array($c, [CURLOPT_RETURNTRANSFER => 1, CURLOPT_CUSTOMREQUEST => $m, CURLOPT_HTTPHEADER => $h, CURLOPT_TIMEOUT => 30]);
  $r = curl_exec($c); $code = curl_getinfo($c, CURLINFO_HTTP_CODE); curl_close($c); return [$code, json_decode((string)$r, true), (string)$r]; }
$CUT = '2026-11-14'; $INV = 300; $FRIEND = 100;
[, $d] = api('GET', '/api/business/job-bridge/referrals-dashboard');
$got = [];
foreach ($d['history'] ?? [] as $h) $got[$h['type'] . '|' . $h['user_id'] . '|' . ($h['referee_id'] ?? '')] = 1;
$doneFile = '/root/ref_backfill_done.json'; $done = json_decode(@file_get_contents($doneFile), true) ?: [];
$plan = [];
foreach ($d['referrers'] ?? [] as $u) foreach ($u['referrals'] ?? [] as $r) {
  if (substr((string)$r['created_at'], 0, 10) >= $CUT) continue;
  $rid = $r['referee_id'] ?? null; if ($rid === null) continue;
  if (isset($got['referee_signup_bonus|' . $u['user_id'] . '|' . $rid]) === false && isset($done['inv|' . $rid]) === false)
    $plan[] = ['inv|' . $rid, $u['user_id'], $INV, 'Бонус за приглашённого друга: ' . ($r['referee_name'] ?? ''), ($u['name'] ?? '?') . ' — за друга ' . ($r['referee_name'] ?? '')];
  if (isset($got['signup_bonus|' . $rid . '|' . $rid]) === false && isset($done['fr|' . $rid]) === false)
    $plan[] = ['fr|' . $rid, $rid, $FRIEND, 'Приветственный бонус за регистрацию по приглашению', ($r['referee_name'] ?? '?') . ' — приветственный бонус'];
}
$sum = 0; foreach ($plan as $p) { echo "  +{$p[2]} ₽  {$p[4]}\n"; $sum += $p[2]; }
echo "Начислений: " . count($plan) . ", на сумму $sum ₽\n";
if ($apply === false) { echo "Пробный режим. Для начисления: php ref_backfill.php --apply\n"; return; }
foreach ($plan as $p) {
  [$c, $r, $raw] = api('POST', '/api/ag/bonus/admin/apply', ['kind' => 'add', 'user_id' => $p[1], 'amount' => $p[2], 'comment' => $p[3], 'employee_id' => 2, 'employee_name' => 'Реферальная программа']);
  if ($c < 300) { $done[$p[0]] = date('c'); echo "  ок  {$p[4]}\n"; } else echo "  ошибка ($c) {$p[4]}: " . substr($raw, 0, 120) . "\n";
  file_put_contents($doneFile, json_encode($done, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
}
