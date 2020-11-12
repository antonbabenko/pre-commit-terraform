# Change Log

All notable changes to this project will be documented in this file.

<a name="unreleased"></a>
## [Unreleased]



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


[Unreleased]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.45.0...HEAD
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
