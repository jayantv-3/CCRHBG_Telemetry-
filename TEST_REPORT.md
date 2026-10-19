# Delivery verification

- Sample CSV inspected with an independent Python calculation: 1,201 finite numeric rows, expected headers, strictly increasing 0–120 s timestamps, valid coordinate bounds and all synthetic flags set to 1.
- Checked speed range and maximum 46.8 km/h, speed-integrated distance 1,200 m, and lateral g consistency with v²/(45 × 9.80665), within rounding tolerance.
- MATLAB code manually inspected for schema checks, base-MATLAB functions, provenance labeling and export paths.
- ZIP contents checked against the project files. No synced reference files were modified.

MATLAB and Octave were unavailable in this environment. MATLAB code, figure rendering and acceptance tests were NOT executed here; runtime compatibility remains to be confirmed. Run `ccr_self_test` in MATLAB R2020a or newer. It checks demo metrics, CSV round trip, output creation and malformed-input rejection.
