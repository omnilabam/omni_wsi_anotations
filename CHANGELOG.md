## 0.0.1-beta

* Initial release.
- **Unified Coordinate Space (Level 0)**: All shape coordinates inside models are stored as `double` pixel values at maximum magnification (**Level 0**, where `(0, 0)` is the top-left corner).
- **Hamamatsu NDPI Physical Calibration**: Explicit coordinate transformation between Level 0 pixels and physical nanometers relative to the slide's optical center via the `SlidePhysicalContext` class.
- **Rich Set of Geometric Shapes**:
- **Geometric Computations**:
   
