# Skins design alternatives

Shared content: the registered morning/night products, one weekly date selector, product details, and AI consultation entry. All metadata lives in a single footer below the photograph: product type, brand, ingredient, and usage frequency. Numbers remain above the metadata and identify routine order; 04A/04B denote alternative steps.

- Original: clean white cards, blue typography, 3 columns. Clear container boundaries and aligned image/footer baselines.
- Dresser: a shared pale-blue shelf with open, arched product displays, larger AM/PM section labels, and small tags below each shelf.
- Routine Notes: editorial typography, oversized numbers, vertical item sequences. Morning/night columns sit side by side on desktop, and stack on mobile.

Interaction: brief card entrance, a small photo lift on hover, and restrained date selection feedback. Reduced-motion settings disable animation. Default app remains Original; alternatives use `?design=dresser` and `?design=notes`. The review-only gallery is `/designs.html`.

Validation: 320px and 375px mobile widths, no horizontal overflow, all tags below photos, product details and date filtering; desktop parallel morning/night layout for Routine Notes.
