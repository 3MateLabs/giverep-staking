#[test_only]
module giverep_staking::giverep_staking_tests;

use sui::coin;
use sui::sui::SUI;
use sui::test_scenario::{Self as ts};
use giverep_staking::giverep_staking::{Self, StakedCoin};

const ALICE: address = @0xA11CE;

#[test]
fun test_stake_and_unstake() {
    let mut scenario = ts::begin(ALICE);

    // Create a test coin and stake it
    {
        let ctx = scenario.ctx();
        let coin = coin::mint_for_testing<SUI>(1000, ctx);
        giverep_staking::stake(coin, ctx);
    };

    // Verify the staked coin was created and sent to Alice
    scenario.next_tx(ALICE);
    {
        let staked = scenario.take_from_sender<StakedCoin<SUI>>();
        assert!(giverep_staking::value(&staked) == 1000);
        ts::return_to_sender(&scenario, staked);
    };

    // Unstake the coin and verify the returned coin
    scenario.next_tx(ALICE);
    {
        let staked = scenario.take_from_sender<StakedCoin<SUI>>();
        let coin = giverep_staking::unstake(staked);
        assert!(coin.value() == 1000);
        coin::burn_for_testing(coin);
    };

    scenario.end();
}

#[test]
fun test_stake_zero_value() {
    let mut scenario = ts::begin(ALICE);

    // Stake a zero-value coin
    {
        let ctx = scenario.ctx();
        let coin = coin::mint_for_testing<SUI>(0, ctx);
        giverep_staking::stake(coin, ctx);
    };

    // Verify staking and unstaking works for zero value
    scenario.next_tx(ALICE);
    {
        let staked = scenario.take_from_sender<StakedCoin<SUI>>();
        assert!(giverep_staking::value(&staked) == 0);
        let coin = giverep_staking::unstake(staked);
        assert!(coin.value() == 0);
        coin::burn_for_testing(coin);
    };

    scenario.end();
}

#[test]
fun test_multiple_stakes() {
    let mut scenario = ts::begin(ALICE);

    // Stake multiple coins
    {
        let ctx = scenario.ctx();
        let coin1 = coin::mint_for_testing<SUI>(100, ctx);
        giverep_staking::stake(coin1, ctx);
    };

    scenario.next_tx(ALICE);
    {
        let ctx = scenario.ctx();
        let coin2 = coin::mint_for_testing<SUI>(200, ctx);
        giverep_staking::stake(coin2, ctx);
    };

    // Verify both staked coins exist
    scenario.next_tx(ALICE);
    {
        // Take and check both staked coins
        let staked1 = scenario.take_from_sender<StakedCoin<SUI>>();
        let staked2 = scenario.take_from_sender<StakedCoin<SUI>>();

        // Values should be 100 and 200 (order may vary)
        let v1 = giverep_staking::value(&staked1);
        let v2 = giverep_staking::value(&staked2);
        assert!(v1 + v2 == 300);

        ts::return_to_sender(&scenario, staked1);
        ts::return_to_sender(&scenario, staked2);
    };

    scenario.end();
}

#[test]
fun test_coin_accessor() {
    let mut scenario = ts::begin(ALICE);

    {
        let ctx = scenario.ctx();
        let coin = coin::mint_for_testing<SUI>(500, ctx);
        giverep_staking::stake(coin, ctx);
    };

    scenario.next_tx(ALICE);
    {
        let staked = scenario.take_from_sender<StakedCoin<SUI>>();

        // Test the coin accessor
        let coin_ref = giverep_staking::coin(&staked);
        assert!(coin_ref.value() == 500);

        ts::return_to_sender(&scenario, staked);
    };

    scenario.end();
}

#[test]
fun test_merge() {
    let mut scenario = ts::begin(ALICE);

    // Stake two coins
    {
        let ctx = scenario.ctx();
        let coin1 = coin::mint_for_testing<SUI>(100, ctx);
        giverep_staking::stake(coin1, ctx);
    };

    scenario.next_tx(ALICE);
    {
        let ctx = scenario.ctx();
        let coin2 = coin::mint_for_testing<SUI>(250, ctx);
        giverep_staking::stake(coin2, ctx);
    };

    // Merge the two staked coins
    scenario.next_tx(ALICE);
    {
        let mut staked1 = scenario.take_from_sender<StakedCoin<SUI>>();
        let staked2 = scenario.take_from_sender<StakedCoin<SUI>>();

        // Merge staked2 into staked1
        giverep_staking::merge(&mut staked1, staked2);

        // Verify the merged value
        assert!(giverep_staking::value(&staked1) == 350);

        ts::return_to_sender(&scenario, staked1);
    };

    // Unstake and verify final value
    scenario.next_tx(ALICE);
    {
        let staked = scenario.take_from_sender<StakedCoin<SUI>>();
        let coin = giverep_staking::unstake(staked);
        assert!(coin.value() == 350);
        coin::burn_for_testing(coin);
    };

    scenario.end();
}
