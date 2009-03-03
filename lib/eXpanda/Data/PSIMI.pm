package eXpanda::Data::PSIMI;

use warnings;
use strict;
use Data::Dumper;
use XML::Twig;
use Carp qw/carp croak confess/;
use Storable qw{dclone};

sub psimi_1_1 {

}

sub psimi_2_5 {
    print STDERR "[debug] psimi_2_5\n" if $eXpanda::DEBUG;
    my $this = shift;

    my $handlers = { 'entrySet'
        =>  sub { push @_, $this; &mif25entrySet; },
        '/entrySet/entry'
        => sub { push @_, $this; &mif25entry; },
        '/entrySet/entry/source'
        => sub { push @_, $this; &mif25source; },
        '/entrySet/entry/availabilityList'
        => sub { push @_, $this; &mif25avail;},
        '/entrySet/entry/experimentList'
        => sub { push @_, $this; &mif25exp;},
        '/entrySet/entry/interactorList/interactor'
        => sub { push @_, $this; &mif25interactor;},
        '/entrySet/entry/interactionList/interaction'
        => sub { push @_, $this; &mif25interaction;},
        '/entrySet/entry/attributeList'
        => sub { push @_, $this; &mif25attlist;},
    };

    my $twig = XML::Twig->new(
        twig_handlers => $handlers
    );

    $twig->parsefile($this->{filepath});
    $twig->purge();

    return $this;
}

sub mif25entrySet {
    my ($t, $elm, $this) = @_;
    $this->{meta}->{spec} = {
        namespace => $elm->att('xmlns'),
        version => $elm->att('version'),
        level => $elm->att('level'),
        minorVersion => $elm->att('minorVersion') || 'nil',
    };
}

{
    my $entrycount = 1;

    sub mif25entry {
        my ($t, $elm, $this) = @_;
        $entrycount++;
    }

    sub entrycount {
        return $entrycount;
    }
}

# Naming rule
# attribute -> _attributename
#
# source, avail, expriment
#
sub mif25source {
    my ($t, $elm, $this) = @_;
    my $source = {names => {}, bibref => {}, xref => {}, attributeList => {},};
    # sequence : names bibref xref attributeList #
    # attributes : release(opt) releaseDate(opt) #

    if ( $elm->has_child('names') ) {
        my $nameselt = $elm->first_child('names');
        $source->{names} = namesType($nameselt);
    }

    if ( $elm->has_child('bibref') ) {
        my $bibelt = $elm->first_child('bibref');
        $source->{bibref} = bibrefType($bibelt);
    }

    if ( $elm->has_child('xref') ) {
        my $xrefelt = $elm->first_child('xref');
        $source->{xref} = xrefType($xrefelt);
    }

    if ( $elm->has_child('attributeList') ) {
        $source->{attributeList} = attributeListType($elm->first_child('attributeList'));
    }

    # attributes (optional)
    if ($elm->has_atts()) {
        my $release = $elm->att('release');
        my $releaseDate = $elm->att('releaseDate');
        $source->{_release} = $release;
        $source->{_releaseDate} = $releaseDate;
    }
    $this->{meta}->{source}->{"entry".entrycount()} = $source;

    $t->purge;
}

sub mif25avail {
    my ($t, $elm, $this) = @_;
    my $avail;
    #sequence : availability(availabilityType, unbounded)
    my $count = $elm->children_count('availability');
    if ( $count > 0 ) {
        for my $availtype ($elm->children('availability')) {
            push @{$avail}, availabilityType($availtype);
        }
    }

    $this->{meta}->{availability}->{"entry".entrycount()} = $avail;

    $t->purge;
}

sub mif25exp {
    my ($t, $elm, $this) = @_;
    my $exp;
    # sequence : experimentDescription(experimentType, unbounded)
    my $count = $elm->children_count('experimentDescription');

    if ( $count > 0 ) {
        for my $expdesc ($elm->children('experimentDescription')) {
            push @{$exp}, experimentType($expdesc);
        }
    }

    $this->{meta}->{experiment}->{"entry".entrycount()} = $exp;

    $t->purge;
}

{
    my $interactor_map = {};
    my $nodecount = 0;

    sub interactor_map_add {
        my ( $identifier ) = @_;
        $nodecount++;
        $interactor_map->{$identifier} = $nodecount;
        return $nodecount;
    }

    sub interactor_map_get {
        my ( $identifier ) = @_;
        carp "[interactor_map_get:error] identifier is nil" unless $identifier;
        if ( defined($interactor_map->{$identifier}) ) {
            return $interactor_map->{$identifier};
        }
        else {
            return undef;
        }
    }
}

{
    my $notation = '';
    sub notation_set {
        $notation = shift;
    }
    sub notation_get {
        return $notation;
    }
}

### for Interaction - Interactor messaging
{
    my $interactor_map = {};

    sub alternative_map_add {
        my ( $identifier, $entryid, $id ) = @_;
        $interactor_map->{$entryid}->{$id} = $identifier;
    }

    sub alternative_map_get {
        my ( $entryid, $id  ) = @_;
        if ( defined($interactor_map->{$entryid}->{$id}) ) {
            return $interactor_map->{$entryid}->{$id};
        }
        else {
            return undef;
        }
    }
}

{
    my $nodecount = 1;

    sub mif25interactor {
        my ($t, $elm, $this) = @_;
        my $entry_id = entrycount();
        my $expanda_id;
        my $interactorElement = interactorElementType($elm);
        $interactorElement->{entry} = $entry_id;

        if ( $interactorElement->{xref}->{primaryRef}->{_db} eq 'HPRD') {
            my $ident = $interactorElement->{xref}->{primaryRef}->{_id};

            # <!-- for interactionElement
            notation_set('HPRD');
            alternative_map_add($ident, $entry_id, $interactorElement->{_id});
            #    for interactionElement -->

            if ( interactor_map_get($ident) ) {
                $expanda_id = interactor_map_get($ident);
            }
            else {
                $expanda_id = interactor_map_add($ident);
            }
        }
        else {
            if ( interactor_map_get($interactorElement->{_id}) ) {
                $expanda_id = interactor_map_get($interactorElement->{_id});
            }
            else {
                $expanda_id = interactor_map_add($interactorElement->{_id});
            }
        }

        my $label = $interactorElement->{names}->{shortLabel};

        $this->{node}->{$expanda_id} = {
            'score' => {},
            'graphics' => {},
            '_internal_id' => $expanda_id,
            '_id' => $interactorElement->{_id},
            '_entry_id' => $entry_id,
            'label' => $label,
            'information' => $interactorElement,
        };
        $t->purge;
    }
    sub nodecount {
        my $retnum = $nodecount;
        $nodecount++;
        return $retnum;
    }
}

sub mif25interaction {
    my ($t, $elm, $this) = @_;
    my $entry_id = entrycount();
    my $interactionElement = interactionElementType($elm);
    my @participant_id;

    ### Insert Data to eXpanda Str

    for ( @{$interactionElement->{participantList}->{participant}} ) {
        my $orgid;

        if ( notation_get() eq 'HPRD' ) {
            $orgid = alternative_map_get($entry_id, $_->{interactorRef});
        }
        else {
            $orgid = $_->{_id};
        }
        my $expid = interactor_map_get($orgid);

        if (!$expid) {
            carp "[mif25interaction:error]$orgid id not found\n";
        }
        push @participant_id, $expid;
    }

    if ( scalar(@participant_id) == 2 ) {
        if ( !$participant_id[0] or !$participant_id[1]) {
            print Dumper $interactionElement;
        }
        $this->{edge}->{$participant_id[0]}->{$participant_id[1]} =
        {
            label => '',
            score => {},
            graphics => {},
            '_entry_id' => $entry_id,
            '_id' => $interactionElement->{_id},
            'informaion' => $interactionElement,
        };
    }
    elsif ( scalar(@participant_id) > 2 ) {
        for my $a ( @participant_id ) {
            for my $b ( @participant_id ) {
                unless ($a == $b) {
                    $this->{edge}->{$a}->{$b} =
                    {
                        label => '',
                        score => {},
                        graphics => {},
                        '_entry_id' => $entry_id,
                        '_id' => $interactionElement->{_id},
                        'informaion' => dclone($interactionElement),
                    };
                }
            }
        }
    }

    $t->purge();
}

sub mif25attlist {
    my ($t, $elm, $this) = @_;
    my $attlist = attributeListType($elm);
    $this->{meta}->{attribute}->{"entry".entrycount()} = $attlist;
    $t->purge();
}

##################  Utility  ####################

sub parse_elm_by_array {
    my ($elm) = shift;
    my @array = @_;
    # array -> { tagname => 'type' }, ...
    my $tmp;
    for ( @array )
    {
        no strict 'refs';
        my @tag_type = %{$_};
        my $count = $elm->children_count($tag_type[0]);
        if ( $count == 1 ) {
            $tmp->{$tag_type[0]} = &{$tag_type[1]}($elm->first_child($tag_type[0]));
        }
        elsif ( $count > 1 ) {
            for ( $elm->children($tag_type[0]) ) {
                push @{$tmp->{$tag_type[0]}} , &{$tag_type[1]}($_);
            }
        }
    }
    return $tmp;
}

sub extension {
    my ($elm, $base, $exts) = @_;
    my $tmp;
    my @exts_tag = %{$exts};
    no strict 'refs';

    $tmp = &{$base}($elm);

    if ( $elm->has_child($exts_tag[0]) ) {
        $tmp->{$exts_tag[0]} = parse_elm_by_array($elm, $exts);
    }
    return $tmp;
}

################## complexType Parsers ####################

sub xs_string {
    my ($elm) = @_;
    return $elm->text();
}

sub xs_boolean {
    my ($elm) = @_;
    return $elm->text();
}

sub xs_int {
    my ($elm) = @_;
    return $elm->text();
}

# List of experiments in which this interaction has been determined.
sub experientListElement {
    my ($elm) = @_;
    my $explistelt;

    #choice : experimentRef(xs_int) | experimentDescription(experimentType)

    if ( $elm->has_child('experimentRef') ) {
        $explistelt->{experimentRef} = $elm->first_child('experimentRef')->text();
    }
    elsif ( $elm->has_child('experimentDescription') ) {
        $explistelt->{experimentDescription} = experimentType($elm->first_child('experimentDescription'));
    }

    return $explistelt;
}

sub experimentalInteractor {
    my ($elm) = @_;
    my $einteractor;
    #sequence : [choice: interactorRef(xs_int) | interactor(interactorElementType)],
    #           experimentRefList(experimentRefListType)

    if ( $elm->has_child("interactorRef") ) {
        $einteractor->{interactorRef} = $elm->first_child("interactorRef")->text();
    }
    elsif ($elm->has_child("interactor")) {
        $einteractor->{interactor} = interactorElementType($elm->first_child("interactor"));
    }

    if ( $elm->has_child('experimentRefList') ) {
        $einteractor->{'experimentRefList'} = experimentRefListType($elm->first_child("experimentRefList"));
    }

    return $einteractor;
}

sub positionType {
    my ($elm) = @_;
    my $pos;
    #attribute : position(required);
    $pos->{_position} = $elm->att('position');
    return $pos;
}

sub intervalType {
    my ($elm) = @_;
    my $interval;
    #attribute : begin(required), end(required)
    $interval->{_begin} = $elm->att('begin');
    $interval->{_end} = $elm->att('end');
    return $interval;
}

sub baseLocationType {
    my ($elm) = @_;
    my $loc;
    #sequence : [sequence:  startStatus(cvType), [choice: begin(positionType) | beginInterval(intervalType)] ]
    #           [sequence: endStratus(cvType),  [choice: end(positionType) | endInterval(intervalType)] ]
    #           isLink(xs_boolean)

    $loc = parse_elm_by_array($elm,
        {startStatus => 'cvType'},
        {endStatus => 'cvType'},
        {isLink => 'xs_boolean'});

    # choice 1
    if ( $elm->has_child('begin') ) {
        $loc->{begin} = positionType($elm->first_child('begin'));
    }
    elsif ( $elm->has_child('beginInterval') ) {
        $loc->{beginInterval} = intervalType($elm->first_child('beginInterval'));
    }

    # choice 2
    if ( $elm->has_child('end') ) {
        $loc->{end} = positionType($elm->first_child('end'));
    }
    elsif ( $elm->has_child('endInterval') ) {
        $loc->{endInterval} = intervalType($elm->first_child('endInterval'));
    }

    return $loc;
}

sub featureElementType {
    my ($elm) = @_;
    my $feature;
    #sequence : names(namesType), xref(xrefType), featureType(cvType)
    #           featureDetectionMethod(cvType), experimentRefList(experimentRefListType)
    #           attributeList(attributeListType), featureRangeList[sequence: featureRange(baseLocationType)]

    $feature = parse_elm_by_array($elm,
        {names => 'namesType'},{xref => 'xrefType'},{featureType => 'cvType'},
        {featureDetectionMethod => 'cvType'}, {experimentRefList => 'experimentRefListType'},
        {attributeList => 'attributeListType'});

    #featureRangeList

    if ( $elm->has_child('featureRangeList') ) {
        my @des = $elm->descendants('featureRange');
        if (scalar(@des) > 0) {
            for my $range ( @des ) {
                push @{$feature->{featureRangeList}} , baseLocationType($range);
            }
        }
    }

    return $feature;
}

sub participantType {
    my ($elm) = @_;
    my $participant;
    #sequence : names(namesType), xref(xrefType), [choice : interactorRef | interactor | interactionRef ]
    #           biologicalRole(cvType), confidenceList(confidenceListType), attributeList(attributeListType)
    #
    #           participantIdentificationMethodList(! complex element !)->participantIdentificationMethodListElement
    #           experimentalRoleList(! complex element !)->experimentalRoleListElement
    #           experimentalPreparationList(! complex element !)->experimentalPreparationListElement
    #           experimentalRoleList(! complex element !)->experimentalRoleListElement
    #           experimentalInteractorList(! complex element !)->experimentalInteractorListElement
    #           featureList->featureListElement
    #           hostOrganismList
    #           parameterList

    $participant = parse_elm_by_array($elm,
        { names => 'namesType' },
        { xref => 'xrefType' },
        { biologicalRole => 'cvType' },
        { confidenceList => 'confidenceListType' },
        { attributeList => 'attributeListType' },
    );

    # [choice : interactorRef | interactor | interactionRef ]

    if ( $elm->has_child('interactorRef') ) {
        $participant->{'interactorRef'} = $elm->first_child('interactorRef')->text();
    }
    elsif ($elm->has_child('interactor')) {
        $participant->{'interactor'} = interactorElementType($elm->first_child('interactor'));
    }
    elsif ($elm->has_child('interactionRef')) {
        $participant->{'interactionRef'} = $elm->first_child('interactionRef')->text();
    }

    # elements in sequence

    # participantIdentificationMethodList
    if ($elm->has_child("participantIdentificationMethodList")) {
        my @des = $elm->descendants("participantIdentificationMethod");
        if (scalar(@des) > 0) {
            for my $pim (@des) {
                push @{$participant->{"participantIdentificationMethodList"}} ,
                extension($pim, "cvType", { "experimentRefList" => "experimentRefListType"} );
            }
        }
    }

    # experimentalRoleList
    if ($elm->has_child("experimentalRoleList")) {
        my @des = $elm->descendants("experimentalRole");
        if (scalar(@des) > 0) {
            for my $pim (@des) {
                push @{$participant->{"participantIdentificationMethodList"}} ,
                extension($pim, "cvType", { "experimentRefList" => "experimentRefListType"} );
            }
        }
    }

    # experimentalPreparationList
    if ($elm->has_child("experimentalPreparationList")) {
        my @des = $elm->descendants("experimentalPreparation");
        if (scalar(@des) > 0) {
            for my $pim (@des) {
                push @{$participant->{"experimentalPreparationList"}} ,
                extension($pim, "cvType", { "experimentRefList" => "experimentRefListType"} );
            }
        }
    }

    # experimentalInteractorList
    if ($elm->has_child("experimentalInteractorList")) {
        my @des = $elm->descendants("experimentalInteractor");
        for my $eil ( @des ) {
            push @{$participant->{experimentalInteractorList}}, experimentalInteractor($eil);
        }
    }

    # featureList
    if ( $elm->has_child("featureList") ) {
        my @des = $elm->descendants("feature");
        for my $feat ( @des ) {
            push @{$participant->{feature}} , featureElementType($feat);
        }
    }

    # hostOrganismList
    if ( $elm->has_child("hostOrganismList") ) {
        my @des = $elm->descendants("hostOrganism");
        for my $org (@des) {
            push @{$participant->{"hostOrganismList"}} ,
            extension($org, "bioSourceType", { "experimentRefList" => "experimentRefListType"} );
        }
    }

    # parameterList
    if ( $elm->has_child("parameterList") ) {
        my @des = $elm->descendants("parameter");
        for my $para (@des) {
            my $parastr = extension($para, "parameterType", { "experimentRef" => "xs_int"} );
            if ( $para->has_atts() ) {
                $parastr->{_uncertainty} = $para->att('uncertainty');
            }
            push @{$participant->{"hostOrganismList"}} , $parastr;
        }
    }

    # id
    $participant->{_id} = $elm->att('id');

    return $participant;
}

# A list of molecules participating in this interaction. An interaction has one (intramolecular),
# two (binary), or more (n-ary, complexes)  participants.
sub participantListElement {
    my ($elm) = @_;
    # sequence : participant(participantType)
    return parse_elm_by_array($elm, {participant => 'participantType'});
}

sub parameterType {
    my ($elm) = @_;
    my $parameter;
    my @att_names = $parameter->att_names();

    for my $att (@att_names) {
        $parameter->{"_$att"} = $elm->att($att);
    }

    return $parameter;
}

sub parameterListElement {
    my ($elm) = @_;
    my $plist;
    my $c = $elm->children_count('parameter');
    if ($c > 0) {
        for my $p ($elm->children) {
            my $para = extension($p, "parameterType", { experimentRef => "xs_int" });
            $para->{_uncertainty} = $p->att('uncertainty') if $p->has_atts();
            push @{$plist}, $para;
        }
    }
    return $plist;
}

sub inferredInteractionListElement {
    my ($elm) = @_;
    my $iint;
    # sequence : inferredInteraction(unbounded)[sequence: particiapnt([choice: participantRef| participantFeatureRef])]
    #            experimentRefList(experimentRefListType)
    if ( $elm->has_child('inferredInteraction') ) {
        for my $inferd ( $elm->children('inferredInteraction') ) {
            my $inferdinteraction;
            if ( $inferd->has_child('participant') ) {
                for my $part ($inferd->children('participant') ) {
                    my $participant;
                    if ( $part->has_child('participantRef') ) {
                        $participant->{participantRef} = $part->first_child('participantRef')->text();
                    }
                    elsif ($part->has_child('participantFeatureRef')) {
                        $participant->{participantFeatureRef} = $part->first_child('participantFeatureRef')->text();
                    }
                    push @{$inferdinteraction->{participant}} , $participant;
                }
            }
            if ($inferd->has_child('experimentRefList')) {
                $inferdinteraction->{experimentRefList} = experimentRefListType($inferd->first_child('experimentRefList'));
            }
            push @{$iint}, $inferdinteraction;
        }
    }
    return $iint;
}

sub interactionElementType {
    my ($elm) = @_;
    my $interactionelt;
    #sequence : names(namesType), xref(xrefType),
    #           interactionType(cvType, unbounded), modelled(xs_boolean), intraMolecular(xs_boolean),
    #           negative(xs_boolean), confidenceList(confidenceListType),
    #           attributeList(attributeListType)
    #           [choice: availabilityRef(xs_int) | availability(availabilityType) ]
    #           experimentList([choice: experimentRef(int)|experimentDescription(experimentType)  ](unbounded)),
    #           participantList([sequence: participant(participantType)]),
    #           parameterList([sequence: ...])
    #           inferredInteractionList([sequence: interredInteraction(unbounded, [sequnence: ...]) ])
    #attribute : id(required), imexId(optional)

    #sequence
    $interactionelt = parse_elm_by_array($elm,
        { names => 'namesType' },
        { xref => 'xrefType' },
        { interactionType => 'cvType' },
        { modelled => 'xs_boolean' },
        { intraMolecular => 'xs_boolean' },
        { negative => 'xs_boolean' },
        { confidenceList => 'confidenceListType' },
        { attributeList => 'attributeListType' },
        { experimentList => 'experientListElement' },
        { participantList => 'participantListElement' },
        { parameterList => 'parameterListElement' },
        { inferredInteractionList => 'inferredInteractionListElement' },
    );

    #choice in sequence
    if ( $elm->has_child('availabilityRef')) {
        $interactionelt->{availabilityRef} = $elm->first_child('availabilityRef')->text();
    }
    elsif ( $elm->has_child('availability') ) {
        $interactionelt->{availability} = availabilityType($elm->first_child('availability'));
    }

    #attribute
    $interactionelt->{_id} = $elm->att('id');
    $interactionelt->{_imexId} = $elm->att('imexId');

    return $interactionelt;
}

sub interactorElementType {
    my ($elm) = @_;
    my $interelt;
    #sequence : names(namesType), xref(xrefType), interactorType(cvType),
    #           organism(bioSourceType), sequence(string), attributeList(attributeListType)
    #attribute : id(required)
    #sequence
    $interelt = parse_elm_by_array($elm,
        { names => 'namesType' },
        { xref => 'xrefType' },
        { interactorType => 'cvType' },
        { organism => 'bioSourceType' },
        { attributeList => 'attributeListType' },
        { sequence => 'xs_string' },
    );

    #attribute
    $interelt->{_id} = $elm->att('id');

    return $interelt;
}

sub confidenceType {
    my ( $elm ) = @_;
    my $confidence;
    # sequence : unit(openCvType), value(xs:string)

    if ( $elm->has_child('unit') ) {
        $confidence->{unit} = openCvType($elm->first_child('unit'));
    }
    if ( $elm->has_child('value') ) {
        $confidence->{value} = $elm->first_child('value')->text();
    }

    return $confidence;
}

sub experimentRefListType {
    my ( $elm ) = @_;
    my $expreflist;
    #sequence : experimentRef(unbounded)
    my $count = $elm->children_count('experimentRef');
    if ( $count > 0 ) {
        for ( $elm->children('experimentRef') ) {
            push @{$expreflist}, $_->text();
        }
    }
    return $expreflist;
}

sub confidenceListType {
    my ( $elm ) = @_;
    my $confilist;
    #sequence : confidence( base:confidenceType,
    #                       extend:experimentRefList(experimentRefListType), unbounded)

    my $count = $elm->children_count('confidence');
    if ($count > 0) {
        for my $c ( $elm->children('confidence') ) {
            my $confidence = confidenceType($c);
            if ( $c->has_child('experimentRefList') ) {
                $confidence->{experimentRefList} = experimentRefListType($c->first_child('experimentRefList'));
            }
            push @{$confilist}, $confidence;
        }
    }

    return $confilist;
}

sub bioSourceType {
    my ( $elm ) = @_;
    my $biosource;
    #sequence : names(namesType), cellType(openCvType), compartment(openCvType),
    #           tissue(openCvType)
    #attribute : ncbiTaxId(required)

    #sequence
    $biosource = parse_elm_by_array( $elm,
        {names => 'namesType'},
        {cellType => 'openCvType'},
        {compartment => 'openCvType'},
        {tissue => 'openCvType'},
    );
    #attribute
    $biosource->{_ncbiTaxId} = $elm->att('ncbiTaxId');

    return $biosource;
}

sub openCvType {
    my ( $elm ) = @_;
    my $opencv;
    #sequence : names(namesType), xref(xrefType), attributeList(attributeListType)
    $opencv = parse_elm_by_array($elm,
        {names => 'namesType'},
        {xref => 'xrefType'},
        {attributeList => 'attributeListType'},
    );
    return $opencv;
}

sub cvType {
    my ( $elm ) = @_;
    my $cv;
    #sequence : names(namesType), xref(xrefType)
    if ( $elm->has_child('names') ) {
        $cv->{names} = namesType($elm->first_child('names'));
    }
    if ( $elm->has_child('xref') ) {
        $cv->{xref} = xrefType($elm->first_child('xref'));
    }
    return $cv;
}

sub experimentType {
    my ($elm) = @_;
    my $exptype;
    #sequence : names(namesType), bibref(bibrefType), xref(xrefType), hostOrganismList,
    #           interactionDetectionMethod(cvType), participantIdentificationMethod(cvType)
    #           featureDetectionMethod(cvType), confidenceList(confidenceListType)
    #           attributeList(attributeListType)
    #
    #attribute : id(required)

    for ( { names => 'namesType' },
        { bibref => 'bibrefType' },
        { xref => 'xrefType' },
        { interactionDetectionMethod => 'cvType'},
        { participantIdentificationMethod => 'cvType' },
        { featureDetectionMethod => 'cvType' },
        { confidenceList => 'confidenceListType' },
        { attributeList => 'attributeListType' },
    )
    {
        no strict 'refs';
        my @tag_type = %{$_};
        my $count = $elm->children_count($tag_type[0]);
        if ( $count == 1 ) {
            $exptype->{$tag_type[0]} = &{$tag_type[1]}($elm->first_child($tag_type[0]));
        }
        elsif ( $count > 1 ) {
            for ( $elm->children($tag_type[0]) ) {
                push @{$exptype->{$tag_type[0]}} , &{$tag_type[1]}($_);
            }
        }
    }

    # hostOrganismList

    if ( $elm->has_child('hostOrganismList') ) {
        # sequence : hostOrganism(unbounded)
        my $list = $elm->first_child('hostOrganismList');
        my $count_org = $list->children_count('hostOrganism');

        print "[expanda] hostOrganism count $count_org\n";
        if ( $count_org == 1 ) {
            $exptype->{hostOrganism} = bioSourceType($list->first_child('hostOrganism'));
        }
        elsif ( $count_org > 1 ) {
            for ( $list->children('hostOrganism') ) {
                push @{$exptype->{hostOrganismList}} ,bioSourceType($_);
            }
        }
    }
    else {
        print "[expanda] missing hostOrganismList \n";
    }

    #attribute
    $exptype->{_id} = $elm->att('id');

    return $exptype;
}

sub availabilityType {
    my ($elm) = @_;
    my $atype;
    #simpleContent
    #attribute : id(required)

    #attribute
    $atype->{_id} = $elm->att('id');
    #text
    $atype->{text} = $elm->text();

    return $atype;
}

sub attributeListType {
    my ($elm) = @_;
    my $attlisttype;
    #sequence : attribute(complexType:simpleContent)
    my $count = $elm->children_count('attribute');
    if ( $count > 0 ) {
        for my $attribute ( $elm->children('attribute') ) {
            #required att
            my $name = $attribute->att('name');
            #optional att
            my $nameAc = $attribute->att('nameAc');
            #text
            my $text = $attribute->text();
            push @{$attlisttype}, {'_name' => $name, '_nameAc' => $nameAc||'', text => $text};
        }
    }

    return $attlisttype;
}

sub dbReferenceType {
    my ($elm) = @_;
    my $dbreftype;
    #sequence : attributeList(attributeListType)
    #attribute : db(required), dbAc(optonal), id(required) , secondary(optional), version(optional)
    #            refType(optional), refTypeAc(optional)

    #required attributes.
    $dbreftype->{_db} = $elm->att('db');
    $dbreftype->{_id} = $elm->att('id');
    # optional attributes.
    for my $attname ( 'dbAc', 'secondary', 'version', 'refType', 'refTypeAc' ) {
        my $attval = $elm->att($attname);
        if ($attval) {
            $dbreftype->{"_$attname"} = $attval;
        }
        else {
            $dbreftype->{"_$attname"} = '';
        }
    }
    #sequence
    if ( $elm->has_child('attributeList') ) {
        my $attlist = $elm->first_child('attributeList');
        $dbreftype->{attributeList} = attributeListType($attlist);
    }

    return $dbreftype;
}

sub xrefType {
    my ( $elm ) = @_;
    my $xreftype;
    #sequence : primaryRef(1) secondaryRef(unbounded)

    if ( $elm->has_child('primaryRef') ) {
        $xreftype->{primaryRef} = dbReferenceType($elm->first_child('primaryRef'));
    }

    if ( $elm->children_count('secondaryRef') == 1 ) {
        $xreftype->{secondaryRef} = dbReferenceType($elm->first_child('secondaryRef'));
    }
    elsif ( $elm->children_count('secondaryRef') > 1 ) {
        for my $sref ( $elm->children('secondaryRef') ) {
            push @{$xreftype->{secondaryRef}}, dbReferenceType($sref);
        }
    }

    return $xreftype;
}

sub bibrefType {
    my ( $elm ) = @_;
    my $bibref = {};
    if ( $elm->has_child('xref') ) {
        $bibref->{xref} = xrefType($elm->first_child('xref'));
    }
    elsif ( $elm->has_child('attributeList') ) {
        $bibref->{attributeList} = attributeListType($elm->first_child('attributeList'));
    }
    return $bibref;
}

sub namesType {
    my ( $elm ) = @_;
    my $namestype = {shortLabel => '', fullName => '', alias => []};
    # sequence: shortLabel, fullName, alias(cT)
    my $sl = $elm->first_child('shortLabel');
    my $fn = $elm->first_child('fullName');
    $namestype->{shortLabel} = $sl->text() if $sl;
    $namestype->{fullName} = $fn->text() if $fn;
    my @aliases = $elm->children('alias');
    for my $alias ( @aliases ) {
        my $typeAc = $alias->att('typeAc');
        my $type = $alias->att('type');
        my $text = $alias->text();
        push @{$namestype->{alias}}, {
            typeAc => $typeAc || '',
            type => $type || '',
            text => $text,
        };
    }
    return $namestype;
}

1;
