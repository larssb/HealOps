__HealOps__ is a state monitoring, stats gathering and broken state repairing framework. Use it for operation validation, repairing and stats gathering. With HealOps you can automatically gather stats and/or monitor and repair the state of IT systems and their components.

Systems and components are monitored by writing Pester tests that acts as the state determining engine. When a broken state is found a repair is automatically executed.
Tests, Repairs and Stats executions generate metrics. HealOps reports all metrics to a time-shift database backend. From there they are picked up by a metrics visualization system which can be used to create dashboards with graphs of various kinds. On these dashboards, threshold levels can be set. This makes it possible to automatically react to a component above a set threshold. If a threshold is met, it means that a broken state could not be repaired. So, the natural action to take, is to get some human eyeballs on the issue. For this to happen the visualization system pushes an alert to an incident management system. The incident management system then automatically contact the personnel responsible for a failed IT system or component. That is the full lifecycle of HealOps.

A nice bonus of the above is that, even though a state could not be repaired, it is possible with todays metrics visualization systems, to send useful info along with an alert to an incident management system. This could be:

* A picture of the graph of a failed component.
* URI's to documentation articles. Advice on how to fix a failed component.
* URI's to e.g. a system change log, system status websites and so forth.
* Info on where to login.

Other bonuses of using HealOps:

* In the situation that a component could not be repaired and you have to troubleshoot it manually. You can, when you think that have repaired a failed component, simply execute the same Tests file that found the component to be failed. This will help you determine if you actually really fixed the component or not.
    * This heightens your sense of certainty when troubleshooting.
    * Limits the number of cases where you think something was fixed but it wasn't really.
* A more data oriented approach to troubleshooting.

----

This is the home of all the documentation on HealOps. You should be able to find everything you need to get started with HealOps. Use this site as a helping hand in all your HealOps business.

I hope you find the documentation useful and less boring to read than the manual to your new vacuum cleaner.

__If you are already well versed in HealOps you should have a look at the HealOps package concept > [What is a HealOpsPackage?](./HealOpsPackages-What.md)__