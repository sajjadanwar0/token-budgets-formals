--------------------------- MODULE Budget ---------------------------
EXTENDS Naturals

CONSTANT B0

ASSUME B0Type == B0 \in Nat

VARIABLES
    liveSum,
    outstandingReceipts,
    outstandingRefunds,
    totalCharged,
    totalUnrecoverable,
    totalReleased

vars == << liveSum, outstandingReceipts, outstandingRefunds,
           totalCharged, totalUnrecoverable, totalReleased >>

TypeOK ==
    /\ liveSum \in Nat
    /\ outstandingReceipts \in Nat
    /\ outstandingRefunds \in Nat
    /\ totalCharged \in Nat
    /\ totalUnrecoverable \in Nat
    /\ totalReleased \in Nat

Init ==
    /\ liveSum = B0
    /\ outstandingReceipts = 0
    /\ outstandingRefunds = 0
    /\ totalCharged = 0
    /\ totalUnrecoverable = 0
    /\ totalReleased = 0

SpendSuccess(r, c) ==
    /\ r \in Nat /\ r > 0
    /\ c \in Nat /\ c <= r
    /\ r <= liveSum
    /\ liveSum' = liveSum - r
    /\ totalCharged' = totalCharged + c
    /\ totalUnrecoverable' = totalUnrecoverable + (r - c)
    /\ UNCHANGED << outstandingReceipts, outstandingRefunds, totalReleased >>

SpendInsufficient(r) ==
    /\ r \in Nat /\ r > 0
    /\ r > liveSum
    /\ UNCHANGED vars

SpendFailPostCheck(r, c) ==
    /\ r \in Nat /\ r > 0
    /\ c \in Nat /\ c <= r
    /\ r <= liveSum
    /\ liveSum' = liveSum - r
    /\ totalCharged' = totalCharged + c
    /\ totalUnrecoverable' = totalUnrecoverable + (r - c)
    /\ UNCHANGED << outstandingReceipts, outstandingRefunds, totalReleased >>

Split == UNCHANGED vars
Merge == UNCHANGED vars

Consume(amount) ==
    /\ amount \in Nat /\ amount > 0
    /\ amount <= liveSum
    /\ liveSum' = liveSum - amount
    /\ totalReleased' = totalReleased + amount
    /\ UNCHANGED << outstandingReceipts, outstandingRefunds,
                    totalCharged, totalUnrecoverable >>

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
