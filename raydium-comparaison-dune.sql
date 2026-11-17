with before_model as (
with pools as (
    select
        ip.account_tokenMint0 as tokenA
        , ip.account_tokenVault0 as tokenAVault
        , ip.account_tokenMint1 as tokenB
        , ip.account_tokenVault1 as tokenBVault
        , ip.account_ammConfig as fee_tier
        , ip.account_poolState as pool_id
        , ip.call_tx_id as init_tx
        , ip.call_block_time as init_time
        , row_number() over (partition by ip.account_poolState order by ip.call_block_time desc) as recent_init
    from raydium_clmm_solana."amm_v3_call_createPool" ip
)
, swaps as (
    select
        account_poolState
        , call_is_inner
        , call_outer_instruction_index
        , call_inner_instruction_index
        , call_tx_id
        , call_block_time
        , call_block_slot
        , call_outer_executing_account
        , call_tx_signer
        , call_tx_index
    from raydium_clmm_solana."amm_v3_call_swap"
    where call_block_time >= timestamp '2026-10-22 00:00:00'
      and call_block_time < timestamp '2026-11-16 00:00:00'
    union all
    select
        account_poolState
        , call_is_inner
        , call_outer_instruction_index
        , call_inner_instruction_index
        , call_tx_id
        , call_block_time
        , call_block_slot
        , call_outer_executing_account
        , call_tx_signer
        , call_tx_index
    from raydium_clmm_solana."amm_v3_call_swapV2"
    where call_block_time >= timestamp '2026-10-22 00:00:00'
      and call_block_time < timestamp '2026-11-16 00:00:00'
)
, transfers as (
    select
        tx_id
        , outer_instruction_index
        , inner_instruction_index
        , amount
        , token_mint_address
        , from_token_account
        , to_token_account
    from tokens_solana."transfers"
    where block_time >= timestamp '2026-10-22 00:00:00'
      and block_time < timestamp '2026-11-16 00:00:00'
)
, all_swaps as (
    select
        sp.call_block_time as block_time
        , 'raydium' as project
        , 3 as version
        , 'solana' as blockchain
        , sp.call_block_slot as block_slot
        , case when sp.call_is_inner = false then 'direct'
            else sp.call_outer_executing_account
            end as trade_source
        , tr_2.amount as token_bought_amount_raw
        , tr_1.amount as token_sold_amount_raw
        , p.pool_id
        , sp.call_tx_signer as trader_id
        , sp.call_tx_id as tx_id
        , sp.call_outer_instruction_index as outer_instruction_index
        , coalesce(sp.call_inner_instruction_index, 0) as inner_instruction_index
        , sp.call_tx_index as tx_index
        , case when tr_1.token_mint_address = p.tokenA then p.tokenB
            else p.tokenA
            end as token_bought_mint_address
        , case when tr_1.token_mint_address = p.tokenA then p.tokenA
            else p.tokenB
            end as token_sold_mint_address
        , case when tr_1.token_mint_address = p.tokenA then p.tokenBVault
            else p.tokenAVault
            end as token_bought_vault
        , case when tr_1.token_mint_address = p.tokenA then p.tokenAVault
            else p.tokenBVault
            end as token_sold_vault
    from swaps as sp
    inner join pools as p
        on sp.account_poolState = p.pool_id
        and p.recent_init = 1
    inner join transfers as tr_1
        on tr_1.tx_id = sp.call_tx_id
        and tr_1.outer_instruction_index = sp.call_outer_instruction_index
        and ((sp.call_is_inner = false and tr_1.inner_instruction_index = 1)
            or (sp.call_is_inner = true and tr_1.inner_instruction_index = sp.call_inner_instruction_index + 1))
    inner join transfers as tr_2
        on tr_2.tx_id = sp.call_tx_id
        and tr_2.outer_instruction_index = sp.call_outer_instruction_index
        and ((sp.call_is_inner = false and tr_2.inner_instruction_index = 2)
            or (sp.call_is_inner = true and tr_2.inner_instruction_index = sp.call_inner_instruction_index + 2))
)

select
    tb.blockchain
    , tb.project
    , tb.version
    , cast(date_trunc('month', tb.block_time) as date) as block_month
    , tb.block_time
    , tb.block_slot
    , tb.trade_source
    , tb.token_bought_amount_raw
    , tb.token_sold_amount_raw
    , cast(null as double) as fee_tier
    , tb.token_sold_mint_address
    , tb.token_bought_mint_address
    , tb.token_sold_vault
    , tb.token_bought_vault
    , tb.pool_id as project_program_id
    , 'CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK' as project_main_id
    , tb.trader_id
    , tb.tx_id
    , tb.outer_instruction_index
    , tb.inner_instruction_index
    , tb.tx_index
from
    all_swaps as tb
), after_model as (
with pools as (
    select
        ip.account_tokenMint0 as tokenA
        , ip.account_tokenVault0 as tokenAVault
        , ip.account_tokenMint1 as tokenB
        , ip.account_tokenVault1 as tokenBVault
        , ip.account_ammConfig as fee_tier
        , ip.account_poolState as pool_id
        , ip.call_tx_id as init_tx
        , ip.call_block_time as init_time
        , row_number() over (partition by ip.account_poolState order by ip.call_block_time desc) as recent_init
    from raydium_clmm_solana."amm_v3_call_createPool" ip
)
, swaps as (
    select
        account_poolState
        , call_is_inner
        , call_outer_instruction_index
        , call_inner_instruction_index
        , call_tx_id
        , call_block_time
        , call_block_slot
        , call_outer_executing_account
        , call_tx_signer
        , call_tx_index
        , cast(null as varchar) as input_mint
        , cast(null as varchar) as output_mint
        , cast(null as varchar) as input_vault
        , cast(null as varchar) as output_vault
    from raydium_clmm_solana."amm_v3_call_swap"
    where call_block_time >= timestamp '2026-10-22 00:00:00'
      and call_block_time < timestamp '2026-11-16 00:00:00'
    union all
    select
        account_poolState
        , call_is_inner
        , call_outer_instruction_index
        , call_inner_instruction_index
        , call_tx_id
        , call_block_time
        , call_block_slot
        , call_outer_executing_account
        , call_tx_signer
        , call_tx_index
        , account_inputVaultMint as input_mint
        , account_outputVaultMint as output_mint
        , account_inputVault as input_vault
        , account_outputVault as output_vault
    from raydium_clmm_solana."amm_v3_call_swapV2"
    where call_block_time >= timestamp '2026-10-22 00:00:00'
      and call_block_time < timestamp '2026-11-16 00:00:00'
)
, transfers as (
    select
        tx_id
        , outer_instruction_index
        , inner_instruction_index
        , amount
        , token_mint_address
        , from_token_account
        , to_token_account
    from tokens_solana."transfers"
    where block_time >= timestamp '2026-10-22 00:00:00'
      and block_time < timestamp '2026-11-16 00:00:00'
)
, all_swaps as (
    select
        sp.call_block_time as block_time
        , 'raydium' as project
        , 3 as version
        , 'solana' as blockchain
        , sp.call_block_slot as block_slot
        , case when sp.call_is_inner = false then 'direct'
            else sp.call_outer_executing_account
            end as trade_source
        , tr_2.amount as token_bought_amount_raw
        , tr_1.amount as token_sold_amount_raw
        , sp.account_poolState as pool_id
        , sp.call_tx_signer as trader_id
        , sp.call_tx_id as tx_id
        , sp.call_outer_instruction_index as outer_instruction_index
        , coalesce(sp.call_inner_instruction_index, 0) as inner_instruction_index
        , sp.call_tx_index as tx_index
        , case when p.pool_id is null then sp.output_mint
            when tr_1.token_mint_address = p.tokenA then p.tokenB
            else p.tokenA
            end as token_bought_mint_address
        , case when p.pool_id is null then sp.input_mint
            when tr_1.token_mint_address = p.tokenA then p.tokenA
            else p.tokenB
            end as token_sold_mint_address
        , case when p.pool_id is null then sp.output_vault
            when tr_1.token_mint_address = p.tokenA then p.tokenBVault
            else p.tokenAVault
            end as token_bought_vault
        , case when p.pool_id is null then sp.input_vault
            when tr_1.token_mint_address = p.tokenA then p.tokenAVault
            else p.tokenBVault
            end as token_sold_vault
    from swaps as sp
    left join pools as p
        on sp.account_poolState = p.pool_id
        and p.recent_init = 1
    inner join transfers as tr_1
        on tr_1.tx_id = sp.call_tx_id
        and tr_1.outer_instruction_index = sp.call_outer_instruction_index
        and ((sp.call_is_inner = false and tr_1.inner_instruction_index = 1)
            or (sp.call_is_inner = true and tr_1.inner_instruction_index = sp.call_inner_instruction_index + 1))
    inner join transfers as tr_2
        on tr_2.tx_id = sp.call_tx_id
        and tr_2.outer_instruction_index = sp.call_outer_instruction_index
        and ((sp.call_is_inner = false and tr_2.inner_instruction_index = 2)
            or (sp.call_is_inner = true and tr_2.inner_instruction_index = sp.call_inner_instruction_index + 2))
    -- swapV2 supplies both vaults and mints even when createPool has no row.
    where p.pool_id is not null
        or (tr_1.to_token_account = sp.input_vault
            and tr_2.from_token_account = sp.output_vault
            and tr_1.token_mint_address = sp.input_mint
            and tr_2.token_mint_address = sp.output_mint)
)

select
    tb.blockchain
    , tb.project
    , tb.version
    , cast(date_trunc('month', tb.block_time) as date) as block_month
    , tb.block_time
    , tb.block_slot
    , tb.trade_source
    , tb.token_bought_amount_raw
    , tb.token_sold_amount_raw
    , cast(null as double) as fee_tier
    , tb.token_sold_mint_address
    , tb.token_bought_mint_address
    , tb.token_sold_vault
    , tb.token_bought_vault
    , tb.pool_id as project_program_id
    , 'CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK' as project_main_id
    , tb.trader_id
    , tb.tx_id
    , tb.outer_instruction_index
    , tb.inner_instruction_index
    , tb.tx_index
from
    all_swaps as tb
)
select date_trunc('day', block_time) as day,
    count_if(version_name = 'before') as before_rows,
    count_if(version_name = 'after') as after_rows,
    count_if(version_name = 'after') - count_if(version_name = 'before') as net_rows
from (
    select 'before' as version_name, block_time from before_model
    union all
    select 'after' as version_name, block_time from after_model
) results
group by 1
order by 1
