use aiken/collection/list.{has}
use aiken/collection/pairs.{has_key}
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/address.{Address, Credential, Inline, Script, VerificationKey}
use cardano/assets.{Lovelace, PolicyId}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, find_input,
}
use redeemers.{MintBeacon, MintGovernanceBeacon, MintStable, PolicyRedeemer}

validator policy(init_utxo: OutputReference) {
  mint(redeemer: PolicyRedeemer, policy_id: PolicyId, transaction: Transaction) {
    when redeemer is {
      //can only be minted if inputs contain init_utxo
      MintGovernanceBeacon -> todo
      //beacon must go to pool script + stake addr, staking key must sign
      MintBeacon -> todo
      MintStable -> todo
    }
  }

  else(_) {
    fail
  }
}
