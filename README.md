# Compulsory Assignment 1 Review Guide

### [Lecture 1](https://github.com/annafoldberg/dbd/tree/main/mobilityticketing-lecture-1-starter-main)

Each sql file contains its relevant extensions according to the exercise.  

Within the `dossier.md` are discussions, models, and evidence.

#### Limitation or open question

<b>What does our implementation not guarantee, or what are we still unsure about?</b>
We are still unsure about performance with many database records.

<b>Relevant evidence</b>  
We only have few database records as shown in 002_seed.sql.

<b>What should we check next?</b>  
We should understand how the current implementation performs with many database records, and research relevant measures on how to improve performance accordingly.

---

### [Lecture 2](https://github.com/annafoldberg/dbd/tree/main/mobilityticketing-lecture-2-starter-main)

`011_ticketing_integrity.sql` contains the implementation of constraints.  

The `dossier.md` contains the analysis, decisions, and evidence for `lab.md`.

#### Decision worth discussing  
Should it be possible to validate a ticket multiple times?

<b>What did I choose?</b>  
It is possible to validate a ticket multiple times, as I find that it would be relevant to validate a ticket each time a person enters a new travel vehicle.

<b>What was the alternative?</b>  
The alternative is to allow only one validation per ticket, and letting the validation be valid for the entirety of what's left of the ticket time.

<b>Why does my choice fit MobilityTicketing?</b>  
In the design brief it's written that "A passenger presents a ticket when boarding."

<b>Which file or result supports it?</b>  
In `011_ticketing_integrity.sql`, `validations` contains no constraint for `ticket_code` or `ticket_id` to be unique.

---

### [Lecture 3](https://github.com/annafoldberg/dbd/tree/main/mobilityticketing-lecture-3-starter-main)

Each sql file under migrations contains its relevant extensions according to the exercise.

The `dossier.md` contains the experiments, analysis, and decisions for `lab.md`.

---

### [Lecture 4](https://github.com/annafoldberg/dbd/tree/main/mobilityticketing-lecture-4-starter-main)

#### Decisions worth discussing

<b>What did I choose?</b>  

<b>What was the alternative?</b>  

<b>Why does my choice fit MobilityTicketing?</b>  

<b>Which file or result supports it?</b>  

#### Limitation or open question

<b>What does our implementation not guarantee, or what are we still unsure about?</b>

<b>Relevant evidence</b>

<b>What should we check next?</b>

---