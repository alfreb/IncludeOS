# Changelog
<!--
Please categorize a release with the following headings: Added, Changed, Deprecated, Removed, Fixed, Security
Guidelines taken from: https://keepachangelog.com/en/1.0.0/
-->
## v0.16.0
This release restores most of the v0.15 funcionality with Nix, which adds significant workflow imporvements for development and testing. It reintroduces the original multicore support without pthreads and upgrades IncludeOS to use C++20 and libc++ from LLVM18. 

The most noticable change is that Conan is replaced by Nix as the build system. [Bjørn Forsman](https://github.com/bjornfor) wrote [the initial nix expression](https://github.com/includeos/IncludeOS/pull/2225) that helped us get a baseline to compile after a few years in hiatus. When resuming work on IncludeOS in 2023 everything was broken; all our conanfiles were deprecated by the release of Conan 2.0 and several tools and libraries were out of support and no longer available. Bjørn first wrote the nix expression in 2021, and the fact that it still just works 3 years later convinced us that this is the build system we want to use going forward. 

Another noticable changes is that v0.16.0 forks off from the old master a few commits after the v0.15 release, leaving some of the unfinished work on pthreads behind. After some discussion we agreed that supporting pthreads without a preemptive scheduler is problematic and that our non-preemptive cooperative multicore model is a more interesting direction for a unikernel. Big thanks to [MagnusS](https://github.com/MagnusS) for bringing multicore back. As a parallell track it might be worthwhile exploring native pthread support as an optional platform library, next to x86_pc and nano; one obvious advantage being that it would make it much easier to port existing applications to IncludeOS. The pthread work is preserved in the [pthread-kernel](https://github.com/includeos/IncludeOS/tree/pthread-kernel) branch as the v0.16.0 fork becomes `main` and replaces `master` as the default branch. 

Since we're a small group of active developers we can't support all the things. If you're wondering if x y or z is supported, the answer is probably no, but we're always open to contributions. IncludeOS is a for-science operating system intented to be a platform for new ideas more so than for existing code.

### Added
- Nix build system
  - Link to all Nix PR's
- New spinlock
  - Link to PR's 
- test.sh
- vmbuild and elf_syms is added back in tree
  - Link to PR
- Conan 2.0 files for some of the dependencies. 

### Changed
- Multicore support without pthreads
  - Link to all PR's
- C++20 is the default language
  - Link to PR
- Lots of test fixes and improvements
  - List PR's

### Deprecated
- Pthreads are no longer the default and not really supported. 

### Removed 
- Conan build system. There are some conan 2.0 files for some of the dependencies, in case someone wants to add back and maintain conan support together with Nix.

## v0.15.0

### Added
- Conan build system
  - Major refactoring of how IncludeOS is built
  - Multiple ARCH is managed by Conan profiles and dependencies
  - 3rd party dependencies are now built and managed in Jenkins. All recipes can be found [here](https://github.com/includeos/conan)
    - Updated to libcxx, libcxxabi 7.0.1
    - Updated to GSL 2.0.0
  - Stable and latest binary packages can be found in [bintray](https://bintray.com/includeos/includeos)
  - A repo to install Conan configs for IncludeOS: [conan_config](https://github.com/includeos/conan_config)
  - Improvements to Jenkins integration, automatic uploads of latest/stable packages on master-merge/tags
- Experimental IPv6 (WIP) including SLAAC
  - IPv6/IPv4 dual stack integration
  - TCP/UDP client / server
  - Autoconfiguration with SLAAC
  - Configuration with config.json - see [#2114](https://github.com/includeos/IncludeOS/pull/2114)
- HAL (work in progress)
  - The OS is now backed by a common Machine structure that makes it easier to create new ports
  - A custom C++ allocator is available very early allowing the use of STL before libc is ready

### Changed
- Updates to workflow. All documented in the [README](README.md)
  - No more need for `INCLUDEOS_PREFIX` in env variables
  - Removed ARCH as part of the path to libraries/drivers/plugins/etc
    - Drivers and Plugins can be created outside includeos
- Moved IncludeOS repository from `hioa-cs` to `includeos` organization
- Major breaking changes in the OS API, in particular the OS class is removed, replaced with a smaller os namespace. Much of the code moved to new `kernel::` namespace.
- Relocated plugins/libraries/scripts:
  - [Hello World example](https://github.com/includeos/hello_world)
  - [Demos and examples](https://github.com/includeos/demo-examples)
  - [Mana](https://github.com/includeos/mana)
  - [Uplink](https://github.com/includeos/uplink)
  - [Vmrunner](https://github.com/includeos/vmrunner)
  - [Diskbuilder](https://github.com/includeos/diskbuilder)
  - [Vmbuild](https://github.com/includeos/vmbuild)
  - [MicroLB](https://github.com/includeos/microlb)

### Removed / archived
- Cleanup of unused/outdated scripts
  - `install.sh` is gone as it does no longer work with the Conan workflow
- mender client is [archived](https://github.com/includeos/mender)
