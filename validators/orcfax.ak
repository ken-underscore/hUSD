use aiken/collection/list
use aiken/crypto.{ScriptHash}
use aiken/math/rational
use aiken/primitive/bytearray
use cardano/address.{Address, Credential, Script}
use cardano/assets.{quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Mint, Output, OutputReference, Transaction, Withdraw,
  find_input,
}
use orcfax/feed_id.{starts_with}
use orcfax/rational.{Rational, RationalFsDat} as orcfax_rational
use orcfax/tokens as orcfax_tokens
use orcfax/types as orcfax_t
use orcfax/validity_range.{get_bounds}
use redeemers.{PriceOracleRedeemer}

pub type Params {
  fsp_hash: ByteArray,
  currency: ByteArray,
  ada_is_base: Bool,
}

validator orcfax_oracle(params: Params) {
  withdraw(
    redeemer: PriceOracleRedeemer,
    credential: Credential,
    transaction: Transaction,
  ) {
    let Params { fsp_hash, currency, ada_is_base } = params
    let feed_id = mk_feed_id(currency, ada_is_base)
    let Transaction {
      reference_inputs,
      validity_range,
      mint,
      outputs,
      inputs,
      ..
    } = transaction

    // START: Find Fsp, and extract FsHash
    expect Some(Input { output: Output { datum: InlineDatum(fs_idat), .. }, .. }) =
      reference_inputs
        |> list.find(
            fn(i) {
              (
                i.output.value
                  |> quantity_of(fsp_hash, orcfax_tokens.fsp_vali())
              ) == 1
            },
          )
    expect fs_hash: ByteArray = fs_idat

    // END: Find Fsp, and extract FsHash
    // START: Find Fs, and verify Statement
    // Note: Here we are assuming there will be only one in the tx.
    expect Some(Input { output: Output { datum: InlineDatum(fs_idat), .. }, .. }) =
      reference_inputs
        |> list.find(
            fn(i) {
              ( i.output.value |> quantity_of(fs_hash, orcfax_tokens.fs()) ) == 1
            },
          )
    expect fs_dat: RationalFsDat = fs_idat
    let orcfax_t.FsDat {
      statement: orcfax_t.Statement {
        feed_id: feed_id_,
        created_at,
        body: Rational { num, denom },
      },
      ..
    } = fs_dat

    // We want only the expected price feed 
    expect feed_id_ |> starts_with(feed_id)
    // End: Find Fs, and verify Statement
    //oracle price must match redeemer
    let PriceOracleRedeemer((price_num, price_denom)) = redeemer
    expect num == price_num && denom == price_denom
    True
  }

  else(_) {
    fail
  }
}

pub fn mk_feed_id(currency: ByteArray, ada_is_base: Bool) -> ByteArray {
  if ada_is_base {
    "CER/ADA-" |> bytearray.concat(currency) |> bytearray.concat("/")
  } else {
    "CER/" |> bytearray.concat(currency) |> bytearray.concat("-ADA/")
  }
}
