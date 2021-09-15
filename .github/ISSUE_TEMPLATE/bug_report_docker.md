---
name: Docker bug report
about: Create a bug report
labels:
- bug
- area/docker
---

<!--
Thank you for helping to improve pre-commit-terraform!

Please be sure to search for open issues before raising a new one. We use issues
for bug reports and feature requests. Please note, this template is for bugs
report, not feature requests.
-->

### Describe the bug

<!--
Please let us know what behavior you expected and how terraform-docs diverged
from that behavior.
-->


### How can we reproduce it?

<!--
Help us to reproduce your bug as succinctly and precisely as possible. Any and
all steps or script that triggers the issue are highly appreciated!

Do you have long logs to share? Please use collapsible sections, that can be created via:

<details><summary>SECTION_NAME</summary>

```bash
YOUR_LOG_HERE
```

</details>
-->


### Environment information

* OS:  

<!-- I.e.:
OS: Windows 10
OS: Win10 with Ubuntu 20.04 on WSL2
OS: MacOS
OS: Ubuntu 20.04
-->

* `docker info`:

<details><summary><code>command output</summary>

```bash
INSERT_OUTPUT_HERE
```

</details>

* Docker image tag/git commit:  

* Tools versions. Don't forget to specify right tag in command -  
  `TAG=latest && docker run --entrypoint cat pre-commit:$TAG /usr/bin/tools_versions_info`

```bash
INSERT_OUTPUT_HERE
```

* `.pre-commit-config.yaml`:

<details><summary>file content</summary>

```bash
INSERT_FILE_CONTENT_HERE
```

</details>
