# ExampleBarcodeAndQRScan

Example of how to show a popup and read machine-readable code in Swift.

To use, drop the BarcodeScannerViewController.swift in your project and
use the ViewController.swift as an example of how to integrate.

You will probably wish to adapt the objectTypesToScan array in
BarcodeScannerViewController. It defines which kind of machine-readable codes
are picked up.

Some current shortcomings:
* Although you can flip the camera, I did not succeed in making the
  front-facing camera read a machine-readable code on my iPhone X. Perhaps it
  should be detected and skipped.
* In the code that flips the camera, I simply loop through all devices and
  search for the opposite position. It may be better to search for the NEXT
  device. I.e. in case of the iPhone X, go from the normal camera to the 2x
  camera.
* When the user has an iPad and uses this app in split view, then the capture
  session is interrupted. If they resize the app and make it full screen, iOS
  doesn't send the notification AVCaptureSessionInterruptionEnded and thus the
  app doesn't continue the capture session. Backgrounding and foregrounding the
  app resumes it again.

