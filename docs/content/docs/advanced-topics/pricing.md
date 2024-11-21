---
title: Pricing
---

Blue Agent packages infrastructure as code ready to be deployed on two stacks, Kubernetes and Azure Container Apps.

#### Kubernetes

Costs of a Kubernetes cluster vary a lot depending of your provider, region, and the resources you need.

For precise cost reports, you can use [OpenCost](https://github.com/opencost/opencost), or [Azure Kubernetes Service cost analysis addon](https://learn.microsoft.com/en-us/azure/aks/cost-analysis). The AKS cost analysis addon is based on OpenCost.

#### Azure Container Apps

As of Oct 22, 2024, Azure Container Apps pricing is as follows:

| Meter                | Pay as you go Price\* | 1-year Savings Plan Price\*      | 3-year Savings Plan Price\*      |
| -------------------- | --------------------- | -------------------------------- | -------------------------------- |
| vCPU (seconds)       | $0.000024 /sec        | $0.0000204 /sec<br>~15% savings  | $0.00001992 /sec<br>~17% savings |
| Memory (GiB-Seconds) | $0.000003 /sec        | $0.00000255 /sec<br>~15% savings | $0.00000249 /sec<br>~17% savings |

As agents are scaled down to zero when not in use, the cost is calculated based on the time the agent is running. Default deployment is 2 vCPUs and 4GiB of memory.

```txt
= ([vCPU cost] * 2 + [Memory cost] * 4) * [Time in seconds]
= (0.000024 * 2 + 0.000003 * 4) * [Time in seconds]
= 0.00006 * [Time in seconds]
```

Thus, cost per hour is:

```txt
= 0.00006 * 3600
= $0.216
```
