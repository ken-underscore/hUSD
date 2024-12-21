use aiken/collection/list.{has}
use aiken/collection/pairs.{has_key}
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/address.{Address, Credential, Inline, Script, VerificationKey}
use cardano/assets.{Lovelace}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, find_input,
}
use datums.{PoolDatum}
use redeemers.{ClosePool, Deposit, Mint, PoolRedeemer, Withdraw}
use utils.{staking_cred_approves}

validator pool(husd_policy: ScriptHash) {
  spend(
    datum: Option<PoolDatum>,
    redeemer: PoolRedeemer,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    when redeemer is {
      //lovelace must increase, datum must not change
      Deposit -> {
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
        //verify beacon is present in the utxo receiving the deposit and the output to the script
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
      //lovelace must decrease, datum must not change, staking key must sign, must stay above minimum reserve ratio, price oracle validator must succeed
      Withdraw -> {
        let Transaction { inputs, outputs, extra_signatories, withdrawals, .. } =
          self
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
        //verify beacon is present in the utxo receiving the deposit and the output to the script
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
        expect assets.lovelace_of(out_val) < assets.lovelace_of(own_val)
        //staking key must sign
        expect staking_cred_approves(own_addr, extra_signatories, withdrawals)
        todo //price oracle validator must succeed
        todo //must stay above min reserve ratio
        todo
      }
      Mint -> fail
      ClosePool -> fail
    }
    //use value.match
    // expect Some(Datum { owner }) = datum
    // let must_say_hello = redeemer.msg == "Hello, World!"
    // let must_be_signed = list.has(self.extra_signatories, owner)
    // must_say_hello && must_be_signed
  }

  else(_) {
    fail
  }
}
