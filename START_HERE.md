# CCR live phone viewer — start here

Run only ccr_phone_live in desktop MATLAB on your laptop. Keep all files together; you do not open or run every helper file. No extra toolboxes required. MATLAB Mobile is not supported by the selection dialogs.

1. Extract this ZIP. Set MATLAB Current Folder to the extracted folder containing ccr_phone_live.m.
2. On iPhone open your phyphox experiment with BOTH Location/GPS and Linear Acceleration (without g). Enable remote access, press Play and keep phyphox open. Connect laptop and phone to the same network.
3. In the MATLAB Command Window enter: ccr_phone_live
4. Enter the exact current address shown by phyphox, including http:// and any port. The default address is from an earlier session and may have changed.
5. Select GPS speed (m/s), linear acceleration X (m/s^2), GPS latitude (decimal degrees), and GPS longitude (decimal degrees) when prompted. If names are unclear, cancel and share a screenshot of the channel list. Canceling a coordinate selection omits the map.
6. Confirm the acceleration and speed channels. One MATLAB figure shows speed vs time, lateral acceleration in g vs time, and a local GPS path. Close it to stop the viewer. Stop recording separately in phyphox.

For lateral g mount phone flat, screen up, top edge toward vehicle front. Confirm axis/sign with a controlled gentle test. Conversion: speed * 3.6 = km/h; acceleration / 9.80665 = g. The program assumes correct channel selection and does not calibrate mounting, gravity subtraction, bias or sign. A passenger should operate during motion.

The viewer polls latest values at up to about 5 times/second. Time is laptop elapsed time at receipt, not sensor timestamps. GPS updates more slowly and values can repeat. This is a preview, not a full-rate synchronized recording. The time graphs show the last 60 seconds; the path accumulates changed received positions during this viewer session. The map is a local approximate path drawing, without satellite imagery. GPS drift can draw movement while stationary. Fix accuracy and timestamp alignment are not verified. Network gaps are not reconstructed. The viewer does not save data; export the full recording from phyphox for later analysis.

For a separate synthetic demo, run run_demo. The original README.md describes that demo and its canonical CSV analyzer. Its output/export features do not apply to the live viewer. Raw phone CSVs need a converter before that analyzer can import them; none is included.

Delivery checks: ZIP integrity and expected 12-file contents checked. The map update was manually inspected but MATLAB is not installed in the delivery environment, so live behavior must be tested with your phone. ccr_self_test covers the original demo analyzer only, not live streaming.

Reference: https://phyphox.org/docs/remote-interface/
