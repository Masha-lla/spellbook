import datetime
import json
import sys
from dbt.contracts.graph.nodes import ModelNode
from dbt.materializations.incremental.microbatch import MicrobatchBuilder

manifest = json.load(open(sys.argv[1]))
node = ModelNode.from_dict(manifest['nodes']['model.solana.raydium_v3_base_trades_backfill'])
utc = datetime.timezone.utc
if isinstance(node.config.begin, str):
    node.config.begin = datetime.datetime.fromisoformat(node.config.begin).replace(tzinfo=utc)
for label, start, end, expected in [
    ('Historical CI', None, None, 1554),
    ('Bounded comparison', datetime.datetime(2026, 10, 22, tzinfo=utc), datetime.datetime(2026, 11, 16, tzinfo=utc), 25),
    ('Single-day replay', datetime.datetime(2026, 11, 15, tzinfo=utc), datetime.datetime(2026, 11, 16, tzinfo=utc), 1),
]:
    builder = MicrobatchBuilder(node, False, start, end, datetime.datetime(2026, 11, 17, 13, 30, tzinfo=utc))
    first = builder.build_start_time(None)
    last = builder.build_end_time()
    batches = builder.build_batches(first, last)
    assert len(batches) == expected
    print(label, 'batches=', len(batches), 'start=', first.isoformat(), 'end(exclusive)=', last.isoformat())
print('PASS: batch planning only; no warehouse query executed.')
