---
title: Base Plans Refresh is Coming to Habitat Core Plans!
date: 2018-06-13
author: Nell Shamrell-Harrington
tags: core plans
category: update
classes: body-article
---

Greetings, fellow Habicats!

We will be refreshing the base plans of Core Plans on Tuesday, June 19th.  Let's go over what this means for us and, more important, what it means for you.

## Base Plans 101

Currently, there are about 500 Habitat plans under the Core Origin on Builder.

These include everything from services like Postgresql to binaries like Go to very low level system libraries like GCC, all of which you can easily pull into your own Habitat artifacts.

### What's a Base Plan?

The Base Plans are a group of plans (mostly low level systems libraries) that:
* are used by nearly every other plan (or a dependency of that plan) on Builder
* are used to build Habitat itself
* need to be built in a certain order.

You can see [the full list of Base Plans](https://github.com/habitat-sh/core-plans/blob/master/CODEOWNERS) in the Core Plans CODEOWNERS file.

Any time one of these plans is updated (especially ones that are nearly universally used, like [glibc](https://en.wikipedia.org/wiki/GNU_C_Library) and [gcc](https://gcc.gnu.org/), all other base plans which depend on it need to be built in a certain order, and then all plans that depend (or depend on a plan that depends) on those base plans also need to be rebuilt. We call this the "rebuild the world" scenario.

### Why are you refreshing them?

Many of our current base plans are on very old versions - i.e. the current version of gcc on Builder is 5.2.0, when the most recent stable release of gcc is 8.1.0).  It is vital to update them - and consequently every plan that depends on them - to more recent stable versions.

Many of them also must be updated simultaneously - if we update gcc to 8.1 and it requires a later version of glibc than we current have, we must also update glibc.

### What else does it affect?

We are simultaneously refreshing nearly every [core plan](https://github.com/habitat-sh/core-plans/) at the same time as we are refreshing the base plans.  This is because the majority (if not all) of the core plans depend on at least one of the base plans in some fashion (or, at the very least, a base plan is in their dependency chain).

## Base Plans and You

So far we've discussed how and why we are refreshing the base plans and core plans, but what does that mean for the plans in your own origin?

### How does this affect me?

Chances are, any plan within your origin depends on at least one of the core base plans somewhere in its chain of dependencies.  When that plan is updated, your plan also must be rebuilt.  This sounds simple, but if you have plans in your origin that depend on other plans - and those plans depend on a core plan (let's say glibc), all of them must be built with the same version of glibc.  Let's look at this visually.

### Dependencies

Let's say I have a plan under my origin (nellshamrell) called widget_world - let's say it lives at nellshamrell/widget_world on Builder.

```
nellshamrell/widget_world
```

Now, let's say that plan depends on two more plans nellshamrell/widget and nellshamrell/world (yes, it's contrived, just go with it for now).

```
nellshamrell/widget_world
-> nellshamrell/widget
-> nellshamrell/world
```

And let's say each of those plans depends on core/glibc for some reason

```
nellshamrell/widget_world
-> nellshamrell/widget
   --> core/glibc
-> nellshamrell/world
   --> core/glibc
```

And let's say both are using the current core/glibc plan, which means they are both using version 2.22

```
nellshamrell/widget_world
-> nellshamrell/widget
   --> core/glibc/2.22
-> nellshamrell/world
   --> core/glibc/2.22
```

My nellshamrell/widget_world plan will build fine, because both of its dependencies are built with the same version of glibc.

```
(studio) $ build widget_world
...
Success!
I love when a plan.sh comes together!
```

Then suppose the Habitat team upgrades core/glibc to 2.27.  And let's say for some reason you only update one of the dependencies to use the updated glibc - so nellshamrell/widget will depend on core/glibc/2.27, while nellshamrell/world will still depend on core/glibc/2.22

```
nellshamrell/widget_world
-> nellshamrell/widget
   --> core/glibc/2.27
-> nellshamrell/world
   --> core/glibc/2.22
```

This time, if I attempt to build "nellshamrell/widget_world", it will return a very ugly error that look similar to this:

```
(studio) $ build widget_world
(...)
   widget_world: WARN
   widget_world: WARN The following runtime dependencies have more than one version
   widget_world: WARN release in the full dependency chain:
   widget_world: WARN
   widget_world: WARN   * core/glibc ( core/glibc/2.22/<timestamp> core/glibc/2.27/<timestamp> )
   widget_world: WARN
   widget_world: WARN The current situation usually arises when a Plan has a direct
   widget_world: WARN dependency on one version of a package (`acme/A/7.0/20160101200001`)
   widget_world: WARN and has a direct dependency on another package which itself depends
   widget_world: WARN on another version of the same package (`acme/A/2.0/20151201060001`).
   widget_world: WARN If this package (`acme/A`) contains shared libraries which are
   widget_world: WARN loaded at runtime by the current Plan, then both versions of
   widget_world: WARN `acme/A` could be loaded into the same process in a potentially
   widget_world: WARN surprising order. Worse, if both versions of `acme/A` are
   widget_world: WARN ABI-incompatible, runtime segmentation faults are more than likely.
   widget_world: WARN
   widget_world: WARN In order to preserve reliability at runtime the duplicate dependency
   widget_world: WARN entries will need to be resolved before this Plan can be built.
   widget_world: WARN Below is an expanded graph of all `$pkg_deps` and their dependencies
   widget_world: WARN with the problematic lines noted.
   widget_world: WARN
   widget_world: WARN Computed dependency graph (Lines with '*' denote a problematic entry):

nellshamrell/widget_world/1.0.0/<timestamp>
    nellshamrell/widget/1.0.0/<timestamp> (*)
        core/glibc/2.27/<timestamp> (*)
    nellshamrell/world/1.0.0/<timestamp> (*)
        core/glibc/2.22/<timestamp> (*)

ERROR: Computed runtime dependency check failed, aborting
```

This error occurs because nellshamrell/widget_world has one dependency that was built with 2.27, and another that was built with 2.22.  This makes them uncompatible, and the nellshamrell/widget_world plan will not build.

### How do I resolve this?

In this case, you can resolve this error by rebuilding nellshamrell/world with core/glibc version 2.27.  If we do that, and now both dependencies depend on the same version of glibc, then nellshamrell/widget_world will build fine.

```
nellshamrell/widget_world
-> nellshamrell/widget
   --> core/glibc/2.27
-> nellshamrell/world
   --> core/glibc/2.27
```

Success!

```
(studio) $ build widget_world
...
Success!
I love when a plan.sh comes together!
```

So...after the core plans refresh gets added to production, and all of the base plans and dependent base plans are promoted to stable, you may see some of these failures with your own plans.  It's also possible they may fail on more than one dependency being out of sync.  You can fix these errors in 2 ways:
1) Rebuilding a dependency with an older version of a base plan (i.e. nellshamrell/world with core/glibc/2.22) with a newer version of that base plan, or at least the same version as the rest of your dependencies (i.e. nellshamrell/world with core/glibc/2.27).
2) Pinning both dependencies to an older version of the base plan (i.e. we could pin both nellshamrell/widget and nellshamrell/world to core/glibc/2.22, and nellshamrell/widget_world would build just fine).

### Do I need to do this for all my plans?

If you have plans that depend on base plans (which I expect most if not all plans do), you will likely run into this dependency error on at least one of your plans.  You can fix it as outlined above.  If you need assistance, have questions, or just want some company through the updating process, please feel free to ask for help in the [Habitat Slack](http://slack.habitat.sh/) - we are there during normal business hours and happy to help!