# Capital College Racing — Vehicle Telemetry Analyzer v1.0

Scope: GPS path, vehicle speed, and cornering (lateral) g only. No extra MATLAB toolboxes, online maps, ECU connection, or hardware drivers are required. Intended for base MATLAB R2020a or newer with desktop graphics. GNU Octave compatibility is not claimed.

## Start here

1. Extract the ZIP to a folder you can write to.
2. Open MATLAB. In the Current Folder panel, navigate to the extracted `CCR_Telemetry_Analyzer_v1` folder containing the `.m` files. Alternatively use `cd('C:\your\folder\CCR_Telemetry_Analyzer_v1')` on Windows, replacing the path with your actual folder.
3. Type `run_demo` in the Command Window and press Enter, or open `run_demo.m` and click Run.
4. A dashboard opens. The Command Window displays metrics and the full results folder path. Every run creates a separate folder beneath `results`.
5. Use the figure toolbar to zoom, pan, and inspect points. Speed and lateral-g time plots share a linked time axis. Close the figure when finished.

The demo banner says **SYNTHETIC DEMO — NOT CAR MEASUREMENTS**. Nothing in this demo is measured on CCR's car.

## Exact commands

```matlab
run_demo
% Same demo, without clearing your workspace:
result = ccr_analyzer();

% Import the supplied sample (also synthetic):
result = ccr_analyzer('sample_SYNTHETIC.csv');

% Import your prepared canonical CSV (replace the file path):
result = ccr_analyzer('C:\Users\YourName\Documents\test_run.csv');

% Choose the parent export folder:
result = ccr_analyzer('test_run.csv', 'my_results');

% Export plots without displaying their window:
result = ccr_analyzer('sample_SYNTHETIC.csv', 'my_results', false);

% Inspect returned tables:
result.data
result.metrics
result.outputDirectory

% Generate another identical demo CSV:
writetable(ccr_generate_demo(), 'another_SYNTHETIC.csv');

% Run the included acceptance tests:
ccr_self_test
```

All `.m` files must be in the Current Folder or on MATLAB's path. Paths may contain spaces when enclosed in quotes. Outputs require a writable folder. A false `showPlots` still creates and exports an invisible figure; graphics support is required.

## CSV contract and units

Use a comma-delimited text file with exactly one header row, then one synchronized sample per row. Required headers are case sensitive. Their suffixes declare units; there is no separate units row. Extra columns are ignored and excluded from processed exports. Required columns may appear in any order.

| Header | Meaning and required units | Accepted range |
|---|---|---|
| `time_s` | Numeric elapsed/log time in seconds; first sample need not be zero | Nonnegative, strictly increasing |
| `speed_kmh` | Nonnegative vehicle speed in kilometres per hour | 0–300 |
| `latitude_deg` | WGS84 latitude in decimal degrees | −90 to +90 |
| `longitude_deg` | WGS84 longitude in decimal degrees | −180 to +180 |
| `lateral_g` | Signed lateral acceleration divided by standard gravity | −5 to +5 |
| `is_synthetic` | Provenance flag for every row | All 1 for synthetic; all 0 for user-declared measured data |

The range limits are sanity checks for this FSAE project, not car performance limits. The program checks names, numeric content, bounds and timestamps. It **cannot prove the physical units or provenance** of numbers from a header. You must verify those before import. A CSV marked 0 is labeled “IMPORTED DATA — USER DECLARED NON-SYNTHETIC”; this is not independent verification.

At least three rows are required. Blanks, NaN, infinity, duplicate or reversed timestamps, and mixed provenance flags are rejected. Missing columns produce an error. No sorting, interpolation, smoothing, missing-data filling or automatic unit guessing takes place. Fix problems in a copy of the source log. A timestamp gap greater than five times the median interval produces a warning; integration still spans that gap. GPS positions of (0,0) and paths spanning more than 0.1 degree produce warnings requiring inspection. Invalid GPS fixes inside legal coordinate bounds cannot be reliably detected by this format.

Convert before saving:

- m/s → km/h: multiply by 3.6.
- mph → km/h: multiply by 1.609344.
- milliseconds → seconds: divide by 1000.
- lateral acceleration in m/s² → g: divide by 9.80665.
- Latitude/longitude must be decimal degrees, not degrees/minutes/seconds or metre coordinates.

For measured data, adopt positive lateral g for left turns and negative for right turns, and document any axis/sign correction you make. The analyzer plots the supplied sign without changing it. An accelerometer requires mounting orientation and calibration; tilt, banking, gravity projection, vibration and bias can affect its lateral channel. Do not substitute total acceleration magnitude for lateral acceleration.

## Dashboard

1. **Vehicle speed:** speed against elapsed time from the first sample.
2. **Signed cornering g:** supplied lateral-g channel against the same time axis.
3. **GPS path:** north/east offsets from the first fix, coloured by speed. Green circle is the start; red cross is the end. This is a local path plot, not a satellite map. Latitude/longitude remain in the exported CSV.
4. **Speed vs cornering g:** one point per sample, coloured by elapsed time. This helps inspect how cornering acceleration changes with speed; it is not a tire friction envelope or a handling diagnosis.

The local projection uses a spherical Earth radius of 6,371,000 m and longitude scaling at the first latitude. It suits a small track at mid-latitudes. Large regions, polar coordinates, poor GPS fixes and discontinuities can distort the plot. Plot connections do not establish continuous GPS coverage.

## Metrics and exports

Each unique run directory contains:

- `processed_telemetry.csv`: validated required columns, with original timestamps, units and provenance retained.
- `metrics.csv`: metric name, numerical value and unit.
- `run_info.txt`: provenance label, source path, creation time and calculation notes.
- `dashboard.png`: shareable dashboard image with provenance banner.
- `dashboard.fig`: MATLAB figure; reopen using `openfig('full/path/dashboard.fig')`.

Metrics are sample count, duration (`last time − first time`), maximum speed, time-weighted mean speed, speed-integrated distance, peak absolute lateral g, maximum/minimum signed lateral g, time-weighted RMS lateral g, median sample interval and largest sample gap.

`trapz` integrates adjacent samples using trapezoids and actual timestamps. Mean speed is integrated speed divided by duration. Distance integrates km/h divided by 3.6 over seconds, giving metres; it is **not GPS distance**. RMS g is the square root of the time average of squared lateral g. Peak values are raw sample peaks and are sensitive to spikes. Signed extrema are not separately classified left/right cornering peaks when a run only contains one sign. No lap times, turn detection, performance comparisons or inferred limits are calculated.

## How the synthetic data works

`ccr_generate_demo` creates 1,201 samples at 10 Hz over 120 seconds. Speed varies smoothly between 7 and 13 m/s (25.2–46.8 km/h) with a 30-second period. The car follows a flat, counterclockwise circle of radius 45 m. Angular position integrates speed/radius. Lateral g equals `speed_mps^2 / (45 * 9.80665)`, so it is always positive. The arbitrary origin near 40° N, 77° W is not a surveyed CCR track.

This ideal kinematic demonstration has no tire, suspension, road, GPS-noise or accelerometer model. It is useful for learning the interface and checking calculations, not evaluating CCR's vehicle or predicting safe speed. Expected duration is 120 s, integrated distance 1,200 m, maximum speed 46.8 km/h and peak lateral g approximately 0.38296. The supplied sample CSV uses the same equations and rounded numeric values; tiny differences from newly generated data are normal.

## Every code component

| File | Responsibility |
|---|---|
| `run_demo.m` | Beginner entry script; clears workspace/Command Window and runs demo, storing `result`. |
| `ccr_analyzer.m` | Public entry function. Generates or reads data, assigns numeric import types, validates, calculates metrics, creates a unique output directory, exports tables/notes/plots, and returns a struct. |
| `ccr_generate_demo.m` | Deterministic synthetic GPS/speed/g generator; no random seed or toolbox needed. |
| `ccr_validate.m` | Enforces the CSV schema, numerical ranges, timestamps and provenance; warns on time gaps and suspicious GPS extent/fixes. Returns canonical columns only. |
| `ccr_metrics.m` | Calculates statistics using real time intervals; returns a three-column table. Call after validation. |
| `ccr_plot.m` | Builds four dashboard panels using base MATLAB graphics and local GPS coordinates. Call after validation. |
| `ccr_self_test.m` | Checks known demo results, import round trip, output creation and rejection of several malformed inputs. Uses a temporary folder and removes only that test folder afterward. |
| `sample_SYNTHETIC.csv` | Ready-to-import synthetic example with the exact required header and provenance flag. |
| `TEST_REPORT.md` | Records checks actually performed in the delivery environment and runtime limitations. |

The public entry point is `ccr_analyzer`. Helper functions are separated so you can understand and extend one responsibility at a time. Errors use `CCR:` identifiers, which let the self-test verify the reason an input was rejected. `onCleanup` closes the notes file even if writing fails. Previous run outputs are preserved. If plotting/export fails, partial files can remain in the new run folder; do not treat those as a completed run.

## Using real Haltech Nexus R5 data later

Haltech describes the Nexus R5 as including a data logger: https://www.haltech.com/product/ht-195000-nexus-r5-vcu/ . That does not establish the CSV layout of your installed software or guarantee the required GPS channels are present. Confirm your team's actual GPS source, speed source, lateral channel, calibration, logging configuration and synchronization.

This project is a **canonical CSV importer**, not a native Haltech log parser. No recorded CCR export was available to verify. It does not read proprietary/binary logs, connect to an R5, decode CAN, or assume specific NSP channel names or export menu options. Consult the documentation for your installed Haltech software for log retrieval and export. If it can produce tabular CSV, work on a copy, map its channels into the required columns, convert units, remove metadata/units rows, and save a comma-delimited CSV. If it cannot, obtain a documented supported conversion route before importing. Do not rename a binary log to `.csv`.

Make a channel mapping record containing original name, original unit, conversion, sensor source, sign convention and time reference. Different channels can log at different rates; do not simply combine unrelated rows. Align them to a common timebase using a deliberate documented method before this importer, and inspect gaps/fix validity. The program does not perform synchronization. Preserve the unmodified original log for audit and troubleshooting.

When the first real export arrives, adapt a separate converter to that exact verified format. The canonical importer and analysis functions can then remain stable. Future RPM/throttle/brake additions can be developed later without adding those requirements now.

## Troubleshooting

- **Undefined function:** MATLAB is in the wrong folder; navigate to the folder containing the `.m` files.
- **Missing columns:** compare the first CSV line with the required header, including capitalization and unit suffixes. Remove vendor preamble and unit rows in a copy.
- **Numeric error:** check for blanks, text units in data cells, missing-value markers and nonnumeric timestamps.
- **Time error:** verify seconds, remove duplicates deliberately and check ordering in the original log. The app will not silently sort.
- **Speed/g range error:** verify unit conversion and sensor calibration before changing limits.
- **No useful GPS path:** check valid fixes, correct decimal degrees and lat/lon order. Constant coordinates are accepted but show a point.
- **Cannot write files:** choose a writable output directory and check free storage.
- **Graphics error:** run in MATLAB with graphics support. The invisible export mode still requires graphics.

No installation of Signal Processing, Mapping, Vehicle Network or other toolboxes is needed for this version.
