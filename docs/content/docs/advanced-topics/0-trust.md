---
title: 0 trust
---

By design, Blue Agent must be able to use a token to register itself to the Azure DevOps server. Centrally manage the tokens storage, their lifecycle and their access [greatly improve operational security](https://en.wikipedia.org/wiki/Zero_trust_architecture).

#### Kubernetes (Helm)

##### Azure Kubernetes Service

Azure Kubernetes Service implements [Pod Identity](https://learn.microsoft.com/en-us/azure/aks/use-azure-ad-pod-identity), which allows to use a Managed Identity from a Kubernetes Pod. This will allow components on the cluster to access the secrets stored in Azure Key Vault.

Prerequisites to the deployment are:

- The Key Vault provider for Secrets Store CSI Driver add-on [installed in the cluster](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver).
- An Key Vault with two secrets named `organization-url` and `personal-access-token`, both of type `secret`.
- A Managed Identity (system or user managed) with the `Key Vault Secrets User` role on the Key Vault.

```yaml
# values.yaml
secret:
  create: true
  azureKeyVault:
    enabled: false
    managedIdentityId: MY_MANAGED_IDENTITY_ID
    name: MY_KEY_VAULT_NAME
    tenantId: MY_TENANT_ID
```

##### Other distributions

Disable the secret creation in the Helm chart, and integrate yourself with your own secret management solution.

```yaml
# values.yaml
secret:
  create: false
```

#### Azure Container Apps (Bicep)

Bicep is not supported out of the box. But, integration between Azure Key Vault and Azure Container Apps is native and can be done in an hour. [See the documentation.](https://learn.microsoft.com/en-us/azure/container-apps/manage-secrets?tabs=azure-cli)
