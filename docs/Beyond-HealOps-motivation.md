# Motivation

I [Lars Bengtsson](https://github.com/larssb) started developing HealOps in early 2017. Stemming from the thought that it had to be possible to make life as a DevOps Engineer and as a member of the on-call team at work easier. __By:__

- Improving the info received when getting a call when on on-call duty.
- Even better, developing a system that tries healing 'x' IT component and if that succeeds I can continue my sleep unknowingly of the mishap.
    - Although it will be possible to see that this happened, as the issue is logged.
- Having the system automatically contact the person on on-call duty, instead of having manual labour doing this. Because, having manual labor doing this.
    - The person/persons alerting an on-call duty person, often does not have the info and even sometimes the necessary skillset required to manage what 'x' component being in a bad state really means for 'x' system.
    - Has so far been my experience that this slows the mean time to response.
    - The number of incorrect call-ups is too high.
- Automatizing the monitoring, healing and alerting of IT services and its components.
- By making it possible to query the health of IT services and its components over time and thereby making available, to a higher degree of likeliness, the support of informed decisions that are based on data.
- Present and visualize data via dashboard systems.
- Packaging the code needed to monitor and healing 'x' IT service and its components into clearly compartmentalized entities. That makes it possible to:
    - Deploy those easily.
    - Modularize these packages, which then makes it easier to re-use them for different IT service monitoring and healing situations.

The above is the motivation for developing HealOps.