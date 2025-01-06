use aiken/collection/list
use aiken/crypto.{ScriptHash}
use aiken/math/rational.{Rational}
use cardano/address.{Address, Credential, Script}
use cardano/assets.{quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Mint, Output, OutputReference, Transaction, Withdraw,
  find_input,
}
use core.{Fraction}
use datums.{HusdParamsDatum, PoolDatum}
use redeemers.{PriceOracleRedeemer, ResolvedOraclePrice}
use utils.{get_husd_params}

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
    let prices: List<Rational> =
      list.filter_map(
        redeemers,
        fn(Pair(purpose, rdmr)) {
          when purpose is {
            Withdraw(Script(hash)) ->
              if list.has(price_oracles, hash) {
                expect PriceOracleRedeemer((num, denom)) = rdmr
                rational.new(num, denom)
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
    expect Some(price) = rational.arithmetic_mean(prices)
    and {
      rational.numerator(price) == redeemer.price.1st,
      rational.denominator(price) == redeemer.price.2nd,
    }
  }

  else(_) {
    fail
  }
}
