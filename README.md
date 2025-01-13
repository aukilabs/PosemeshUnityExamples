## Posemesh SDK iOS Unity Examples

A basic Unity project that compares the iOS [posemesh SDK](https://github.com/aukilabs/posemesh)'s PnP solver with [ConjureKit Ark](https://github.com/aukilabs/com.aukilabs.unity.ark) pose solver.

Contains a prebuilt posemesh SDK from [this PR](https://github.com/aukilabs/posemesh/pull/24).

Currently the QR code physical square side length is set to 0.05m / 5cm (Assets/Scripts/ArkVsPnpMain.cs `PortalSideLength = 0.05f`), adjust accordingly if you're testing with larger or smaller ones.