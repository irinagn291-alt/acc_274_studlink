# Studlink

A points-only weekend league for friends who argue about football. You shackle picks into one chain and prove it. The chain scores only if every link holds.

No bookmaker, no account, no money, no server. Two phones share a fixture card by scanning a code.

## Who it is for

Friends who want a local league of weekend picks. Home is the chain itself, not a list of unrelated cards.

## Architecture

The product is one pure fold: `ChainFold.reduce(state:event:)` over a Proof ADT (`bare`, `made`, `proved`, `parted`).

That shape fits this job. A chain is not a bag of independent bets. Each verb has to see the whole object: one link per fixture, one swage before kickoff, Proof as the lock, settlement that stops at the first miss and voids everything below. A store-shaped view model would hide those refusals. The fold is a free function. Tests drive every refusal, the squared load, and the part index without a clock or disk.

UI sits above the fold. `ChainStore` applies an event, then debounces a Codable write of one `ChainBook`. Views never touch UserDefaults.

## Unique feature

Single-swage chain proof.

- A chain pays link count squared, and only when every link holds. Three links pay 9. Six pay 36.
- Before Proof, exactly one unstarted link may be swaged. The second swage is refused and the chain rattles.
- After Proof the chain takes no more links.
- Settlement is a left fold. The first false link writes a SnapMark, parts the chain there, and voids every later link.

Proof House rebuilds from the append-only mark ledger and names the link that parted.

## Art

Paper cut origami collage, typographic. Layered hand-torn paper, typewriter figures cut and inlaid, no sports photography and no currency.

Base prompt used for every asset:

```
Paper cut origami collage, typographic. Layered hand-torn and knife-cut paper with visible deckle edges, fibre grain and slight lift at the corners, photographed flat under soft raking light so each layer throws a thin hairline shadow onto the one beneath. Subjects are built from folded and creased paper strips: interlocking studlink chain links, a shackle, a torn fixture card, a stamped mark. Typographic elements are cut from printed paper — typewriter letterforms and figures physically sliced out and inlaid, never digitally overlaid. Composition is asymmetric and dense, board-like, with one dominant form and smaller cut fragments placed on an implicit grid; enterprise-clean, restrained, no ornament, no gradients, no gloss, no 3D render look, no photographic sports imagery, no crowds, no logos, no currency, no dice, no chips, no emoji. Flat orthographic view, high edge definition, print-plate feel.
```

Imagesets are named `sdl_AppIcon`, `sdl_Splash`, `sdl_Onboarding1` through `sdl_Onboarding3`, `sdl_EmptyHome`, `sdl_EmptyList`, `sdl_CardBackdrop`, `sdl_ControlFace`, `sdl_TwistHero`, `sdl_SuccessMark`, `sdl_HeaderDecor`, `sdl_ChainEmpty`, `sdl_ProofSeal`, `sdl_SnapBreak`, `sdl_ProofHouseEmpty`, `sdl_SeasonEmpty`. Pixel art is filled by a later assets step.

## How this is not a repeat

The other prediction league in the portfolio locks independent fixture cards one at a time, with odds and a purse. Studlink is one object built downward. Length is the only decision. Swage is a second verb with no analogue there. Settlement records the exact part. There is no purse and no odds.

## Build

```bash
cd Studlink
xcodegen generate
xcodebuild build-for-testing -scheme Studlink -destination 'generic/platform=iOS Simulator'
```

Launch keys (after onboarding): `-ReviewScreen today`, `log`, `goals`, `proofhouse`, `settings`.
