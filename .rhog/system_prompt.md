Task 3.1.1-2: Connection model + rendering + persistence (Flow Canvas)

I am developing a web app for personal use. It will be build using the Flutter framework (Dart language) for the Web platform. I am planning to use Firebase for the backend, and have the emulators downloaded for debugging/dev purposes. The project has been planned in `.rhog/PLAN.md`, based on the `FEATURES.md` file. The `.rhog` subdirectory contains reference images (in `/mockups`), boilerplate code (in `/boilerplate`), and useful information (in `/skills`). You have access to Flutter and Chrome devtools for debugging, inspection, loggin, profiling, etc.

You have access to the Chrome browser instance, so navigate to `localhost:8080` to access the app if needed. Refresh to show the latest changes for future code changes.

DO NOT modify `system_prompt.md` or `PLAN.md`

Your job is to implement without breaking existing functionality, the specified task:


###### Task 3.1.1-2: Connection model + rendering + persistence (Flow Canvas) [L4]

```text
Prompt (L4):

Implement the connections system referenced in FEATURES.md §3.1.1.

Requirements:
- Connections are created by clicking an out-port (green/red circles) then clicking a destination node.
- While adding a connection:
  - nodes that are not valid destinations (port type mismatch) are greyed out.
- Connections are persisted per-tab in the WorkspaceTab document (Appendix A).

Data model (required):
- class CanvasPortSpec { String portId; String direction; String portType; }
- class CanvasLink {
    String linkId;
    String fromItemId;
    String fromPortId;
    String toItemId;
    String toPortId;
    String relationType; // e.g. outboundDependency|labelledArrow|...
  }

Workspace schema changes:
- Add `links` map to `workspaces/{workspaceId}/tabs/{tabId}`:
  links: { "<linkId>": { fromItemId, fromPortId, toItemId, toPortId, relationType } }

Rendering:
- Draw links as a separate overlay layer (CustomPainter) above items.
- Link endpoints should track the connected item worldRect + port positions.

Operations:
- api.canvas.addLink
- api.canvas.deleteLink

Validation:
- NodeTemplate.renderSpec.ports declares each port’s `portType`.
- A connection is valid only if from.portType is compatible with to.portType.

Add tests:
- Unit tests for port compatibility + link serialization.
```