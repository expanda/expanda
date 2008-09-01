BioPAX Level 2, version 1.0 README File

____________________________________________________________________________________


BioPAX - Biological Pathways Exchange - http://biopax.org

The BioPAX workgroup was formed to create a data exchange format
that enables sharing of pathway information, such as signal transduction,
metabolic and gene regulatory pathways.

We are pleased to release BioPAX Level 2 v1.0, available in OWL (Web Ontology Language).
This release supports representation of metabolic pathways, molecular interaction
and proteomics databases and some aspects of signal transduction, such as protein
post-translational modifications using PSI-MI Level 2 controlled vocabularies.

Available Level 1 data sources:
*BioCyc
*KEGG and WIT coming soon

Available Level 2 data sources:
*Reactome

Additionally, a number of software systems now support BioPAX.
See the BioPAX wiki for more information: http://biopaxwiki.org/cgi-bin/moin.cgi/FrontPage

BioPAX ontology files and documentation are freely available (under the GNU
LGPL license) here: http://www.biopax.org

Subsequent levels will support signaling pathways, gene regulatory and genetic
interaction networks. We request feedback on BioPAX for development of future levels
via the biopax-discuss mailing list, which you can join here:
http://www.biopax.org/mailman/listinfo/biopax-discuss

Comments on bugs and features received on the mailing list will be addressed
with future maintenance releases of BioPAX Level 2.

Thanks for your time and we look forward to hearing from you.

Best regards,
BioPAX Workgroup 

____________________________________________________________________________________


README TABLE OF CONTENTS

1. File Descriptions
2. Examples
3. Known Issues
4. BioPAX Workgroup Contact Info

____________________________________________________________________________________


1.  File Descriptions
=====================

The following files are included in this distribution of BioPAX:

biopax-level2.owl
-----------------
This is the main definition file for BioPAX Level 2.  It contains the BioPAX
Level 2 ontology, encoded in the Web Ontology Language (OWL).


biopax-level2-documentation.pdf
-------------------------------
This document provides an overview of BioPAX Level 2, Version 1.0. This includes 
descriptions of the BioPAX ontology classes, sample use cases and best practice
recommendations.


biopax-level2-diagram-main.pdf
------------------------------
This diagram shows the classes and properties of the main BioPAX ontology.  The diagram was
generated using the ezOWL plug-in in the Protege ontology editor.


biopax-level2-diagram-utility.pdf
---------------------------------
This diagram shows the classes and properties of the utility class BioPAX ontology.  The diagram was
generated using the ezOWL plug-in in the Protege ontology editor.


psi-mi25.obo
------------
The PSI-MI Level 2.5 ontology from October 2005. BioPAX Level 2 adopts many classes
from PSI-MI (Proteomics Standards Initiative - Molecular Interactions) which depend
on PSI-MI controlled vocabularies defined here.  For the latest file, please see:
http://cvs.sourceforge.net/viewcvs.py/psidev/psi/mi/rel25/data/


2. Examples
===========

Note: each example is composed of two files:
1. The OWL file e.g. example-pathway.owl. This is the actual BioPAX file.
2. The Protege project file e.g. example-pathway.pprj.
Loading this file into Protege, rather than building (or "importing", depending on
the Protege version) the e.g. example-pathway.owl file, will preserve a number
of Protege settings that allow easier viewing of the file.  Both the .pprj file
and the corresponding .owl file must be in the same directory.

Note: The .pprj files were created with Protege version 3.0 build 141, OWL Plugin 1.3, Build 225.4;
it may not load properly into other versions.

biopax-example-short-pathway
----------------------------
A short example pathway - the first two steps of glycolysis.  It is a simple
illustration of how various BioPAX classes and properties should be used.
This was originally a BioPAX Level 1 example, but it is compatible with Level 2.

biopax-example-ecocyc-glycolysis
--------------------------------
The glycolysis pathway from the EcoCyc database, translated into BioPAX format.
It shows what a pathway from an existing database may look like after
being translated into BioPAX format.  This was originally a BioPAX Level 1 example,
but it is compatible with Level 2 after one minor change:
For modulation instances, ACTIVATION-UNKMECH was changed to ACTIVATION and similarly
for INHIBITION-UNKMECH.  This is the only backward compatibility issue with this example.

biopax-example-reactome-CHK2-ATM
--------------------------------
A single catalyzed biochemical reaction from the Reactome database. The reaction
makes use of features new to BioPAX Level 2 including a sequence modification on
one of the proteins (Chk2).

biopax-example-proteomics-protein-interaction
---------------------------------------------
A single proteomics style protein-protein interaction converted from the MINT database.
This illustrates use of the physicalInteraction class for proteomics style molecular
interactions where no result of the interaction is captured. These interactions often
require associated experimental evidence to interpret reliably. Experimental evidence
of the form captured in the PSI-MI format is included here to illustrate this new Level 2
feature.

3. Known Issues
===============

While Level 2 represents important progress relative to Level 1, it is likely that
Level 3 and future levels will not be backwards compatible with Level 2 or Level 1.
Specific issues are: our use of OWL does not conform to the OWL semantics, there is
discussion in the community about the biological semantics of specific classes, and
some current features conflict with new features that will be added. Conversion to
Level 2 should be done with an attempt to isolate the intended semantics of the
original database from the specific OWL generated. See Appendix C of the documentation
for more information. 

4. BioPAX Workgroup Contact Info
================================

If you have a question that is not answered in the BioPAX, OWL, or Protege documentation,
please feel free to submit it to the BioPAX-discuss email list (biopax-discuss@biopax.org).
The email list is open to all but you must first join the list in order to post to it.  To
join, go here: http://www.biopax.org/mailman/listinfo/biopax-discuss

Please visit the BioPAX wiki for up-to-date documentation:
http://www.biopax.org/wiki

