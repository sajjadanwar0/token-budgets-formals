--------------------------- MODULE Budget ---------------------------
(***************************************************************************)
(* Budget v2: state-machine specification of the Token Capabilities        *)
(* discipline at the aggregate level, covering both the original spend     *)
(* path (SpendSuccess, SpendInsufficient, SpendFailPostCheck, Consume) and *)
(* the receipt-path mechanism (Reserve, ConfirmWithRefund, Forfeit,        *)
(* RefundTo) introduced in Section IV-F of the paper.                      *)
(*                                                                         *)
(* Unified-variable design (6 variables instead of v1's 4 + extension      *)
(* delta of 4): replace the v1 split between totalReserved (eager-spend    *)
(* tracking) and totalCharged (a shadow tracker) with two clean            *)
(* categories:                                                             *)
(*                                                                         *)
(*   - totalCharged: cumulative actual provider charges (across all paths) *)
(*   - totalUnrecoverable: budget consumed without producing a charge or   *)
(*                         refund (old-spend overhead + forfeited receipts)*)
(*                                                                         *)
(* This unification simplifies the spec: 6 variables, single CapSoundness  *)
(* invariant (totalCharged <= B0), proofs that are purely arithmetic over  *)
(* Conservation.                                                           *)
(*                                                                         *)
(* SEMANTIC EQUIVALENCE WITH v1: the v1 totalReserved corresponds to       *)
(* (totalCharged_old + totalUnrecoverable_old) where the underscore-old    *)
(* denotes contributions from the old spend actions only. The v1           *)
(* invariant totalCharged_v1 <= totalReserved_v1 is now subsumed by the    *)
(* tighter v2 invariant totalCharged <= B0.                                *)
(*                                                                         *)
(* Note on TLC compatibility: this module extends Naturals only, NOT       *)
(* TLAPS. The TLAPS module is imported by BudgetProofs.tla, where it is    *)
(* needed for proof tactics. This separation lets TLC model-check the      *)
(* spec without needing the TLAPS module to be on the search path.         *)
(*                                                                         *)
(* Backend for the TLAPS proofs: Zenon + Isabelle default chain. No SMT    *)
(* required.                                                               *)
(***************************************************************************)
EXTENDS Naturals

CONSTANT B0    \* Initial budget value (micro-cents). A natural number.

ASSUME B0Type == B0 \in Nat

VARIABLES
    liveSum,              \* Current sum of all live Budget values.
    outstandingReceipts,  \* Sum of amounts held in unconfirmed receipts.
    outstandingRefunds,   \* Sum of refund-token amounts not yet applied.
    totalCharged,         \* Cumulative actual provider charges.
    totalUnrecoverable,   \* Cumulative consumed-without-charge-or-refund:
                          \* old-spend overhead (r - c on SpendSuccess /
                          \* SpendFailPostCheck) plus Forfeit amounts.
    totalReleased         \* Cumulative budget released via Consume.

vars == << liveSum, outstandingReceipts, outstandingRefunds,
           totalCharged, totalUnrecoverable, totalReleased >>

(***************************************************************************)
(* Type invariant                                                          *)
(***************************************************************************)
TypeOK ==
    /\ liveSum \in Nat
    /\ outstandingReceipts \in Nat
    /\ outstandingRefunds \in Nat
    /\ totalCharged \in Nat
    /\ totalUnrecoverable \in Nat
    /\ totalReleased \in Nat

(***************************************************************************)
(* Initial state.                                                          *)
(***************************************************************************)
Init ==
    /\ liveSum = B0
    /\ outstandingReceipts = 0
    /\ outstandingRefunds = 0
    /\ totalCharged = 0
    /\ totalUnrecoverable = 0
    /\ totalReleased = 0

(***************************************************************************)
(* === SPEND-PATH TRANSITIONS ===                                          *)
(*                                                                         *)
(* SpendSuccess(r, c): the LLM call succeeds with reservation r and        *)
(* actual charge c, where 0 <= c <= r.                                     *)
(* Effect: liveSum -= r; totalCharged += c; totalUnrecoverable += (r - c). *)
(* Conservation: -r + c + (r - c) = 0. Preserved.                          *)
(***************************************************************************)
SpendSuccess(r, c) ==
    /\ r \in Nat /\ r > 0
    /\ c \in Nat /\ c <= r
    /\ r <= liveSum
    /\ liveSum' = liveSum - r
    /\ totalCharged' = totalCharged + c
    /\ totalUnrecoverable' = totalUnrecoverable + (r - c)
    /\ UNCHANGED << outstandingReceipts, outstandingRefunds, totalReleased >>

(***************************************************************************)
(* SpendInsufficient(r): runtime check fails; no LLM call.                 *)
(***************************************************************************)
SpendInsufficient(r) ==
    /\ r \in Nat /\ r > 0
    /\ r > liveSum
    /\ UNCHANGED vars

(***************************************************************************)
(* SpendFailPostCheck(r, c): runtime check passes, LLM call fails after,   *)
(* provider may have charged 0 <= c <= r. Same accounting as SpendSuccess  *)
(* at this aggregate level.                                                *)
(***************************************************************************)
SpendFailPostCheck(r, c) ==
    /\ r \in Nat /\ r > 0
    /\ c \in Nat /\ c <= r
    /\ r <= liveSum
    /\ liveSum' = liveSum - r
    /\ totalCharged' = totalCharged + c
    /\ totalUnrecoverable' = totalUnrecoverable + (r - c)
    /\ UNCHANGED << outstandingReceipts, outstandingRefunds, totalReleased >>

(***************************************************************************)
(* Split / Merge: stuttering at the aggregate level.                       *)
(***************************************************************************)
Split == UNCHANGED vars
Merge == UNCHANGED vars

(***************************************************************************)
(* Consume(amount): release `amount` of liveSum back to the host program.  *)
(***************************************************************************)
Consume(amount) ==
    /\ amount \in Nat /\ amount > 0
    /\ amount <= liveSum
    /\ liveSum' = liveSum - amount
    /\ totalReleased' = totalReleased + amount
    /\ UNCHANGED << outstandingReceipts, outstandingRefunds,
                    totalCharged, totalUnrecoverable >>

(***************************************************************************)
(* === RECEIPT-PATH TRANSITIONS ===                                        *)
(***************************************************************************)
Reserve(r) ==
    /\ r \in Nat /\ r > 0
    /\ r <= liveSum
    /\ liveSum' = liveSum - r
    /\ outstandingReceipts' = outstandingReceipts + r
    /\ UNCHANGED << outstandingRefunds, totalCharged,
                    totalUnrecoverable, totalReleased >>

ConfirmWithRefund(r, c) ==
    /\ r \in Nat /\ r > 0
    /\ c \in Nat /\ c <= r
    /\ r <= outstandingReceipts
    /\ outstandingReceipts' = outstandingReceipts - r
    /\ totalCharged' = totalCharged + c
    /\ outstandingRefunds' = outstandingRefunds + (r - c)
    /\ UNCHANGED << liveSum, totalUnrecoverable, totalReleased >>

Forfeit(r) ==
    /\ r \in Nat /\ r > 0
    /\ r <= outstandingReceipts
    /\ outstandingReceipts' = outstandingReceipts - r
    /\ totalUnrecoverable' = totalUnrecoverable + r
    /\ UNCHANGED << liveSum, outstandingRefunds, totalCharged, totalReleased >>

RefundTo(amount) ==
    /\ amount \in Nat /\ amount > 0
    /\ amount <= outstandingRefunds
    /\ outstandingRefunds' = outstandingRefunds - amount
    /\ liveSum' = liveSum + amount
    /\ UNCHANGED << outstandingReceipts, totalCharged,
                    totalUnrecoverable, totalReleased >>

(***************************************************************************)
(* Next-state relation                                                     *)
(***************************************************************************)
Next ==
    \/ \E r, c \in 0..B0 : SpendSuccess(r, c)
    \/ \E r \in 0..(B0 + 1) : SpendInsufficient(r)
    \/ \E r, c \in 0..B0 : SpendFailPostCheck(r, c)
    \/ \E amount \in 1..B0 : Consume(amount)
    \/ \E r \in 1..B0 : Reserve(r)
    \/ \E r, c \in 0..B0 : ConfirmWithRefund(r, c)
    \/ \E r \in 1..B0 : Forfeit(r)
    \/ \E amount \in 1..B0 : RefundTo(amount)
    \/ Split
    \/ Merge

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* SAFETY PROPERTIES                                                       *)
(***************************************************************************)
Conservation ==
    liveSum
    + outstandingReceipts
    + outstandingRefunds
    + totalCharged
    + totalUnrecoverable
    + totalReleased
    = B0

CapSoundness ==
    totalCharged <= B0

Inv ==
    /\ TypeOK
    /\ Conservation
    /\ CapSoundness

=============================================================================
