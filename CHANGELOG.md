# Changelog

All notable changes to this project will be documented in this file.

# [1.64.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.63.0...v1.64.0) (2022-02-10)


### Features

* Improved speed of `pre-commit run -a` for multiple hooks ([#338](https://github.com/antonbabenko/pre-commit-terraform/issues/338)) ([579dc45](https://github.com/antonbabenko/pre-commit-terraform/commit/579dc45fb40bc64c6742d42a9da78eddb0b70e1d))

# [1.63.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.62.3...v1.63.0) (2022-02-10)


### Features

* Improve performance during `pre-commit --all (-a)` run ([#327](https://github.com/antonbabenko/pre-commit-terraform/issues/327)) ([7e7c916](https://github.com/antonbabenko/pre-commit-terraform/commit/7e7c91643e8f213168b95d0583f787f914b04ce4))

## [1.62.3](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.62.2...v1.62.3) (2021-12-22)


### Bug Fixes

* Check all directories with changes and pass all args in terrascan hook ([#305](https://github.com/antonbabenko/pre-commit-terraform/issues/305)) ([66401d9](https://github.com/antonbabenko/pre-commit-terraform/commit/66401d93f485164fb2272af297df835b932c61c3))

## [1.62.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.62.1...v1.62.2) (2021-12-21)


### Bug Fixes

* Properly exclude .terraform directory with checkov hook ([#306](https://github.com/antonbabenko/pre-commit-terraform/issues/306)) ([b431a43](https://github.com/antonbabenko/pre-commit-terraform/commit/b431a43ffa6cd13156485ef853c967856e9572ef))
* Speedup `terrascan` hook up to x3 times in big repos ([#307](https://github.com/antonbabenko/pre-commit-terraform/issues/307)) ([2e8dcf9](https://github.com/antonbabenko/pre-commit-terraform/commit/2e8dcf9298733a256cc7f8c6f05b3ef9a1047a36))

## [1.62.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.62.0...v1.62.1) (2021-12-18)


### Bug Fixes

* **terraform_tflint:** Restore current working directory behavior ([#302](https://github.com/antonbabenko/pre-commit-terraform/issues/302)) ([93029dc](https://github.com/antonbabenko/pre-commit-terraform/commit/93029dcfcf6b9b121c24573f3e647d9fde255486))

# [1.62.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.61.0...v1.62.0) (2021-12-12)


### Features

* Added semantic release ([#296](https://github.com/antonbabenko/pre-commit-terraform/issues/296)) ([1bcca44](https://github.com/antonbabenko/pre-commit-terraform/commit/1bcca44d1677128c23d505be644f1d16c320eb4c))

# Change Log

All notable changes to this project will be documented in this file.

<a name="unreleased"></a>
## [Unreleased]



<a name="v1.61.0"></a>
## [v1.61.0] - 2021-12-11

- feat: Pass custom arguments to terraform init in `terraform_validate` hook ([#293](https://github.com/antonbabenko/pre-commit-terraform/issues/293))
- fix: analyse all folders with tflint and don't stop on first execution ([#289](https://github.com/antonbabenko/pre-commit-terraform/issues/289))


<a name="v1.60.0"></a>
## [v1.60.0] - 2021-12-08

- fix: pre-build docker image ([#292](https://github.com/antonbabenko/pre-commit-terraform/issues/292))


<a name="v1.59.0"></a>
## [v1.59.0] - 2021-12-06

- fix: Fixed docker build ([#288](https://github.com/antonbabenko/pre-commit-terraform/issues/288))


<a name="v1.58.0"></a>
## [v1.58.0] - 2021-11-20

- chore: Publish container image on release ([#285](https://github.com/antonbabenko/pre-commit-terraform/issues/285))
- chore: Fix master merge to working branch on pre-commit autofixes ([#286](https://github.com/antonbabenko/pre-commit-terraform/issues/286))


<a name="v1.57.0"></a>
## [v1.57.0] - 2021-11-17

- fix: typo in arg name for terraform-docs ([#283](https://github.com/antonbabenko/pre-commit-terraform/issues/283))
- chore: Add deprecation notice to `terraform_docs_replace` ([#280](https://github.com/antonbabenko/pre-commit-terraform/issues/280))


<a name="v1.56.0"></a>
## [v1.56.0] - 2021-11-08

- feat: Updated Docker image from Ubuntu to Alpine ([#278](https://github.com/antonbabenko/pre-commit-terraform/issues/278))
- chore: Updated messages shown in terraform_tflint hook ([#274](https://github.com/antonbabenko/pre-commit-terraform/issues/274))


<a name="v1.55.0"></a>
## [v1.55.0] - 2021-10-27

- fix: Fixed 1.54.0 where `terraform_docs` was broken ([#272](https://github.com/antonbabenko/pre-commit-terraform/issues/272))


<a name="v1.54.0"></a>
## [v1.54.0] - 2021-10-27

- feat: Add support for quoted values in `infracost_breakdown` `--hook-config` ([#269](https://github.com/antonbabenko/pre-commit-terraform/issues/269))
- docs: Added notes about sponsors ([#268](https://github.com/antonbabenko/pre-commit-terraform/issues/268))
- fix: Fixed args expand in terraform_docs ([#260](https://github.com/antonbabenko/pre-commit-terraform/issues/260))


<a name="v1.53.0"></a>
## [v1.53.0] - 2021-10-26

- docs: Pre-release 1.53 ([#267](https://github.com/antonbabenko/pre-commit-terraform/issues/267))
- docs: Clarify docs for terraform_tfsec hook ([#266](https://github.com/antonbabenko/pre-commit-terraform/issues/266))
- feat: Add infracost_breakdown hook ([#252](https://github.com/antonbabenko/pre-commit-terraform/issues/252))
- feat: Set up PR reviewers automatically ([#258](https://github.com/antonbabenko/pre-commit-terraform/issues/258))
- docs: fix protocol to prevent MITM ([#257](https://github.com/antonbabenko/pre-commit-terraform/issues/257))
- feat: add __GIT_WORKING_DIR__ to tfsec ([#255](https://github.com/antonbabenko/pre-commit-terraform/issues/255))
- docs: Add missing space in terrascan install cmd ([#253](https://github.com/antonbabenko/pre-commit-terraform/issues/253))
- fix: command not found ([#251](https://github.com/antonbabenko/pre-commit-terraform/issues/251))
- fix: execute tflint once in no errors ([#250](https://github.com/antonbabenko/pre-commit-terraform/issues/250))
- docs: fix deps ([#249](https://github.com/antonbabenko/pre-commit-terraform/issues/249))
- feat: Add `terraform_docs` hook settings ([#245](https://github.com/antonbabenko/pre-commit-terraform/issues/245))
- fix: terrafrom_tflint ERROR output for files located in repo root ([#243](https://github.com/antonbabenko/pre-commit-terraform/issues/243))
- feat: Add support for specify terraform-docs config file ([#244](https://github.com/antonbabenko/pre-commit-terraform/issues/244))
- docs: Document hooks dependencies ([#247](https://github.com/antonbabenko/pre-commit-terraform/issues/247))
- feat: Allow passing of args to terraform_fmt ([#147](https://github.com/antonbabenko/pre-commit-terraform/issues/147))
- docs: Add terraform_fmt usage instructions and how-to debug script with args ([#242](https://github.com/antonbabenko/pre-commit-terraform/issues/242))
- fix: TFSec outputs the same results multiple times ([#237](https://github.com/antonbabenko/pre-commit-terraform/issues/237))
- chore: Do not mark issues and PR's in milestone as stale ([#241](https://github.com/antonbabenko/pre-commit-terraform/issues/241))


<a name="v1.52.0"></a>
## [v1.52.0] - 2021-10-04

- feat: Add new hook for `terraform providers lock` operation ([#173](https://github.com/antonbabenko/pre-commit-terraform/issues/173))
- docs: Document terraform_tfsec args usage ([#238](https://github.com/antonbabenko/pre-commit-terraform/issues/238))
- docs: Make contributors more visible ([#236](https://github.com/antonbabenko/pre-commit-terraform/issues/236))
- docs: Add contributing guide and docs about performance tests ([#235](https://github.com/antonbabenko/pre-commit-terraform/issues/235))
- fix: terraform_tflint hook executes in a serial way to run less often ([#211](https://github.com/antonbabenko/pre-commit-terraform/issues/211))
- feat: Add PATH outputs when TFLint found any problem ([#234](https://github.com/antonbabenko/pre-commit-terraform/issues/234))
- fix: Dockerfile if INSTALL_ALL is not defined ([#233](https://github.com/antonbabenko/pre-commit-terraform/issues/233))
- docs: Describe hooks usage and improve examples ([#232](https://github.com/antonbabenko/pre-commit-terraform/issues/232))
- chore: Add shfmt to workflow ([#231](https://github.com/antonbabenko/pre-commit-terraform/issues/231))
- fix: remove dead code from terraform-docs script ([#229](https://github.com/antonbabenko/pre-commit-terraform/issues/229))


<a name="v1.51.0"></a>
## [v1.51.0] - 2021-09-17

- fix: trigger terraform-docs on changes in lock files ([#228](https://github.com/antonbabenko/pre-commit-terraform/issues/228))
- fix: label auto-adding after label rename ([#226](https://github.com/antonbabenko/pre-commit-terraform/issues/226))
- chore: Updated GH stale action config ([#223](https://github.com/antonbabenko/pre-commit-terraform/issues/223))
- feat: Add GH checks and templates ([#222](https://github.com/antonbabenko/pre-commit-terraform/issues/222))
- feat: Add mixed line ending check to prevent possible errors ([#221](https://github.com/antonbabenko/pre-commit-terraform/issues/221))
- fix: Dockerized pre-commit-terraform ([#219](https://github.com/antonbabenko/pre-commit-terraform/issues/219))
- docs: Initial docs improvement ([#218](https://github.com/antonbabenko/pre-commit-terraform/issues/218))
- chore: Update Ubuntu install method ([#198](https://github.com/antonbabenko/pre-commit-terraform/issues/198))


<a name="v1.50.0"></a>
## [v1.50.0] - 2021-04-22

- feat: Adds support for Terrascan ([#195](https://github.com/antonbabenko/pre-commit-terraform/issues/195))


<a name="v1.49.0"></a>
## [v1.49.0] - 2021-04-20

- fix: Fix and pin versions in Dockerfile ([#193](https://github.com/antonbabenko/pre-commit-terraform/issues/193))
- chore: Fix mistake on command ([#185](https://github.com/antonbabenko/pre-commit-terraform/issues/185))
- Update README.md


<a name="v1.48.0"></a>
## [v1.48.0] - 2021-03-12

- chore: add dockerfile ([#183](https://github.com/antonbabenko/pre-commit-terraform/issues/183))
- docs: Added checkov install ([#182](https://github.com/antonbabenko/pre-commit-terraform/issues/182))


<a name="v1.47.0"></a>
## [v1.47.0] - 2021-02-25

- fix: remove sed postprocessing from the terraform_docs_replace hook to fix compatibility with terraform-docs 0.11.0+ ([#176](https://github.com/antonbabenko/pre-commit-terraform/issues/176))
- docs: updates installs for macOS and ubuntu ([#175](https://github.com/antonbabenko/pre-commit-terraform/issues/175))


<a name="v1.46.0"></a>
## [v1.46.0] - 2021-02-20

- fix: Terraform validate for submodules ([#172](https://github.com/antonbabenko/pre-commit-terraform/issues/172))


<a name="v1.45.0"></a>
## [v1.45.0] - 2020-11-12

- fix: Correct deprecated parameter to terraform-docs ([#156](https://github.com/antonbabenko/pre-commit-terraform/issues/156))


<a name="v1.44.0"></a>
## [v1.44.0] - 2020-11-02



<a name="v1.43.1"></a>
## [v1.43.1] - 2020-11-02

- feat: Make terraform_validate to run init if necessary ([#158](https://github.com/antonbabenko/pre-commit-terraform/issues/158))


<a name="v1.43.0"></a>
## [v1.43.0] - 2020-09-24

- fix: Fix regex considering terraform-docs v0.10.0 old ([#151](https://github.com/antonbabenko/pre-commit-terraform/issues/151))


<a name="v1.42.0"></a>
## [v1.42.0] - 2020-09-24

- fix: make terraform_docs Windows compatible ([#129](https://github.com/antonbabenko/pre-commit-terraform/issues/129))


<a name="v1.41.0"></a>
## [v1.41.0] - 2020-09-23

- fix: terraform-docs version 0.10 removed with-aggregate-type-defaults ([#150](https://github.com/antonbabenko/pre-commit-terraform/issues/150))


<a name="v1.40.0"></a>
## [v1.40.0] - 2020-09-22

- feat: Add possibility to share tflint config file for subdirs ([#149](https://github.com/antonbabenko/pre-commit-terraform/issues/149))


<a name="v1.39.0"></a>
## [v1.39.0] - 2020-09-08

- feat: Add checkov support ([#143](https://github.com/antonbabenko/pre-commit-terraform/issues/143))


<a name="v1.38.0"></a>
## [v1.38.0] - 2020-09-07

- fix: Correctly handle arrays in terraform_docs.sh ([#141](https://github.com/antonbabenko/pre-commit-terraform/issues/141))


<a name="v1.37.0"></a>
## [v1.37.0] - 2020-09-01

- fix: make terraform_tfsec.sh executable ([#140](https://github.com/antonbabenko/pre-commit-terraform/issues/140))


<a name="v1.36.0"></a>
## [v1.36.0] - 2020-09-01

- feat: have option for terraform_tfsec hook to only run in relevant modified directories ([#135](https://github.com/antonbabenko/pre-commit-terraform/issues/135))


<a name="v1.35.0"></a>
## [v1.35.0] - 2020-08-28

- fix: Squash terraform_docs bug ([#138](https://github.com/antonbabenko/pre-commit-terraform/issues/138))


<a name="v1.34.0"></a>
## [v1.34.0] - 2020-08-27

- chore: Use lib_getopt for all hooks and some style tweaks ([#137](https://github.com/antonbabenko/pre-commit-terraform/issues/137))


<a name="v1.33.0"></a>
## [v1.33.0] - 2020-08-27

- fix: Pass args and env vars to terraform validate ([#125](https://github.com/antonbabenko/pre-commit-terraform/issues/125))
- docs: Update terraform-docs link pointing to new organization ([#130](https://github.com/antonbabenko/pre-commit-terraform/issues/130))


<a name="v1.32.0"></a>
## [v1.32.0] - 2020-08-19

- feat: add terragrunt validate hook ([#134](https://github.com/antonbabenko/pre-commit-terraform/issues/134))


<a name="v1.31.0"></a>
## [v1.31.0] - 2020-05-27

- fix: Updated formatting in README (closes [#113](https://github.com/antonbabenko/pre-commit-terraform/issues/113))
- docs: Fixed the docs to use the latest config syntax([#106](https://github.com/antonbabenko/pre-commit-terraform/issues/106))
- docs: Added coreutils as requirements in README.md ([#105](https://github.com/antonbabenko/pre-commit-terraform/issues/105))


<a name="v1.30.0"></a>
## [v1.30.0] - 2020-04-23

- Updated pre-commit deps
- feat: Support for TFSec ([#103](https://github.com/antonbabenko/pre-commit-terraform/issues/103))


<a name="v1.29.0"></a>
## [v1.29.0] - 2020-04-04

- fix: Change terraform_validate hook functionality for subdirectories with terraform files ([#100](https://github.com/antonbabenko/pre-commit-terraform/issues/100))

### 

configuration for the appropriate working directory.

* Neglected to change the terraform validate call to use the default of the
current directory.

* Several changes to improve functionality:
- Switch to checking the path for '*.tf' instead of always checking the current

directory.
- Try to find a '.terraform' directory (which indicates a `terraform init`) and

change to that directory before running `terraform validate`.

* Fix the description for the terraform_validate hook to reflect changes that were
made in:
https://github.com/antonbabenko/pre-commit-terraform/commit/35e0356188b64a4c5af9a4e7200d936e514cba71

* - Clean up comments.
- Adjust variable names to better reflect what they are holding.


<a name="v1.28.0"></a>
## [v1.28.0] - 2020-04-04

- Allow passing multiple args to terraform-docs ([#98](https://github.com/antonbabenko/pre-commit-terraform/issues/98))
- Update installation instructions ([#79](https://github.com/antonbabenko/pre-commit-terraform/issues/79))


<a name="v1.27.0"></a>
## [v1.27.0] - 2020-03-02

- corrected tflint documentation ([#95](https://github.com/antonbabenko/pre-commit-terraform/issues/95))


<a name="v1.26.0"></a>
## [v1.26.0] - 2020-02-21

- Updated pre-commit-hooks
- Fixed exit code for terraform 0.11 branch in terraform_docs ([#94](https://github.com/antonbabenko/pre-commit-terraform/issues/94))


<a name="v1.25.0"></a>
## [v1.25.0] - 2020-01-30

- Fixed tflint hook to iterate over files ([#77](https://github.com/antonbabenko/pre-commit-terraform/issues/77))


<a name="v1.24.0"></a>
## [v1.24.0] - 2020-01-21

- Added shfmt to autoformat shell scripts ([#86](https://github.com/antonbabenko/pre-commit-terraform/issues/86))


<a name="v1.23.0"></a>
## [v1.23.0] - 2020-01-21

- Added support for terraform-docs 0.8.0 with proper support for Terraform 0.12 syntax (bye-bye awk) ([#85](https://github.com/antonbabenko/pre-commit-terraform/issues/85))


<a name="v1.22.0"></a>
## [v1.22.0] - 2020-01-13

- move terraform-docs args after markdown command ([#83](https://github.com/antonbabenko/pre-commit-terraform/issues/83))


<a name="v1.21.0"></a>
## [v1.21.0] - 2019-11-16

- use getopt for args in the tflint hook, following the approach in terraform-docs ([#75](https://github.com/antonbabenko/pre-commit-terraform/issues/75))


<a name="v1.20.0"></a>
## [v1.20.0] - 2019-11-02

- Fixes [#65](https://github.com/antonbabenko/pre-commit-terraform/issues/65): terraform-docs should not fail if complex types contain 'description' keyword ([#73](https://github.com/antonbabenko/pre-commit-terraform/issues/73))
- Added FUNDING.yml
- Improve installation instructions and make README more readable ([#72](https://github.com/antonbabenko/pre-commit-terraform/issues/72))
- Update rev in README.md ([#70](https://github.com/antonbabenko/pre-commit-terraform/issues/70))


<a name="v1.19.0"></a>
## [v1.19.0] - 2019-08-20

- Updated README with terraform_tflint hook
- Added support for TFLint with --deep parameter ([#53](https://github.com/antonbabenko/pre-commit-terraform/issues/53))


<a name="v1.18.0"></a>
## [v1.18.0] - 2019-08-20

- Updated README with terragrunt_fmt hook
- Formatter for Terragrunt HCL files ([#60](https://github.com/antonbabenko/pre-commit-terraform/issues/60))


<a name="v1.17.0"></a>
## [v1.17.0] - 2019-06-25

- Fixed enquoted types in terraform_docs (fixed [#52](https://github.com/antonbabenko/pre-commit-terraform/issues/52))
- Fix typo in README ([#51](https://github.com/antonbabenko/pre-commit-terraform/issues/51))


<a name="v1.16.0"></a>
## [v1.16.0] - 2019-06-18

- Add slash to mktemp dir (fixed [#50](https://github.com/antonbabenko/pre-commit-terraform/issues/50))


<a name="v1.15.0"></a>
## [v1.15.0] - 2019-06-18

- Fixed awk script for terraform-docs (kudos [@cytopia](https://github.com/cytopia)) and mktemp on Mac (closes [#47](https://github.com/antonbabenko/pre-commit-terraform/issues/47), [#48](https://github.com/antonbabenko/pre-commit-terraform/issues/48), [#49](https://github.com/antonbabenko/pre-commit-terraform/issues/49))
- Fix version in README.md ([#46](https://github.com/antonbabenko/pre-commit-terraform/issues/46))


<a name="v1.14.0"></a>
## [v1.14.0] - 2019-06-17

- Upgraded to work with Terraform >= 0.12 ([#44](https://github.com/antonbabenko/pre-commit-terraform/issues/44))


<a name="v1.13.0"></a>
## [v1.13.0] - 2019-06-17

- Added support for terraform_docs for Terraform 0.12 ([#45](https://github.com/antonbabenko/pre-commit-terraform/issues/45))


<a name="v1.12.0"></a>
## [v1.12.0] - 2019-05-27

- Added note about incompatibility of terraform-docs with Terraform 0.12 ([#41](https://github.com/antonbabenko/pre-commit-terraform/issues/41))
- Fixed broken "maintained badge"
- Update README.md ([#36](https://github.com/antonbabenko/pre-commit-terraform/issues/36))


<a name="v1.11.0"></a>
## [v1.11.0] - 2019-03-01

- Updated changelog
- fix check for errors at the end ([#35](https://github.com/antonbabenko/pre-commit-terraform/issues/35))


<a name="v1.10.0"></a>
## [v1.10.0] - 2019-02-21

- Bump new version
- Add exit code for 'terraform validate' so pre-commit check fails ([#34](https://github.com/antonbabenko/pre-commit-terraform/issues/34))


<a name="v1.9.0"></a>
## [v1.9.0] - 2019-02-18

- Added chglog (hi [@robinbowes](https://github.com/robinbowes) :))
- Require terraform-docs runs in serial to avoid pre-commit doing parallel operations on similar file paths


<a name="v1.8.1"></a>
## [v1.8.1] - 2018-12-15

- Fix bug not letting terraform_docs_replace work in the root directory of a repo


<a name="v1.8.0"></a>
## [v1.8.0] - 2018-12-14

- fix typo
- Address requested changes
- Add `--dest` argument
- Address requested changes
- Add new hook for running terraform-docs with replacing README.md from doc in main.tf


<a name="v1.7.4"></a>
## [v1.7.4] - 2018-12-11

- Merge remote-tracking branch 'origin/master' into pr25
- Added followup after [#25](https://github.com/antonbabenko/pre-commit-terraform/issues/25)
- Add feature to pass options to terraform-docs.
- Added license file (fixed [#21](https://github.com/antonbabenko/pre-commit-terraform/issues/21))


<a name="v1.7.3"></a>
## [v1.7.3] - 2018-05-24

- Updated README
- Only run validate if .tf files exist in the directory. ([#20](https://github.com/antonbabenko/pre-commit-terraform/issues/20))


<a name="v1.7.2"></a>
## [v1.7.2] - 2018-05-20

- Replace terraform_docs use of GNU sed with perl ([#15](https://github.com/antonbabenko/pre-commit-terraform/issues/15))
- Fixes use of md5 for tempfile name ([#16](https://github.com/antonbabenko/pre-commit-terraform/issues/16))


<a name="v1.7.1"></a>
## [v1.7.1] - 2018-05-16

- Run terraform_docs only if README.md is present
- Run terraform_docs only if README.md is present


<a name="v1.7.0"></a>
## [v1.7.0] - 2018-05-16

- Added terraform-docs integration ([#13](https://github.com/antonbabenko/pre-commit-terraform/issues/13))


<a name="v1.6.0"></a>
## [v1.6.0] - 2018-04-21

- Allow to have spaces in directories ([#11](https://github.com/antonbabenko/pre-commit-terraform/issues/11))


<a name="v1.5.0"></a>
## [v1.5.0] - 2018-03-06

- Bump new version
- Format tfvars files explicitely, because terraform fmt ignores them ([#9](https://github.com/antonbabenko/pre-commit-terraform/issues/9))


<a name="v1.4.0"></a>
## [v1.4.0] - 2018-01-24

- Updated readme
- Show failed path
- Show failed path
- Show failed path
- Updated scripts
- Added scripts to validate terraform files


<a name="v1.3.0"></a>
## [v1.3.0] - 2018-01-15

- Added badges
- Added formatting for tfvars (fixes [#4](https://github.com/antonbabenko/pre-commit-terraform/issues/4)) ([#6](https://github.com/antonbabenko/pre-commit-terraform/issues/6))


<a name="v1.2.0"></a>
## [v1.2.0] - 2017-06-08

- Renamed shell script file to the correct one
- Updated .pre-commit-hooks.yaml
- Updated sha in README
- Exclude .terraform even on subfolders


<a name="v1.1.0"></a>
## [v1.1.0] - 2017-02-04

- Copied to .pre-commit-hooks.yaml for compatibility (closes [#1](https://github.com/antonbabenko/pre-commit-terraform/issues/1))


<a name="v1.0.0"></a>
## v1.0.0 - 2016-09-27

- Updated README
- Ready, probably :)
- Initial commit
- Initial commit


[Unreleased]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.61.0...HEAD
[v1.61.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.60.0...v1.61.0
[v1.60.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.59.0...v1.60.0
[v1.59.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.58.0...v1.59.0
[v1.58.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.57.0...v1.58.0
[v1.57.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.56.0...v1.57.0
[v1.56.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.55.0...v1.56.0
[v1.55.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.54.0...v1.55.0
[v1.54.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.53.0...v1.54.0
[v1.53.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.52.0...v1.53.0
[v1.52.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.51.0...v1.52.0
[v1.51.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.50.0...v1.51.0
[v1.50.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.49.0...v1.50.0
[v1.49.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.48.0...v1.49.0
[v1.48.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.47.0...v1.48.0
[v1.47.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.46.0...v1.47.0
[v1.46.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.45.0...v1.46.0
[v1.45.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.44.0...v1.45.0
[v1.44.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.43.1...v1.44.0
[v1.43.1]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.43.0...v1.43.1
[v1.43.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.42.0...v1.43.0
[v1.42.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.41.0...v1.42.0
[v1.41.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.40.0...v1.41.0
[v1.40.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.39.0...v1.40.0
[v1.39.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.38.0...v1.39.0
[v1.38.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.37.0...v1.38.0
[v1.37.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.36.0...v1.37.0
[v1.36.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.35.0...v1.36.0
[v1.35.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.34.0...v1.35.0
[v1.34.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.33.0...v1.34.0
[v1.33.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.32.0...v1.33.0
[v1.32.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.31.0...v1.32.0
[v1.31.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.30.0...v1.31.0
[v1.30.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.29.0...v1.30.0
[v1.29.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.28.0...v1.29.0
[v1.28.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.27.0...v1.28.0
[v1.27.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.26.0...v1.27.0
[v1.26.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.25.0...v1.26.0
[v1.25.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.24.0...v1.25.0
[v1.24.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.23.0...v1.24.0
[v1.23.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.22.0...v1.23.0
[v1.22.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.21.0...v1.22.0
[v1.21.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.20.0...v1.21.0
[v1.20.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.19.0...v1.20.0
[v1.19.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.18.0...v1.19.0
[v1.18.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.17.0...v1.18.0
[v1.17.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.16.0...v1.17.0
[v1.16.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.15.0...v1.16.0
[v1.15.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.14.0...v1.15.0
[v1.14.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.13.0...v1.14.0
[v1.13.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.12.0...v1.13.0
[v1.12.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.11.0...v1.12.0
[v1.11.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.10.0...v1.11.0
[v1.10.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.9.0...v1.10.0
[v1.9.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.8.1...v1.9.0
[v1.8.1]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.8.0...v1.8.1
[v1.8.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.7.4...v1.8.0
[v1.7.4]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.7.3...v1.7.4
[v1.7.3]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.7.2...v1.7.3
[v1.7.2]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.7.1...v1.7.2
[v1.7.1]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.7.0...v1.7.1
[v1.7.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.6.0...v1.7.0
[v1.6.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.5.0...v1.6.0
[v1.5.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.4.0...v1.5.0
[v1.4.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.3.0...v1.4.0
[v1.3.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.2.0...v1.3.0
[v1.2.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.1.0...v1.2.0
[v1.1.0]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.0.0...v1.1.0
