.. _9_other/1_post_analyses:

Post Analysis Treatments
------------------------

Post-analysis treatments are flag-activated Kind 2 features that are not
directly related to verification. The current post-analysis treatments available are

* certification,
* compilation to Rust,
* test generation,
* contract generation,
* assumption generation,
* invariant printing, and
* inductive validity core generation

All of them are deactivated by default. Post-analysis treatments run on the
*last analysis* of a system. It is defined as the last analysis performed by
Kind 2 on a given system. With the default settings, Kind 2 performs a single,
monolithic analysis of the top node. In this case, the *last analysis* is this
unique analysis.

This behavior is changed by the ``compositional`` flag. For example, say Kind 2
is asked to analyze node ``top`` calling two subnodes ``sub_1`` and ``sub_2``\ , in
compositional mode. Say also ``sub_1`` and ``sub_2`` have contracts, and that
refinement is possible.
In this situation, Kind 2 will analyze ``top`` by abstracting its two subnodes.
Assume for now that this analysis concludes the system is safe. Kind 2 has
nothing left to do on ``top``\ , so this compositional analysis is the *last
analysis* of ``top``\ , Kind 2 will run the post-analysis treatments.
Assume now that this purely compositional analysis discovers a counterexample.
Since refinement is possible, Kind 2 will refine ``sub_1`` (and/or ``sub_2``\ ) and
start a new analysis. Hence, the first, purely compositional analysis is not
the *last analysis* of ``top``.
The analysis where ``sub_1`` and ``sub_2`` are refined is the *last analysis* of
``top`` regardless of its outcome (assuming no other refinement is possible).

Long story short, the *last analysis* of a system is either the first analysis
allowing to prove the system safe, or the analysis where all refineable systems
have been refined.

The ``modular`` flag forces Kind 2 to apply whatever analysis / treatment the
rest of the flags specify to all the nodes of the system, bottom-up.
Post-analysis treatments respect this behavior and will run on the last
analysis of each node.

Prerequisites
^^^^^^^^^^^^^

Some treatments can fail (which results in a warning) because some conditions
were not met by the system and/or the last analysis. The prerequisites for each
treatment are:

.. We have to use the explicit grid table form to allow for wrapping in cells

+-----------------------+-----------------------------------------------+----------------------------------------+
| Treatment             | Conditions                                    | Notes                                  |
+-----------------------+-----------------------------------------------+----------------------------------------+
| certification         | last analysis proved the system safe          | will fail if node is partially defined |
+-----------------------+-----------------------------------------------+----------------------------------------+
| compilation to Rust   |                                               |                                        |
+-----------------------+-----------------------------------------------+----------------------------------------+
| test generation       | system has a contract with more than one mode |                                        |
|                       | and the last analysis proved the system safe  |                                        |
+-----------------------+-----------------------------------------------+----------------------------------------+
| contract generation   |                                               | experimental                           |
+-----------------------+-----------------------------------------------+----------------------------------------+
| assumption generation | last analysis falsified some property         | generates non-temporal constraints     |
+-----------------------+-----------------------------------------------+----------------------------------------+
| invariant printing    |                                               |                                        |
+-----------------------+-----------------------------------------------+----------------------------------------+
| inductive validity    | last analysis proved the system safe          |                                        |
| core generation       |                                               |                                        |
+-----------------------+-----------------------------------------------+----------------------------------------+
