# An architectural overview of HealOps

This page is not for the faint of heart. However, if you do hold out, you will gain invaluable knowledge on how HealOps works. Especially useful when developing HealOpsPackages and certainly required reading if contributing to HealOps itself.

## The components of HealOps

### Deploy components

_The Install-HealOps script_.

- Publish it to the feed you use for HealOps on your package management system: `Publish-Script -Path ./location_of_HealOps/Deployment/Install-HealOps.ps1 -NuGetApiKey "KEY" -Repository "REGISTERED_REPOSITY"`
        - In this way it can be installed when you want to deploy HealOps on/to a node.
        - The script is a part of the HealOps repository. It is placed in the `Deployment` folder.

### The time-series database

- First you need to decide what time-series database backend you want to use together with HealOps. HealOps has been thoroughly tested with `OpenTSDB` as its time-series database backend. Others should be supported as well. As long as the requirements and the data type of a metric to be reported, matches the requirements of `OpenTSDB`.

### Metric visualization system

- Here you should have several choices as well. However, HealOps together with `Grafana` has been tested and tried.
        * [Grafana](https://grafana.com/)

## Diagrams

### The state engine of HealOps

A picture or words? PICTURE!

> A sequence diagram illustrating the case of a component in a failed state.

![seq-diagram-failed-state](./images/HealOpsTestAndRepairCycle_StateFailed_SequenceDiagram.jpg)

> A sequence diagram illustrating the case of a component in an okay state

![seq-diagram-okay-state](./images/HealOpsTestAndRepairCycle_StateOkay_SequenceDiagram.jpg)