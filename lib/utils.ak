use aiken/collection/list.{has}
use aiken/collection/pairs.{has_key}
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{
  Address, Credential, Inline, Script, StakeCredential, VerificationKey,
}
use cardano/assets.{Lovelace}

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
