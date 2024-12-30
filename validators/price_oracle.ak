use aiken/collection/list
use aiken/crypto.{ScriptHash}
use aiken/math/rational
use cardano/address.{Address, Credential, Script}
use cardano/assets.{quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Mint, Output, OutputReference, Transaction, Withdraw,
  find_input,
}
use datums.{HusdParamsDatum, PoolDatum}
use redeemers.{PriceOracleRedeemer, ResolvedOraclePrice}
use utils.{get_husd_params, staking_cred_approves}

validator price_oracle(husd_policy: ScriptHash) {
  withdraw(
    redeemer: ResolvedOraclePrice,
    credential: Credential,
    transaction: Transaction,
  ) {
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
    let HusdParamsDatum { price_oracles, .. } =
      get_husd_params(reference_inputs, husd_policy)

    True
  }

  else(_) {
    fail
  }
}
