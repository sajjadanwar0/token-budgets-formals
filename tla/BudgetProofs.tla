--------------------------- MODULE BudgetProofs ---------------------------

EXTENDS Budget, TLAPS

USE B0Type


LEMMA NatPlusZero == \A n \in Nat : n + 0 = n
    OBVIOUS

LEMMA NatPlusZeroSix == \A n \in Nat : n + 0 + 0 + 0 + 0 + 0 = n
    OBVIOUS

LEMMA NatZeroLeAll == \A n \in Nat : 0 <= n
    OBVIOUS

LEMMA NatPlusNatIsNat == \A x, y \in Nat : x + y \in Nat
    OBVIOUS

LEMMA NatMinusLeqIsNat == \A x, y \in Nat : y <= x => (x - y) \in Nat
    OBVIOUS

LEMMA NatSubAddCancel ==
    \A x, y \in Nat : y <= x => (x - y) + y = x
    OBVIOUS

LEMMA NatSubAddSplit ==
    \A x, y, z \in Nat : z <= y /\ y <= x =>
        (x - y) + z + (y - z) = x
    OBVIOUS

LEMMA B0InNat == B0 \in Nat
    BY B0Type


LEMMA InitImpliesTypeOK == Init => TypeOK
    <1> SUFFICES ASSUME Init PROVE TypeOK
        OBVIOUS
    <1>1. liveSum = B0
        BY DEF Init
    <1>2. liveSum \in Nat
        BY <1>1, B0InNat
    <1>3. outstandingReceipts = 0 /\ outstandingRefunds = 0
          /\ totalCharged = 0 /\ totalUnrecoverable = 0
          /\ totalReleased = 0
        BY DEF Init
    <1>4. outstandingReceipts \in Nat /\ outstandingRefunds \in Nat
          /\ totalCharged \in Nat /\ totalUnrecoverable \in Nat
          /\ totalReleased \in Nat
        BY <1>3
    <1>5. QED
        BY <1>2, <1>4 DEF TypeOK

LEMMA InitImpliesConservation == Init => Conservation
    <1> SUFFICES ASSUME Init PROVE Conservation
        OBVIOUS
    <1>1. liveSum = B0
        BY DEF Init
    <1>2. outstandingReceipts = 0 /\ outstandingRefunds = 0
          /\ totalCharged = 0 /\ totalUnrecoverable = 0
          /\ totalReleased = 0
        BY DEF Init
    <1>3. liveSum + outstandingReceipts + outstandingRefunds
          + totalCharged + totalUnrecoverable + totalReleased = B0
        BY <1>1, <1>2, B0InNat
    <1>4. QED
        BY <1>3 DEF Conservation

LEMMA InitImpliesCapSoundness == Init => CapSoundness
    <1> SUFFICES ASSUME Init PROVE CapSoundness
        OBVIOUS
    <1>1. totalCharged = 0
        BY DEF Init
    <1>2. 0 <= B0
        BY B0InNat, NatZeroLeAll
    <1>3. QED
        BY <1>1, <1>2 DEF CapSoundness

LEMMA InitImpliesInv == Init => Inv
    BY InitImpliesTypeOK, InitImpliesConservation, InitImpliesCapSoundness
       DEF Inv

LEMMA SpendSuccessPreservesInv ==
    Inv /\ (\E r, c \in 0..B0 : SpendSuccess(r, c)) => Inv'
    <1> SUFFICES ASSUME Inv,
                        NEW r \in 0..B0,
                        NEW c \in 0..B0,
                        SpendSuccess(r, c)
                 PROVE Inv'
        OBVIOUS
    <1>1. liveSum \in Nat /\ outstandingReceipts \in Nat
          /\ outstandingRefunds \in Nat /\ totalCharged \in Nat
          /\ totalUnrecoverable \in Nat /\ totalReleased \in Nat
        BY DEF Inv, TypeOK
    <1>2. liveSum + outstandingReceipts + outstandingRefunds
          + totalCharged + totalUnrecoverable + totalReleased = B0
        BY DEF Inv, Conservation
    <1>3. r \in Nat /\ r > 0 /\ c \in Nat /\ c <= r /\ r <= liveSum
        BY DEF SpendSuccess
    <1>4. liveSum' = liveSum - r
          /\ totalCharged' = totalCharged + c
          /\ totalUnrecoverable' = totalUnrecoverable + (r - c)
          /\ outstandingReceipts' = outstandingReceipts
          /\ outstandingRefunds' = outstandingRefunds
          /\ totalReleased' = totalReleased
        BY DEF SpendSuccess
    <1>5. (r - c) \in Nat
        BY <1>3, NatMinusLeqIsNat
    <1>6a. liveSum' \in Nat
        BY <1>1, <1>3, <1>4, NatMinusLeqIsNat
    <1>6b. totalCharged' \in Nat
        BY <1>1, <1>3, <1>4, NatPlusNatIsNat
    <1>6c. totalUnrecoverable' \in Nat
        BY <1>1, <1>4, <1>5, NatPlusNatIsNat
    <1>6d. outstandingReceipts' \in Nat /\ outstandingRefunds' \in Nat
           /\ totalReleased' \in Nat
        BY <1>1, <1>4
    <1>7. TypeOK'
        BY <1>6a, <1>6b, <1>6c, <1>6d DEF TypeOK
    <1>8. (liveSum - r) + (totalCharged + c) + (totalUnrecoverable + (r - c))
          = liveSum + totalCharged + totalUnrecoverable
        BY <1>1, <1>3, <1>5, NatSubAddSplit
    <1>9. liveSum' + outstandingReceipts' + outstandingRefunds'
          + totalCharged' + totalUnrecoverable' + totalReleased' = B0
        BY <1>1, <1>2, <1>3, <1>4, <1>8
    <1>10. Conservation'
        BY <1>9 DEF Conservation
    <1>11. totalCharged' <= B0
        BY <1>6a, <1>6b, <1>6c, <1>6d, <1>9, NatZeroLeAll, B0InNat
    <1>12. CapSoundness'
        BY <1>11 DEF CapSoundness
    <1>13. QED
        BY <1>7, <1>10, <1>12 DEF Inv

LEMMA SpendInsufficientPreservesInv ==
    Inv /\ (\E r \in 0..(B0 + 1) : SpendInsufficient(r)) => Inv'
    <1> SUFFICES ASSUME Inv,
                        NEW r \in 0..(B0 + 1),
                        SpendInsufficient(r)
                 PROVE Inv'
        OBVIOUS
    <1>1. UNCHANGED vars
        BY DEF SpendInsufficient
    <1>2. liveSum' = liveSum /\ outstandingReceipts' = outstandingReceipts
          /\ outstandingRefunds' = outstandingRefunds
          /\ totalCharged' = totalCharged
          /\ totalUnrecoverable' = totalUnrecoverable
          /\ totalReleased' = totalReleased
        BY <1>1 DEF vars
    <1>3. TypeOK' /\ Conservation' /\ CapSoundness'
        BY <1>2 DEF Inv, TypeOK, Conservation, CapSoundness
    <1>4. QED
        BY <1>3 DEF Inv

LEMMA SpendFailPreservesInv ==
    Inv /\ (\E r, c \in 0..B0 : SpendFailPostCheck(r, c)) => Inv'
    <1> SUFFICES ASSUME Inv,
                        NEW r \in 0..B0,
                        NEW c \in 0..B0,
                        SpendFailPostCheck(r, c)
                 PROVE Inv'
        OBVIOUS
    <1>1. liveSum \in Nat /\ outstandingReceipts \in Nat
          /\ outstandingRefunds \in Nat /\ totalCharged \in Nat
          /\ totalUnrecoverable \in Nat /\ totalReleased \in Nat
        BY DEF Inv, TypeOK
    <1>2. liveSum + outstandingReceipts + outstandingRefunds
          + totalCharged + totalUnrecoverable + totalReleased = B0
        BY DEF Inv, Conservation
    <1>3. r \in Nat /\ r > 0 /\ c \in Nat /\ c <= r /\ r <= liveSum
        BY DEF SpendFailPostCheck
    <1>4. liveSum' = liveSum - r
          /\ totalCharged' = totalCharged + c
          /\ totalUnrecoverable' = totalUnrecoverable + (r - c)
          /\ outstandingReceipts' = outstandingReceipts
          /\ outstandingRefunds' = outstandingRefunds
          /\ totalReleased' = totalReleased
        BY DEF SpendFailPostCheck
    <1>5. (r - c) \in Nat
        BY <1>3, NatMinusLeqIsNat
    <1>6a. liveSum' \in Nat
        BY <1>1, <1>3, <1>4, NatMinusLeqIsNat
    <1>6b. totalCharged' \in Nat
        BY <1>1, <1>3, <1>4, NatPlusNatIsNat
    <1>6c. totalUnrecoverable' \in Nat
        BY <1>1, <1>4, <1>5, NatPlusNatIsNat
    <1>6d. outstandingReceipts' \in Nat /\ outstandingRefunds' \in Nat
           /\ totalReleased' \in Nat
        BY <1>1, <1>4
    <1>7. TypeOK'
        BY <1>6a, <1>6b, <1>6c, <1>6d DEF TypeOK
    <1>8. (liveSum - r) + (totalCharged + c) + (totalUnrecoverable + (r - c))
          = liveSum + totalCharged + totalUnrecoverable
        BY <1>1, <1>3, <1>5, NatSubAddSplit
    <1>9. liveSum' + outstandingReceipts' + outstandingRefunds'
          + totalCharged' + totalUnrecoverable' + totalReleased' = B0
        BY <1>1, <1>2, <1>3, <1>4, <1>8
    <1>10. Conservation'
        BY <1>9 DEF Conservation
    <1>11. totalCharged' <= B0
        BY <1>6a, <1>6b, <1>6c, <1>6d, <1>9, NatZeroLeAll, B0InNat
    <1>12. CapSoundness'
        BY <1>11 DEF CapSoundness
    <1>13. QED
        BY <1>7, <1>10, <1>12 DEF Inv

LEMMA SplitPreservesInv == Inv /\ Split => Inv'
    <1> SUFFICES ASSUME Inv, Split PROVE Inv'
        OBVIOUS
    <1>1. UNCHANGED vars
        BY DEF Split
    <1>2. liveSum' = liveSum /\ outstandingReceipts' = outstandingReceipts
          /\ outstandingRefunds' = outstandingRefunds
          /\ totalCharged' = totalCharged
          /\ totalUnrecoverable' = totalUnrecoverable
          /\ totalReleased' = totalReleased
        BY <1>1 DEF vars
    <1>3. TypeOK' /\ Conservation' /\ CapSoundness'
        BY <1>2 DEF Inv, TypeOK, Conservation, CapSoundness
    <1>4. QED
        BY <1>3 DEF Inv

LEMMA MergePreservesInv == Inv /\ Merge => Inv'
    <1> SUFFICES ASSUME Inv, Merge PROVE Inv'
        OBVIOUS
    <1>1. UNCHANGED vars
        BY DEF Merge
    <1>2. liveSum' = liveSum /\ outstandingReceipts' = outstandingReceipts
          /\ outstandingRefunds' = outstandingRefunds
          /\ totalCharged' = totalCharged
          /\ totalUnrecoverable' = totalUnrecoverable
          /\ totalReleased' = totalReleased
        BY <1>1 DEF vars
    <1>3. TypeOK' /\ Conservation' /\ CapSoundness'
        BY <1>2 DEF Inv, TypeOK, Conservation, CapSoundness
    <1>4. QED
        BY <1>3 DEF Inv

LEMMA ConsumePreservesInv ==
    Inv /\ (\E amount \in 1..B0 : Consume(amount)) => Inv'
    <1> SUFFICES ASSUME Inv,
                        NEW amount \in 1..B0,
                        Consume(amount)
                 PROVE Inv'
        OBVIOUS
    <1>1. liveSum \in Nat /\ outstandingReceipts \in Nat
          /\ outstandingRefunds \in Nat /\ totalCharged \in Nat
          /\ totalUnrecoverable \in Nat /\ totalReleased \in Nat
        BY DEF Inv, TypeOK
    <1>2. liveSum + outstandingReceipts + outstandingRefunds
          + totalCharged + totalUnrecoverable + totalReleased = B0
        BY DEF Inv, Conservation
    <1>3. amount \in Nat /\ amount > 0 /\ amount <= liveSum
        BY DEF Consume
    <1>4. liveSum' = liveSum - amount
          /\ totalReleased' = totalReleased + amount
          /\ outstandingReceipts' = outstandingReceipts
          /\ outstandingRefunds' = outstandingRefunds
          /\ totalCharged' = totalCharged
          /\ totalUnrecoverable' = totalUnrecoverable
        BY DEF Consume
    <1>5a. liveSum' \in Nat
        BY <1>1, <1>3, <1>4, NatMinusLeqIsNat
    <1>5b. totalReleased' \in Nat
        BY <1>1, <1>3, <1>4, NatPlusNatIsNat
    <1>5c. outstandingReceipts' \in Nat /\ outstandingRefunds' \in Nat
           /\ totalCharged' \in Nat /\ totalUnrecoverable' \in Nat
        BY <1>1, <1>4
    <1>6. TypeOK'
        BY <1>5a, <1>5b, <1>5c DEF TypeOK
    <1>7. (liveSum - amount) + (totalReleased + amount) = liveSum + totalReleased
        BY <1>1, <1>3, NatSubAddCancel
    <1>8. liveSum' + outstandingReceipts' + outstandingRefunds'
          + totalCharged' + totalUnrecoverable' + totalReleased' = B0
        BY <1>1, <1>2, <1>3, <1>4, <1>7
    <1>9. Conservation'
        BY <1>8 DEF Conservation
    <1>10. totalCharged' <= B0
        BY <1>5a, <1>5b, <1>5c, <1>8, NatZeroLeAll, B0InNat
    <1>11. CapSoundness'
        BY <1>10 DEF CapSoundness
    <1>12. QED
        BY <1>6, <1>9, <1>11 DEF Inv

LEMMA ReservePreservesInv ==
    Inv /\ (\E r \in 1..B0 : Reserve(r)) => Inv'
    <1> SUFFICES ASSUME Inv,
                        NEW r \in 1..B0,
                        Reserve(r)
                 PROVE Inv'
        OBVIOUS
    <1>1. liveSum \in Nat /\ outstandingReceipts \in Nat
          /\ outstandingRefunds \in Nat /\ totalCharged \in Nat
          /\ totalUnrecoverable \in Nat /\ totalReleased \in Nat
        BY DEF Inv, TypeOK
    <1>2. liveSum + outstandingReceipts + outstandingRefunds
          + totalCharged + totalUnrecoverable + totalReleased = B0
        BY DEF Inv, Conservation
    <1>3. r \in Nat /\ r > 0 /\ r <= liveSum
        BY DEF Reserve
    <1>4. liveSum' = liveSum - r
          /\ outstandingReceipts' = outstandingReceipts + r
          /\ outstandingRefunds' = outstandingRefunds
          /\ totalCharged' = totalCharged
          /\ totalUnrecoverable' = totalUnrecoverable
          /\ totalReleased' = totalReleased
        BY DEF Reserve
    <1>5a. liveSum' \in Nat
        BY <1>1, <1>3, <1>4, NatMinusLeqIsNat
    <1>5b. outstandingReceipts' \in Nat
        BY <1>1, <1>3, <1>4, NatPlusNatIsNat
    <1>5c. outstandingRefunds' \in Nat /\ totalCharged' \in Nat
           /\ totalUnrecoverable' \in Nat /\ totalReleased' \in Nat
        BY <1>1, <1>4
    <1>6. TypeOK'
        BY <1>5a, <1>5b, <1>5c DEF TypeOK
    <1>7. (liveSum - r) + (outstandingReceipts + r) = liveSum + outstandingReceipts
        BY <1>1, <1>3, NatSubAddCancel
    <1>8. liveSum' + outstandingReceipts' + outstandingRefunds'
          + totalCharged' + totalUnrecoverable' + totalReleased' = B0
        BY <1>1, <1>2, <1>3, <1>4, <1>7
    <1>9. Conservation'
        BY <1>8 DEF Conservation
    <1>10. totalCharged' <= B0
        BY <1>5a, <1>5b, <1>5c, <1>8, NatZeroLeAll, B0InNat
    <1>11. CapSoundness'
        BY <1>10 DEF CapSoundness
    <1>12. QED
        BY <1>6, <1>9, <1>11 DEF Inv

LEMMA ConfirmWithRefundPreservesInv ==
    Inv /\ (\E r, c \in 0..B0 : ConfirmWithRefund(r, c)) => Inv'
    <1> SUFFICES ASSUME Inv,
                        NEW r \in 0..B0,
                        NEW c \in 0..B0,
                        ConfirmWithRefund(r, c)
                 PROVE Inv'
        OBVIOUS
    <1>1. liveSum \in Nat /\ outstandingReceipts \in Nat
          /\ outstandingRefunds \in Nat /\ totalCharged \in Nat
          /\ totalUnrecoverable \in Nat /\ totalReleased \in Nat
        BY DEF Inv, TypeOK
    <1>2. liveSum + outstandingReceipts + outstandingRefunds
          + totalCharged + totalUnrecoverable + totalReleased = B0
        BY DEF Inv, Conservation
    <1>3. r \in Nat /\ r > 0 /\ c \in Nat /\ c <= r
          /\ r <= outstandingReceipts
        BY DEF ConfirmWithRefund
    <1>4. outstandingReceipts' = outstandingReceipts - r
          /\ totalCharged' = totalCharged + c
          /\ outstandingRefunds' = outstandingRefunds + (r - c)
          /\ liveSum' = liveSum
          /\ totalUnrecoverable' = totalUnrecoverable
          /\ totalReleased' = totalReleased
        BY DEF ConfirmWithRefund
    <1>5. (r - c) \in Nat
        BY <1>3, NatMinusLeqIsNat
    <1>6a. outstandingReceipts' \in Nat
        BY <1>1, <1>3, <1>4, NatMinusLeqIsNat
    <1>6b. totalCharged' \in Nat
        BY <1>1, <1>3, <1>4, NatPlusNatIsNat
    <1>6c. outstandingRefunds' \in Nat
        BY <1>1, <1>4, <1>5, NatPlusNatIsNat
    <1>6d. liveSum' \in Nat /\ totalUnrecoverable' \in Nat
           /\ totalReleased' \in Nat
        BY <1>1, <1>4
    <1>7. TypeOK'
        BY <1>6a, <1>6b, <1>6c, <1>6d DEF TypeOK
    <1>8. (outstandingReceipts - r) + (totalCharged + c)
          + (outstandingRefunds + (r - c))
          = outstandingReceipts + totalCharged + outstandingRefunds
        BY <1>1, <1>3, <1>5, NatSubAddSplit
    <1>9. liveSum' + outstandingReceipts' + outstandingRefunds'
          + totalCharged' + totalUnrecoverable' + totalReleased' = B0
        BY <1>1, <1>2, <1>3, <1>4, <1>8
    <1>10. Conservation'
        BY <1>9 DEF Conservation
    <1>11. totalCharged' <= B0
        BY <1>6a, <1>6b, <1>6c, <1>6d, <1>9, NatZeroLeAll, B0InNat
    <1>12. CapSoundness'
        BY <1>11 DEF CapSoundness
    <1>13. QED
        BY <1>7, <1>10, <1>12 DEF Inv

LEMMA ForfeitPreservesInv ==
    Inv /\ (\E r \in 1..B0 : Forfeit(r)) => Inv'
    <1> SUFFICES ASSUME Inv,
                        NEW r \in 1..B0,
                        Forfeit(r)
                 PROVE Inv'
        OBVIOUS
    <1>1. liveSum \in Nat /\ outstandingReceipts \in Nat
          /\ outstandingRefunds \in Nat /\ totalCharged \in Nat
          /\ totalUnrecoverable \in Nat /\ totalReleased \in Nat
        BY DEF Inv, TypeOK
    <1>2. liveSum + outstandingReceipts + outstandingRefunds
          + totalCharged + totalUnrecoverable + totalReleased = B0
        BY DEF Inv, Conservation
    <1>3. r \in Nat /\ r > 0 /\ r <= outstandingReceipts
        BY DEF Forfeit
    <1>4. outstandingReceipts' = outstandingReceipts - r
          /\ totalUnrecoverable' = totalUnrecoverable + r
          /\ liveSum' = liveSum /\ outstandingRefunds' = outstandingRefunds
          /\ totalCharged' = totalCharged /\ totalReleased' = totalReleased
        BY DEF Forfeit
    <1>5a. outstandingReceipts' \in Nat
        BY <1>1, <1>3, <1>4, NatMinusLeqIsNat
    <1>5b. totalUnrecoverable' \in Nat
        BY <1>1, <1>3, <1>4, NatPlusNatIsNat
    <1>5c. liveSum' \in Nat /\ outstandingRefunds' \in Nat
           /\ totalCharged' \in Nat /\ totalReleased' \in Nat
        BY <1>1, <1>4
    <1>6. TypeOK'
        BY <1>5a, <1>5b, <1>5c DEF TypeOK
    <1>7. (outstandingReceipts - r) + (totalUnrecoverable + r)
          = outstandingReceipts + totalUnrecoverable
        BY <1>1, <1>3, NatSubAddCancel
    <1>8. liveSum' + outstandingReceipts' + outstandingRefunds'
          + totalCharged' + totalUnrecoverable' + totalReleased' = B0
        BY <1>1, <1>2, <1>3, <1>4, <1>7
    <1>9. Conservation'
        BY <1>8 DEF Conservation
    <1>10. totalCharged' <= B0
        BY <1>5a, <1>5b, <1>5c, <1>8, NatZeroLeAll, B0InNat
    <1>11. CapSoundness'
        BY <1>10 DEF CapSoundness
    <1>12. QED
        BY <1>6, <1>9, <1>11 DEF Inv

LEMMA RefundToPreservesInv ==
    Inv /\ (\E amount \in 1..B0 : RefundTo(amount)) => Inv'
    <1> SUFFICES ASSUME Inv,
                        NEW amount \in 1..B0,
                        RefundTo(amount)
                 PROVE Inv'
        OBVIOUS
    <1>1. liveSum \in Nat /\ outstandingReceipts \in Nat
          /\ outstandingRefunds \in Nat /\ totalCharged \in Nat
          /\ totalUnrecoverable \in Nat /\ totalReleased \in Nat
        BY DEF Inv, TypeOK
    <1>2. liveSum + outstandingReceipts + outstandingRefunds
          + totalCharged + totalUnrecoverable + totalReleased = B0
        BY DEF Inv, Conservation
    <1>3. amount \in Nat /\ amount > 0 /\ amount <= outstandingRefunds
        BY DEF RefundTo
    <1>4. outstandingRefunds' = outstandingRefunds - amount
          /\ liveSum' = liveSum + amount
          /\ outstandingReceipts' = outstandingReceipts
          /\ totalCharged' = totalCharged
          /\ totalUnrecoverable' = totalUnrecoverable
          /\ totalReleased' = totalReleased
        BY DEF RefundTo
    <1>5a. outstandingRefunds' \in Nat
        BY <1>1, <1>3, <1>4, NatMinusLeqIsNat
    <1>5b. liveSum' \in Nat
        BY <1>1, <1>3, <1>4, NatPlusNatIsNat
    <1>5c. outstandingReceipts' \in Nat /\ totalCharged' \in Nat
           /\ totalUnrecoverable' \in Nat /\ totalReleased' \in Nat
        BY <1>1, <1>4
    <1>6. TypeOK'
        BY <1>5a, <1>5b, <1>5c DEF TypeOK
    <1>7. (outstandingRefunds - amount) + (liveSum + amount)
          = outstandingRefunds + liveSum
        BY <1>1, <1>3, NatSubAddCancel
    <1>8. liveSum' + outstandingReceipts' + outstandingRefunds'
          + totalCharged' + totalUnrecoverable' + totalReleased' = B0
        BY <1>1, <1>2, <1>3, <1>4, <1>7
    <1>9. Conservation'
        BY <1>8 DEF Conservation
    <1>10. totalCharged' <= B0
        BY <1>5a, <1>5b, <1>5c, <1>8, NatZeroLeAll, B0InNat
    <1>11. CapSoundness'
        BY <1>10 DEF CapSoundness
    <1>12. QED
        BY <1>6, <1>9, <1>11 DEF Inv

THEOREM InvImpliesNextInv ==
    ASSUME Inv, [Next]_vars
    PROVE  Inv'
    <1>1. CASE UNCHANGED vars
        <2>1. liveSum' = liveSum /\ outstandingReceipts' = outstandingReceipts
              /\ outstandingRefunds' = outstandingRefunds
              /\ totalCharged' = totalCharged
              /\ totalUnrecoverable' = totalUnrecoverable
              /\ totalReleased' = totalReleased
            BY <1>1 DEF vars
        <2>2. TypeOK' /\ Conservation' /\ CapSoundness'
            BY <2>1 DEF Inv, TypeOK, Conservation, CapSoundness
        <2>3. QED
            BY <2>2 DEF Inv
    <1>2. CASE Next
        <2>1. CASE \E r, c \in 0..B0 : SpendSuccess(r, c)
            BY <2>1, SpendSuccessPreservesInv
        <2>2. CASE \E r \in 0..(B0 + 1) : SpendInsufficient(r)
            BY <2>2, SpendInsufficientPreservesInv
        <2>3. CASE \E r, c \in 0..B0 : SpendFailPostCheck(r, c)
            BY <2>3, SpendFailPreservesInv
        <2>4. CASE \E amount \in 1..B0 : Consume(amount)
            BY <2>4, ConsumePreservesInv
        <2>5. CASE \E r \in 1..B0 : Reserve(r)
            BY <2>5, ReservePreservesInv
        <2>6. CASE \E r, c \in 0..B0 : ConfirmWithRefund(r, c)
            BY <2>6, ConfirmWithRefundPreservesInv
        <2>7. CASE \E r \in 1..B0 : Forfeit(r)
            BY <2>7, ForfeitPreservesInv
        <2>8. CASE \E amount \in 1..B0 : RefundTo(amount)
            BY <2>8, RefundToPreservesInv
        <2>9. CASE Split
            BY <2>9, SplitPreservesInv
        <2>10. CASE Merge
            BY <2>10, MergePreservesInv
        <2>11. QED
            BY <1>2, <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8, <2>9, <2>10
               DEF Next
    <1>3. QED
        BY <1>1, <1>2

THEOREM SpecImpliesInv == Spec => []Inv
    <1>1. Init => Inv
        BY InitImpliesInv
    <1>2. Inv /\ [Next]_vars => Inv'
        BY InvImpliesNextInv
    <1>3. QED
        BY <1>1, <1>2, PTL DEF Spec

THEOREM SpecImpliesConservation == Spec => []Conservation
    <1>1. Inv => Conservation
        BY DEF Inv
    <1>2. QED
        BY <1>1, SpecImpliesInv, PTL

THEOREM SpecImpliesCapSoundness == Spec => []CapSoundness
    <1>1. Inv => CapSoundness
        BY DEF Inv
    <1>2. QED
        BY <1>1, SpecImpliesInv, PTL

=============================================================================
