# TODO: Fix List Position After Deleting Taken Dose

## Task Description

When deleting a taken dose in PastDosesPage, the list scrolls to the beginning. It should position itself to the next taken dose.

## Steps to Complete

-   [ ] Add ScrollController to PastDosesPage state
-   [ ] Add variable to track deleted index
-   [ ] Modify onDismissed to set deleted index before dispatching delete event
-   [ ] Add BlocListener to handle scroll after state update
-   [ ] Test the implementation
