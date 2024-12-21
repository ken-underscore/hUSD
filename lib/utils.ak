use aiken/collection/list.{has}
use aiken/collection/pairs.{has_key}
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Address, Credential, Inline, Script, VerificationKey}
use cardano/assets.{Lovelace}

pub fn staking_cred_approves(
  addr: Address,
  extra_signatories: List<VerificationKeyHash>,
  withdrawals: Pairs<Credential, Lovelace>,
) -> Bool {
  when addr.stake_credential is {
    None -> True
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
