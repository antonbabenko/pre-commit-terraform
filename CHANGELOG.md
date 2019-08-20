<a name="unreleased"></a>
## [Unreleased]



<a name="v1.19.0"></a>
## [v1.19.0] - 2019-08-20

- Updated README with terraform_tflint hook
- Added support for TFLint with --deep parameter ([#53](https://github.com/antonbabenko/pre-commit-terraform/issues/53))


<a name="v1.18.0"></a>
## [v1.18.0] - 2019-08-20

- Updated CHANGELOG
- Updated README with terragrunt_fmt hook
- Formatter for Terragrunt HCL files ([#60](https://github.com/antonbabenko/pre-commit-terraform/issues/60))


<a name="v1.17.0"></a>
## [v1.17.0] - 2019-06-25

- Updated CHANGELOG
- Fixed enquoted types in terraform_docs (fixed [#52](https://github.com/antonbabenko/pre-commit-terraform/issues/52))
- Fix typo in README ([#51](https://github.com/antonbabenko/pre-commit-terraform/issues/51))


<a name="v1.16.0"></a>
## [v1.16.0] - 2019-06-18

- Updated CHANGELOG
- Add slash to mktemp dir (fixed [#50](https://github.com/antonbabenko/pre-commit-terraform/issues/50))


<a name="v1.15.0"></a>
## [v1.15.0] - 2019-06-18

- Updated CHANGELOG
- Fixed awk script for terraform-docs (kudos [@cytopia](https://github.com/cytopia)) and mktemp on Mac (closes [#47](https://github.com/antonbabenko/pre-commit-terraform/issues/47), [#48](https://github.com/antonbabenko/pre-commit-terraform/issues/48), [#49](https://github.com/antonbabenko/pre-commit-terraform/issues/49))
- Fix version in README.md ([#46](https://github.com/antonbabenko/pre-commit-terraform/issues/46))


<a name="v1.14.0"></a>
## [v1.14.0] - 2019-06-17

- Updated CHANGELOG
- Upgraded to work with Terraform >= 0.12 ([#44](https://github.com/antonbabenko/pre-commit-terraform/issues/44))


<a name="v1.13.0"></a>
## [v1.13.0] - 2019-06-17

- Updated CHANGELOG
- Added support for terraform_docs for Terraform 0.12 ([#45](https://github.com/antonbabenko/pre-commit-terraform/issues/45))


<a name="v1.12.0"></a>
## [v1.12.0] - 2019-05-27

- Updated CHANGELOG
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

- Added CHANGELOG.md
- Added chglog (hi [@robinbowes](https://github.com/robinbowes) :))
- Merge pull request [#33](https://github.com/antonbabenko/pre-commit-terraform/issues/33) from chrisgilmerproj/run_terraform_docs_in_serial
- Require terraform-docs runs in serial to avoid pre-commit doing parallel operations on similar file paths


<a name="v1.8.1"></a>
## [v1.8.1] - 2018-12-15

- Merge pull request [#30](https://github.com/antonbabenko/pre-commit-terraform/issues/30) from RothAndrew/feature/fix_issue_29
- Fix bug not letting terraform_docs_replace work in the root directory of a repo


<a name="v1.8.0"></a>
## [v1.8.0] - 2018-12-14

- Merge pull request [#27](https://github.com/antonbabenko/pre-commit-terraform/issues/27) from RothAndrew/feature/new_hook
- fix typo
- Address requested changes
- Add `--dest` argument
- Address requested changes
- Add new hook for running terraform-docs with replacing README.md from doc in main.tf


<a name="v1.7.4"></a>
## [v1.7.4] - 2018-12-11

- Merge remote-tracking branch 'origin/master' into pr25
- Added followup after [#25](https://github.com/antonbabenko/pre-commit-terraform/issues/25)
- Merge pull request [#25](https://github.com/antonbabenko/pre-commit-terraform/issues/25) from getcloudnative/feat-pass-terraform-docs-opts
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
- Merge pull request [#5](https://github.com/antonbabenko/pre-commit-terraform/issues/5) from schneems/schneems/codetriage-badge
- [ci skip] Get more Open Source Helpers


<a name="v1.2.0"></a>
## [v1.2.0] - 2017-06-08

- Renamed shell script file to the correct one
- Updated .pre-commit-hooks.yaml
- Updated sha in README
- Merge pull request [#3](https://github.com/antonbabenko/pre-commit-terraform/issues/3) from pecigonzalo/master
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


[Unreleased]: https://github.com/antonbabenko/pre-commit-terraform/compare/v1.19.0...HEAD
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
