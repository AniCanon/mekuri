# Mekuri for Jetpack Compose

How to install the pager, how a page learns it is being turned, and every parameter.

## Installation

The Android library is published to GitHub Packages as `app.mekuri:mekuri`. GitHub's Maven registry requires authentication even for public packages, so supply a personal access token with the `read:packages` scope. Keep it out of the repository — `~/.gradle/gradle.properties` is the usual home.

```kotlin
// settings.gradle.kts
dependencyResolutionManagement {
    repositories {
        mavenCentral()
        google()
        maven {
            url = uri("https://maven.pkg.github.com/AniCanon/mekuri")
            credentials {
                username = providers.gradleProperty("gpr.user").get()
                password = providers.gradleProperty("gpr.key").get()
            }
        }
    }
}
```

```kotlin
// build.gradle.kts
dependencies {
    implementation("app.mekuri:mekuri:0.1.0")
}
```

## Using the pager

Compose has no cascading modifier for arbitrary values, so the Compose API mirrors the concepts rather than the syntax: everything that is a modifier on iOS is a parameter with a default here. The page mode arrives through a composition local so a deep child can read it, exactly as on iOS.

```kotlin
val state = rememberMekuriPagerState(pageCount = pages.size, direction = MekuriDirection.RightToLeft)

MekuriPager(
    state = state,
    configuration = MekuriConfiguration(creaseBow = 0.6f),
    pagingEnabled = !isZoomed,
    onCenterTap = { chromeHidden = !chromeHidden },
    spread = MekuriSpread.Automatic,
    coverStandsAlone = true,
    pageAspectRatio = 2f / 3f,
) { pageIndex ->
    PageContent(page = pages[pageIndex])   // reads LocalMekuriPageMode.current
}

state.animateToPage(n)
```

`MekuriPagerState` carries the selection. `currentPage` follows the page on screen; `animateToPage` curls to its target and `scrollToPage` cuts to it, and a `scrollToPage` arriving mid-turn cancels a pending `animateToPage`. A turn the user grabs and pushes back returns from `animateToPage` normally, with the settled page, rather than throwing. `rememberMekuriPagerState` saves the page across a configuration change.

To hold the state outside composition — in a view model, say — build it directly with the page count as a function, the way Compose's own pager state takes it, so a book that loads its pages later still reports them:

```kotlin
val state = MekuriPagerState(pageCount = { book.pages.size })
```

The fold and gesture knobs live on `MekuriConfiguration`, whose public constructor takes `foldRadius`, `cornerLift`, `creaseBow`, `tapZone`, `snapThreshold`, `settleAnimation` and `reducedMotionOverride` — the same seven the SwiftUI modifiers expose. `settleAnimation` is a Compose `AnimationSpec` and is the one value deliberately not held in parity with iOS; the two animation systems have no shared representation, so the feel is matched by eye and the numbers are not asserted equal.

## Working against a checkout

To develop against the library rather than a release, include `android/` as a composite build. It substitutes the published coordinate automatically:

```kotlin
// settings.gradle.kts
includeBuild("../mekuri/android") {
    name = "mekuri-android"
}
```

See [the SwiftUI guide](swiftui.md) for the same API in Swift, and [the fold](the-fold.md) for what the constants mean.
