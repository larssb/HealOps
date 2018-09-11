# What is a HealOpsPackage?

A HealOpsPackage is to HealOps, what a package is to your Node.js project. Equivalent to a module in the Java 9+ world.....and on you go for other programming languages that has a package management system via which you can share collections of code.

Specifically a HealOpsPackage contains *.Tests.ps1 and *.Repairs.ps1 files. Or/and *.Stats.ps1 files. These files are invoked in order to:

* Test the state of an IT system or component ==> * _a *.Tests.ps1 file_.
* Repair a broken state of 'x' component ==> _a *.Repairs.ps1 file_.
* Or simply just report the stats of 'x' component ==> _a *.Stats.ps1 file_.

You install a HealOpsPackage directly on a node running IT components you wish to have HealOps look at. Or you could install it on a node, external to the system you wish to have HealOps look at (you will then just configure the HealOpsPackage to point to the system/component that HealOps should look at).

To know more. Continue through the other articles on the HealOpsPackage concept.