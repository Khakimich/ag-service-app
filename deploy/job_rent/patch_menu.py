# AG_RENT2: пункт «AG Гараж» в главном меню job (для сотрудников 2, 3, 28)
import sys, re
root = sys.argv[1]

f = root + '/employee.php'
s = open(f, encoding='utf-8').read()
if 'AG_RENT2' in s:
    print('employee.php: already')
else:
    m = re.search(r"\n(\s*)'ag_service' => in_array\(", s)
    if not m:
        print('employee.php: anchor not found'); sys.exit(1)
    ins = "\n" + m.group(1) + "'ag_garage' => in_array((int)$employeeId, [2, 3, 28], true), /* AG_RENT2 */"
    s = s[:m.start()] + ins + s[m.start():]
    open(f, 'w', encoding='utf-8').write(s)
    print('employee.php: added')

f = root + '/app-header.js'
s = open(f, encoding='utf-8').read()
if 'AG_RENT2' in s:
    print('app-header.js: already')
else:
    a = "    ag_service: ['service', 'AG Service', 'Записи и клиенты сервиса', '/ag_service/'],"
    if a not in s:
        print('app-header.js: anchor not found'); sys.exit(1)
    s = s.replace(a, a + "\n    ag_garage: ['car', 'AG Гараж', 'Машины в аренду для приложения', '/ag_service/rent.php'], /* AG_RENT2 */", 1)
    b = "  const ICONS = {"
    s = s.replace(b, b + "\n    car: '<path d=\"M5 17V12.5l1.8-4.6A2 2 0 0 1 8.7 6.6h6.6a2 2 0 0 1 1.9 1.3L19 12.5V17\"/><path d=\"M3.5 12.5h17V17a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1z\"/>', /* AG_RENT2 */", 1)
    open(f, 'w', encoding='utf-8').write(s)
    print('app-header.js: added')
