use aiken/collection/list
use aiken/crypto.{ScriptHash}
use aiken/math/rational
use cardano/address.{Address, Credential, Script}
use cardano/assets.{quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Mint, Output, OutputReference, Transaction, Withdraw,
  find_input,
}
use redeemers.{PriceOracleRedeemer}

validator orcfax_oracle {
  withdraw(
    redeemer: PriceOracleRedeemer,
    credential: Credential,
    transaction: Transaction,
  ) {
    todo
  }

  else(_) {
    fail
  }
}
