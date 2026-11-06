# MATLAB code review and provenance

## Archival files
- `original_matlab_redacted/Right_leg_original_redacted.m` is a copy of the uploaded `Right_leg(2).m`, with only the identifying Excel basename replaced by `REDACTED_RECORDING.xlsx`.
- `original_matlab_redacted/Double_Limb_Support_original_redacted.m` is based on the uploaded `Double_Limb_Support.m`; its participant-derived hard-coded stance arrays were replaced with empty arrays. It is preserved as source history, **not runnable as provided**.

## Corrections in maintained MATLAB functions
1. Reads a configurable recording file instead of relying on an identifying hard-coded basename.
2. Checks timestamp monotonicity, sample frequency, column count and signal units.
3. Uses seconds for minimum peak spacing rather than fixed sample counts.
4. Keeps gyro event indices separate from later acceleration peak-detection operations.
5. Pairs toe-off, mid-swing, heel-strike, next toe-off in time order rather than mixing adjacent intervals.
6. Computes cadence as 120/mean full-stride time (assuming two steps per stride).
7. Ignores zero-duration interval overlaps in double-support computation.
8. Removes the undefined `stanceStartIndex` / `stanceEndIndex` reference from the maintained workflow.
9. Does **not** claim reliable gravity correction, ZUPT, speed or stride length: those require validated orientation and units, stance segmentation and original recordings. Old formulas remain visible in the archival original for research transparency.
10. Generates new MATLAB plots only if authorised original Excel data are available. Included static figures are excerpts from the archived thesis PDF, not newly computed plots.

## Scientific limitations
Event labels depend on gyro sensor-axis alignment and validation against ground truth. The original script's figures and published findings have not been independently reproduced or recalculated. The revised script is an interpretable starting point, not a validated clinical device.
