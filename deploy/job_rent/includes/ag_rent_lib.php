<?php
/* AG_RENT1 — «AG Гараж»: машины в аренду для приложения AG Service.
 * Машины добавляют сотрудники 2, 3 и 28 на странице /ag_service/rent.php.
 * Приложение берёт список с /ag_rent_feed.php (без авторизации, только опубликованные машины).
 */
declare(strict_types=1);

const AG_RENT_EDITORS = [2, 3, 28];
const AG_RENT_SITE = 'https://job.autogrom.ru';
const AG_RENT_MAX_PHOTOS = 10;

const AG_RENT_CLASSES = ['economy' => 'Эконом', 'comfort' => 'Комфорт', 'comfort_plus' => 'Комфорт+', 'business' => 'Бизнес', 'minivan' => 'Минивэн'];
const AG_RENT_GEARS = ['auto' => 'Автомат', 'manual' => 'Механика', 'robot' => 'Робот', 'cvt' => 'Вариатор'];
const AG_RENT_FUELS = ['petrol' => 'Бензин', 'gas' => 'Газ/бензин', 'diesel' => 'Дизель', 'hybrid' => 'Гибрид', 'electric' => 'Электро'];
const AG_RENT_STATUSES = ['available' => 'Свободна', 'rented' => 'В аренде', 'service' => 'На ремонте', 'hidden' => 'Скрыта'];
const AG_RENT_FEATURES = [
    'taxi_license' => 'Лицензия такси', 'branding' => 'Оклейка такси', 'kasko' => 'КАСКО', 'osago' => 'ОСАГО без ограничений',
    'conditioner' => 'Кондиционер', 'navigator' => 'Навигатор', 'camera' => 'Камера заднего вида', 'heated_seats' => 'Подогрев сидений',
    'winter_tires' => 'Зимняя резина', 'child_seat' => 'Детское кресло', 'gps' => 'GPS-трекер', 'unlimited_km' => 'Без лимита пробега',
];

function ag_rent_can(int $employeeId): bool
{
    return in_array($employeeId, AG_RENT_EDITORS, true);
}

function ag_rent_dir(): string
{
    $d = dirname(__DIR__) . '/uploads/ag_rent';
    if (!is_dir($d)) @mkdir($d, 0775, true);
    return $d;
}

function ag_rent_photo_url(string $file): string
{
    return AG_RENT_SITE . '/uploads/ag_rent/' . rawurlencode(basename($file));
}

function ag_rent_table(PDO $pdo): void
{
    static $done = false;
    if ($done) return;
    $done = true;
    $pdo->exec("CREATE TABLE IF NOT EXISTS ag_rent_cars (
        id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        brand VARCHAR(60) NOT NULL DEFAULT '',
        model VARCHAR(80) NOT NULL DEFAULT '',
        year SMALLINT UNSIGNED NULL,
        car_class VARCHAR(20) NOT NULL DEFAULT 'economy',
        gearbox VARCHAR(20) NOT NULL DEFAULT 'auto',
        fuel VARCHAR(20) NOT NULL DEFAULT 'petrol',
        color VARCHAR(40) NOT NULL DEFAULT '',
        seats TINYINT UNSIGNED NOT NULL DEFAULT 5,
        plate VARCHAR(20) NOT NULL DEFAULT '',
        price_day INT UNSIGNED NOT NULL DEFAULT 0,
        price_week_day INT UNSIGNED NOT NULL DEFAULT 0,
        deposit INT UNSIGNED NOT NULL DEFAULT 0,
        min_days SMALLINT UNSIGNED NOT NULL DEFAULT 1,
        for_taxi TINYINT(1) NOT NULL DEFAULT 1,
        description TEXT NULL,
        features TEXT NULL,
        photos TEXT NULL,
        status VARCHAR(20) NOT NULL DEFAULT 'available',
        sort_order INT NOT NULL DEFAULT 0,
        created_by INT NULL,
        updated_by INT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        KEY idx_status (status, sort_order)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
}

function ag_rent_json_list(?string $raw): array
{
    $v = json_decode((string)$raw, true);
    return is_array($v) ? array_values(array_filter($v, 'is_string')) : [];
}

/** Строка из базы → массив для приложения (без госномера). */
function ag_rent_public(array $r): array
{
    $photos = array_map('ag_rent_photo_url', ag_rent_json_list($r['photos'] ?? ''));
    $features = [];
    foreach (ag_rent_json_list($r['features'] ?? '') as $k) {
        if (isset(AG_RENT_FEATURES[$k])) $features[] = ['key' => $k, 'title' => AG_RENT_FEATURES[$k]];
    }
    return [
        'id' => (int)$r['id'],
        'brand' => (string)$r['brand'],
        'model' => (string)$r['model'],
        'year' => $r['year'] !== null ? (int)$r['year'] : null,
        'class' => (string)$r['car_class'],
        'class_title' => AG_RENT_CLASSES[$r['car_class']] ?? '',
        'gearbox' => (string)$r['gearbox'],
        'gearbox_title' => AG_RENT_GEARS[$r['gearbox']] ?? '',
        'fuel' => (string)$r['fuel'],
        'fuel_title' => AG_RENT_FUELS[$r['fuel']] ?? '',
        'color' => (string)$r['color'],
        'seats' => (int)$r['seats'],
        'price_day' => (int)$r['price_day'],
        'price_week_day' => (int)$r['price_week_day'],
        'deposit' => (int)$r['deposit'],
        'min_days' => max(1, (int)$r['min_days']),
        'for_taxi' => (bool)$r['for_taxi'],
        'description' => (string)($r['description'] ?? ''),
        'features' => $features,
        'photos' => $photos,
        'status' => (string)$r['status'],
        'status_title' => AG_RENT_STATUSES[$r['status']] ?? '',
    ];
}

/** Сохранить загруженное фото: уменьшаем до 1600 px и сохраняем в JPG. Возвращает имя файла. */
function ag_rent_save_photo(array $file): string
{
    if (empty($file['tmp_name']) || !is_uploaded_file($file['tmp_name'])) throw new RuntimeException('Фото не выбрано.');
    if ((int)($file['size'] ?? 0) > 15 * 1024 * 1024) throw new RuntimeException('Фото больше 15 МБ.');
    $info = @getimagesize($file['tmp_name']);
    $mime = (string)($info['mime'] ?? '');
    if (!in_array($mime, ['image/jpeg', 'image/png', 'image/webp'], true)) throw new RuntimeException('Подходят JPG, PNG и WEBP.');
    $name = 'car_' . date('Ymd_His') . '_' . bin2hex(random_bytes(4)) . '.jpg';
    $dest = ag_rent_dir() . '/' . $name;
    $src = function_exists('imagecreatefromstring') ? @imagecreatefromstring((string)file_get_contents($file['tmp_name'])) : false;
    if ($src) {
        $w = imagesx($src); $h = imagesy($src);
        $k = min(1, 1600 / max($w, $h));
        $nw = (int)round($w * $k); $nh = (int)round($h * $k);
        $dst = imagecreatetruecolor($nw, $nh);
        imagefill($dst, 0, 0, imagecolorallocate($dst, 255, 255, 255));
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $nw, $nh, $w, $h);
        if (!imagejpeg($dst, $dest, 84)) throw new RuntimeException('Не удалось сохранить фото.');
        imagedestroy($src); imagedestroy($dst);
    } elseif (!move_uploaded_file($file['tmp_name'], $dest)) {
        throw new RuntimeException('Не удалось сохранить фото.');
    }
    return $name;
}
