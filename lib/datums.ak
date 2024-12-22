use aiken/crypto.{ScriptHash, VerificationKeyHash}

pub type PoolDatum {
  liabilities: Int,
}

pub type HusdParamsDatum {
  price_oracle_hash: ScriptHash,
}
