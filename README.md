# CCR Telemetry

A MATLAB telemetry project for Capital College Racing, focused on vehicle speed, lateral acceleration, and GPS position.

The project started with synthetic data so development could begin before recorded car data was available. It now also includes a viewer that reads measurements from an iPhone running phyphox and displays them in MATLAB.

This is an early prototype. The aim is to learn how to collect useful measurements, check their units, and understand what the graphs can tell us before adding more vehicle channels.

## What’s included

There are two ways to use the project:

| Mode | What it does | Command |
|---|---|---|
| Phone viewer | Displays speed, sideways acceleration, and a GPS path from phyphox | `ccr_phone_live_fixed` |
| Demo and CSV analyzer | Generates synthetic data or imports a CSV, calculates metrics, and exports results | `run_demo` or `ccr_analyzer` |

The phone viewer uses measurements from the phone. The demo uses generated data, clearly marked as synthetic. The demo does not represent measurements from CCR’s car.

## Requirements

- Desktop MATLAB R2020a or newer, with graphics support. No additional toolboxes are required by this code.
- For the phone viewer: an iPhone with phyphox installed.
- A network connection that allows the laptop to reach the phone directly.

The live viewer uses desktop dialogs and is not intended to run in MATLAB Mobile. Compatibility across the stated MATLAB versions has not been fully tested.

## Quick start: synthetic demo

Download the repository, extract it if needed, and set MATLAB’s Current Folder to the folder containing the `.m` files. Keep the files together; you do not need to open each one.

In the Command Window, beside `>>`, enter:

```matlab
run_demo
```

The demo opens a dashboard and writes results into a new folder under `results`. MATLAB prints the full output location in the Command Window.

The dashboard shows speed against time, lateral g against time, a GPS path coloured by speed, and speed against lateral g. The figure toolbar lets you zoom and inspect points.

## Live measurements from an iPhone

### Set up phyphox

Create a simple experiment with both **Location/GPS** and **Linear Acceleration**, also called acceleration without g. Set the acceleration sensor rate to 50 Hz. GPS will update at its own slower rate.

The fixed viewer expects the channel names confirmed during setup:

| Phone channel | Measurement | Raw unit |
|---|---|---|
| `gpsV` | GPS speed | m/s |
| `lin_accX` | Linear acceleration along the phone’s X axis | m/s² |
| `gpsLat` | Latitude | Decimal degrees |
| `gpsLon` | Longitude | Decimal degrees |

If your experiment uses different names, the viewer needs adapting. Opening the built-in GPS experiment alone will not provide acceleration.

Enable **Allow remote access** in phyphox. Keep the app open and press Play to start recording.

### Connect the laptop

For this version, the laptop and phone must share a reachable local network. A phone hotspot is an alternative to shared Wi-Fi. Campus networks may prevent devices from communicating even when both use the same Wi-Fi name.

Open the exact address displayed by phyphox in the laptop’s browser first. Include `http://` and any port number. The address can change when you change networks.

Then, in MATLAB’s Command Window, run:

```matlab
ccr_phone_live_fixed
```

Paste the current phone address into the prompt. The viewer automatically selects the four channels listed above.

To pass the address directly, use this format, replacing the example address with the one on your phone:

```matlab
ccr_phone_live_fixed('http://192.168.1.20')
```

One MATLAB figure displays:

- Speed against time, in km/h.
- Sideways acceleration against time, in g.
- An approximate GPS path, with a red dot marking the latest received position.

Close the figure to stop the viewer. Stop the recording separately in phyphox.

### Position the phone

For X acceleration to represent sideways vehicle motion, mount the phone securely **flat, screen up, with its top edge pointing toward the front of the vehicle**. Check the axis and sign with a gentle controlled test before interpreting turns.

The viewer uses the supplied acceleration without changing its sign or calibrating it. Tilt, mounting movement, sensor bias, vibration, and the phone’s gravity-removal estimate can affect the reading. Have a passenger handle the equipment during a moving test.

### What the live display actually shows

The viewer requests the latest values, waits 0.2 seconds after each update, and repeats. That gives up to roughly five updates per second, depending on network response. It does not retrieve every 50 Hz acceleration sample.

The time axis is elapsed time on the laptop when values arrive, not the original sensor timestamps. Speed, acceleration, and coordinates can update at different rates. A repeated value does not necessarily mean a fresh measurement arrived.

The time graphs display a rolling 60-second window. The GPS path accumulates changed positions received during the viewer session. It is a local path drawing, not a satellite or road map. GPS drift can make a stationary phone appear to move, and the viewer does not check GPS fix accuracy. It also does not reconstruct movement missed during a network interruption.

**The live viewer does not save its readings.** Export the recording from phyphox if you need to keep the original phone data. Those exports need conversion before the separate CSV analyzer can read them; that converter is not included.

The window indicates when phyphox is paused or a request fails. After three consecutive failed requests, it stops polling. It also stops if it detects a change of experiment/session.

## Analyzing a CSV

To try the supplied sample:

```matlab
result = ccr_analyzer('sample_SYNTHETIC.csv');
```

For a prepared recording:

```matlab
result = ccr_analyzer('my_run.csv');
```

The CSV needs one header row and these columns:

| Column | Meaning | Accepted values |
|---|---|---|
| `time_s` | Time in seconds | Nonnegative, strictly increasing |
| `speed_kmh` | Speed in km/h | 0 to 300 |
| `latitude_deg` | WGS84 latitude in decimal degrees | −90 to +90 |
| `longitude_deg` | WGS84 longitude in decimal degrees | −180 to +180 |
| `lateral_g` | Signed lateral acceleration in g | −5 to +5 |
| `is_synthetic` | Data origin flag | All `1` for synthetic, or all `0` for user-declared measured data |

Headers are case sensitive. Required columns may appear in any order; extra columns are ignored. Use commas as separators and periods as decimal points. Do not include a separate units row.

At least three samples are required. The validator rejects missing or non-finite values, duplicate or reversed timestamps, out-of-range values, and mixed data-origin flags. It warns about large time gaps, unusually large GPS extents, and coordinates at `(0,0)`.

The code does not sort, fill gaps, smooth signals, synchronize channels, or guess units. The headers declare the units, but cannot prove that the numbers use those units. Check and convert the source data first. Marking a file as measured data is your declaration, not verification by the program.

Useful conversions:

```text
Speed in m/s × 3.6 = speed in km/h
Speed in mph × 1.609344 = speed in km/h
Acceleration in m/s² ÷ 9.80665 = acceleration in g
Time in milliseconds ÷ 1000 = time in seconds
```

Lateral g is a supplied input, not a value calculated from the GPS path. For consistent comparisons, document your sensor orientation and use a consistent left/right sign convention.

## Metrics and saved results

The CSV/demo analyzer calculates sample count, duration, maximum speed, time-weighted mean speed, speed-integrated distance, peak absolute lateral g, signed maximum and minimum lateral g, RMS lateral g, median sample interval, and largest sample gap.

Distance is calculated by integrating speed over time; it is not distance measured from GPS coordinates. Time-weighted calculations use the actual sample intervals. Large gaps and sensor spikes can distort the results, so inspect the traces before relying on a summary value.

Each analyzer run creates a separate output folder containing:

| Output | Contents |
|---|---|
| `processed_telemetry.csv` | Validated required columns |
| `metrics.csv` | Metric names, values, and units |
| `run_info.txt` | Data origin, source, creation time, and calculation notes |
| `dashboard.png` | Dashboard image |
| `dashboard.fig` | Figure that can be reopened in MATLAB |

These exports apply to `ccr_analyzer`, not the live phone viewer. A failed export may leave a partially written results folder.

You can choose another output location:

```matlab
result = ccr_analyzer('my_run.csv', 'my_results');
```

The returned structure contains `result.data`, `result.metrics`, and `result.outputDirectory`.

## About the demo data

The generator creates 120 seconds of ideal motion at 10 Hz: 1,201 samples on a flat, counterclockwise circle with a 45 m radius. Speed varies between 25.2 and 46.8 km/h. Lateral acceleration follows `v² / radius`, then converts to g.

Expected checks include a 120-second duration, 1,200 m of speed-integrated distance, and a maximum speed of 46.8 km/h. The GPS origin is arbitrary and does not describe a surveyed CCR track.

This is a calculation and plotting example. It does not model tires, suspension, road conditions, or sensor noise, and should not be used to predict the car’s performance.

## Files

| File | Purpose |
|---|---|
| `ccr_phone_live_fixed.m` | Current live phone viewer with automatic channel selection |
| `ccr_phone_live.m` | Earlier viewer with manual channel selection; use the fixed version for the setup above |
| `run_demo.m` | Starts the synthetic demo; clears the workspace and Command Window |
| `ccr_analyzer.m` | Runs the demo or imports a CSV, calculates metrics, and exports results |
| `ccr_generate_demo.m` | Generates the synthetic data |
| `ccr_validate.m` | Checks required columns and values |
| `ccr_metrics.m` | Calculates summary measurements |
| `ccr_plot.m` | Builds the CSV/demo dashboard |
| `ccr_self_test.m` | Tests the demo calculations, CSV round trip, exports, and selected invalid inputs |
| `sample_SYNTHETIC.csv` | Example input in the analyzer’s format |
| `TEST_REPORT.md` | Records the original delivery checks and their limits |
| `START_HERE.md` | Earlier quick-start guide; use this README for the current fixed viewer |

If your download contains only the original analyzer files, you can run the demo and CSV workflow. The phone instructions also require `ccr_phone_live_fixed.m`.

## Troubleshooting

**MATLAB cannot find the function:** Set Current Folder to the directory containing the `.m` files. Enter commands in the Command Window, not inside the function file.

**“Execution of script as a function is not supported”:** Restore a clean copy of the file. The first line of the fixed viewer must be `function ccr_phone_live_fixed(phoneURL)`, and its filename must remain `ccr_phone_live_fixed.m`. Do not paste run commands above the function definition.

**Cannot connect:** Check the current phyphox address in the laptop browser. Keep phyphox open with remote access enabled. Check the network connection and any port number. If the browser works but MATLAB fails on a Mac, check MATLAB’s Local Network permission in System Settings. During setup, launching MATLAB from Terminal allowed one session to reach the channel-selection stage; that is a troubleshooting observation, not a guaranteed fix.

**Required channels are missing:** Check that the active phone experiment includes both GPS and linear acceleration and uses the names listed above.

**Acceleration stays near zero:** That is expected when the phone is stationary. Confirm phyphox is recording and gently move the phone to check the signal. GPS speed may still be unavailable indoors.

**CSV import fails:** Compare the headers and units with the table above. A raw phyphox export is not automatically compatible with this format. Preserve the original recording and prepare a separate converted copy.

## Testing and next steps

Run the included analyzer checks in MATLAB with:

```matlab
ccr_self_test
```

These checks cover the demo and CSV analyzer, not live networking, phone calibration, or track accuracy. The original delivery environment did not have MATLAB installed. During manual setup, the demo ran and phone configuration could be retrieved, but that does not establish a completed validation of the fixed live viewer.

Further work includes testing the live plots on a recorded route, comparing readings against reference measurements, saving live data with sensor timestamps, and adding a phone-export converter.

Sending data from a car on cellular service to a laptop on campus Wi-Fi requires an internet relay. That relay is not implemented here. This version also has no direct Haltech connection, native log parser, lap timing, or additional engine channels.

## Development

This project was developed with substantial ChatGPT assistance for code and documentation. It is being used to learn MATLAB and explore telemetry for Capital College Racing. The code and measurements still need to be understood, tested, and checked against the team’s actual equipment before being used for engineering decisions.
