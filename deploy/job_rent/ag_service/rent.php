<?php
/* AG_RENT1 — «AG Гараж»: машины в аренду для приложения AG Service.
 * Доступ: сотрудники 2, 3 и 28. Клиенты видят машины в приложении: Сервисы → «AG Гараж».
 */
declare(strict_types=1);

require_once __DIR__ . '/_api.php';
require_once __DIR__ . '/_layout.php';
require_once dirname(__DIR__) . '/includes/ag_rent_lib.php';

$pageTitle = 'AG Гараж';
$activeMenu = 'rent';

if (!ag_rent_can((int)$employeeId)) {
    http_response_code(403);
    exit('Нет доступа к разделу «AG Гараж».');
}

ag_rent_table($pdo);

/* ───────────── AJAX ───────────── */
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
    header('Content-Type: application/json; charset=utf-8');
    $out = static function (array $d, int $code = 200): void { http_response_code($code); echo json_encode($d, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES); exit; };
    $action = (string)($_POST['action'] ?? '');
    try {
        if ($action === 'upload') {
            $name = ag_rent_save_photo($_FILES['photo'] ?? []);
            $out(['ok' => true, 'file' => $name, 'url' => ag_rent_photo_url($name)]);
        }

        if ($action === 'save') {
            $id = (int)($_POST['car_id'] ?? 0);
            $pick = static fn(string $k, array $allowed, string $def) => isset($allowed[(string)($_POST[$k] ?? '')]) ? (string)$_POST[$k] : $def;
            $num = static fn(string $k, int $max) => max(0, min($max, (int)preg_replace('/\D/', '', (string)($_POST[$k] ?? '0'))));
            $photos = array_values(array_filter(array_map('basename', (array)json_decode((string)($_POST['photos'] ?? '[]'), true)),
                static fn($f) => is_string($f) && preg_match('/^car_[\w.-]+\.(jpe?g|png|webp)$/i', $f) && is_file(ag_rent_dir() . '/' . $f)));
            $features = array_values(array_intersect(array_keys(AG_RENT_FEATURES), (array)($_POST['features'] ?? [])));
            $brand = trim((string)($_POST['brand'] ?? ''));
            $model = trim((string)($_POST['model'] ?? ''));
            if ($brand === '' || $model === '') $out(['ok' => false, 'error' => 'Укажите марку и модель.'], 400);
            $year = $num('year', 2100);
            $data = [
                'brand' => mb_substr($brand, 0, 60),
                'model' => mb_substr($model, 0, 80),
                'year' => $year >= 1980 ? $year : null,
                'car_class' => $pick('car_class', AG_RENT_CLASSES, 'economy'),
                'gearbox' => $pick('gearbox', AG_RENT_GEARS, 'auto'),
                'fuel' => $pick('fuel', AG_RENT_FUELS, 'petrol'),
                'color' => mb_substr(trim((string)($_POST['color'] ?? '')), 0, 40),
                'seats' => max(2, min(9, $num('seats', 9) ?: 5)),
                'plate' => mb_strtoupper(mb_substr(preg_replace('/\s+/', '', (string)($_POST['plate'] ?? '')), 0, 20)),
                'price_day' => $num('price_day', 1000000),
                'price_week_day' => $num('price_week_day', 1000000),
                'deposit' => $num('deposit', 10000000),
                'min_days' => max(1, min(365, $num('min_days', 365) ?: 1)),
                'for_taxi' => empty($_POST['for_taxi']) ? 0 : 1,
                'description' => mb_substr(trim((string)($_POST['description'] ?? '')), 0, 3000),
                'features' => json_encode($features),
                'photos' => json_encode(array_slice($photos, 0, AG_RENT_MAX_PHOTOS)),
                'status' => $pick('status', AG_RENT_STATUSES, 'available'),
            ];
            if ($data['price_day'] <= 0) $out(['ok' => false, 'error' => 'Укажите цену за сутки.'], 400);
            if ($id > 0) {
                $set = implode(',', array_map(static fn($k) => "$k=:$k", array_keys($data)));
                $st = $pdo->prepare("UPDATE ag_rent_cars SET $set, updated_by=:by WHERE id=:id");
                $st->execute($data + ['by' => (int)$employeeId, 'id' => $id]);
            } else {
                $cols = implode(',', array_keys($data));
                $vals = ':' . implode(',:', array_keys($data));
                $st = $pdo->prepare("INSERT INTO ag_rent_cars ($cols, created_by, updated_by) VALUES ($vals, :by, :by2)");
                $st->execute($data + ['by' => (int)$employeeId, 'by2' => (int)$employeeId]);
                $id = (int)$pdo->lastInsertId();
            }
            $out(['ok' => true, 'id' => $id]);
        }

        if ($action === 'status') {
            $id = (int)($_POST['id'] ?? 0);
            $status = (string)($_POST['status'] ?? '');
            if (!isset(AG_RENT_STATUSES[$status])) $out(['ok' => false, 'error' => 'Неизвестный статус.'], 400);
            $pdo->prepare('UPDATE ag_rent_cars SET status=?, updated_by=? WHERE id=?')->execute([$status, (int)$employeeId, $id]);
            $out(['ok' => true]);
        }

        if ($action === 'delete') {
            $id = (int)($_POST['id'] ?? 0);
            $st = $pdo->prepare('SELECT photos FROM ag_rent_cars WHERE id=?');
            $st->execute([$id]);
            $photos = ag_rent_json_list((string)$st->fetchColumn());
            $pdo->prepare('DELETE FROM ag_rent_cars WHERE id=?')->execute([$id]);
            foreach ($photos as $f) @unlink(ag_rent_dir() . '/' . basename($f));
            $out(['ok' => true]);
        }

        if ($action === 'move') {
            $ids = array_map('intval', (array)json_decode((string)($_POST['ids'] ?? '[]'), true));
            $st = $pdo->prepare('UPDATE ag_rent_cars SET sort_order=? WHERE id=?');
            foreach ($ids as $i => $cid) $st->execute([$i, $cid]);
            $out(['ok' => true]);
        }

        $out(['ok' => false, 'error' => 'Неизвестное действие.'], 400);
    } catch (Throwable $e) {
        error_log('AG RENT: ' . $e->getMessage());
        $out(['ok' => false, 'error' => $e instanceof RuntimeException ? $e->getMessage() : 'Ошибка сохранения. Попробуйте ещё раз.'], 500);
    }
}

$rows = $pdo->query('SELECT * FROM ag_rent_cars ORDER BY sort_order, id DESC')->fetchAll(PDO::FETCH_ASSOC);
$cars = array_map(static function (array $r): array {
    $p = ag_rent_public($r);
    $p['plate'] = (string)$r['plate'];
    $p['photo_files'] = ag_rent_json_list($r['photos'] ?? '');
    $p['feature_keys'] = ag_rent_json_list($r['features'] ?? '');
    return $p;
}, $rows);
$count = ['all' => count($cars)];
foreach (AG_RENT_STATUSES as $k => $_) $count[$k] = count(array_filter($cars, static fn($c) => $c['status'] === $k));

ag_layout_header($pageTitle, $activeMenu);
?>
<style>
.rg{--o:#ff5a00;--o2:#ff8a2b;--ink:#111318;--mut:#6b7280;--line:#eceef2;--bg:#f6f7f9}
.rg-head{display:flex;align-items:center;gap:14px;flex-wrap:wrap;margin-bottom:18px}
.rg-head h1{margin:0;font-size:28px;letter-spacing:-.03em;flex:1;min-width:200px}
.rg-head h1 small{display:block;font-size:13.5px;font-weight:600;color:var(--mut);letter-spacing:0;margin-top:2px}
.rg-btn{height:46px;padding:0 18px;border-radius:14px;border:0;font:inherit;font-weight:800;font-size:15px;cursor:pointer;display:inline-flex;align-items:center;gap:8px}
.rg-btn.p{color:#fff;background:linear-gradient(135deg,var(--o2),var(--o));box-shadow:0 10px 24px rgba(255,90,0,.3)}
.rg-btn.g{background:#fff;color:var(--ink);border:1px solid var(--line)}
.rg-btn.d{background:#fdecea;color:#b91c1c}
.rg-btn svg{width:18px;height:18px;fill:none;stroke:currentColor;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round}
.rg-tabs{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:16px}
.rg-tabs button{height:38px;padding:0 14px;border-radius:12px;border:1px solid var(--line);background:#fff;font:inherit;font-weight:800;font-size:13.5px;color:var(--mut);cursor:pointer}
.rg-tabs button.on{background:var(--ink);color:#fff;border-color:var(--ink)}
.rg-tabs b{margin-left:6px;opacity:.7}
.rg-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(290px,1fr));gap:16px}
.rg-card{background:#fff;border-radius:22px;overflow:hidden;box-shadow:0 8px 24px rgba(17,19,24,.06);border:1px solid var(--line);display:flex;flex-direction:column;cursor:pointer;transition:transform .2s,box-shadow .2s}
.rg-card:hover{transform:translateY(-3px);box-shadow:0 16px 34px rgba(17,19,24,.1)}
.rg-ph{position:relative;aspect-ratio:16/10;background:linear-gradient(135deg,#f1f2f5,#e6e8ee);display:grid;place-items:center;color:#b6bac4}
.rg-ph img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
.rg-ph svg{width:64px;height:64px;fill:currentColor}
.rg-st{position:absolute;left:12px;top:12px;font-size:12px;font-weight:900;padding:5px 10px;border-radius:99px;background:#fff;box-shadow:0 4px 10px rgba(0,0,0,.08)}
.rg-st.available{color:#15803d}.rg-st.rented{color:#c2410c}.rg-st.service{color:#1d4ed8}.rg-st.hidden{color:#6b7280}
.rg-cnt{position:absolute;right:12px;bottom:12px;font-size:12px;font-weight:800;color:#fff;background:rgba(0,0,0,.5);padding:4px 9px;border-radius:99px}
.rg-body{padding:14px 16px 16px;display:grid;gap:8px}
.rg-t{display:flex;align-items:baseline;gap:8px}.rg-t b{font-size:18px;letter-spacing:-.02em;flex:1}.rg-t span{color:var(--mut);font-weight:700}
.rg-chips{display:flex;flex-wrap:wrap;gap:6px}.rg-chips span{font-size:12px;font-weight:800;padding:4px 9px;border-radius:9px;background:var(--bg);color:#374151}
.rg-chips span.taxi{background:#fff4d6;color:#a16207}
.rg-price{display:flex;align-items:baseline;gap:6px}.rg-price b{font-size:20px;color:var(--o);letter-spacing:-.02em}.rg-price small{color:var(--mut);font-weight:700}
.rg-plate{font-size:12px;font-weight:900;color:var(--mut);letter-spacing:.06em}
.rg-empty{background:#fff;border:2px dashed #e3e5ea;border-radius:24px;padding:48px 20px;text-align:center;color:var(--mut)}
.rg-empty b{display:block;font-size:20px;color:var(--ink);margin-bottom:6px}
/* окно */
.rg-modal{position:fixed;inset:0;z-index:1000;display:none;align-items:flex-start;justify-content:center;padding:24px 12px;overflow:auto;background:rgba(10,12,16,.45);backdrop-filter:blur(4px)}
.rg-modal.open{display:flex}
.rg-sheet{width:min(860px,100%);background:#fff;border-radius:28px;box-shadow:0 30px 80px rgba(0,0,0,.25);overflow:hidden}
.rg-sh{display:flex;align-items:center;gap:12px;padding:18px 22px;border-bottom:1px solid var(--line);position:sticky;top:0;background:#fff;z-index:2}
.rg-sh h2{margin:0;font-size:21px;flex:1;letter-spacing:-.02em}
.rg-x{width:40px;height:40px;border-radius:12px;border:0;background:var(--bg);cursor:pointer;font-size:20px}
.rg-form{padding:20px 22px;display:grid;gap:18px}
.rg-sec{display:grid;gap:12px}.rg-sec h3{margin:0;font-size:15px;letter-spacing:-.01em}
.rg-row{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px}
.rg-f{display:grid;gap:6px}.rg-f label{font-size:12.5px;font-weight:800;color:var(--mut)}
.rg-f input,.rg-f select,.rg-f textarea{height:46px;border-radius:13px;border:1.5px solid var(--line);background:var(--bg);padding:0 13px;font:inherit;font-size:15px;font-weight:600;color:var(--ink);outline:0;width:100%;box-sizing:border-box}
.rg-f textarea{height:96px;padding:11px 13px;resize:vertical}
.rg-f input:focus,.rg-f select:focus,.rg-f textarea:focus{border-color:var(--o);background:#fff}
.rg-seg{display:flex;flex-wrap:wrap;gap:6px}
.rg-seg label{cursor:pointer}.rg-seg input{display:none}
.rg-seg span{display:inline-flex;align-items:center;height:38px;padding:0 13px;border-radius:11px;border:1.5px solid var(--line);font-weight:800;font-size:13.5px;color:#374151;background:#fff}
.rg-seg input:checked+span{border-color:var(--o);background:#fff4ec;color:var(--o)}
.rg-photos{display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:10px}
.rg-pi{position:relative;aspect-ratio:4/3;border-radius:14px;overflow:hidden;background:var(--bg)}
.rg-pi img{width:100%;height:100%;object-fit:cover}
.rg-pi .cover{position:absolute;left:6px;top:6px;font-size:10.5px;font-weight:900;color:#fff;background:var(--o);padding:2px 7px;border-radius:7px}
.rg-pi .tools{position:absolute;right:5px;bottom:5px;display:flex;gap:4px}
.rg-pi .tools button{width:28px;height:28px;border-radius:9px;border:0;background:rgba(0,0,0,.6);color:#fff;cursor:pointer;font-size:14px;font-weight:900}
.rg-add{aspect-ratio:4/3;border-radius:14px;border:2px dashed #ffc9a6;background:#fff8f3;color:var(--o);display:grid;place-items:center;cursor:pointer;font-weight:900;font-size:13px;text-align:center}
.rg-add input{display:none}
.rg-ft{display:flex;gap:10px;flex-wrap:wrap;padding:16px 22px;border-top:1px solid var(--line);position:sticky;bottom:0;background:#fff}
.rg-ft .sp{flex:1}
.rg-err{display:none;padding:11px 14px;border-radius:13px;background:#fdecea;color:#b91c1c;font-weight:700}
.rg-toast{position:fixed;left:50%;bottom:24px;transform:translateX(-50%);background:#111318;color:#fff;padding:12px 18px;border-radius:14px;font-weight:800;z-index:2000;opacity:0;transition:.3s;pointer-events:none}
.rg-toast.on{opacity:1}
@media(max-width:640px){.rg-head h1{font-size:23px}.rg-form,.rg-sh,.rg-ft{padding-left:16px;padding-right:16px}}
</style>

<div class="rg">
  <div class="rg-head">
    <h1>AG Гараж<small>Машины в аренду — клиенты видят их в приложении AG Service: Сервисы → «AG Гараж»</small></h1>
    <button class="rg-btn p" type="button" id="rgNew"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>Добавить машину</button>
  </div>

  <div class="rg-tabs" id="rgTabs">
    <button type="button" class="on" data-f="all">Все<b><?= $count['all'] ?></b></button>
    <?php foreach (AG_RENT_STATUSES as $k => $t): ?><button type="button" data-f="<?= ag_h($k) ?>"><?= ag_h($t) ?><b><?= $count[$k] ?></b></button><?php endforeach; ?>
  </div>

  <div class="rg-grid" id="rgGrid"></div>
  <div class="rg-empty" id="rgEmpty" style="display:none"><b>Машин пока нет</b>Нажмите «Добавить машину» — она сразу появится в приложении.</div>
</div>

<div class="rg-modal" id="rgModal" aria-hidden="true">
  <div class="rg-sheet" role="dialog" aria-modal="true">
    <div class="rg-sh"><h2 id="rgTitle">Новая машина</h2><button class="rg-x" type="button" data-close aria-label="Закрыть">×</button></div>
    <form class="rg-form" id="rgForm" autocomplete="off">
      <input type="hidden" name="car_id">
      <div class="rg-sec"><h3>Фотографии <small style="color:var(--mut);font-weight:600">— первое фото будет обложкой, до <?= AG_RENT_MAX_PHOTOS ?> шт.</small></h3>
        <div class="rg-photos" id="rgPhotos"></div>
      </div>
      <div class="rg-sec"><h3>Автомобиль</h3>
        <div class="rg-row">
          <div class="rg-f"><label>Марка *</label><input name="brand" placeholder="Hyundai" required></div>
          <div class="rg-f"><label>Модель *</label><input name="model" placeholder="Solaris" required></div>
          <div class="rg-f"><label>Год</label><input name="year" inputmode="numeric" maxlength="4" placeholder="2022"></div>
          <div class="rg-f"><label>Цвет</label><input name="color" placeholder="Белый"></div>
        </div>
        <div class="rg-row">
          <div class="rg-f"><label>Госномер (клиентам не показывается)</label><input name="plate" placeholder="А123ВС196"></div>
          <div class="rg-f"><label>Мест</label><input name="seats" inputmode="numeric" maxlength="1" value="5"></div>
        </div>
        <div class="rg-f"><label>Класс</label><div class="rg-seg"><?php foreach (AG_RENT_CLASSES as $k => $t): ?><label><input type="radio" name="car_class" value="<?= $k ?>"><span><?= $t ?></span></label><?php endforeach; ?></div></div>
        <div class="rg-f"><label>Коробка</label><div class="rg-seg"><?php foreach (AG_RENT_GEARS as $k => $t): ?><label><input type="radio" name="gearbox" value="<?= $k ?>"><span><?= $t ?></span></label><?php endforeach; ?></div></div>
        <div class="rg-f"><label>Топливо</label><div class="rg-seg"><?php foreach (AG_RENT_FUELS as $k => $t): ?><label><input type="radio" name="fuel" value="<?= $k ?>"><span><?= $t ?></span></label><?php endforeach; ?></div></div>
      </div>
      <div class="rg-sec"><h3>Условия аренды</h3>
        <div class="rg-row">
          <div class="rg-f"><label>Цена за сутки, ₽ *</label><input name="price_day" inputmode="numeric" placeholder="2500"></div>
          <div class="rg-f"><label>Сутки при аренде от 7 дней, ₽</label><input name="price_week_day" inputmode="numeric" placeholder="2200"></div>
          <div class="rg-f"><label>Залог, ₽</label><input name="deposit" inputmode="numeric" placeholder="10000"></div>
          <div class="rg-f"><label>Минимум суток</label><input name="min_days" inputmode="numeric" value="1"></div>
        </div>
        <div class="rg-seg"><label><input type="checkbox" name="for_taxi" value="1"><span>Подходит для работы в такси</span></label></div>
      </div>
      <div class="rg-sec"><h3>Что есть в машине</h3>
        <div class="rg-seg"><?php foreach (AG_RENT_FEATURES as $k => $t): ?><label><input type="checkbox" name="features[]" value="<?= $k ?>"><span><?= $t ?></span></label><?php endforeach; ?></div>
      </div>
      <div class="rg-sec"><h3>Описание</h3>
        <div class="rg-f"><textarea name="description" placeholder="Состояние, пробег, условия выдачи и возврата…"></textarea></div>
      </div>
      <div class="rg-sec"><h3>Статус</h3>
        <div class="rg-seg"><?php foreach (AG_RENT_STATUSES as $k => $t): ?><label><input type="radio" name="status" value="<?= $k ?>"><span><?= $t ?></span></label><?php endforeach; ?></div>
      </div>
      <div class="rg-err" id="rgErr"></div>
    </form>
    <div class="rg-ft">
      <button class="rg-btn d" type="button" id="rgDel">Удалить</button>
      <span class="sp"></span>
      <button class="rg-btn g" type="button" data-close>Отмена</button>
      <button class="rg-btn p" type="button" id="rgSave">Сохранить</button>
    </div>
  </div>
</div>
<div class="rg-toast" id="rgToast"></div>

<script>
(function(){
  'use strict';
  var CARS = <?= json_encode($cars, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG) ?>;
  var STATUS = <?= json_encode(AG_RENT_STATUSES, JSON_UNESCAPED_UNICODE) ?>;
  var MAXP = <?= AG_RENT_MAX_PHOTOS ?>, SITE = <?= json_encode(AG_RENT_SITE . '/uploads/ag_rent/') ?>;
  var grid = document.getElementById('rgGrid'), empty = document.getElementById('rgEmpty'), filter = 'all';
  var modal = document.getElementById('rgModal'), form = document.getElementById('rgForm'), err = document.getElementById('rgErr');
  var photos = [], current = null;
  var CAR_SVG = '<svg viewBox="0 0 24 24"><path d="M7.3 6h9.4a2 2 0 0 1 1.85 1.24L20 11a2 2 0 0 1 1 1.73V18a1 1 0 0 1-1 1h-1v1.5a1.5 1.5 0 0 1-3 0V19H8v1.5a1.5 1.5 0 0 1-3 0V19H4a1 1 0 0 1-1-1v-5.27A2 2 0 0 1 4 11l1.45-3.76A2 2 0 0 1 7.3 6zm.2 2-1.15 3h11.3l-1.15-3z"/></svg>';
  function esc(s){ return String(s == null ? '' : s).replace(/[&<>"']/g, function(c){ return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]; }); }
  function money(n){ return Number(n || 0).toLocaleString('ru-RU') + ' ₽'; }
  function toast(t){ var el = document.getElementById('rgToast'); el.textContent = t; el.classList.add('on'); clearTimeout(el._t); el._t = setTimeout(function(){ el.classList.remove('on'); }, 2400); }
  function post(data){ return fetch(location.pathname, { method: 'POST', body: data, credentials: 'same-origin' }).then(function(r){ return r.json().catch(function(){ return { ok: false, error: 'Ошибка сервера' }; }); }); }

  function render(){
    var list = CARS.filter(function(c){ return filter === 'all' || c.status === filter; });
    empty.style.display = list.length ? 'none' : 'block';
    grid.innerHTML = list.map(function(c){
      var ph = c.photos && c.photos[0] ? '<img src="' + esc(c.photos[0]) + '" alt="" loading="lazy">' : CAR_SVG;
      var chips = [c.class_title, c.gearbox_title, c.fuel_title, c.year].filter(Boolean).map(function(x){ return '<span>' + esc(x) + '</span>'; }).join('');
      if (c.for_taxi) chips = '<span class="taxi">Для такси</span>' + chips;
      return '<div class="rg-card" data-id="' + c.id + '"><div class="rg-ph">' + ph + '<span class="rg-st ' + esc(c.status) + '">' + esc(c.status_title) + '</span>' +
        (c.photos && c.photos.length > 1 ? '<span class="rg-cnt">' + c.photos.length + ' фото</span>' : '') + '</div>' +
        '<div class="rg-body"><div class="rg-t"><b>' + esc(c.brand + ' ' + c.model) + '</b>' + (c.plate ? '<span class="rg-plate">' + esc(c.plate) + '</span>' : '') + '</div>' +
        '<div class="rg-chips">' + chips + '</div><div class="rg-price"><b>' + money(c.price_day) + '</b><small>/ сутки</small>' +
        (c.deposit ? '<small>· залог ' + money(c.deposit) + '</small>' : '') + '</div></div></div>';
    }).join('');
  }
  document.getElementById('rgTabs').addEventListener('click', function(e){
    var b = e.target.closest('button'); if (!b) return;
    filter = b.dataset.f; this.querySelectorAll('button').forEach(function(x){ x.classList.toggle('on', x === b); }); render();
  });
  grid.addEventListener('click', function(e){ var c = e.target.closest('.rg-card'); if (c) open(CARS.find(function(x){ return x.id === +c.dataset.id; })); });
  document.getElementById('rgNew').addEventListener('click', function(){ open(null); });

  function setRadio(name, v){ var el = form.querySelector('[name="' + name + '"][value="' + v + '"]') || form.querySelector('[name="' + name + '"]'); if (el) el.checked = true; }
  function open(c){
    current = c; form.reset(); err.style.display = 'none';
    document.getElementById('rgTitle').textContent = c ? c.brand + ' ' + c.model : 'Новая машина';
    document.getElementById('rgDel').style.display = c ? '' : 'none';
    form.car_id.value = c ? c.id : '';
    ['brand','model','color','plate','description'].forEach(function(k){ form[k].value = c ? (c[k] || '') : ''; });
    form.year.value = c && c.year ? c.year : '';
    form.seats.value = c ? c.seats : 5;
    form.price_day.value = c ? c.price_day || '' : '';
    form.price_week_day.value = c && c.price_week_day ? c.price_week_day : '';
    form.deposit.value = c && c.deposit ? c.deposit : '';
    form.min_days.value = c ? c.min_days : 1;
    form.for_taxi.checked = c ? !!c.for_taxi : true;
    setRadio('car_class', c ? c.class : 'economy'); setRadio('gearbox', c ? c.gearbox : 'auto');
    setRadio('fuel', c ? c.fuel : 'petrol'); setRadio('status', c ? c.status : 'available');
    form.querySelectorAll('[name="features[]"]').forEach(function(x){ x.checked = !!(c && c.feature_keys.indexOf(x.value) >= 0); });
    photos = c ? c.photo_files.slice() : [];
    drawPhotos();
    modal.classList.add('open'); modal.setAttribute('aria-hidden', 'false'); document.body.style.overflow = 'hidden';
  }
  function close(){ modal.classList.remove('open'); modal.setAttribute('aria-hidden', 'true'); document.body.style.overflow = ''; }
  modal.addEventListener('click', function(e){ if (e.target === modal || e.target.closest('[data-close]')) close(); });
  document.addEventListener('keydown', function(e){ if (e.key === 'Escape' && modal.classList.contains('open')) close(); });

  function drawPhotos(){
    var box = document.getElementById('rgPhotos');
    box.innerHTML = photos.map(function(f, i){
      return '<div class="rg-pi"><img src="' + SITE + encodeURIComponent(f) + '" alt="">' + (i === 0 ? '<span class="cover">Обложка</span>' : '') +
        '<div class="tools">' + (i > 0 ? '<button type="button" data-l="' + i + '" title="Левее">‹</button>' : '') +
        '<button type="button" data-r="' + i + '" title="Убрать">×</button></div></div>';
    }).join('') + (photos.length < MAXP ? '<label class="rg-add"><input type="file" accept="image/*" multiple><span>＋<br>Добавить фото</span></label>' : '');
  }
  document.getElementById('rgPhotos').addEventListener('click', function(e){
    var b = e.target.closest('button'); if (!b) return;
    if (b.dataset.r !== undefined) photos.splice(+b.dataset.r, 1);
    if (b.dataset.l !== undefined){ var i = +b.dataset.l, t = photos[i - 1]; photos[i - 1] = photos[i]; photos[i] = t; }
    drawPhotos();
  });
  document.getElementById('rgPhotos').addEventListener('change', function(e){
    var files = Array.prototype.slice.call(e.target.files || []).slice(0, MAXP - photos.length);
    if (!files.length) return;
    toast('Загружаю фото…');
    files.reduce(function(p, f){ return p.then(function(){ var d = new FormData(); d.append('action', 'upload'); d.append('photo', f);
      return post(d).then(function(r){ if (r.ok){ photos.push(r.file); drawPhotos(); } else toast(r.error || 'Не удалось загрузить фото'); }); }); }, Promise.resolve())
      .then(function(){ toast('Фото добавлены'); });
  });

  document.getElementById('rgSave').addEventListener('click', function(){
    var b = this, d = new FormData(form); d.append('action', 'save'); d.set('photos', JSON.stringify(photos));
    if (!form.for_taxi.checked) d.delete('for_taxi');
    b.disabled = true; err.style.display = 'none';
    post(d).then(function(r){ b.disabled = false; if (!r.ok){ err.textContent = r.error || 'Не удалось сохранить'; err.style.display = 'block'; return; } toast('Сохранено'); setTimeout(function(){ location.reload(); }, 400); })
      .catch(function(){ b.disabled = false; err.textContent = 'Нет связи с сервером'; err.style.display = 'block'; });
  });
  document.getElementById('rgDel').addEventListener('click', function(){
    if (!current || !window.confirm('Удалить ' + current.brand + ' ' + current.model + ' вместе с фото? Это нельзя отменить.')) return;
    var d = new FormData(); d.append('action', 'delete'); d.append('id', current.id);
    post(d).then(function(r){ if (r.ok) location.reload(); else toast(r.error || 'Не удалось удалить'); });
  });
  render();
})();
</script>
<?php
ag_layout_footer();
