use aiken/collection/list
use aiken/crypto.{ScriptHash}
use aiken/math/rational
use cardano/address.{Address, Script}
use cardano/assets.{quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Mint, Output, OutputReference, Transaction, Withdraw,
  find_input,
}
use datums.{HusdParamsDatum, PoolDatum}
use redeemers.{
  ClosePool, DepositCollateral, MintHusd, PoolRedeemer, PriceOracleRedeemer,
  WithdrawCollateral,
}
use utils.{staking_cred_approves}

pub const micros_conversion_factor = 1_000_000

validator pool(husd_policy: ScriptHash) {
  spend(
    datum: Option<PoolDatum>,
    redeemer: PoolRedeemer,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    when redeemer is {
      //lovelace must increase, datum must not change, beacon must return
      DepositCollateral -> {
        let Transaction { inputs, outputs, .. } = self
        expect Some(Input(_, Output(own_addr, own_val, ..))) =
          find_input(inputs, own_ref)
        expect Address(Script(script_hash), _) = own_addr
        expect [Output(_, out_val, InlineDatum(out_datum), _)] =
          list.filter(outputs, fn(output) { output.address == own_addr })
        let own_asset_count =
          own_val
            |> assets.flatten()
            |> list.length()
        let out_asset_count =
          out_val
            |> assets.flatten()
            |> list.length()
        //verify beacon is present in input and output to script
        expect assets.quantity_of(own_val, husd_policy, script_hash) == 1
        expect assets.quantity_of(out_val, husd_policy, script_hash) == 1
        //lovelace and the beacon token must be the only assets
        expect out_asset_count == 2
        expect own_asset_count == 2
        //the datum must not change
        expect Some(own_dat) = datum
        expect out_dat: PoolDatum = out_datum
        expect own_dat == out_dat
        //output must have more lovelace
        expect assets.lovelace_of(out_val) > assets.lovelace_of(own_val)
        True
      }
      //lovelace must decrease, datum must not change, beacon token must return, staking key must sign, price oracle validator present, must stay above minimum reserve ratio
      WithdrawCollateral -> {
        let Transaction {
          inputs,
          outputs,
          extra_signatories,
          withdrawals,
          reference_inputs,
          redeemers,
          ..
        } = self
        expect Some(Input(_, Output(own_addr, own_val, ..))) =
          find_input(inputs, own_ref)
        expect Address(Script(script_hash), _) = own_addr
        expect [Output(_, out_val, InlineDatum(out_datum), _)] =
          list.filter(outputs, fn(output) { output.address == own_addr })
        let own_asset_count =
          own_val
            |> assets.flatten()
            |> list.length()
        let out_asset_count =
          out_val
            |> assets.flatten()
            |> list.length()
        //verify beacon is present in input and output to script
        expect assets.quantity_of(own_val, husd_policy, script_hash) == 1
        expect assets.quantity_of(out_val, husd_policy, script_hash) == 1
        //lovelace and the beacon token must be the only assets
        expect out_asset_count == 2
        expect own_asset_count == 2
        //the datum must not change
        expect Some(own_dat) = datum
        expect out_dat: PoolDatum = out_datum
        expect own_dat == out_dat
        //output must have less lovelace
        let new_collateral_total = assets.lovelace_of(out_val)
        expect new_collateral_total < assets.lovelace_of(own_val)
        //staking key must sign
        expect
          staking_cred_approves(
            own_addr.stake_credential,
            extra_signatories,
            withdrawals,
          )
        //price oracle validator withdrawal present
        expect [Input(_, Output(_, _, InlineDatum(husd_datum), _))] =
          list.filter(
            reference_inputs,
            fn(input) {
              quantity_of(input.output.value, husd_policy, "husd_params") == 1
            },
          )
        expect HusdParamsDatum { price_oracle_hash, min_reserve_ratio, .. } =
          husd_datum
        expect Some(Pair(price_oracle_cred, _)) =
          list.find(
            withdrawals,
            fn(Pair(cred, _)) {
              when cred is {
                Script(hash) -> hash == price_oracle_hash
                _other -> False
              }
            },
          )
        //must stay above min reserve ratio
        expect Some(Pair(_, price_redeemer)) =
          list.find(
            redeemers,
            fn(Pair(purpose, _)) {
              when purpose is {
                Withdraw(cred) -> cred == price_oracle_cred
                _other -> False
              }
            },
          )
        expect PriceOracleRedeemer { price } = price_redeemer
        let PoolDatum(liabilities, ..) = out_dat
        let liabilities_in_lovelace =
          liabilities * price / micros_conversion_factor
        expect Some(new_reserve_ratio) =
          rational.new(new_collateral_total, liabilities_in_lovelace)
        expect Some(min_reserve_ratio) =
          rational.new(min_reserve_ratio.1st, min_reserve_ratio.2nd)
        expect rational.compare_with(new_reserve_ratio, >=, min_reserve_ratio)
        True
      }
      //beacon token must return, datum must be correctly updated, price oracle validator present, change in lovelace reflects mint amount, policy mints, if mint > 0 must stay above minimum reserve ratio
      MintHusd(mint_amount) -> {
        let Transaction {
          inputs,
          outputs,
          withdrawals,
          reference_inputs,
          redeemers,
          ..
        } = self
        expect Some(Input(_, Output(own_addr, own_val, ..))) =
          find_input(inputs, own_ref)
        expect Address(Script(script_hash), _) = own_addr
        expect [Output(_, out_val, InlineDatum(out_datum), _)] =
          list.filter(outputs, fn(output) { output.address == own_addr })
        let own_asset_count =
          own_val
            |> assets.flatten()
            |> list.length()
        let out_asset_count =
          out_val
            |> assets.flatten()
            |> list.length()
        //verify beacon is present in input and output to script
        expect assets.quantity_of(own_val, husd_policy, script_hash) == 1
        expect assets.quantity_of(out_val, husd_policy, script_hash) == 1
        //lovelace and the beacon token must be the only assets
        expect out_asset_count == 2
        expect own_asset_count == 2
        //datum must be correctly updated
        expect Some(own_dat) = datum
        expect PoolDatum(liabilities, locked_until, created_at) = out_datum
        expect liabilities - own_dat.liabilities == mint_amount
        let expected_dat =
          PoolDatum {
            liabilities: own_dat.liabilities,
            locked_until,
            created_at,
          }
        expect own_dat == expected_dat
        //price oracle validator withdrawal present
        expect Some(Input(_, Output(_, _, InlineDatum(husd_datum), _))) =
          list.find(
            reference_inputs,
            fn(input) {
              quantity_of(input.output.value, husd_policy, "husd_params") == 1
            },
          )
        expect HusdParamsDatum { price_oracle_hash, min_reserve_ratio, .. } =
          husd_datum
        expect Some(Pair(price_oracle_cred, _)) =
          list.find(
            withdrawals,
            fn(Pair(cred, _)) {
              when cred is {
                Script(hash) -> hash == price_oracle_hash
                _other -> False
              }
            },
          )
        //change in lovelace reflects mint amount
        expect Some(Pair(_, price_redeemer)) =
          list.find(
            redeemers,
            fn(Pair(purpose, _)) {
              when purpose is {
                Withdraw(cred) -> cred == price_oracle_cred
                _other -> False
              }
            },
          )
        expect PriceOracleRedeemer { price } = price_redeemer
        let new_collateral_total = assets.lovelace_of(out_val)
        let collateral_change =
          new_collateral_total - assets.lovelace_of(own_val)
        expect collateral_change / price == mint_amount
        //husd policy is present
        expect
          list.any(
            redeemers,
            fn(Pair(purpose, _)) {
              when purpose is {
                Mint(policy_id) -> policy_id == husd_policy
                _other -> False
              }
            },
          )
        //if mint amount > 0 must stay above minimum reserve ratio
        if mint_amount > 0 {
          let liabilities_in_lovelace =
            liabilities * price / micros_conversion_factor
          expect Some(new_reserve_ratio) =
            rational.new(new_collateral_total, liabilities_in_lovelace)
          expect Some(min_reserve_ratio) =
            rational.new(min_reserve_ratio.1st, min_reserve_ratio.2nd)
          rational.compare_with(new_reserve_ratio, >=, min_reserve_ratio)
        } else {
          True
        }
      }
      //staking key signs, liabilities are 0, husd policy is present with MintBeacon redeemer
      ClosePool -> {
        let Transaction {
          inputs,
          withdrawals,
          redeemers,
          extra_signatories,
          ..
        } = self
        expect Some(Input(_, Output(own_addr, ..))) =
          find_input(inputs, own_ref)
        //staking key must sign
        expect
          staking_cred_approves(
            own_addr.stake_credential,
            extra_signatories,
            withdrawals,
          )
        //liabilities are 0
        expect Some(PoolDatum(liabilities, ..)) = datum
        expect liabilities == 0
        //husd policy is present
        expect
          list.any(
            redeemers,
            fn(Pair(purpose, _)) {
              when purpose is {
                Mint(policy_id) -> policy_id == husd_policy
                _other -> False
              }
            },
          )
        True
      }
    }
  }

  else(_) {
    fail
  }
}
