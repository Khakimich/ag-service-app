<?php
define('AG_SERVICE_INTERNAL', true);
$key = trim((string)require '/home/khakimjon/web/job.autogrom.ru/public_html/ag_service_bridge_secret.php');
function req($m, $p, $body = null) { global $key; $c = curl_init('https://api.autogrom-group.com/api/business/job-bridge/' . $p);
  $h = ['Accept: application/json', 'X-AG-Job-Key: ' . $key]; if ($body !== null) { $h[] = 'Content-Type: application/json'; curl_setopt($c, CURLOPT_POSTFIELDS, json_encode($body, JSON_UNESCAPED_UNICODE)); }
  curl_setopt_array($c, [CURLOPT_RETURNTRANSFER => 1, CURLOPT_CUSTOMREQUEST => $m, CURLOPT_HTTPHEADER => $h, CURLOPT_TIMEOUT => 30]);
  $r = curl_exec($c); $code = curl_getinfo($c, CURLINFO_HTTP_CODE); curl_close($c); return [$code, json_decode((string)$r, true), (string)$r]; }
$sec = ['01'=>'Техническое обслуживание','02'=>'Двигатель','03'=>'Топливная система','04'=>'Система охлаждения','05'=>'Система выпуска','06'=>'Трансмиссия','07'=>'Ходовая часть','08'=>'Рулевое управление','09'=>'Тормозная система','10'=>'Электрооборудование','11'=>'Отопление / кондиционирование','12'=>'Детали салона','13'=>'Детали кузова','14'=>'Дополнительное оборудование'];
$want = [];
foreach (json_decode(file_get_contents(__DIR__ . '/catalog_import.json'), true)['items'] as $i) $want[mb_strtolower(trim($i['title']))] = $sec[substr($i['code'], 0, 2)];
[, $d] = req('GET', 'services-admin'); $n = 0;
foreach ($d['services'] ?? [] as $s) {
  $cat = $want[mb_strtolower(trim($s['title']))] ?? null; if ($cat === null) continue;
  $desc = (string)$s['description'];
  $fixed = preg_match('/^\[Категория: [^\]]*\]/u', $desc) ? preg_replace('/^\[Категория: [^\]]*\]/u', "[Категория: $cat]", $desc) : "[Категория: $cat]\n" . $desc;
  if ($fixed === $desc) continue;
  $p = ['title' => $s['title'], 'description' => $fixed, 'price_from' => (float)$s['price_from'], 'price_fixed' => (bool)$s['price_fixed'], 'duration_minutes' => (int)$s['duration_minutes'], 'photo_url' => (string)$s['photo_url']];
  [$c] = req('PUT', 'services-admin/' . $s['id'], $p);
  echo ($c < 300 ? 'ок  ' : "ошибка $c ") . $s['title'] . " → $cat\n"; $n++;
}
@array_map('unlink', glob('/home/khakimjon/web/job.autogrom.ru/private/ag_cache/svc_*.json'));
echo "Исправлено: $n\n";
