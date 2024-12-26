use aiken/crypto.{ScriptHash, VerificationKeyHash}
use core.{Fraction}

pub type PoolDatum {
  liabilities: Int,
  locked_until: Int,
}

pub type HusdParamsDatum {
  price_oracle_hash: ScriptHash,
  min_reserve_ratio: Fraction,
  pool_script: ScriptHash,
}
