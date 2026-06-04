From Top Require Import BudgetTypedCap.
From Top Require Import BudgetIrisTypedCap.
From Top Require Import BudgetRustBeltTypedCap.

Print Assumptions typed_cap_soundness.
Print Assumptions typed_cap_conservation.
Print Assumptions step_invariant.
Print Assumptions reachable_invariant.

Print Assumptions wp_spend_cap.
Print Assumptions wp_split_cap.
Print Assumptions wp_merge_cap.
Print Assumptions wp_consume_cap.
Print Assumptions budget_inv_cap_excl.
Print Assumptions budget_iris_typed_cap_closed.

Print Assumptions spend_well_typed_max.
Print Assumptions split_well_typed_max.
Print Assumptions merge_well_typed_max.
Print Assumptions consume_well_typed_max.
Print Assumptions rust_to_abstract_refinement_max.
