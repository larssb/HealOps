[![Documentation Status](https://readthedocs.org/projects/healops/badge/?version=latest)](https://healops.readthedocs.io/en/latest/?badge=latest)

__HealOps__ is a state monitoring and broken state repairing framework. Use it for all your operation validation needs. Automatically monitor and repair the state of IT systems and their components. Systems and components can be monitored by writing Pester tests that acts as the state determining engine.
Regular PowerShell scripts are used for repairing a broken state of a system or component. Furthermore, HealOps can also be used to collect stats. This also happens via PowerShell scripts.

The parts mentioned above, the Pester tests, Repairs and Stats PowerShell scripts. Has been designed in such a way, that it should be quite clear what is needed in order for e.g. a Repairs script to work with HealOps. The collected whole that hold these components is called a HealOpsPackage.

## Documentation

__You find the main documentation on HealOps right [here](https://healops.readthedocs.io)__

- For documentation on HealOpsPackages specifically, start out by going to [What is a HealOpsPackage?](https://healops.readthedocs.io/en/latest/HealOpsPackages-What/)