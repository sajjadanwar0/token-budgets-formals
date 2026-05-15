--------------------------- MODULE BudgetMC ---------------------------
(***************************************************************************)
(* Wrapper module for TLC model checking. Re-exports Budget's spec; the    *)
(* concrete value of B0 is supplied via Budget.cfg (B0 = 5 by default).    *)
(* No additional constants are introduced here.                            *)
(***************************************************************************)
EXTENDS Budget

=============================================================================
