
# A Scalable Terragrunt Repository Architecture for Enterprise Environments

Managing infrastructure with **Terraform/OpenTofu** and **Terragrunt** can quickly become complex - especially as environments, teams, and requirements grow. Having a transparent, readable, and **DRY (Don't Repeat Yourself)** repository structure is essential for maintaining scalability and manageability over time.

The approach described here has been proven across real-world projects ranging from a few dozen to several hundred Terragrunt units. It's adaptable to any setup and built around a **hierarchical structure** that makes it easy to configure, extend, and reuse components.

This structure enables multiple teams to collaborate within the same repository without interfering with one another, simplifying how infrastructure changes are developed and deployed. Designed with **CI/CD pipelines** in mind, it supports fast, reliable deployments - whether you're updating a single module or rolling out changes across entire stacks.

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
* **`local-tf-modules/`** Contains reusable OpenTofu modules specific to this repository that don't warrant their own repositories.
* **`tg-base/`** The main Terragrunt directory hierarchy containing stacks and units. You can use multiple such directories and name them according to your needs.
* **`tg-base/_templates/`** A location for shared unit templates with common configurations, as described in the [Terragrunt multiple includes documentation](https://terragrunt.gruntwork.io/docs/features/includes/#using-multiple-includes).

### Implicit vs. Explicit Stacks

In this example, we use [implicit Terragrunt stacks](https://terragrunt.gruntwork.io/docs/features/stacks/#implicit-stacks-directory-based-organization), meaning stacks are defined through a hierarchy of directories.

If your infrastructure is highly homogeneous or contains many repeating stacks, consider using [explicit stacks](https://terragrunt.gruntwork.io/docs/features/stacks/#explicit-stacks-blueprint-based-generation) via Terragrunt's built-in stack feature or another blueprint-based approach.

### Multiple Levels of Stacks

You can use multi-level stack hierarchies, where each level holds its own configurations and variables. For instance, stacks may be organized by:

* **Geographical area** (e.g., `eu-central`, `us-east`)
* **Environment or stage** (e.g., `dev`, `staging`, `prod`)
* **Logical groupings** such as departments, teams, or projects

The correct stack order depends on your needs - for example, if a team has shared infrastructure across multiple regions, the team-level stack should sit above the regional stack. Go through your setup and find precedessors and successors of each level.

There's no universal best practice here - determine your hierarchy based on your organization's requirements.

### Why This Structure Matters

* **CI/CD Integration**
  The layout supports pipelines that deploy individual stacks independently. Each stack can be deployed using standard Terragrunt commands without excessive scripting. Keeping the structure pipeline-friendly is key to scalability.

* **Team Collaboration**
  Splitting infrastructure into separate stacks and units allows parallel development by multiple engineers. However, coordinate changes carefully to avoid deployment conflicts.
  Note that most version control systems (GitHub, GitLab, Azure DevOps) apply permissions at the repository level. For stricter access control, consider separate repositories per environment or stack.

* **Readability and Simplicity**
  Organize stacks so each level contains only the necessary entities. Too many small components complicate navigation; too few make deployments overly broad. Striking the right balance is essential.

### Templates

Templating units allows you to define sharable unit configurations that can be reused across multiple stacks or environments, reducing duplication and ensuring that core setup logic remains standardized.

A template can consume configurations from different stack levels, inheriting variables or settings from parent directories of an individual unit. This is possible, since a unit , even if it consumes a teamplate, is always able to inject its individual configuration from parent stacks. You can visit an [example template](https://github.com/AlexMe99/terragrunt-default-structure/blob/main/tg-base/_templates/unit.hcl) and especially compare the [consuming unit](https://github.com/AlexMe99/terragrunt-default-structure/blob/main/tg-base/stack_level_a/stack_level_b/unit-from-template/terragrunt.hcl) with a [standalone unit](https://github.com/AlexMe99/terragrunt-default-structure/blob/main/tg-base/stack_level_a/stack_level_b/unit-standalone/terragrunt.hcl) to get an insight into the difference.

At the same time, individual units can override specific variables or configurations from the template - for example, changing the Provider versions or adjusting resource parameters to meet their own requirements. This blend of inheritance and customization keeps your setup both DRY and adaptable.

One current limitation is that [Terragrunt does not support nested includes](https://github.com/gruntwork-io/terragrunt/issues/1566). A common workaround is to use [`read_terragrunt_config`](https://terragrunt.gruntwork.io/docs/features/includes/#using-read_terragrunt_config) to import shared data across deeper hierarchies.

## Variables and Configurations

After setting up the directory hierarchy, the next step is defining how variables and configurations flow through it. Variables form the backbone of any Terragrunt setup - they make your infrastructure flexible and reusable, but only if managed consistently. Again let's see how the example repository fills the different directories with files containing variables and configurations:

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

Variables can exist at multiple levels - from the repository root down to individual units. This allows global reuse with local customization where needed.

While Terragrunt supports variables in **HCL**, **YAML**, **JSON**, or **TFVARS**, the recommended format is **HCL**. Terragrunt includes features (like `--queue-include-units-reading`) to automatically derive all units that include a given configuration file.

If you prefer using YAML or JSON, you can rely on OpenTofu's [`file()`](https://opentofu.org/docs/language/functions/file/), [`yamldecode()`](https://opentofu.org/docs/language/functions/yamldecode/) and [`jsondecode()`](https://opentofu.org/docs/language/functions/jsondecode/) functions. However, this approach requires extra CI/CD logic to properly derive affected Terragrunt units.

### Global Variables

The `global-vars/` directory is the central hub for shared variables. The variables per file may target the whole repository or a common subset of units and stacks. The second case is important, if you need such variables for stacks/units which have are used in different parent stacks, to avoid duplicating variables and configurations. This helps ensure that only relevant units are affected when a variable changes - an important optimization for CI/CD pipelines.

### Stack-Specific Variables

Each stack can have its own variable files, which units within the stack consume. Consistent naming is crucial, especially when templates reference stack-specific variables.

Directory naming conventions help here: using Terragrunt and OpenTofu functions, you can dynamically derive stack names or regions from paths. This makes the directory names become explicit variables used to configure your infrastructure. The [unit template](https://github.com/AlexMe99/terragrunt-default-structure/blob/main/tg-base/_templates/unit.hcl#L6-L7) in the example repo shows how this works.

### Templates and Variable Injection

Templates can collect and pass variables into specific units while also injecting unit-specific values. Again you can have a look into the [unit template](https://github.com/AlexMe99/terragrunt-default-structure/blob/main/tg-base/_templates/unit.hcl#L3-L4) to get the mechanism.

This hybrid model allows both shared and custom configurations without breaking consistency.

### Dependencies and Outputs

Terragrunt dependencies enable sharing data between units. Different values may be needed for a successor. From resource names to cryptic IDs. The OpenTofu native approach would requiring to use the [terraform_remote_state resource](https://opentofu.org/docs/language/state/remote-state-data/). With our approach, you can define [dependencies](https://terragrunt.gruntwork.io/docs/reference/hcl/blocks/#dependency) and configure it for your needs.

This feature has to be used appropriatly. You need to initialize the different units in the right order, since outputs are generated during the OpenTofu apply. If you try to apply multiple units, which are depending on each other regarding their Outputs, you get a race condition. You may mitigate this risk by using [mock outputs](https://terragrunt.gruntwork.io/docs/features/stacks/#unapplied-dependency-and-mock-outputs), but do this cautiously.

## Remote State

Always use **remote state**. The OpenTofu state file is the single source of truth for your deployed infrastructure - losing or corrupting it can cause severe issues.

By persisting your state remotely, you ensure that teams can collaborate safely and that every change to your infrastructure is logged and traceable. Enabling versioning on your remote storage backend provides a detailed audit trail, allowing you to roll back or inspect previous states when needed.

### Why Terragrunt Excels

On major advantage of using Terragrunt is the way it structures and manages OpenTofu's state files. Because Terragrunt encourages smaller, modular Terraform configurations, each module maintains its own state. This leads to:

* **Faster plan/apply times** since only the relevant subset of infrastructure is evaluated and updated.
* **Smaller, more manageable state files** which are easier to handle, safer to version, and less prone to corruption.
* **Better scalability and safety** especially when managing complex environments or running frequent updates across multiple units.

### "path-relative-to-include"

Terragrunt's [`path_relative_to_include()`](https://terragrunt.gruntwork.io/docs/reference/hcl/functions/#path_relative_to_include) or similar functions provide an elegant solution for keeping state files organized and conflict-free. It allows you to structure your remote state paths to mirror the directory hierarchy of your Terragrunt repository. Take a look at the example repos [root.hcl file](https://github.com/AlexMe99/terragrunt-default-structure/blob/main/root.hcl#L3-L7), where such a dynamic configuration is illustrated.

Benefits include:

* **Simplified management** each state file corresponds naturally to its unit, making it easy to locate and maintain.
* **Avoid naming conflicts** Since the file paths reflect the directory structure, the possibility of overlapping state names is avoided.
* **Flexible backends** By parameterizing backend configuration variables, you can easily switch between or combine different remote storage resources. Especially for large projects, distributing state files across multiple backends can become important. Two typical cases can be identified:
  * **throttling limites** running units may lead to non-data-plane operations on the backend service, which normally has relatively restrictive limits. Take [Azure's storage account limits](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/request-limits-and-throttling#storage-throttling) as an example for this case.
  * **identity permissions** when applying subsets of the project with different identities, to keep `principle-of-least-privileges`, you may need to change your storage backend resource for each subset. An example would be, applying your infrastructure over multiple `Azure Subscriptions` with individual identities and storage accounts per subscription. This is a usual scenario especially for splitting your infrastructure into different environments/stages.

## Provider Configuration

Efficient provider management is a key part of optimizing Terragrunt and Terraform performance, especially in large infrastructures with many stacks and units. Properly configuring providers helps ensure consistency, reduces initialization times, and allows you to take full advantage of [Terragrunt's provider caching](https://terragrunt.gruntwork.io/docs/features/provider-cache-server/). Take also a look into my [article for provider caching in CI/CD pipelines](https://medium.com/@alex_meschede_29414/terragrunt-ci-cd-with-run-all-and-provider-caching-650773892c31).

### Root-Level Configuration

Define shared provider configurations at the [repository root](https://github.com/AlexMe99/terragrunt-default-structure/blob/main/root.hcl#L24-L35). This is possible with the [generate block](https://terragrunt.gruntwork.io/docs/reference/hcl/blocks/#generate):

* **Caching efficiency:** When all units share the same provider version, OpenTofu can reuse the cached provider binary. This dramatically reduces initialization time, particularly in ephemeral environments (like short-lived Kubernetes runners or CI/CD pipelines).
* **Simplified dependencies:** Teams no longer need to track different provider versions across multiple modules.
* **Consistency:** A unified provider version helps ensure identical behavior and compatibility across all deployments.

When managing provider configurations, pay special attention to additional provider files (normally given as provider.tf) in the OpenTofu modules. Terragrunt allows you to control how these files are handled. Existing provider definitions can be `overwritten` by setting `if_exists = "overwrite"` or `if_exists = "skip"` in your `generate block` to allow downstream provider settings. This ensures that root-level providers don't unintentionally conflict with module-specific definitions.

### Unit-Level Customization

Sometimes, certain units or modules require additional or specialized providers. For example, some of your units may a certain provider (like [hashicorp/kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) or [hashicorp/azuread](https://registry.terraform.io/providers/hashicorp/azuread/latest)) and/or some stacks/units need **specific versions** due to **breaking changes**. In such cases, defining provider configurations directly within those units/stacks/templates can make OpenTofu runs both faster and more modular.

* **Speed up module initialization** Only the necessary providers for that unit are loaded.
* **Allow different provider versions per module** Useful when certain modules depend on features from newer (or specific) provider releases.
* **Offer finer-grained control** You can adjust provider settings (e.g., credentials, endpoints, regions) independently without affecting global configuration.

To enable this behaviour, use `if_exists = "skip"` at the root to avoid overwriting local provider definitions, and `if_exists = "overwrite"` or `"overwrite_terragrunt"` in your individualized configuration. In the example repo, you can find such an implemantation in the [unit template definition](https://github.com/AlexMe99/terragrunt-default-structure/blob/main/tg-base/_templates/unit.hcl#L14-L30).

## Adding New Stacks and Scaling Units

As your infrastructure evolves, adding stacks or scaling units should be straightforward. The structure presented in this article is designed for **heterogeneous environments**, where stacks and units differ between services or teams.

### Working with Heterogeneous Units

In reality, few units are identical. Using [implicit stacks](https://terragrunt.gruntwork.io/docs/features/stacks/#implicit-stacks-directory-based-organization) provides flexibility to reflect real-world diversity while maintaining a clear, hierarchical organization that reflects your infrastructure. Each stack can define its own configuration depth and composition, making it easy to adapt to unique requirements without overengineering the layout.

This approach lets you:

* **Stay DRY and transparent** Keep higher-level configurations generic and reusable, while allowing individual stacks to override or extend them only where necessary.
* **Scale organically** Add new stacks or units with minimal friction, adapting them precisely to their context.
* **Reuse sensibly** Share configuration layers (like global variables or base modules) where it makes sense, but without forcing artificial uniformity.

One challenge with implicit stacks is the temptation to **copy and paste** from existing stacks and units to create new ones. This may seem faster in the short term but leads to inconsistency and maintenance headaches later. So be catious or, instead, automate stack creation wherever possible. A good pattern is to:

* Use and maintain your **unit templates** as defaults.
* Keep **shared variables and configuration at higher stack levels** so new units can inherit variables automatically.
* frequently **evaluate and adjust your setup** according the variables and configurations and possibly changing defaults.

### When Homogeneity Becomes the Norm

If your infrastructure becomes highly uniform (e.g., hundreds of identical stacks) and the amount of stacks/units gets very high, consider:

* [Terragrunt's explicit stacks](https://terragrunt.gruntwork.io/docs/features/stacks/#explicit-stacks-blueprint-based-generation)
* Blueprinting or templating systems for programmatic stack generation

For most dynamic, heterogeneous environments, however, the implicit stack model remains the most flexible, maintainable and even scalable approach.

## OpenTofu Modules

OpenTofu modules are the building blocks of your infrastructure. How you organize and source them greatly affects maintainability and scalability. In most Terragrunt projects, you'll encounter two main types of module sources: **local modules** and **remote modules**. Each serves a distinct purpose depending on the maturity and scale of your setup.

### Local Modules

Looking into the example repo, the local tf modules are beyond the [local-tf-modules](https://github.com/AlexMe99/terragrunt-default-structure/tree/main/local-tf-modules/unit) directory. They are ideal for:

* **Fast iteration and prototyping** You can quickly modify module code and test it without pushing changes to a remote registry.
* **Simplified debugging and development** Developers can easily explore, update, and debug modules as part of their day-to-day work.
* **Ideal for prototyping** In the early stages of a project, it's easier to evolve your architecture when modules are local and versioning constraints are minimal.

However, they lack versioning and cross-repo sharing capabilities, making them less suited for mature environments.

### Remote Modules

For more mature projects, or when multiple teams or repositories depend on the same modules, it's better to switch to **remote modules**. Remote modules are hosted externally in their own repository or certain public or private registries - and are referenced by a versioned source path. This approach offers several key benefits:

* **Version control and stability** Each environment can pin to a specific version, ensuring consistent behavior even as modules evolve.
* **Cross-repo sharing** Remote modules allow you to reuse the same infrastructure logic across multiple repositories, keeping your architecture DRY and maintainable.
* **Robust collaboration**: Teams can work independently on module improvements while keeping production deployments stable through controlled version updates.

Combining Terragrunt's configuration management with remote modules enables scalable, maintainable infrastructure growth.

### Choosing Between Local and Remote

A simple rule of thumb:

* **Start local** for quick iteration, flexibility and designing your initial building blocks.
* **Move to remote** once stability and collaboration become priorities.

This evolution balances early agility with long-term reliability.

## Conclusion

Designing a Terragrunt repository that's transparent, scalable, and maintainable requires more than just good folder structure. It's about building a **system** that supports collaboration, automation, and growth.

By keeping your setup **DRY**, organizing stacks and variables thoughtfully, leveraging **remote state** and **provider caching**, and combining **templating** with **modular OpenTofu design**, you enable teams to manage complex infrastructures confidently and efficiently.

Whether you're starting small or operating at scale, these principles ensure that every change - from a single unit tweak to a full-stack rollout - remains **clear, consistent, and reliable**.
