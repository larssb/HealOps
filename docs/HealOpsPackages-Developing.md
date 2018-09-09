# Developing a HealOps package

## Common ground for Tests and Stats files.

These files has to be structured as an implicit PowerShell function. If you are using VS Code as your IDE, you can use the PowerShell snippets included in the HealOpsPackage Plaster template. Meaning, that you can just write a keyword in a "new file" VS Code tab and then you will be provided the required structure for writing a HealOps Stats file. If you are not using the HealOpsPackage plaster template, then make sure to read the [Developing a HealOpsPackage](./HealOpsPackages-GettingStarted.md) page. There you can find template references to both files.

Both file types return a MetricsCollection object of a type specific to HealOps.
- The full type name is `[System.Collections.Generic.List``1[MetricItem]]`. Get it by calling the public Out-MetricsCollectionObject HealOps function.
- The returned collection can only contain objects of type MetricItem. Use the public HealOps function named Out-MetricItemObject to get one.
    - The `Value` property on each `MetricItem` object should have a value and that value should of type `Int32`.

> For all the above goes that controls are made by HealOps. In order to ensure that the return from Tests, Repairs and Stats files is as required.

## Specifics on Tests and Repairs files

Tests and Repairs files is respectively the file for testing the state of an IT system or one of its components and the file for repairing a possibly failed state of that IT system or component.

### The Tests file

Is a Pester test file. It has `Arange`, `Act` and `Assert` sections. Feel free to use the included PowerShell snippet if you are using VS Code as your IDE (the snippet is prefixed with `pester...` in the name). That will make it easier for you to get going.

- Should always be named *.Tests.ps1 - where the wildcard/* is to be changed to a logical name in regards to what is being tested. The `Tests` part of the name is important because it is a Pester test file. If the file does not have `Tests` in the name it will not be executed by Pester.
- Has to return both a:
    - `$global:passedTestResult = $MetricsCollection` and a...
    - `$global:failedTestResult = $MetricsCollection`
    - Note that both the variables are global. They are in order for HealOps to be able snatch them when the *.Tests.ps1 file has finished executing.
- Especially the `Assert` section is important. It should conform to the requirements of Pester so that the entity being tested is properly asserted. Go to the [Pester documentation](https://github.com/pester/Pester/wiki/Should) for more on designing Pester tests.

### The Repairs file

The repairs file is executed when a tested IT system or component is found to be in a bad state. You can be as creative as needs be when developing a Repairs file. As long as you ensure:

- That the Repairs files returns a boolean. HealOps controls on this boolean when submitting the metric data of a IT system or component to the HealOps backend.
- The Repairs file is an implicit function. Again, refer to the templates mentioned in the `Developing a HealOpsPackage`. Find a link to that page at the beginning of this one.
- It has a parameter named `TestData`. Via which it is possible to send in data from the test. Which could be used to go in different directions when repairing.
- The file should have the same name as its partner `Tests.ps1` file, with the difference that it ends in `Repairs.ps1`.
    - E.g. a file named `MyComponent.Tests.ps1` have a partner `Repairs` file named `MyComponent.Repairs.ps1`.

## Specifics on Stats files

You might simply want to collect stats on a component of an IT system. This is possible via a HealOps *.Stats.ps1 file.

### The Stats file

- Should always be named *.Stats.ps1 - where the wildcard/* is to be changed to a logical name in regards to what the stats represent.
- Specific to the return of a Stats file:
    - A property named `StatsOwner` can be included on the returned MetricItem. This is useful when the returned Stats is gathered on a node that is not the node to which the stats belong. Set the `StatsOwner` property to the name of the node that the returned stats belong to.
- The `Stats` file is an implicit function.