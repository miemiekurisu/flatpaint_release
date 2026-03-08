# License Decision (final for this export)

## Selected policy
Open-source libraries under `git/libs/` are released under:
- GNU LGPL v2.1+ with Lazarus modified linking exception.

Reference texts:
- `git/licenses/COPYING.LGPL.txt`
- `git/licenses/COPYING.modifiedLGPL.txt`

## Rationale
- Compatible with Lazarus/LCL ecosystem expectations.
- Keeps integration path straightforward for FPC/Lazarus users.
- Avoids introducing additional custom licensing in this public package.

## Scope boundary
- This decision applies to the source published under `git/libs/`.
- It does not automatically apply to all code outside `git/`.
