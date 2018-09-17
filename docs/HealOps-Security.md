# Security considerations when using HealOps

## In general

The Stats, Tests and Repairs files of a HealOps package will likely need access to e.g. a database system, in order to e.g. restore a database to a point in time. This is needed for your scripts to do their magic. So there is no way to avoid given permissions here and there. However, what you CAN do is follow the [_PoLP_](https://en.wikipedia.org/wiki/Principle_of_least_privilege) (Principle of least privilege). Which in a condensed form states (loosely formulated): Give only permissions to specific components, not entire systems and ensure that the level of permissions is as low as possible. In other words don't give the `DELETE` right on a database if all the HealOps user needs is `READ` rights.

## When on Windows

HealOps requires that the user executing a HealOps file (Stats, Tests and Repairs files) has administrator permissions. In order to heighten the security. You should:

* Use a local administrator user. Created for the purpose of running HealOps jobs.
        * The user should be kept local as this heightens the chances that the uer only have permissions on the server where it is creaated.
* The password of this user should be unique for each server HealOps is running on.
* The password does not have to and should not be stored anywhere. You will not need it again. And it is not necessary that you know it for HealOps to work. If you need to change a job you just set a new password and configure each job to get this new password. For the same reasons the `Install-HealOps` deploy script does not store the password and does not let you know the password.