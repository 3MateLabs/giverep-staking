/// Module: giverep_staking
/// A simple staking/locking contract where users can stake Coin<T> into a
/// non-transferable owned object and unstake instantly.
#[allow(lint(coin_field))]
module giverep_staking::giverep_staking;

use sui::coin::Coin;

/// A non-transferable wrapper for staked coins.
/// Only has `key` ability, so it cannot be transferred or stored in other objects.
public struct StakedCoin<phantom T> has key {
    id: UID,
    coin: Coin<T>,
}

/// Stake coins by wrapping them in a non-transferable StakedCoin object.
/// The StakedCoin is sent to the caller's address.
public fun stake<T>(coin: Coin<T>, ctx: &mut TxContext) {
    let staked = StakedCoin {
        id: object::new(ctx),
        coin,
    };
    transfer::transfer(staked, ctx.sender());
}

/// Unstake coins by unwrapping the StakedCoin and returning the original Coin.
/// Returns the Coin directly for composability in programmable transactions.
public fun unstake<T>(staked: StakedCoin<T>): Coin<T> {
    let StakedCoin { id, coin } = staked;
    object::delete(id);
    coin
}

/// Merge another StakedCoin into this one, combining their values.
/// The `other` StakedCoin is consumed and destroyed.
public fun merge<T>(self: &mut StakedCoin<T>, other: StakedCoin<T>) {
    let StakedCoin { id, coin } = other;
    object::delete(id);
    self.coin.join(coin);
}

/// Get the value of staked coins without consuming the StakedCoin.
public fun value<T>(staked: &StakedCoin<T>): u64 {
    staked.coin.value()
}

/// Get a reference to the inner coin (for inspection).
public fun coin<T>(staked: &StakedCoin<T>): &Coin<T> {
    &staked.coin
}
