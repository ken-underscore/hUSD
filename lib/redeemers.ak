pub type PoolRedeemer {
  Deposit
  Withdraw
  Mint
  ClosePool
}

pub type PriceOracleRedeemer {
  price: Int,
}

pub type PolicyRedeemer {
  MintBeacon
  MintStable
}
