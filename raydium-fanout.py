import datetime,json,sys
from pathlib import Path
import duckdb
from jinja2 import Template
tx=json.load(open('/tmp/raydium-tx.json'))
tid=tx['transaction']['signatures'][0]
ts=datetime.datetime.fromtimestamp(tx['blockTime'],datetime.timezone.utc).replace(tzinfo=None)
g=next(x for x in tx['meta']['innerInstructions'] if x['index']==3)
a=g['instructions'][0]['accounts']
c=duckdb.connect()
c.execute('create table amm_v3_call_createPool(account_tokenMint0 varchar,account_tokenVault0 varchar,account_tokenMint1 varchar,account_tokenVault1 varchar,account_ammConfig varchar,account_poolState varchar,call_tx_id varchar,call_block_time timestamp)')
c.execute('create table amm_v3_call_swap(account_poolState varchar,call_is_inner boolean,call_outer_instruction_index int,call_inner_instruction_index int,call_tx_id varchar,call_block_time timestamp,call_block_slot bigint,call_outer_executing_account varchar,call_tx_signer varchar,call_tx_index int)')
c.execute('create table amm_v3_call_swapV2 as select *, null::varchar account_inputVaultMint,null::varchar account_outputVaultMint,null::varchar account_inputVault,null::varchar account_outputVault from amm_v3_call_swap')
c.execute('create table transfers(tx_id varchar,outer_instruction_index int,inner_instruction_index int,amount bigint,token_mint_address varchar,from_token_account varchar,to_token_account varchar)')
outer=tx['transaction']['message']['instructions'][3]['programId']
c.execute('insert into amm_v3_call_swapV2 values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)',[a[2],True,3,1,tid,ts,tx['slot'],outer,a[0],0,a[11],a[12],a[5],a[6]])
for idx in (2,3):
 t=g['instructions'][idx-1]['parsed']['info']
 c.execute('insert into transfers values (?,?,?,?,?,?,?)',[tid,3,idx,int(t['tokenAmount']['amount']),t['mint'],t['source'],t['destination']])
def run(path):
 sql=Template(Path(path).read_text()).render(config=lambda **kwargs:'',var=lambda key,default:default,source=lambda schema,table:table)
 return c.execute(sql).fetchall()
before,after=sys.argv[1:]
assert len(run(before)) == 0
assert len(run(after)) == 1
c.execute('insert into transfers select * from transfers where inner_instruction_index = 2')
rows = run(after)
assert len(rows) == 2 and rows[0] == rows[1]
print('Real transaction fixture: 1 row with one input transfer; 2 identical trade rows with one duplicated input transfer.')
