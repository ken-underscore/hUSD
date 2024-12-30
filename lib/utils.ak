use aiken/collection/list.{has}
use aiken/collection/pairs.{has_key}
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{
  Address, Credential, Inline, Script, StakeCredential, VerificationKey,
}
use cardano/assets.{Lovelace, PolicyId, quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Spend, Transaction, find_input,
}
use datums.{HusdParamsDatum, PoolDatum}

pub fn staking_cred_approves(
  stake_cred: Option<StakeCredential>,
  extra_signatories: List<VerificationKeyHash>,
  withdrawals: Pairs<Credential, Lovelace>,
) -> Bool {
  when stake_cred is {
    None -> False
    Some(ref_cred) ->
      when ref_cred is {
        Inline(cred) ->
          when cred is {
            VerificationKey(vkh) -> has(extra_signatories, vkh)
            Script(_) -> has_key(withdrawals, cred)
          }
        _pointer -> fail @"Pointer address not supported"
      }
  }
}

pub fn get_husd_params(
  ref_inputs: List<Input>,
  policy_id: PolicyId,
) -> HusdParamsDatum {
  expect Some(Input(_, Output(_, _, InlineDatum(husd_datum), _))) =
    list.find(
      ref_inputs,
      fn(input) {
        quantity_of(input.output.value, policy_id, "husd_params") == 1
      },
    )
  expect params: HusdParamsDatum = husd_datum
  params
}
