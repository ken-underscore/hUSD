use aiken/collection/dict
use aiken/collection/list.{has}
use aiken/collection/pairs.{has_key}
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use aiken/option
use cardano/address.{Address, Credential, Inline, Script, VerificationKey}
use cardano/assets.{PolicyId, quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Spend, Transaction, find_input,
}
use datums.{HusdParamsDatum, PoolDatum}
use redeemers.{ClosePool, MintHusd, PoolRedeemer}
use utils.{get_husd_params, staking_cred_approves}

validator husd_policy {
  mint(_redeemer: Data, policy_id: PolicyId, transaction: Transaction) {
    //beacon must go to pool script + stake addr, staking key must sign
    let Transaction {
      inputs,
      reference_inputs,
      outputs,
      mint,
      withdrawals,
      extra_signatories,
      redeemers,
      id,
      ..
    } = transaction
    let HusdParamsDatum { pool_script, .. } =
      get_husd_params(reference_inputs, policy_id)
    //find the expected mints based on redeemers from pool_script
    let (expected_stable_mint, expected_beacon_mint) =
      list.foldl(
        redeemers,
        (0, 0),
        fn(Pair(purpose, redeemer), (stable_mint, beacon_mint)) {
          when purpose is {
            Spend(out_ref) -> {
              expect Some(Input(_, Output(Address(cred, _), ..))) =
                find_input(inputs, out_ref)
              when cred is {
                Script(hash) ->
                  if hash == pool_script {
                    expect mint_redeemer: PoolRedeemer = redeemer
                    when mint_redeemer is {
                      MintHusd(amount) -> (stable_mint + amount, beacon_mint)
                      ClosePool -> (stable_mint, beacon_mint - 1)
                      _other -> (stable_mint, beacon_mint)
                    }
                  } else {
                    (stable_mint, beacon_mint)
                  }
                _other -> (stable_mint, beacon_mint)
              }
            }
            _other -> (stable_mint, beacon_mint)
          }
        },
      )
    let husd_tokens = assets.tokens(mint, policy_id)
    let actual_stable_mint =
      husd_tokens |> dict.get("HUSD") |> option.or_else(0)
    //mint total must match pool script redeemers
    expect expected_stable_mint == actual_stable_mint
    let actual_beacon_mint =
      husd_tokens |> dict.get(pool_script) |> option.or_else(0)
    //must only mint HUSD or beacon tokens
    expect
      husd_tokens
        |> dict.delete("HUSD")
        |> dict.delete(pool_script)
        |> dict.is_empty()
    //if actual_beacon_mint is greater there should be new pool(s) being created
    if actual_beacon_mint > expected_beacon_mint {
      let new_pools =
        list.foldl(
          outputs,
          0,
          fn(Output(addr, val, dat, _), pools) {
            if quantity_of(val, policy_id, pool_script) == 1 {
              expect InlineDatum(inline) = dat
              expect PoolDatum { liabilities, locked_until, created_at } =
                inline
              expect Address(Script(hash), stake_cred) = addr
              //beacon must go to pool script
              expect hash == pool_script
              if created_at == id {
                //new beacon must go to signed stake cred
                expect
                  staking_cred_approves(
                    stake_cred,
                    extra_signatories,
                    withdrawals,
                  )
                expect liabilities == 0
                expect locked_until == 0
                pools + 1
              } else {
                pools
              }
            } else {
              pools
            }
          },
        )
      //new pools must account for the difference between actual_beacon_mint and expected_beacon_mint
      actual_beacon_mint == expected_beacon_mint + new_pools
    } else if actual_beacon_mint == expected_beacon_mint {
      True
    } else {
      False
    }
  }

  else(_) {
    fail
  }
}
