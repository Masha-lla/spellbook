import sqlite3
from pathlib import Path

db = sqlite3.connect(':memory:')
db.create_function('date_trunc', 2, lambda unit, value: value[:10])
db.create_function('greatest', -1, max)
class CountIf:
    def __init__(self): self.total = 0
    def step(self, value): self.total += bool(value)
    def finalize(self): return self.total
db.create_aggregate('count_if', 1, CountIf)
for version, rows in [('before', [('lost',0,None),('same',0,1),('stable',0,2),('stable',0,2)]),
                      ('after', [('new',0,None),('new',0,None),('same',0,1),('same',0,1),('stable',0,2),('stable',0,2)])]:
    db.execute(f'create table {version}_model (block_time, tx_id, outer_instruction_index, inner_instruction_index)')
    db.executemany(f'insert into {version}_model values (?,?,?,?)', [('2026-11-05 12:00:00', *row) for row in rows])
sql = Path('spellbook-preuves/raydium-comparaison-dune.sql').read_text()
cursor = db.execute('with ' + sql.split(', comparison_rows as (',1)[1].join(['comparison_rows as (','']))
result = cursor.fetchone()
assert result == ('2026-11-05', 4, 6, 2, 1, 1, 2, 2), result
for column, value in zip(cursor.description, result): print(f'{column[0]}: {value}')
print('Fixture passed. Warehouse validation pending.')
