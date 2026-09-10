# Running the tests

From the root of this repository:

```bash
swift test
cd android && ./gradlew :mekuri:check
```

The geometry, the turn model and the spread layout are UIKit-free, so the Swift suite runs on macOS without a simulator, and the Kotlin unit tests are plain JVM tests. `MekuriParityTests.swift` and `MekuriParityTest.kt` assert the same literal expected values on both sides, to an absolute tolerance of 1e-3 at page scale, so a constant that drifts in one language fails there rather than both moving together. The fold itself is verified by running the demos.
