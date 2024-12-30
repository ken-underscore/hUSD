pub type PoolRedeemer {
  DepositCollateral
  WithdrawCollateral
  MintHusd(Int)
  ClosePool
}

pub type PriceOracleRedeemer {
  price: Int,
}

pub type ResolvedOraclePrice {
  price: Int,
}
