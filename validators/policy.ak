use aiken/collection/list.{has}
use aiken/collection/pairs.{has_key}
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/address.{Address, Credential, Inline, Script, VerificationKey}
use cardano/assets.{Lovelace, PolicyId}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, find_input,
}
use redeemers.{MintBeacon, MintStable, PolicyRedeemer}

validator policy {
  mint(redeemer: PolicyRedeemer, policy_id: PolicyId, transaction: Transaction) {
    when redeemer is {
      MintBeacon -> todo
      MintStable -> todo
    }
  }

  else(_) {
    fail
  }
}
