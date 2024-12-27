use aiken/collection/list.{has}
use aiken/collection/pairs.{has_key}
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/address.{Address, Credential, Inline, Script, VerificationKey}
use cardano/assets.{PolicyId, quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Spend, Transaction, find_input,
}
use datums.{HusdParamsDatum}
use redeemers.{
  MintBeacon, MintGovernanceBeacon, MintHusd, MintStable, PolicyRedeemer,
  PoolRedeemer,
}

validator policy(init_utxo: OutputReference) {
  mint(redeemer: PolicyRedeemer, policy_id: PolicyId, transaction: Transaction) {
    when redeemer is {
      //can only be minted if inputs contain init_utxo
      MintGovernanceBeacon -> todo
      //beacon must go to pool script + stake addr, staking key must sign
      MintBeacon -> todo
      //mint value must matche total of pool script mints
      MintStable -> {
        let Transaction { inputs, reference_inputs, mint, redeemers, .. } =
          transaction
        expect Some(Input(_, Output(_, _, InlineDatum(husd_datum), _))) =
          list.find(
            reference_inputs,
            fn(input) {
              quantity_of(input.output.value, policy_id, "husd_params") == 1
            },
          )
        expect HusdParamsDatum { pool_script, .. } = husd_datum
        let total_expected_mint =
          list.foldl(
            redeemers,
            0,
            fn(Pair(purpose, redeemer), total) {
              when purpose is {
                Spend(out_ref) -> {
                  expect Some(Input(_, Output(Address(cred, _), ..))) =
                    find_input(inputs, out_ref)
                  when cred is {
                    Script(hash) ->
                      if hash == pool_script {
                        expect mint_redeemer: PoolRedeemer = redeemer
                        when mint_redeemer is {
                          MintHusd(amount) -> total + amount
                          _other -> total
                        }
                      } else {
                        total
                      }
                    _other -> total
                  }
                }
                _other -> total
              }
            },
          )
        //mint value must match total of pool script mints
        expect quantity_of(mint, policy_id, "HUSD") == total_expected_mint
        True
      }
    }
  }

  else(_) {
    fail
  }
}
