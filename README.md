# pre-commit-terraform hook

Single [pre-commit](http://pre-commit.com/) hook which runs `terraform fmt` on `*.tf` files.

An example `.pre-commit-config.yaml`:

```yaml
-   repo: git@github.com:antonbabenko/pre-commit-terraform
    sha: HEAD
    hooks:
    -   id: terraform_fmt
```

Enjoy the clean code!
