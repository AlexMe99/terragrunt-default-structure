
# Managing Large-Scale Infrastructure with Terragrunt and Terraform/OpenTofu

Managing infrastructure with **Terraform/OpenTofu** and **Terragrunt** can quickly become complex — especially as environments, teams, and requirements grow. Having a transparent, readable, and **DRY (Don’t Repeat Yourself)** repository structure is essential for maintaining scalability and manageability over time.

The approach described here has been proven across real-world projects ranging from a few dozen to several hundred Terragrunt units. It’s adaptable to any setup and built around a **hierarchical structure** that makes it easy to configure, extend, and reuse components.

This structure enables multiple teams to collaborate within the same repository without interfering with one another, simplifying how infrastructure changes are developed and deployed. Designed with **CI/CD pipelines** in mind, it supports fast, reliable deployments — whether you’re updating a single module or rolling out changes across entire stacks.

You can explore a practical example of this architecture in the [terragrunt-default-structure repository](https://github.com/AlexMe99/terragrunt-default-structure).

## Directory Structure

A clear and consistent directory structure forms the foundation of any Terragrunt project. It improves readability, supports team collaboration, and simplifies CI/CD automation. When you look into the presented example repository, the following directory structure is used:

```TEXT
repo/
├── local-tf-modules/
│   └── unit-module/
├── tg-base/
│   └── _templates/
│   └── stack_level_a/
│       └── stack_level_b/
│           └── unit-from-template/
│           └── unit-standalone/
└── global-vars/
```

### Core Directories

Our setup is organized around three main directories:

* **`global-vars/`** A central place for shared configuration values and parameters used across the repository (not related to specific stacks or units).
* **`local-tf-modules/`** Contains reusable Terraform/OpenTofu modules specific to this repository that don’t warrant their own repositories.
* **`tg-base/`** The main Terragrunt directory hierarchy containing stacks and units. You can use multiple such directories and name them according to your needs.
* **`tg-base/_templates/`** A location for shared unit templates with common configurations, as described in the [Terragrunt multiple includes documentation](https://terragrunt.gruntwork.io/docs/features/includes/#using-multiple-includes).

### Implicit vs. Explicit Stacks

In this example, we use [implicit Terragrunt stacks](https://terragrunt.gruntwork.io/docs/features/stacks/#implicit-stacks-directory-based-organization), meaning stacks are defined through a hierarchy of directories.

If your infrastructure is highly homogeneous or contains many repeating stacks, consider using [explicit stacks](https://terragrunt.gruntwork.io/docs/features/stacks/#explicit-stacks-blueprint-based-generation) via Terragrunt’s built-in stack feature or another blueprint-based approach.

### Multiple Levels of Stacks

You can use multi-level stack hierarchies, where each level holds its own configurations and variables. For instance, stacks may be organized by:

* **Geographical area** (e.g., `eu-central`, `us-east`)
* **Environment or stage** (e.g., `dev`, `staging`, `prod`)
* **Logical groupings** such as departments, teams, or projects

The correct stack order depends on your needs — for example, if a team has shared infrastructure across multiple regions, the team-level stack should sit above the regional stack.

There’s no universal best practice here — determine your hierarchy based on your organization’s requirements.

### Why This Structure Matters

* **CI/CD Integration**
  The layout supports pipelines that deploy individual stacks independently. Each stack can be deployed using standard Terragrunt commands without excessive scripting. Keeping the structure pipeline-friendly is key to scalability.

* **Team Collaboration**
  Splitting infrastructure into separate stacks and units allows parallel development by multiple engineers. However, coordinate changes carefully to avoid deployment conflicts.
  Note that most version control systems (GitHub, GitLab, Azure DevOps) apply permissions at the repository level. For stricter access control, consider separate repositories per environment or stack.

* **Readability and Simplicity**
  Organize stacks so each level contains only the necessary entities. Too many small components complicate navigation; too few make deployments overly broad. Striking the right balance is essential.

### Templates

Templates enable reusable unit configurations, minimizing duplication while keeping setups standardized. A template can inherit variables or settings from parent stacks using Terragrunt functions such as: `read_terragrunt_config(find_in_parent_folders("stack_level_a.hcl"))`

This allows templates to remain flexible while individual units can override specific variables as needed — for instance, adjusting provider versions or resource parameters.

One current limitation is that [Terragrunt does not support nested includes](https://github.com/gruntwork-io/terragrunt/issues/1566). A common workaround is to use [`read_terragrunt_config`](https://terragrunt.gruntwork.io/docs/features/includes/#using-read_terragrunt_config) to import shared data across deeper hierarchies.

## Variables and Configurations

After setting up the directory hierarchy, the next step is defining how variables and configurations flow through it. Variables form the backbone of any Terragrunt setup — they make your infrastructure flexible and reusable, but only if managed consistently. Again let's see how the example repository fills the different directories with files containing variables and configurations:

```TEXT
repo/
├── local-tf-modules/
│   └── unit-module/
│       └── main.tf
│       └── outputs.tf
│       └── variables.tf
├── tg-base/
│   ├── _templates/
│   │   └── unit.hcl
│   ├── stack_level_a/
│   │   ├── stack_level_b/
│   │   │   ├── unit-from-template/
│   │   │   │   └── terragrunt.hcl
│   │   │   ├── unit-standalone/
│   │   │   │   └── terragrunt.hcl
│   │   │   └── stack_level_a.hcl
│   │   └── stack_level_a.hcl
│   └── base-configuration.hcl
├── global-vars/
│   └── var-file.yaml
└── root.hcl
```

### Basics

Variables can exist at multiple levels — from the repository root down to individual units. This allows global reuse with local customization where needed.

While Terragrunt supports variables in **HCL**, **YAML**, **JSON**, or **TFVARS**, the recommended format is **HCL**. Terragrunt includes features (like `--queue-include-units-reading`) to automatically derive all units that include a given configuration file.

If you prefer using YAML or JSON, you can rely on [OpenTofu’s `file()`](https://opentofu.org/docs/language/functions/file/) and [`yamldecode()`](https://opentofu.org/docs/language/functions/yamldecode/) functions. However, this approach requires extra CI/CD logic to properly derive affected Terragrunt units.

### Global Variables

The `global-vars/` directory is the central hub for shared variables. You can also define subsets that apply to specific but unrelated stacks. This helps ensure that only relevant units are affected when a variable changes — an important optimization for CI/CD pipelines.

### Stack-Specific Variables

Each stack can have its own variable files, which units within the stack consume. Consistent naming is crucial, especially when templates reference stack-specific variables.

Directory naming conventions help here: using Terragrunt/Terraform/OpenTofu functions, you can dynamically derive stack names or regions from paths, e.g.:

```hcl
# from: https://github.com/AlexMe99/terragrunt-default-structure/blob/main/tg-base/_templates/unit.hcl
path_to_stack_level_a = "${get_terragrunt_dir()}/../../"
stack_level_a_dirname = basename(dirname(local.path_to_stack_level_a))
```

### Templates and Variable Injection

Templates can collect and pass variables into specific units while also injecting unit-specific values. See the [unit.hcl example](https://github.com/AlexMe99/terragrunt-default-structure/blob/main/tg-base/_templates/unit.hcl) for details.

This hybrid model allows both shared and custom configurations without breaking consistency.

### Dependencies and Outputs

Terragrunt dependencies enable sharing data between units — e.g., passing a VPC ID from a networking module to an application stack.

To manage dependencies correctly:

* Ensure outputs exist before being consumed.
* Initialize dependencies in the right order.
* Use [mock outputs](https://terragrunt.gruntwork.io/docs/features/stacks/#unapplied-dependency-and-mock-outputs) cautiously during planning or validation to avoid masking real dependency issues.

## Remote State

Always use **remote state**. The Terraform/OpenTofu state file is the single source of truth for your deployed infrastructure — losing or corrupting it can cause severe issues.

Remote state storage ensures:

* Safe team collaboration
* Versioning and auditability
* Rollback capabilities through state version history

### Why Terragrunt Excels

Terragrunt’s modular approach isolates state files per unit, resulting in:

* **Faster plan/apply times** since only the relevant subset of infrastructure is evaluated and updated.
* **Smaller, more manageable state files** which are easier to handle, safer to version, and less prone to corruption.
* **Better scalability and safety** especially when managing complex environments or running frequent updates across multiple units.

### "path-relative-to-include"

The [`path_relative_to_include()`](https://github.com/AlexMe99/terragrunt-default-structure/blob/main/root.hcl) function allows organizing state paths to mirror the Terragrunt directory hierarchy.

Benefits include:

* Simplified management — each state file corresponds naturally to its unit
* Reduced naming conflicts
* Flexible backend options (e.g., S3, GCS, Azure Storage)

In large environments, distributing state files across multiple backends can prevent throttling and improve performance.

## Provider Configuration

Efficient provider management ensures consistency, faster initialization, and better caching.

### Root-Level Configuration

Define shared provider configurations at the repository root:

* **Caching efficiency:** When all units share the same provider version, Terraform/OpenTofu can reuse the cached provider binary. This dramatically reduces initialization time, particularly in ephemeral environments (like short-lived Kubernetes runners or CI/CD pipelines).
* **Simplified dependencies:** Teams no longer need to track different provider versions across multiple modules.
* **Consistency:** A unified provider version helps ensure identical behavior and compatibility across all deployments.

Terragrunt’s `generate` block supports the `if_exists` flag — use `"overwrite"` or `"skip"` to control how provider definitions cascade between root and unit levels.

### Unit-Level Customization

Certain units (e.g., monitoring or security) may need specialized providers. Defining provider configurations locally can:

* **Speed up module initialization** Only the necessary providers for that unit are loaded.
* **Allow different provider versions per module** Useful when certain modules depend on features from newer (or specific) provider releases.
* **Offer finer-grained control** You can adjust provider settings (e.g., credentials, endpoints, regions) independently without affecting global configuration.

Use `if_exists = "skip"` at the root to avoid overwriting local provider definitions, and `if_exists = "overwrite"` or `"overwrite_terragrunt"` in units.
See [this example configuration](https://github.com/AlexMe99/terragrunt-default-structure/blob/main/tg-base/_templates/unit.hcl).

Maintain version consistency even when customizing — consistent provider versions reduce reinitialization and network overhead, speeding up CI/CD runs.

## Adding New Stacks and Scaling Units

As your infrastructure evolves, adding stacks or scaling units should be straightforward. This structure is designed for **heterogeneous environments**, where stacks differ between services or teams.

### Working with Heterogeneous Units

In reality, few units are identical. Using [implicit stacks](https://terragrunt.gruntwork.io/docs/features/stacks/#implicit-stacks-directory-based-organization) provides flexibility to reflect real-world diversity.

This approach lets you:

* **Stay DRY and transparent** Keep higher-level configurations generic and reusable, while allowing individual stacks to override or extend them only where necessary.
* **Scale organically** Add new stacks or units with minimal friction, adapting them precisely to their context.
* **Reuse sensibly** Share configuration layers (like global variables or base modules) where it makes sense, but without forcing artificial uniformity.

Avoid copy-pasting stacks — instead:

* Use and maintain your **unit templates** as defaults
* Keep **shared variables and configuration at higher stack levels** so new units can inherit variables automatically
* **requirements do change** and you need to evaluate your current variables, configurations and templates against it. Adjust your setup continuously.


### When Homogeneity Becomes the Norm

If your infrastructure becomes highly uniform (e.g., hundreds of identical stacks), consider:

* [Terragrunt’s explicit stacks](https://terragrunt.gruntwork.io/docs/features/stacks/#explicit-stacks-blueprint-based-generation)
* Blueprinting or templating systems for programmatic stack generation

For most dynamic, heterogeneous environments, however, the implicit stack model remains the most flexible and maintainable approach.

## Terraform/OpenTofu Modules

Terraform/OpenTofu modules are the building blocks of your infrastructure. How you organize and source them greatly affects maintainability and scalability.

### Local Modules

Local modules, usually under `local-tf-modules/`, are ideal for:

* **Fast iteration and prototyping** You can quickly modify module code and test it without pushing changes to a remote registry.
* **Simplified debugging and development** Developers can easily explore, update, and debug modules as part of their day-to-day work.
* **Ideal for prototyping** In the early stages of a project, it’s easier to evolve your architecture when modules are local and versioning constraints are minimal.

However, they lack versioning and cross-repo sharing capabilities, making them less suited for mature environments.

### Remote Modules

For more mature projects, or when multiple teams or repositories depend on the same modules, it’s better to switch to **remote modules**. Remote modules are hosted externally — for example, in a Git repository, Terraform Cloud, or a private registry — and are referenced by a versioned source path. This approach offers several key benefits:

* **Version control and stability** Each environment can pin to a specific version, ensuring consistent behavior even as modules evolve.
* **Cross-repo sharing** Remote modules allow you to reuse the same infrastructure logic across multiple repositories, keeping your architecture DRY and maintainable.
* **Robust collaboration**: Teams can work independently on module improvements while keeping production deployments stable through controlled version updates.

Combining Terragrunt’s configuration management with remote modules enables scalable, maintainable infrastructure growth.

### Choosing Between Local and Remote

A simple rule of thumb:

* **Start local** for quick iteration and flexibility.
* **Move to remote** once stability and collaboration become priorities.

This evolution balances early agility with long-term reliability.

## Conclusion

Designing a Terragrunt repository that’s transparent, scalable, and maintainable requires more than just good folder structure. It’s about building a **system** that supports collaboration, automation, and growth.

By keeping your setup **DRY**, organizing stacks and variables thoughtfully, leveraging **remote state** and **provider caching**, and combining **templating** with **modular Terraform/OpenTofu design**, you enable teams to manage complex infrastructures confidently and efficiently.

Whether you’re starting small or operating at scale, these principles ensure that every change — from a single unit tweak to a full-stack rollout — remains **clear, consistent, and reliable**.
