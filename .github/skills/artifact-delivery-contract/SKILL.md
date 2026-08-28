---
name: artifact-delivery-contract
description: Deliver diagrams, canvases, web UI, and other visual artifacts through an explicit viewing surface with acceptance criteria, an early preview checkpoint, persistent files, and final visual verification. Use whenever artifact completion depends on what a user can open and see.
license: MIT
---

# Artifact delivery contract

An artifact is not delivered merely because source files exist. It must persist
at an agreed location, open in an agreed surface, and pass visual acceptance
criteria.

## Establish the contract

Before substantial implementation, determine:

- artifact type and persistent output path;
- delivery surface (editor, browser, canvas, native application, or file link);
- exact open/show action the user will receive;
- required source and exported formats;
- applicable acceptance matrix rows;
- target viewport, device, or page/slide dimensions;
- whether interactivity, keyboard navigation, printing, or offline use matters.

When the prompt omits a variable, choose the safest conventional default and
state it in the first preview.

## Acceptance matrix

Mark non-applicable rows `N/A` with a reason.

| Area | Acceptance criteria |
| --- | --- |
| Theme | Intentional light/dark/high-contrast behavior; sufficient contrast; no invisible or hard-coded conflicting colors |
| Typography | Readable hierarchy, sizes, line lengths, wrapping, and fallback fonts |
| Navigation | Obvious current state, working links/controls, keyboard path, and no dead ends |
| Layout | No overlap, clipping, accidental overflow, or hidden required content |
| Responsive behavior | Defined behavior at target widths; touch targets and reflow where applicable |
| Content | Accurate labels, no placeholder text, useful empty/error/loading states |
| Accessibility | Semantic structure, focus order, alternative text/labels, and non-color cues as applicable |
| Persistence | Source and required exports saved at stable paths and reopen successfully |
| Delivery | The promised surface opens the exact final artifact, not a stale preview |

## Workflow

1. Create the smallest representative artifact that establishes theme,
   typography, navigation model, and layout direction.
2. **First-preview checkpoint:** persist it and open/show it in the promised
   delivery surface before scaling out. Inspect the rendered result, record
   matrix failures, and correct the design direction.
3. Complete the artifact using the approved direction. Keep source assets local
   and avoid embedding credentials, private data, or unlicensed content.
4. Exercise interaction and navigation paths. Test required viewport sizes or
   fixed dimensions and applicable theme states.
5. Persist the final source and exports. Reopen from the persisted path to catch
   transient or unsaved state.
6. Perform final visual verification on the actual delivery surface. Inspect
   each acceptance row and check for clipping, overlap, contrast, wrapping,
   stale content, broken navigation, and missing assets.
7. Open/show the final artifact to the user and report its persistent path,
   format, acceptance results, and any explicit limitations.

Do not claim visual verification from source inspection, compilation, or a
successful export alone. If the delivery surface cannot be opened or visually
inspected, return `BLOCKED` or `DELIVERED WITH UNVERIFIED VISUALS`, never a full
success claim.
