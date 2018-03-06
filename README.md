Worm behavioral mapping and reverse correlation code
====================================================

This is the data collection and anlaysis code accompanying the paper "Temporal processing and context dependency in  *C. elegans* mechanosensation"

Simultanous stimulation and recording control software
-----------------------------------------------------

The data collection software is written mostly in LabVIEW.
Running it requires the hardware as decribed in the medthods section of the paper in addition to installing the associated software and and packages.

Key files and descriptions:
- \LabviewVIs\gaussian correlation time.vi: stimulate and record in random noise experiments
- \LabviewVIs\plate tap.vi: stimulate and record mechanical tap experiments
- \LabviewVIs\triangle wave.vi: stimulate and record triangle wave experiments
- \LabviewVIs\custom stimulus.vi: stimulate and record arbitrary waveforms loaded in from a text file
- \LabviewVIs\varying sqaure wave.vi: stimulate and record light pulse experiments


Behavioral analysis pipeline
----------------------------

After obtaining data collected using the simultanous stimulation and recording control software, they can be analyzed by the behavioral analysis pipeline.

An example of how behavioral analysis is conducted is found in \behavioral_analysis_demo.m

Much of the behavioral analysis pipline is adapted from the paper "Mapping the stereotyped behaviour of freely-moving fruit flies" by Berman, GJ, Choi, DM, Bialek, W, and Shaevitz, JW, J. Royal Society Interface, 99, 20140672 (2014).


Revese correlation
------------------

After analyzing random noise stimulation experiment folders through the entirety of the behavioral analysis pipeline, they can be used to fit LN models that describe how the stimulus inputs relate to behavioral transitions.

How reverse correlation is conducted can be found in \reverse_correlation_demo.m

