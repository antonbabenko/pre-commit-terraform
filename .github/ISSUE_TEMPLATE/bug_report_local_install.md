---
name: Local installation bug report
about: Create a bug report
labels:
- bug
- area/local_installation
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

* `uname -a` and/or `systeminfo | Select-String "^OS"` output:

```bash
INSERT_OUTPUT_HERE
```

<!-- I.e.:
```bash
PS C:\Users\vm> systeminfo | Select-String "^OS"

OS Name:                   Microsoft Windows 10 Pro
OS Version:                10.0.19043 N/A Build 19043
OS Manufacturer:           Microsoft Corporation
OS Configuration:          Standalone Workstation
OS Build Type:             Multiprocessor Free

$ uname -a
Linux DESKTOP-C7315EF 5.4.72-microsoft-standard-WSL2 #1 SMP Wed Oct 28 23:40:43 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux
```
-->

* Tools availability and versions:

<!--  For check all needed version run next script:

$0 << EOF
pre-commit --version                      2>/dev/null || echo "pre-commit SKIPPED"
terraform --version | head -n 1           2>/dev/null || echo "terraform SKIPPED"
python --version                          2>/dev/null || echo "python SKIPPED"
python3 --version                         2>/dev/null || echo "python3 SKIPPED"
echo -n "checkov " && checkov --version   2>/dev/null || echo "checkov SKIPPED"
terraform-docs --version                  2>/dev/null || echo "terraform-docs SKIPPED"
terragrunt --version                      2>/dev/null || echo "terragrunt SKIPPED"
echo -n "terrascan " && terrascan version 2>/dev/null || echo "terrascan SKIPPED"
tflint --version                          2>/dev/null || echo "tflint SKIPPED"
echo -n "tfsec " && tfsec --version       2>/dev/null || echo "tfsec SKIPPED"
EOF

-->

```bash
INSERT_TOOLS_VERSIONS_HERE
```


* `.pre-commit-config.yaml`:

<details><summary>file content</summary>

```bash
INSERT_FILE_CONTENT_HERE
```

</details>
