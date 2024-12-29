use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/transaction.{TransactionId}
use core.{Fraction}

pub type PoolDatum {
  liabilities: Int,
  locked_until: Int,
  created_at: TransactionId,
}

pub type HusdParamsDatum {
  price_oracle_hash: ScriptHash,
  min_reserve_ratio: Fraction,
  pool_script: ScriptHash,
}
