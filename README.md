# Save Swimmer

Connected safety and monitoring for open-water swimmers.

Save Swimmer is a working early prototype of a connected safety and monitoring system for open-water swimmers. The project explores how a dorsal wearable, Android apps, GPS, motion sensors, local logging, and session reports can provide more context than location alone.

This is not a certified rescue device. It is a prototype for validating data capture, swimmer context, app workflows, and future early-warning behavior.

## Why It Matters

Open-water swimmers often train far from shore. Family members, coaches, or event organizers may know the intended route, but not the swimmer's real context in the water.

GPS can show location and speed, but it does not always explain whether the swimmer is moving normally, drifting, pausing, rotating differently, or showing unusual movement patterns. Save Swimmer focuses on connected awareness: location, movement, session state, and trusted-contact workflows.

## Current Prototype

The current project includes:

- a dorsal wearable prototype;
- ESP32-based firmware;
- IMU/motion sensor capture;
- GPS/session data capture;
- Bluetooth LE communication;
- microSD CSV logging;
- Android app concepts for athlete, family, coach, and field testing;
- CSV/session analysis tools;
- report and visualization work for rotation, alignment, movement, and GPS speed;
- hardware, enclosure, and wearable-mounting design notes.

## Repository Map

- `SaveSwimmer_Lite_BLE_Viewer_V054/` - current firmware prototype sketch.
- `android/SaveSwimmerAthlete/` - athlete-facing Android app prototype.
- `android/SaveSwimmerFamily/` - family/emergency-contact app prototype.
- `android/SaveSwimmerCoachLive/` - optional coach/event live monitoring prototype.
- `android/SaveSwimmerFieldViewer/` - field testing and live data review app.
- `backend/` - backend/ngrok test support and local data.
- `herramientas/` - CSV/reporting and analysis tools.
- `reportes_atleta/` - athlete report generation work.
- `datasets/` - test data and evidence datasets.
- `diseno_3d/` - enclosure and 3D mockup files.
- `diseno_arnes/` - dorsal harness/mounting pattern for field testing.
- `outputs/` - project notes, cost analysis, and technical planning documents.
- `redes/` and `social_posts/` - project media and public communication drafts.

## Built With

- Codex
- GPT-5.6
- Android
- Java
- ESP32
- Arduino
- Bluetooth LE
- GPS
- microSD
- CSV
- IoT
- Wearable prototyping
- Sensor data analysis
- Data visualization

## How Codex And GPT-5.6 Were Used

Codex and GPT-5.6 were used as an active development partner across the project, including:

- firmware iteration and test planning;
- Android APK versioning, UI adjustments, and debugging;
- BLE/GPS/session workflow design;
- CSV interpretation and report-generation logic;
- biomechanical reference analysis for rotation and alignment context;
- product positioning and safety-language refinement;
- Devpost submission drafting;
- README and documentation preparation;
- hardware roadmap, cost modeling, and prototype planning.

The project existed as a broader idea before OpenAI Build Week, but it was meaningfully extended during the hackathon period with Codex-assisted work across apps, firmware, reports, product documentation, and submission materials.

## Testing Notes

This project combines software and physical prototype work. Judges can review the Android source/APKs, firmware sketch, CSV/reporting tools, documentation, and demo video. The hardware prototype is intended for controlled field validation and is not presented as a finished commercial product.

Recommended review path:

1. Watch the demo video.
2. Read this README.
3. Review the current firmware in `SaveSwimmer_Lite_BLE_Viewer_V054/`.
4. Review Android prototypes under `android/`.
5. Review CSV/reporting outputs and project documentation.

## Safety Note

Save Swimmer is an early-stage prototype. It does not guarantee rescue, replace lifeguards, replace emergency services, or certify swimmer safety. Its current purpose is to validate data capture, connected monitoring workflows, and the product direction for future open-water safety support.

## Next Steps

- More controlled pool and open-water tests.
- Improved wearable mounting and waterproofing.
- Cleaner hardware layout.
- Better live synchronization.
- Improved GPS and motion interpretation.
- Family/emergency-contact workflow refinement.
- Coach/event dashboard refinement.
- International connectivity planning.

