# Accessibility

The pager is a single element that contains its pages. It exposes the settled page as a value — `Page 3 of 12` — and two actions that turn with the same fold a tap gives: a SwiftUI adjustable action, incrementing forward and decrementing back, and on Compose custom actions named `Next page` and `Previous page`. With paging off the value stays, and the actions differ: Compose removes them, SwiftUI leaves the adjustable action attached and does nothing when it is used.

Those strings are English literals in the library and there is no way to override them. A reader in another language reads its own pages and an English page count.
