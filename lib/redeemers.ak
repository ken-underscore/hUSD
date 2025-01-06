use core.{Fraction}

pub type PoolRedeemer {
  DepositCollateral
  WithdrawCollateral
  MintHusd(Int)
  ClosePool
}

pub type PriceOracleRedeemer {
  price: Fraction,
}

pub type ResolvedOraclePrice {
  price: Fraction,
}
