# Validation status

## Performed during packaging
- Inspected the two supplied original MATLAB scripts and reviewed their key assumptions.
- Replaced the hard-coded potentially identifying Excel basename in the publicly archived original.
- Withheld participant-level stance event arrays in the public-facing double-support archive.
- Included the five exact image files uploaded directly by the researcher (verified byte-for-byte by SHA-256).
- Verified image integrity, repository contents and ZIP structure; MATLAB numerical execution remains unverified.

## Not performed / cannot honestly be claimed
- MATLAB runtime execution (MATLAB/Octave not installed in this environment).
- Numerical validation of the improved algorithms against original raw IMU recordings (original Excel workbook unavailable).
- Exact reproduction of thesis/paper figures by rerunning the scripts.
- Validation of sensor axis alignment, gravity compensation, ZUPT, stride length or speed against ground truth.
- Confirmed participant consent, institutional sharing permissions, or redistribution rights for images.

`tests/test_double_support.m` contains unit assertions for small analytical arithmetic cases; they are not participant results. They must be run in MATLAB by the researcher before making scientific performance claims.
