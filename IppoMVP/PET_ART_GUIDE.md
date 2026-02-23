# Pet Art Generation Guide

## LOCKED-IN ART STYLE (v3 -- FINAL)

**Style name:** "Chibi Sticker" / Polished Mobile Game Sprite

**Key characteristics:**
- **Thick clean dark outlines** around the entire character (like a sticker cutout)
- **Flat/simple colors** with minimal shading -- NOT painterly, NOT heavily rendered
- **Chibi proportions** -- oversized head, small body, stubby limbs
- **Big expressive dark eyes** with single white sparkle/highlight reflection
- **Pink blush marks** on cheeks
- **Small gentle smile** -- happy, content expression
- **Soft warm glow** emanating around the character edges (subtle, not overpowering)
- **Clean white background**, centered composition
- **No text, no watermarks, no extra elements, single character only**

**Color approach:**
- Flat color fills with very subtle gradient/cel-shade at most
- Warm palette overall (even cool-colored characters feel warm)
- Dark outlines are dark brown/near-black, NOT pure black

**What this style is NOT:**
- NOT painterly/watercolor
- NOT heavily shaded/rendered
- NOT Studio Ghibli
- NOT realistic
- NOT sketchy/rough
- NOT 3D rendered

**Reference images (in generated_art/):**
- `mossworth_01_tree_b.png` -- Tree stump spirit, best example of the sticker style
- `dewdrop_01_dragon_b.png` -- Baby dragon, clean simple style
- The fox from `mossworth_01_tree_c.png` (right side) -- Flat fennec fox, perfect sticker style

**Prompt template:**
```
[Description of creature], chibi sticker style illustration, thick clean dark outlines, 
flat simple colors with minimal shading, big expressive dark eyes with sparkle highlight, 
pink blush cheeks, small gentle smile, chibi proportions with oversized head, 
soft warm glow around edges, clean white background, centered, single character only, 
no text, no watermarks, polished mobile game character sprite
```

---

## Current Starters (Phase 1)

### Lumira -- Fennec Fox Spirit
- **Base animal:** Baby fennec fox
- **Color palette:** Golden-orange fur, fluffy white chest, amber eyes
- **Key features:** Enormous pointed ears, fluffy tail, pink paw pads

### Mossworth -- Tree Spirit
- **Base creature:** Living tree stump / acorn spirit
- **Color palette:** Warm browns (body), greens (leaf crown/sprout)
- **Key features:** Leafy crown on head, single sprout growing from top, branch-like arms, root-like feet, MINI BOW TIE
- **Personality:** Professional yet cutesy

### Dewdrop -- Baby Dragon
- **Base creature:** Baby dragon
- **Color palette:** Soft sky blue, cream belly/underjaw
- **Key features:** Small cream horns, tiny bat-wing nubs, rounded snout, curled tail
- **Important:** Warm and friendly looking, NOT icy/cold

---

## Evolution Stages (10 per pet)

Each pet has 10 micro-evolution stages. Stage 1 is the baby/newborn form.
As stages progress, the creature grows slightly larger, gains more detail,
and becomes more refined -- but ALWAYS stays cute, never becomes intimidating.

**Naming convention:** `{petname}_{stage:02d}.png` (e.g., `lumira_01.png` through `lumira_10.png`)

---

## Image Specifications

- **Size:** Generated at highest quality available, minimum 512x512
- **Format:** PNG with white/transparent background
- **Style:** MUST match the locked-in "Chibi Sticker" style above
- **Composition:** Single character, centered, facing viewer
- **Naming:** `petname_XX.png` where XX is 01-10

## Asset Integration

1. Place files in: `IppoMVP/IppoMVP/Assets.xcassets/Pets/`
2. Create imageset folders or drag into Xcode asset catalog
3. Reference in code via `GamePetDefinition.imageNames` array
