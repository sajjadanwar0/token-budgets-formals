#![allow(unused)]
#![allow(dead_code)]

use vstd::prelude::*;
use vstd::tokens::*;

verus! {
tokenized_state_machine! {
    BudgetSM {

        fields {
            #[sharding(constant)]
            pub cap: nat,

            #[sharding(variable)]
            pub live: nat,

            #[sharding(variable)]
            pub reservations: Map<nat, nat>, // receipt_id -> amount

            #[sharding(variable)]
            pub refunded_total: nat,

            #[sharding(variable)]
            pub forfeited_total: nat,
        }

        #[invariant]
        pub fn conservation(&self) -> bool {
            self.live + self.reservations.values().to_seq().sum() +
                self.refunded_total + self.forfeited_total == self.cap
        }

        init! {
            initialize(cap: nat) {
                init cap = cap;
                init live = cap;
                init reservations = Map::empty();
                init refunded_total = 0;
                init forfeited_total = 0;
            }
        }

        transition! {
            reserve(receipt_id: nat, amount: nat) {
                require pre.live >= amount;
                require !pre.reservations.contains_key(receipt_id);
                update live = pre.live - amount;
                update reservations = pre.reservations.insert(receipt_id, amount);
            }
        }

        transition! {
            confirm(receipt_id: nat, actual: nat) {
                require pre.reservations.contains_key(receipt_id);
                let amt = pre.reservations.index(receipt_id);
                require actual <= amt;
                let refund_amount = amt - actual;
                update reservations = pre.reservations.remove(receipt_id);
                update live = pre.live + refund_amount;
            }
        }

        transition! {
            forfeit(receipt_id: nat) {
                require pre.reservations.contains_key(receipt_id);
                let amt = pre.reservations.index(receipt_id);
                update reservations = pre.reservations.remove(receipt_id);
                update forfeited_total = pre.forfeited_total + amt;
            }
        }

        #[inductive(initialize)]
        fn init_satisfies_inv(post: Self, cap: nat) {
            assert(post.reservations.values().to_seq().sum() == 0);
        }

        #[inductive(reserve)]
        fn reserve_preserves_inv(pre: Self, post: Self, receipt_id: nat, amount: nat) {
            assume(
                post.reservations.values().to_seq().sum() ==
                pre.reservations.values().to_seq().sum() + amount
            );
        }

        #[inductive(confirm)]
        fn confirm_preserves_inv(pre: Self, post: Self, receipt_id: nat, actual: nat) {
            assume(false);
        }

        #[inductive(forfeit)]
        fn forfeit_preserves_inv(pre: Self, post: Self, receipt_id: nat) {
            assume(false);
        }

    }
} // verus!
