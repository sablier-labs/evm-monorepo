# NFT Descriptor Pattern

For onchain NFT metadata and SVG generation.

## Architecture

```
src/
├── NFTDescriptor.sol       # Main descriptor (tokenURI logic)
└── libraries/
    ├── NFTSVG.sol          # SVG generation
    └── SVGElements.sol     # Reusable SVG components
```

## Pattern

| Component       | Responsibility                               |
| --------------- | -------------------------------------------- |
| `NFTDescriptor` | Implements `tokenURI()`, composes JSON + SVG |
| `NFTSVG`        | Generates complete SVG from params struct    |
| `SVGElements`   | Reusable cards, circles, text elements       |

## Key Techniques

| Technique                         | Purpose                          |
| --------------------------------- | -------------------------------- |
| `Base64.encode()`                 | Encode SVG/JSON as data URI      |
| `Strings.toHexString()`           | Convert addresses to strings     |
| `*Vars` struct                    | Avoid Stack Too Deep in tokenURI |
| Disable solhint `max-line-length` | SVG strings are long             |

## tokenURI Return Format

```
data:application/json;base64,{base64EncodedJSON}

where JSON = {
  "attributes": [...],
  "description": "...",
  "external_url": "...",
  "name": "...",
  "image": "data:image/svg+xml;base64,{base64EncodedSVG}"
}
```
