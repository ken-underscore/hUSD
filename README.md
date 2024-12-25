# hUSD

- Fully open source
- Fully decentralized
- No project token
- No rent-seeking fees
- Straightforward protocol
- Scales with users
- Governed by the people using it

## Motivation

There are a lot of people building stablecoins, it's become pretty obvious that they are an extremely important part of the blockchain ecosystem. I'm building hUSD because none of the existing ones are what I'm looking for, I'm building it so I can use it.

I think a lot of people are part of the Cardano ecosystem for the same reason I am, it's an alignment of values. I want a stablecoin that embraces those values and strives to be as close to a primitive of Cardano itself as possible, a truly community owned stablecoin.

## Overview

hUSD takes inspiration from Djed and CDP style stablecoins. Instead of collateral providers pooling collateral like in Djed, every collateral provider has their own individual pool of collateral that anyone can mint/redeem hUSD at. Stablecoin users pay fees directly to the collateral providers they mint/redeem with; the fee is the same for every pool and can be adjusted through governance. A pool's outstanding stablecoin liabilities are tracked and the pool can only mint hUSD as long as its reserve ratio (collateral to liabilities) remains above a certain level.

There are several trade offs to consider for constructing a stablecoin this way.

Advantages:

- By avoiding pooling collateral there is less contention when attempting to mint/redeem stablecoins
- Since hUSD can be redeemed at any time regardless of a pool's reserve ratio, hUSD should be very good at maintaining its peg on the open market
- No collateral pooling means collateral providers continue to maintain staking/voting rights over their ada and there is no need for a secondary token such as Shen is for Djed
- Collateral providers are not "locked" in by a drop in the reserve ratio like in Djed, a pool can be closed by the provider at any time by redeeming the outstanding amount of stablecoins the pool owes in liabilities

Disadvantages:

- Since hUSD can be redeemed at any time, collateral providers don't have full control over the amount of leverage their pool has
- Since hUSD will be fully decentralized, it is only as strong as the oracles it uses


The above are properties that come from how hUSD is constructed, but there are some additional advantages that hUSD would have over other available stablecoins.

Fully decentralized and fully open source with no rent-seeking value extraction, the only fees are those paid directly to collateral providers when minting/redeeming stablecoins


The openness of the protocol is one of the biggest selling points. Anyone can be a collateral provider and open a pool with almost any amount of ada (there will be some small minimum value), there is no fee to pay for doing so and you keep full access to your ada's staking/voting rights. This low barrier to entry could encourage many community members who have yet to get their feet wet with defi to try it out.