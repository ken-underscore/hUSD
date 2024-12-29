pub type PoolRedeemer {
  DepositCollateral
  WithdrawCollateral
  MintHusd(Int)
  ClosePool
}

pub type PriceOracleRedeemer {
  price: Int,
}
