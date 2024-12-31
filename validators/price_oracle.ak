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
use utils.{average, get_husd_params}

//all price oracles specified in husd_params must be present, aggregation of those prices must match ResolvedOraclePrice
validator price_oracle_aggregator(husd_policy: ScriptHash) {
  withdraw(
    redeemer: ResolvedOraclePrice,
    _credential: Credential,
    transaction: Transaction,
  ) {
    let Transaction { reference_inputs, redeemers, .. } = transaction
    let HusdParamsDatum { price_oracles, .. } =
      get_husd_params(reference_inputs, husd_policy)
    let prices: List<Int> =
      list.filter_map(
        redeemers,
        fn(Pair(purpose, rdmr)) {
          when purpose is {
            Withdraw(Script(hash)) ->
              if list.has(price_oracles, hash) {
                expect PriceOracleRedeemer { price } = rdmr
                Some(price)
              } else {
                None
              }
            _other -> None
          }
        },
      )
    //all price oracles must be present in redeemers
    expect list.length(price_oracles) == list.length(prices)
    //aggregated price must match ResolvedOraclePrice, todo: more advanced handling than average
    expect average(prices) == redeemer.price
    True
  }

  else(_) {
    fail
  }
}
