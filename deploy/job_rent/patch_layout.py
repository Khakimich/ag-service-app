# AG_RENT1: добавляет пункт меню «AG Гараж» в ag_service/_layout.php на сервере (если его ещё нет)
import sys
f = sys.argv[1]
s = open(f, encoding='utf-8').read()
if 'AG_RENT1' in s:
    print('menu: already there'); sys.exit(0)
anchor = "<?php if((int)$employeeId === 2): ?>"
i = s.find(anchor)
if i < 0:
    print('menu: anchor not found, skipped'); sys.exit(0)
add = """<?php /* AG_RENT1 */ if (in_array((int)$employeeId, [2, 3, 28], true)): ?>
            <a class="<?= $activeMenu==='rent'?'active':'' ?>" href="/ag_service/rent.php">
                <span class="ag-nav-icon"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 17V12.5l1.8-4.6A2 2 0 0 1 8.7 6.6h6.6a2 2 0 0 1 1.9 1.3L19 12.5V17"/><path d="M3.5 12.5h17V17a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1z"/><circle cx="7.5" cy="15" r=".8"/><circle cx="16.5" cy="15" r=".8"/></svg></span>
                <span>AG Гараж</span>
            </a>
            <?php endif; ?>

            """
s = s[:i] + add + s[i:]
open(f, 'w', encoding='utf-8').write(s)
print('menu: added')
