pub type PoolRedeemer {
  DepositCollateral
  WithdrawCollateral
  Mint
  ClosePool
}

pub type PriceOracleRedeemer {
  price: Int,
}

pub type PolicyRedeemer {
  MintGovernanceBeacon
  MintBeacon
  MintStable
}
