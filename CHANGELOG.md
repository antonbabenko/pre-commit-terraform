# Changelog

All notable changes to this project will be documented in this file.

# [1.100.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.99.5...v1.100.0) (2025-08-08)


### Features

* **`terraform_fmt`:** Add support for `.tftest.hcl` and `.tfmock.hcl` formatting ([#911](https://github.com/antonbabenko/pre-commit-terraform/issues/911)) ([7433e13](https://github.com/antonbabenko/pre-commit-terraform/commit/7433e138f8b346687d4ff6357d7b48be709d8130)), closes [/github.com/hashicorp/terraform/blob/0c63fb2b097edcd5cb1a91322765a414206fbea2/internal/command/fmt.go#L30-L35](https://github.com//github.com/hashicorp/terraform/blob/0c63fb2b097edcd5cb1a91322765a414206fbea2/internal/command/fmt.go/issues/L30-L35)

## [1.99.5](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.99.4...v1.99.5) (2025-07-08)


### Bug Fixes

* Regression from (at least) v1.99.0 which incorrectly handle `pre-commit run -a`, that causes multiply hooks runs. `terraform_trivy` from its introduction could always be `Passed` for `pre-commit run -a` ([#909](https://github.com/antonbabenko/pre-commit-terraform/issues/909)) ([a5bd84e](https://github.com/antonbabenko/pre-commit-terraform/commit/a5bd84e94dc228794a017da7f3e21f02745b8c06)), closes [#908](https://github.com/antonbabenko/pre-commit-terraform/issues/908) [/github.com/pre-commit-terraform/#908](https://github.com//github.com/pre-commit-terraform//issues/908)

## [1.99.4](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.99.3...v1.99.4) (2025-06-12)


### Bug Fixes

* **docker:** Drop Mac arm64 build-time hack, needed for `checkov`<3.2.395 ([#907](https://github.com/antonbabenko/pre-commit-terraform/issues/907)) ([3c9ef3d](https://github.com/antonbabenko/pre-commit-terraform/commit/3c9ef3d744011e44642726714521a45e66203eb3))

## [1.99.3](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.99.2...v1.99.3) (2025-06-06)


### Bug Fixes

* **`terraform_docs`, `terraform_wrapper_module_for_each`:** Improve `.tofu` files support ([#904](https://github.com/antonbabenko/pre-commit-terraform/issues/904)) ([4f85212](https://github.com/antonbabenko/pre-commit-terraform/commit/4f852124da4d95fc9671138771e959b6c6adf1ee))

## [1.99.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.99.1...v1.99.2) (2025-06-05)


### Bug Fixes

* make infracost_breakdown.sh compatible with bash 3.2 (macOS) ([#903](https://github.com/antonbabenko/pre-commit-terraform/issues/903)) ([dcb4c36](https://github.com/antonbabenko/pre-commit-terraform/commit/dcb4c3640b9c32db2d1cef5d9d109b56f743a783))

## [1.99.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.99.0...v1.99.1) (2025-05-29)


### Bug Fixes

* **`terragrunt_*` hooks:** Use new subcommands for terragrunt v0.78.0+ instead of deprecated ones ([#901](https://github.com/antonbabenko/pre-commit-terraform/issues/901)) ([54468bb](https://github.com/antonbabenko/pre-commit-terraform/commit/54468bb79590e155b38b462be44937c4809aa84e))

# [1.99.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.98.1...v1.99.0) (2025-04-14)


### Features

* Add support for running hooks on `.tofu` files by default ([#875](https://github.com/antonbabenko/pre-commit-terraform/issues/875)) ([fe1f62f](https://github.com/antonbabenko/pre-commit-terraform/commit/fe1f62f3aecadbc22f8ab5e1f8cb02c2821cf5c2))

## [1.98.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.98.0...v1.98.1) (2025-04-06)


### Bug Fixes

* **WSL:** Fix parallelism support for WSL systems with enabled systemd ([#872](https://github.com/antonbabenko/pre-commit-terraform/issues/872)) ([da2e9a8](https://github.com/antonbabenko/pre-commit-terraform/commit/da2e9a874ac61f94fe0a05e9d952ffb3c7c7639c))

# [1.98.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.97.4...v1.98.0) (2025-03-25)


### Features

* **docker:** Support execution on repos under `git worktree` ([#845](https://github.com/antonbabenko/pre-commit-terraform/issues/845)) ([e64974e](https://github.com/antonbabenko/pre-commit-terraform/commit/e64974ed7745a3c35882b71be49fc89570cb006e))

## [1.97.4](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.97.3...v1.97.4) (2025-02-26)


### Bug Fixes

* **docker image security:** Improve dependency pinning and disable ability to build image from different tag from what specified in Dockefile ([#830](https://github.com/antonbabenko/pre-commit-terraform/issues/830)) ([2c3aa85](https://github.com/antonbabenko/pre-commit-terraform/commit/2c3aa85a2ad4a2d903b2f54ae83ef56ac63146e0))

## [1.97.3](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.97.2...v1.97.3) (2025-02-04)


### Bug Fixes

* **`terraform_docs`:** Fix bug introduced in `v1.97.2` ([#801](https://github.com/antonbabenko/pre-commit-terraform/issues/801)) ([64b81f4](https://github.com/antonbabenko/pre-commit-terraform/commit/64b81f449344ed72d180d57ce0a801389c018584)), closes [#796](https://github.com/antonbabenko/pre-commit-terraform/issues/796)

## [1.97.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.97.1...v1.97.2) (2025-02-03)


### Bug Fixes

* **`terraform_docs`:** Allow having whitespaces in path to `.terraform-docs.yaml` config file ([#796](https://github.com/antonbabenko/pre-commit-terraform/issues/796)) ([7d83911](https://github.com/antonbabenko/pre-commit-terraform/commit/7d839114a62b61f2658167356df7e5da1a42ef8f))

## [1.97.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.97.0...v1.97.1) (2025-02-01)


### Bug Fixes

* Parallelism CPU calculation inside Kubernetes and Docker with limits ([#799](https://github.com/antonbabenko/pre-commit-terraform/issues/799)) ([58a89a1](https://github.com/antonbabenko/pre-commit-terraform/commit/58a89a1cc0760daa515f58da9bb8b167f01044bb))

# [1.97.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.96.3...v1.97.0) (2025-01-16)


### Features

* **`terraform_docs`:** Add support for custom markers to better support other formats than Markdown ([#752](https://github.com/antonbabenko/pre-commit-terraform/issues/752)) ([cd090b6](https://github.com/antonbabenko/pre-commit-terraform/commit/cd090b69c19869924a468b5a81be63264b679171))

## [1.96.3](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.96.2...v1.96.3) (2024-12-24)


### Bug Fixes

* **`terraform_docs`:** Restore multiply `--hook-config` args support. Regression from v1.95.0 ([#731](https://github.com/antonbabenko/pre-commit-terraform/issues/731)) ([87143fb](https://github.com/antonbabenko/pre-commit-terraform/commit/87143fb465503f87d5871b2d579e29b318d2bddf))

## [1.96.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.96.1...v1.96.2) (2024-10-31)


### Bug Fixes

* **WSL:** Make parallelism work appropriately ([#728](https://github.com/antonbabenko/pre-commit-terraform/issues/728)) ([e87ee43](https://github.com/antonbabenko/pre-commit-terraform/commit/e87ee4371c9f09daac814845df196a65cac28a7a))

## [1.96.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.96.0...v1.96.1) (2024-09-17)


### Bug Fixes

* **`terraform_docs`:** Fix issue with processing multiply files without `terraform-docs` markers. Issue introduced in v1.95.0 ([#720](https://github.com/antonbabenko/pre-commit-terraform/issues/720)) ([2b1aec8](https://github.com/antonbabenko/pre-commit-terraform/commit/2b1aec86d8a086de4f25b502bdb97345de2eaa27)), closes [#717](https://github.com/antonbabenko/pre-commit-terraform/issues/717) [/github.com/antonbabenko/pre-commit-terraform/blob/869a106a4c8c48f34f58318a830436142e31e10a/hooks/terraform_docs.sh#L216](https://github.com//github.com/antonbabenko/pre-commit-terraform/blob/869a106a4c8c48f34f58318a830436142e31e10a/hooks/terraform_docs.sh/issues/L216)

# [1.96.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.95.0...v1.96.0) (2024-09-16)


### Features

* Expand environment variables in `--args=` which contains lowercase symbols, like `${TF_VAR_lowercase}` ([#719](https://github.com/antonbabenko/pre-commit-terraform/issues/719)) ([bf156b4](https://github.com/antonbabenko/pre-commit-terraform/commit/bf156b40780275db9b8ab5db6d9ef41cecc78861))

# [1.95.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.94.3...v1.95.0) (2024-09-11)


### Features

* **`terraform_docs`:** Drop support for `terraform-docs` <0.12.0 ([#717](https://github.com/antonbabenko/pre-commit-terraform/issues/717)) ([81e4572](https://github.com/antonbabenko/pre-commit-terraform/commit/81e4572ad4d24fb0066fbfc4626152b6c7d48838))

## [1.94.3](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.94.2...v1.94.3) (2024-09-10)


### Bug Fixes

* **`terraform_docs`:** Restore `--hook-config=--add-to-existing-file` default behavior. Regression from 1.94.0. ([#716](https://github.com/antonbabenko/pre-commit-terraform/issues/716)) ([315342e](https://github.com/antonbabenko/pre-commit-terraform/commit/315342e16d8ac8afe67222176e417ea02e415407))

## [1.94.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.94.1...v1.94.2) (2024-09-09)


### Bug Fixes

* Support custom TF paths which contains spaces ([#714](https://github.com/antonbabenko/pre-commit-terraform/issues/714)) ([2bca410](https://github.com/antonbabenko/pre-commit-terraform/commit/2bca410814fad06f4d9cc9e31123277ae0eed23c))

## [1.94.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.94.0...v1.94.1) (2024-08-30)


### Bug Fixes

* **`terraform_docs`:** Fix non-GNU sed issues, introduced in v1.93.0, as previous fix doesn't work correctly ([#708](https://github.com/antonbabenko/pre-commit-terraform/issues/708)) ([c986c5e](https://github.com/antonbabenko/pre-commit-terraform/commit/c986c5e3440be4bf5a46c7933bb629227a3cd292))

# [1.94.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.93.1...v1.94.0) (2024-08-29)


### Features

* **`terraform-docs`:** Add support for `replace` mode  for TF 0.12+; Use native saving to file for TF 0.12+. Both requires `terraform-docs` v0.12.0+ which released in 2021. ([#705](https://github.com/antonbabenko/pre-commit-terraform/issues/705)) ([1a1b4a3](https://github.com/antonbabenko/pre-commit-terraform/commit/1a1b4a3181065f221568a9bff86319435a4a87e1))

## [1.93.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.93.0...v1.93.1) (2024-08-29)


### Bug Fixes

* **`terraform_docs`:** Fix non-GNU `sed` issues, introduced in v1.93.0 ([#704](https://github.com/antonbabenko/pre-commit-terraform/issues/704)) ([3c8734d](https://github.com/antonbabenko/pre-commit-terraform/commit/3c8734dc55e69bcfc70eceff485768a0ee89e811))

# [1.93.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.92.3...v1.93.0) (2024-08-28)


### Features

* **`terraform_docs`:** Start seamless migration to `terraform-docs` markers ([#701](https://github.com/antonbabenko/pre-commit-terraform/issues/701)) ([d03f44f](https://github.com/antonbabenko/pre-commit-terraform/commit/d03f44facabf31ab7d464468907fb0a5d549e5e7))

## [1.92.3](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.92.2...v1.92.3) (2024-08-27)


### Bug Fixes

* **`terraform_docs`:** Suppress redundant warnings pop-ups introduced in v1.92.2 ([#700](https://github.com/antonbabenko/pre-commit-terraform/issues/700)) ([59b2454](https://github.com/antonbabenko/pre-commit-terraform/commit/59b2454e076a9d26ad93d0ca4037746fd7f5962d))

## [1.92.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.92.1...v1.92.2) (2024-08-16)


### Bug Fixes

* **`terraform_docs`:** Fix issue and prioritize `output.file` setting from `.terraform-docs.yml` config over `--hook-config=--path-to-file=` ([#698](https://github.com/antonbabenko/pre-commit-terraform/issues/698)) ([9d6a22b](https://github.com/antonbabenko/pre-commit-terraform/commit/9d6a22badbd9693a72c2519eb7dde01d10db57b2))

## [1.92.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.92.0...v1.92.1) (2024-08-01)


### Bug Fixes

* **`terraform_docs`:** Suppress "terraform command not found" error message in case binary does not exist ([#693](https://github.com/antonbabenko/pre-commit-terraform/issues/693)) ([6ff3572](https://github.com/antonbabenko/pre-commit-terraform/commit/6ff3572afb0a70c6fe4c6a0524d1f332a4f8fb6c))

# [1.92.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.91.0...v1.92.0) (2024-06-19)


### Features

* Add `terragrunt_validate_inputs` hook to check unused and undefined inputs ([#677](https://github.com/antonbabenko/pre-commit-terraform/issues/677)) ([a139b71](https://github.com/antonbabenko/pre-commit-terraform/commit/a139b71bc722ac1d2d5ed89caeb74d66a882bb94))

# [1.91.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.90.0...v1.91.0) (2024-06-07)


### Features

* Added Terramate as sponsor ([#676](https://github.com/antonbabenko/pre-commit-terraform/issues/676)) ([dae1a48](https://github.com/antonbabenko/pre-commit-terraform/commit/dae1a483b429506863c3c7203932fef4fa74f86a))

# [1.90.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.89.1...v1.90.0) (2024-05-23)


### Features

* Support set custom TF/OpenTofu binary. | If you use a custom Docker image build, please note that `TERRAFORM_VERSION` now must be provided ([#670](https://github.com/antonbabenko/pre-commit-terraform/issues/670)) ([c7011c0](https://github.com/antonbabenko/pre-commit-terraform/commit/c7011c06b84fc96c9a5f2f4508d5ced83ddd2af0))

## [1.89.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.89.0...v1.89.1) (2024-04-25)


### Bug Fixes

* **docker:** Prevent all possible "silent errors" during `docker build` ([#644](https://github.com/antonbabenko/pre-commit-terraform/issues/644)) ([0340c8d](https://github.com/antonbabenko/pre-commit-terraform/commit/0340c8d00fe3ba39829b66fd7890d828697a7878))

# [1.89.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.88.4...v1.89.0) (2024-04-15)


### Features

* Hook terraform_wrapper_module_for_each should use versions.tf from the module if it exists ([#657](https://github.com/antonbabenko/pre-commit-terraform/issues/657)) ([b127601](https://github.com/antonbabenko/pre-commit-terraform/commit/b127601a0b3d5af3dcc9f91a6d74e16f37d66a60))

## [1.88.4](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.88.3...v1.88.4) (2024-03-25)


### Bug Fixes

* Improve README and drop quotes from hook env vars ([#651](https://github.com/antonbabenko/pre-commit-terraform/issues/651)) ([daec682](https://github.com/antonbabenko/pre-commit-terraform/commit/daec6823f980ef0e9ac8675ed93b6861fcbe58cc))

## [1.88.3](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.88.2...v1.88.3) (2024-03-22)


### Bug Fixes

* **`terraform_providers_lock`:** Require `terraform init` (and `terraform_validate` hook) run when only lockfile changed ([#649](https://github.com/antonbabenko/pre-commit-terraform/issues/649)) ([02c1935](https://github.com/antonbabenko/pre-commit-terraform/commit/02c1935a12c889a029bc0a571410f19eb39bbab1))

## [1.88.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.88.1...v1.88.2) (2024-03-13)


### Bug Fixes

* **non-linux:** Bash environment variables in arguments not expanded + Add `trace` log level ([#645](https://github.com/antonbabenko/pre-commit-terraform/issues/645)) ([a2a2990](https://github.com/antonbabenko/pre-commit-terraform/commit/a2a2990ca42f93e2c1d61507d8c75e493d29dee6))

## [1.88.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.88.0...v1.88.1) (2024-03-11)


### Bug Fixes

* **docker:** Checkov installation silently fails on `docker build` in arm64. Workaround till issue will be fixed in `checkov` itself ([#635](https://github.com/antonbabenko/pre-commit-terraform/issues/635)) ([f255b05](https://github.com/antonbabenko/pre-commit-terraform/commit/f255b05feaace02f38822e3b53cf38c38e069115))

# [1.88.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.87.1...v1.88.0) (2024-02-22)


### Features

* Add `terragrunt_providers_lock` hook ([#632](https://github.com/antonbabenko/pre-commit-terraform/issues/632)) ([77940fd](https://github.com/antonbabenko/pre-commit-terraform/commit/77940fd1fbbe9d3ea70306f396e1d8a13534d51d))

## [1.87.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.87.0...v1.87.1) (2024-02-19)


### Bug Fixes

* Replace `mapfile` to support Bash 3.2.57 pre-installed in macOS ([#628](https://github.com/antonbabenko/pre-commit-terraform/issues/628)) ([01ab3f0](https://github.com/antonbabenko/pre-commit-terraform/commit/01ab3f0c68abda9f5799647f783c91c3d1fa3a90))

# [1.87.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.86.1...v1.87.0) (2024-02-17)


### Features

* Add parallelism to major chunk of hooks. Check `Parallelism` section in README ([#620](https://github.com/antonbabenko/pre-commit-terraform/issues/620)) ([6c6eca4](https://github.com/antonbabenko/pre-commit-terraform/commit/6c6eca463a74fa2608cb3de3e03873765d46252f))

## [1.86.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.86.0...v1.86.1) (2024-02-16)


### Bug Fixes

* `grep: warning: stray \ before /` which pop-up in `grep 3.8` ([#625](https://github.com/antonbabenko/pre-commit-terraform/issues/625)) ([e1a93b2](https://github.com/antonbabenko/pre-commit-terraform/commit/e1a93b26b29eda144fd0f53e3d84a99c07b15070))

# [1.86.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.85.0...v1.86.0) (2023-12-21)


### Features

* **`terraform_docs`:** Add `terraform-docs` default markers support and describe how to migrate to them ([#609](https://github.com/antonbabenko/pre-commit-terraform/issues/609)) ([4a0e1fe](https://github.com/antonbabenko/pre-commit-terraform/commit/4a0e1fed008230b65085da0e42b7695bc4e0a5f1))

# [1.85.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.84.0...v1.85.0) (2023-12-15)


### Features

* **trivy:** Add `terraform_trivy` hook and deprecate `terraform_tfsec` ([#606](https://github.com/antonbabenko/pre-commit-terraform/issues/606)) ([f3c819a](https://github.com/antonbabenko/pre-commit-terraform/commit/f3c819a747662d1257fa6989318d6ede5fabaff3))

# [1.84.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.83.6...v1.84.0) (2023-12-12)


### Features

* **deps:** Bump Python version in docker image from 3.11.5 to v3.12.0 ([#597](https://github.com/antonbabenko/pre-commit-terraform/issues/597)) ([28e3cde](https://github.com/antonbabenko/pre-commit-terraform/commit/28e3cde152370bcc5b38e82beb0345299f8c511d))

## [1.83.6](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.83.5...v1.83.6) (2023-11-16)


### Bug Fixes

* **`terraform_validate`:** Run `terraform init` on "Missing required provider" error ([#586](https://github.com/antonbabenko/pre-commit-terraform/issues/586)) ([6e2bb2e](https://github.com/antonbabenko/pre-commit-terraform/commit/6e2bb2e2a12528903d8b8a21f2924473e498385a))

## [1.83.5](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.83.4...v1.83.5) (2023-10-11)


### Bug Fixes

* Suppress duplicate error messages in `terraform_validate` ([#577](https://github.com/antonbabenko/pre-commit-terraform/issues/577)) ([4ea6b14](https://github.com/antonbabenko/pre-commit-terraform/commit/4ea6b14c6fdf48e33fa6e116cbe332bba0888bbb))

## [1.83.4](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.83.3...v1.83.4) (2023-09-22)


### Bug Fixes

* Fix terraform_wrapper_module_for_each for when resource name contains 'variable' ([#573](https://github.com/antonbabenko/pre-commit-terraform/issues/573)) ([941177e](https://github.com/antonbabenko/pre-commit-terraform/commit/941177e066e8de255f58f0a5afbda72995eb3f08))

## [1.83.3](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.83.2...v1.83.3) (2023-09-15)


### Bug Fixes

* Run `terraform_tfsec` only on terraform code changes ([#571](https://github.com/antonbabenko/pre-commit-terraform/issues/571)) ([4253162](https://github.com/antonbabenko/pre-commit-terraform/commit/42531626144fb8cdca3d5750c7206393f501feb4))

## [1.83.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.83.1...v1.83.2) (2023-09-04)


### Bug Fixes

* Extend `terraform_validate` `--retry-once-with-cleanup` errors list ([#566](https://github.com/antonbabenko/pre-commit-terraform/issues/566)) ([19188e5](https://github.com/antonbabenko/pre-commit-terraform/commit/19188e5c384a1803bca607e4e79faf61cc55a5b9))

## [1.83.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.83.0...v1.83.1) (2023-09-04)


### Bug Fixes

* Fixed ordering issue in terraform_wrapper_module_for_each hook ([#565](https://github.com/antonbabenko/pre-commit-terraform/issues/565)) ([dc12be1](https://github.com/antonbabenko/pre-commit-terraform/commit/dc12be1faff4b73a3fc9bd62296c40a351597a20))

# [1.83.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.82.0...v1.83.0) (2023-08-25)


### Features

* Skip legacy modules (with provider block) in terraform_wrapper_module_for_each hook ([#560](https://github.com/antonbabenko/pre-commit-terraform/issues/560)) ([456cc76](https://github.com/antonbabenko/pre-commit-terraform/commit/456cc7616ac4facc3392c51ed9606a7535f8fd0f))

# [1.82.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.81.2...v1.82.0) (2023-08-15)


### Features

* **docker:** Add ssh-client to Docker image to access private modules via ssh ([#553](https://github.com/antonbabenko/pre-commit-terraform/issues/553)) ([1d76157](https://github.com/antonbabenko/pre-commit-terraform/commit/1d76157c9d67a2cbc1b08a4d7bc5ad53a3b663e7))

## [1.81.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.81.1...v1.81.2) (2023-08-10)


### Bug Fixes

* Fix terraform_wrapper_module_for_each hook heredoc vars defaults ([#554](https://github.com/antonbabenko/pre-commit-terraform/issues/554)) ([6fd4263](https://github.com/antonbabenko/pre-commit-terraform/commit/6fd4263f599ff3318cc2095dde03a312bb617511))

## [1.81.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.81.0...v1.81.1) (2023-08-10)


### Bug Fixes

* Fix the terraform_wrapper_module_for_each hook for modules without outputs or variables ([#552](https://github.com/antonbabenko/pre-commit-terraform/issues/552)) ([f24b3fa](https://github.com/antonbabenko/pre-commit-terraform/commit/f24b3fab71b248c4be75ec378c43e6921053491a))

# [1.81.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.80.0...v1.81.0) (2023-06-12)


### Features

* Speedup `terraform_validate` - firstly try run validate without checking is `.terraform/` is valid ([#524](https://github.com/antonbabenko/pre-commit-terraform/issues/524)) ([d0d08ac](https://github.com/antonbabenko/pre-commit-terraform/commit/d0d08ac63cebd23e4ee7ff58fb91ea20c398ab69))

# [1.80.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.79.1...v1.80.0) (2023-05-30)


### Features

* **`terraform_providers_lock`:** Add `--mode` option and deprecate previous workflow ([#528](https://github.com/antonbabenko/pre-commit-terraform/issues/528)) ([2426b52](https://github.com/antonbabenko/pre-commit-terraform/commit/2426b527aeee39aad0386cbbd734747d883ed7b6))

## [1.79.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.79.0...v1.79.1) (2023-05-09)


### Bug Fixes

* Fix `terraform_providers_lock` hook broken in v1.79.0 ([#521](https://github.com/antonbabenko/pre-commit-terraform/issues/521)) ([6bfc5bf](https://github.com/antonbabenko/pre-commit-terraform/commit/6bfc5bf7670a6d9fbf21d1a686fdaa941ab34aa6))

# [1.79.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.78.0...v1.79.0) (2023-05-08)


### Features

* TFLint: Add `--hook-config=--delegate-chdir` to use `tflint -chdir` ([#512](https://github.com/antonbabenko/pre-commit-terraform/issues/512)) ([1e9debc](https://github.com/antonbabenko/pre-commit-terraform/commit/1e9debc02f558156823fc1ddd5cf2b48b1593167))

# [1.78.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.77.4...v1.78.0) (2023-04-28)


### Features

* **ci:** Build multi-arch Docker images (`amd64`, `arm64`) ([#496](https://github.com/antonbabenko/pre-commit-terraform/issues/496)) ([923c2c6](https://github.com/antonbabenko/pre-commit-terraform/commit/923c2c6a1e093620980790e864801f48a13ecf57))

## [1.77.4](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.77.3...v1.77.4) (2023-04-28)


### Bug Fixes

* Speed up x2 TFLint hook execution in dirs with violations ([#514](https://github.com/antonbabenko/pre-commit-terraform/issues/514)) ([49974ab](https://github.com/antonbabenko/pre-commit-terraform/commit/49974ab9ef37e199d65778e6055aaf8130c6a875))

## [1.77.3](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.77.2...v1.77.3) (2023-04-21)


### Bug Fixes

* Updates all dependencies used in Dockerfile and fix Docker image ([#507](https://github.com/antonbabenko/pre-commit-terraform/issues/507)) ([dc177fe](https://github.com/antonbabenko/pre-commit-terraform/commit/dc177fe29ed250fbb98702248c7de232bdb75f58))

## [1.77.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.77.1...v1.77.2) (2023-04-09)


### Bug Fixes

* Fixed spacing in `terraform_wrapper_module_for_each` hook ([#503](https://github.com/antonbabenko/pre-commit-terraform/issues/503)) ([ddc0d81](https://github.com/antonbabenko/pre-commit-terraform/commit/ddc0d81d31a2571de95246b9970216ae0e4432c4))

## [1.77.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.77.0...v1.77.1) (2023-02-03)


### Bug Fixes

* Pass command line arguments to tflint init ([#487](https://github.com/antonbabenko/pre-commit-terraform/issues/487)) ([29a8c00](https://github.com/antonbabenko/pre-commit-terraform/commit/29a8c00251e16941059df0f460b1e55890d4d7b5))

# [1.77.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.76.1...v1.77.0) (2022-11-26)


### Features

* Add `--retry-once-with-cleanup` to `terraform_validate` ([#441](https://github.com/antonbabenko/pre-commit-terraform/issues/441)) ([96fe3ef](https://github.com/antonbabenko/pre-commit-terraform/commit/96fe3ef6577705ee72ae33cba5f366ce32b9a5f7))

## [1.76.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.76.0...v1.76.1) (2022-11-26)


### Bug Fixes

* Describe migration instructions from `terraform_docs_replace` ([#451](https://github.com/antonbabenko/pre-commit-terraform/issues/451)) ([a8bcaa7](https://github.com/antonbabenko/pre-commit-terraform/commit/a8bcaa7975175679f2da0a5d1379f0e20446a2f9))

# [1.76.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.75.0...v1.76.0) (2022-10-06)


### Features

* Add support for version constraints in `tfupdate` ([#437](https://github.com/antonbabenko/pre-commit-terraform/issues/437)) ([a446642](https://github.com/antonbabenko/pre-commit-terraform/commit/a4466425fb486257cfc672094d92b0fb04fdfe93))

# [1.75.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.74.2...v1.75.0) (2022-09-07)


### Features

* Allow running container as non-root UID/GID for ownership issues (docker) ([#433](https://github.com/antonbabenko/pre-commit-terraform/issues/433)) ([abc2570](https://github.com/antonbabenko/pre-commit-terraform/commit/abc2570e42d3b01b56d34a474eedbf13063d3c31))

## [1.74.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.74.1...v1.74.2) (2022-09-02)


### Bug Fixes

* Fixed url for wrappers in generated README (terraform_wrapper_module_for_each) ([#429](https://github.com/antonbabenko/pre-commit-terraform/issues/429)) ([fe29c6c](https://github.com/antonbabenko/pre-commit-terraform/commit/fe29c6c71abf31e5e7fbba6ed1d3555971e89ee4))

## [1.74.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.74.0...v1.74.1) (2022-07-13)


### Bug Fixes

* Passed scenario in `terraform_docs` hook now works as expected ([7ac2736](https://github.com/antonbabenko/pre-commit-terraform/commit/7ac2736ab9544455b06fb66f2fb40d3609a010b6))

# [1.74.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.73.0...v1.74.0) (2022-07-12)


### Bug Fixes

* Add `--env-vars`, deprecate `--envs` ([#410](https://github.com/antonbabenko/pre-commit-terraform/issues/410)) ([2b35cad](https://github.com/antonbabenko/pre-commit-terraform/commit/2b35cad50fd7fe1c662cab1bfaab2a4ef7baa3c9))
* Add `--tf-init-args`, deprecate `--init-args` ([#407](https://github.com/antonbabenko/pre-commit-terraform/issues/407)) ([c4f8251](https://github.com/antonbabenko/pre-commit-terraform/commit/c4f8251d302260953c62a6b2116ea89584ce04a6))


### Features

* Add support for set env vars inside hook runtime ([#408](https://github.com/antonbabenko/pre-commit-terraform/issues/408)) ([d490231](https://github.com/antonbabenko/pre-commit-terraform/commit/d4902313ce11cc12c738397463f307b830a9ba3e))
* Allow `terraform_providers_lock` specify terraform init args ([#406](https://github.com/antonbabenko/pre-commit-terraform/issues/406)) ([32b232f](https://github.com/antonbabenko/pre-commit-terraform/commit/32b232f039ceee24b2db8e09de57047c78c6005b))
* Suppress color for all hooks if `PRE_COMMIT_COLOR=never` set ([#409](https://github.com/antonbabenko/pre-commit-terraform/issues/409)) ([b12f0c6](https://github.com/antonbabenko/pre-commit-terraform/commit/b12f0c662c4ebd104b27880fc380854590c0ca22))

# [1.73.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.72.2...v1.73.0) (2022-06-27)


### Features

* Add __GIT_WORKING_DIR__ to terraform_checkov ([#399](https://github.com/antonbabenko/pre-commit-terraform/issues/399)) ([ae88ed7](https://github.com/antonbabenko/pre-commit-terraform/commit/ae88ed73cfb63398270608d4e68f46bb4424f150))

## [1.72.2](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.72.1...v1.72.2) (2022-06-21)


### Bug Fixes

* Pre-commit-terraform terraform_validate hook ([#401](https://github.com/antonbabenko/pre-commit-terraform/issues/401)) ([d9f482c](https://github.com/antonbabenko/pre-commit-terraform/commit/d9f482c0c6fa0bd464bbaa7444b4f853f1bc4fb9))

## [1.72.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.72.0...v1.72.1) (2022-05-25)


### Bug Fixes

* Fixed `terraform_fmt` with `tfenv`, when `terraform` default version is not specified ([#389](https://github.com/antonbabenko/pre-commit-terraform/issues/389)) ([1b9476a](https://github.com/antonbabenko/pre-commit-terraform/commit/1b9476a2798f49c474cb59e812ddaf66b2cc6ca2))

# [1.72.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.71.0...v1.72.0) (2022-05-25)


### Features

* When a config file is given, do not specify formatter on cli (terraform_docs) ([#386](https://github.com/antonbabenko/pre-commit-terraform/issues/386)) ([962054b](https://github.com/antonbabenko/pre-commit-terraform/commit/962054b923e7a4fff5338fd3f5cb76f957797dd3))

# [1.71.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.70.1...v1.71.0) (2022-05-02)


### Features

* Added terraform_wrapper_module_for_each hook ([#376](https://github.com/antonbabenko/pre-commit-terraform/issues/376)) ([e4e9a73](https://github.com/antonbabenko/pre-commit-terraform/commit/e4e9a73d7eb8182bcad5ffca17876d1c0a4a8a49))

## [1.70.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.70.0...v1.70.1) (2022-04-28)


### Bug Fixes

* Fixed `tfupdate` to work in all cases, not only `pre-commit run --all` ([#375](https://github.com/antonbabenko/pre-commit-terraform/issues/375)) ([297cc75](https://github.com/antonbabenko/pre-commit-terraform/commit/297cc757879f25bed6d3adf3b6254cf0d37b17c2))

# [1.70.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.69.0...v1.70.0) (2022-04-28)


### Features

* Add support for `pre-commit/pre-commit-hooks` in Docker image ([#374](https://github.com/antonbabenko/pre-commit-terraform/issues/374)) ([017da74](https://github.com/antonbabenko/pre-commit-terraform/commit/017da745d0817f94b44c3c773e4aa8d42a80aa09))

# [1.69.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.68.1...v1.69.0) (2022-04-26)


### Features

* Allow env vars expansion in `--args` section for all hooks ([#363](https://github.com/antonbabenko/pre-commit-terraform/issues/363)) ([caa01c3](https://github.com/antonbabenko/pre-commit-terraform/commit/caa01c30b33a5a829b75ee6a9e9e08a534a42216))

## [1.68.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.68.0...v1.68.1) (2022-04-20)


### Bug Fixes

* Fixed git fatal error in Dockerfile ([#372](https://github.com/antonbabenko/pre-commit-terraform/issues/372)) ([c3f8dd4](https://github.com/antonbabenko/pre-commit-terraform/commit/c3f8dd40e6d6867c661e2495f8194ee7bd9c7fdd))

# [1.68.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.67.0...v1.68.0) (2022-04-18)


### Features

* Removed `coreutils` (realpath) from dependencies for MacOS ([#368](https://github.com/antonbabenko/pre-commit-terraform/issues/368)) ([944a2e5](https://github.com/antonbabenko/pre-commit-terraform/commit/944a2e5fefd50df6130c68bcaa4beb4d770c11b9))

# [1.67.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.66.0...v1.67.0) (2022-04-15)


### Features

* Added `terraform_checkov` (run per folder), deprecated `checkov` hook ([#290](https://github.com/antonbabenko/pre-commit-terraform/issues/290)) ([e3a9834](https://github.com/antonbabenko/pre-commit-terraform/commit/e3a98345bb3be407c476749496827b418b81241c))

# [1.66.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.65.1...v1.66.0) (2022-04-13)


### Features

* Added support for `tfupdate` to update version constraints in Terraform configurations ([#342](https://github.com/antonbabenko/pre-commit-terraform/issues/342)) ([ef7a0f2](https://github.com/antonbabenko/pre-commit-terraform/commit/ef7a0f2b467d20f30341d25df3d4012cff2194ec))

## [1.65.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.65.0...v1.65.1) (2022-04-13)


### Bug Fixes

* Improve `tflint --init` command execution ([#361](https://github.com/antonbabenko/pre-commit-terraform/issues/361)) ([d31cb69](https://github.com/antonbabenko/pre-commit-terraform/commit/d31cb6936376bd1aaa9ada83021c29e6ca6727e0))

# [1.65.0](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.64.1...v1.65.0) (2022-04-13)


### Features

* Adding init to terraform_tflint hook ([#352](https://github.com/antonbabenko/pre-commit-terraform/issues/352)) ([1aff30f](https://github.com/antonbabenko/pre-commit-terraform/commit/1aff30f2a4cb0df65a1e693690b5225a112cf621))

## [1.64.1](https://github.com/antonbabenko/pre-commit-terraform/compare/v1.64.0...v1.64.1) (2022-03-31)


### Bug Fixes

* Make hooks bash 3.2 compatible ([#339](https://github.com/antonbabenko/pre-commit-terraform/issues/339)) ([4ad825d](https://github.com/antonbabenko/pre-commit-terraform/commit/4ad825d8d39254c69f0e01fb3e7728f0be9acbb9))

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
