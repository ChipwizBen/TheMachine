package HTML::Table;
use strict;
use warnings;

use vars qw($VERSION $AUTOLOAD);
$VERSION = '2.08a';

use overload	'""'	=>	\&getTable,
				fallback => undef;

=head1 NAME

HTML::Table - produces HTML tables

=head1 SYNOPSIS

  use HTML::Table;

  $table1 = new HTML::Table($rows, $cols);
    or
  $table1 = new HTML::Table(-rows=>26,
                            -cols=>2,
                            -align=>'center',
                            -rules=>'rows',
                            -border=>0,
                            -bgcolor=>'blue',
                            -width=>'50%',
                            -spacing=>0,
                            -padding=>0,
                            -style=>'color: blue',
                            -class=>'myclass',
                            -evenrowclass=>'even',
                            -oddrowclass=>'odd',
                            -head=> ['head1', 'head2'],
                            -data=> [ ['1:1', '1:2'], ['2:1', '2:2'] ] );
   or
  $table1 = new HTML::Table( [ ['1:1', '1:2'], ['2:1', '2:2'] ] );

  $table1->setCell($cellrow, $cellcol, 'This is Cell 1');
  $table1->setCellBGColor('blue');
  $table1->setCellColSpan(1, 1, 2);
  $table1->setRowHead(1);
  $table1->setColHead(1);

  $table1->print;

  $table2 = new HTML::Table;
  $table2->addRow(@cell_values);
  $table2->addCol(@cell_values2);

  $table1->setCell(1,1, "$table2->getTable");
  $table1->print;

=head1 REQUIRES

Perl5.002

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

HTML::Table is used to generate HTML tables for
CGI scripts.  By using the methods provided fairly
complex tables can be created, manipulated, then printed
from Perl scripts.  The module also greatly simplifies
creating tables within tables from Perl.  It is possible
to create an entire table using the methods provided and
never use an HTML tag.

HTML::Table also allows for creating dynamically sized
tables via its addRow and addCol methods.  These methods
automatically resize the table if passed more cell values
than will fit in the current table grid.

Methods are provided for nearly all valid table, row, and
cell tags specified for HTML 3.0.

A Japanese translation of the documentation is available at:

	http://member.nifty.ne.jp/hippo2000/perltips/html/table.htm


=head1 METHODS

  [] indicate optional parameters. default value will
     be used if no value is specified
     
  row_num indicates that a row number is required.  
  	Rows are numbered from 1.  To refer to the last row use the value -1.

  col_num indicates that a col number is required.  
  	Cols are numbered from 1.  To refer to the last col use the value -1.

  	
=head2 Sections

=over 4

From version 2.07 onwards HTML::Table supports table sections (THEAD, TFOOT & TBODY).

Each section can have its own attributes (id, class, etc) set, and will contain 1 or more 
rows.  Section numbering starts at 0, only tbody is allowed to have more than one section.

Methods for manipultaing sections and their data are available and have the general form:

  setSectionCell ( section, section_num, row_num, col_num, data );
  
  For example, the following adds a row to the first body section:
  
  addSectionRow ( 'tbody', 0, "Cell 1", "Cell 2", "Cell 3" );
  
For backwards compatibility, methods with Section in their name will default to manipulating 
the first body section.  

  For example, the following sets the class for the first row in the 
  first body section:
  
  setRowClass ( 1, 'row_class' );
  
  Which is semantically equivalent to:
  
  setSectionRowClass ( 'tbody', 0, 1, 'row_class' );

=back

=head2 Creation

=over 4

=item new HTML::Table([num_rows, num_cols])

Creates a new HTML table object.  If rows and columns
are specified, the table will be initialized to that
size.  Row and Column numbers start at 1,1.  0,0 is
considered an empty table.

=item new HTML::Table([-rows=>num_rows, 
		 -cols=>num_cols, 
		 -border=>border_width,
		 -align=>table_alignment,
		 -style=>table_style,
 		 -class=>table_class,
 		 -evenrowclass=>'even',
         -oddrowclass=>'odd',
		 -bgcolor=>back_colour, 
		 -width=>table_width, 
		 -spacing=>cell_spacing, 
		 -padding=>cell_padding])

Creates a new HTML table object.  If rows and columns
are specified, the table will be initialized to that
size.  Row and Column numbers start at 1,1.  0,0 is
considered an empty table.

If evenrowclass or oddrowclass is specified, these 
classes will be applied to even and odd rows,
respectively, unless those rows have a specific class 
applied to it.

=back

=head2 Table Level Methods

=over 4

=item setBorder([pixels])

Sets the table Border Width

=item setWidth([pixels|percentofscreen])

Sets the table width

 	$table->setWidth(500);
  or
 	$table->setWidth('100%');

=item setCellSpacing([pixels])

=item setCellPadding([pixels])

=item setCaption("CaptionText" [, top|bottom])

=item setBGColor([colorname|colortriplet])

=item autoGrow([1|true|on|anything|0|false|off|no|disable])

Switches on (default) or off automatic growing of the table
if row or column values passed to setCell exceed current
table size.

=item setAlign ( [ left , center , right ] ) 

=item setRules ( [ rows , cols , all, both , groups  ] ) 

=item setStyle ( 'css style' ) 

Sets the table style attribute.

=item setClass ( 'css class' ) 

Sets the table class attribute.

=item setEvenRowClass ( 'css class' )

Sets the class attribute of even rows in the table.

=item setOddRowClass ( 'css class' )

Sets the class attribute of odd rows in the table.

=item setAttr ( 'user attribute' ) 

Sets a user defined attribute for the table.  Useful for when
HTML::Table hasn't implemented a particular attribute yet

=item sort ( [sort_col_num, sort_type, sort_order, num_rows_to_skip] )

        or 
  sort( -sort_col => sort_col_num, 
        -sort_type => sort_type,
        -sort_order => sort_order,
        -skip_rows => num_rows_to_skip,
        -strip_html => strip_html,
        -strip_non_numeric => strip_non_numeric,
        -presort_func => \&filter_func )

    sort_type in { ALPHA | NUMERIC }, 
    sort_order in { ASC | DESC },
    strip_html in { 0 | 1 }, defaults to 1,
    strip_non_numeric in { 0 | 1 }, defaults to 1

  Sort all rows on a given column (optionally skipping table header rows
  by specifiying num_rows_to_skip).

  By default sorting ignores HTML Tags and &nbsp, setting the strip_html parameter to 0 
  disables this behaviour.

  By default numeric Sorting ignores non numeric chararacters, setting the strip_non_numeric
  parameter to 0 disables this behaviour.

  You can provide your own pre-sort function, useful for pre-processing the cell contents 
  before sorting for example dates.


=item getTableRows

Returns the number of rows in the table.

=item getTableCols

Returns the number of columns in the table.

=item getStyle

Returns the table's style attribute.

=back

=head2 Section Level Methods

=over 4

=item setSectionId ( [tbody|thead|tfoot], section_num, 'id' )

Sets the id attribute for the section.

=item setSectionClass ( [tbody|thead|tfoot], section_num, 'class' )

Sets the class attribute for the section.

=item setSectionStyle ( [tbody|thead|tfoot], section_num, 'style' )

Sets the style attribute for the section.

=item setSectionAlign ( [tbody|thead|tfoot], section_num, [center|right|left] )

Sets the horizontal alignment for the section.

=item setSectionValign ( [tbody|thead|tfoot], section_num, [center|top|bottom|middle|baseline] )

Sets the vertical alignment for the section.

=item setSectionAttr ( [tbody|thead|tfoot], section_num, 'user attribute' )

Sets a user defined attribute for the cell.  Useful for when
HTML::Table hasn't implemented a particular attribute yet

=back

=head2 Cell Level Methods

=over 4

=item setCell(row_num, col_num, "content")

Sets the content of a table cell.  This could be any
string, even another table object via the getTable method.
If the row and/or column numbers are outside the existing table
boundaries extra rows and/or columns are created automatically.

=item setSectionCell([tbody|thead|tfoot], section_num, row_num, col_num, "content")

Same as setCell, but able to specify which section to act on.

=item setCellAlign(row_num, col_num, [center|right|left])

Sets the horizontal alignment for the cell.

=item setSectionCellAlign([tbody|thead|tfoot], section_num, row_num, col_num, [center|right|left])

Same as setCellAlign, but able to specify which section to act on.

=item setCellVAlign(row_num, col_num, [center|top|bottom|middle|baseline])

Sets the vertical alignment for the cell.

=item setSectionCellVAlign([tbody|thead|tfoot], section_num, row_num, col_num, [center|top|bottom|middle|baseline])

Same as setCellVAlign, but able to specify which section to act on.

=item setCellWidth(row_num, col_num, [pixels|percentoftable])

Sets the width of the cell.

=item setSectionCellWidth([tbody|thead|tfoot], section_num, row_num, col_num, [pixels|percentoftable])

Same as setCellWidth, but able to specify which section to act on.

=item setCellHeight(row_num, col_num, [pixels])

Sets the height of the cell.

=item setSectionCellHeight([tbody|thead|tfoot], section_num, row_num, col_num, [pixels])

Same as setCellHeight, but able to specify which section to act on.

=item setCellHead(row_num, col_num, [0|1])

Sets cell to be of type head (Ie <th></th>)

=item setSectionCellHead([tbody|thead|tfoot], section_num, row_num, col_num, [0|1])

Same as setCellHead, but able to specify which section to act on.

=item setCellNoWrap(row_num, col_num, [0|1])

Sets the NoWrap attribute of the cell.

=item setSectionCellNoWrap([tbody|thead|tfoot], section_num, row_num, col_num, [0|1])

Same as setCellNoWrap, but able to specify which section to act on.

=item setCellBGColor(row_num, col_num, [colorname|colortriplet])

Sets the background colour for the cell.

=item setSectionCellBGColor([tbody|thead|tfoot], section_num, row_num, col_num, [colorname|colortriplet])

Same as setCellBGColor, but able to specify which section to act on.

=item setCellRowSpan(row_num, col_num, num_cells)

Causes the cell to overlap a number of cells below it.
If the overlap number is greater than number of cells 
below the cell, a false value will be returned.

=item setSectionCellRowSpan([tbody|thead|tfoot], section_num, row_num, col_num, num_cells)

Same as setCellRowSpan, but able to specify which section to act on.

=item setCellColSpan(row_num, col_num, num_cells)

Causes the cell to overlap a number of cells to the right.
If the overlap number is greater than number of cells to
the right of the cell, a false value will be returned.

=item setSectionCellColSpan([tbody|thead|tfoot], section_num, row_num, col_num, num_cells)

Same as setCellColSpan, but able to specify which section to act on.

=item setCellSpan(row_num, col_num, num_rows, num_cols)

Joins the block of cells with the starting cell specified.
The joined area will be num_cols wide and num_rows deep.

=item setSectionCellSpan([tbody|thead|tfoot], section_num, row_num, col_num, num_rows, num_cols)

Same as setCellSpan, but able to specify which section to act on.

=item setCellFormat(row_num, col_num, start_string, end_string)

Start_string should be a string of valid HTML, which is output before
the cell contents, end_string is valid HTML that is output after the cell contents.
This enables formatting to be applied to the cell contents.

	$table->setCellFormat(1, 2, '<b>', '</b>');
	
=item setSectionCellFormat([tbody|thead|tfoot], section_num, row_num, col_num, start_string, end_string)

Same as setCellFormat, but able to specify which section to act on.

=item setCellStyle (row_num, col_num, 'css style') 

Sets the cell style attribute.

=item setSectionCellStyle([tbody|thead|tfoot], section_num, row_num, col_num, 'css style')

Same as setCellStyle, but able to specify which section to act on.

=item setCellClass (row_num, col_num, 'css class') 

Sets the cell class attribute.

=item setSectionCellClass([tbody|thead|tfoot], section_num, row_num, col_num, 'css class')

Same as setCellClass, but able to specify which section to act on.

=item setCellAttr (row_num, col_num, 'user attribute') 

Sets a user defined attribute for the cell.  Useful for when
HTML::Table hasn't implemented a particular attribute yet

=item setSectionCellAttr([tbody|thead|tfoot], section_num, row_num, col_num, 'css class')

Same as setCellAttr, but able to specify which section to act on.

=item setLastCell*

All of the setCell methods have a corresponding setLastCell method which 
does not accept the row_num and col_num parameters, but automatically applies
to the last row and last col of the table.

NB.  Only works on the setCell* methods, not on the setSectionCell* methods.

=item getCell(row_num, col_num)

Returns the contents of the specified cell as a string.

=item getSectionCell([tbody|thead|tfoot], section_num, row_num, col_num)

Same as getCell, but able to specify which section to act on.

=item getCellStyle(row_num, col_num)

Returns cell's style attribute.

=item getSectionCellStyle([tbody|thead|tfoot], section_num, row_num, col_num)

Same as getCellStyle, but able to specify which section to act on.

=back

=head2 Column Level Methods

=over 4

=item addCol("cell 1 content" [, "cell 2 content",  ...])

Adds a column to the right end of the table.  Assumes if
you pass more values than there are rows that you want
to increase the number of rows.

=item addSectionCol([tbody|thead|tfoot], section_num, "cell 1 content" [, "cell 2 content",  ...])

Same as addCol, but able to specify which section to act on.

=item setColAlign(col_num, [center|right|left])

Applies setCellAlign over the entire column.

=item setSectionColAlign([tbody|thead|tfoot], section_num, col_num, [center|right|left])

Same as setColAlign, but able to specify which section to act on.

=item setColVAlign(col_num, [center|top|bottom|middle|baseline])

Applies setCellVAlign over the entire column.

=item setSectionColVAlign([tbody|thead|tfoot], section_num, col_num, [center|top|bottom|middle|baseline])

Same as setColVAlign, but able to specify which section to act on.

=item setColWidth(col_num, [pixels|percentoftable])

Applies setCellWidth over the entire column.

=item setSectionColWidth([tbody|thead|tfoot], section_num, col_num, [pixels|percentoftable])

Same as setColWidth, but able to specify which section to act on.

=item setColHeight(col_num, [pixels])

Applies setCellHeight over the entire column.

=item setSectionColHeight([tbody|thead|tfoot], section_num, col_num, [pixels])

Same as setColHeight, but able to specify which section to act on.

=item setColHead(col_num, [0|1])

Applies setCellHead over the entire column.

=item setSectionColHead([tbody|thead|tfoot], section_num, col_num, [0|1])

Same as setColHead, but able to specify which section to act on.

=item setColNoWrap(col_num, [0|1])

Applies setCellNoWrap over the entire column.

=item setSectionColNoWrap([tbody|thead|tfoot], section_num, col_num, [0|1])

Same as setColNoWrap, but able to specify which section to act on.

=item setColBGColor(row_num, [colorname|colortriplet])

Applies setCellBGColor over the entire column.

=item setSectionColBGColor([tbody|thead|tfoot], section_num, col_num, [colorname|colortriplet])

Same as setColBGColor, but able to specify which section to act on.

=item setColFormat(col_num, start_string, end_sting)

Applies setCellFormat over the entire column.

=item setSectionColFormat([tbody|thead|tfoot], section_num, col_num, start_string, end_sting)

Same as setColFormat, but able to specify which section to act on.

=item setColStyle (col_num, 'css style') 

Applies setCellStyle over the entire column.

=item setSectionColStyle([tbody|thead|tfoot], section_num, col_num, 'css style')

Same as setColStyle, but able to specify which section to act on.

=item setColClass (col_num, 'css class') 

Applies setCellClass over the entire column.

=item setSectionColClass([tbody|thead|tfoot], section_num, col_num, 'css class')

Same as setColClass, but able to specify which section to act on.

=item setColAttr (col_num, 'user attribute') 

Applies setCellAttr over the entire column.

=item setSectionColAttr([tbody|thead|tfoot], section_num, col_num, 'user attribute')

Same as setColAttr, but able to specify which section to act on.

=item setLastCol*

All of the setCol methods have a corresponding setLastCol method which 
does not accept the col_num parameter, but automatically applies
to the last col of the table.

NB.  Only works on the setCol* methods, not on the setSectionCol* methods.

=item getColStyle(col_num)

Returns column's style attribute.  Only really useful after setting a column's style via setColStyle().

=item getSectionColStyle([tbody|thead|tfoot], section_num, col_num)

Same as getColStyle, but able to specify which section to act on.

=back

=head2 Row Level Methods

=over 4

=item addRow("cell 1 content" [, "cell 2 content",  ...])

Adds a row to the bottom of the first body section of the table.  

Adds a row to the bottom of the table.  Assumes if you
pass more values than there are columns that you want
to increase the number of columns.

=item addSectionRow([tbody|thead|tfoot], section_num, "cell 1 content" [, "cell 2 content",  ...])

Same as addRow, but able to specify which section to act on.

=item delRow(row_num)

Deletes a row from the first body section of the table.  If -1 is passed as row_num, the 
last row in the section will be deleted.

=item delSectionRow([tbody|thead|tfoot], section_num, row_num)

Same as delRow, but able to specify which section to act on.

=item setRowAlign(row_num, [center|right|left])

Sets the Align attribute of the row.

=item setSectionRowAlign([tbody|thead|tfoot], section_num, row_num, [center|right|left])

Same as setRowAlign, but able to specify which section to act on.

=item setRowVAlign(row_num, [center|top|bottom|middle|baseline])

Sets the VAlign attribute of the row.

=item setSectionRowVAlign([tbody|thead|tfoot], section_num, row_num, [center|top|bottom|middle|baseline])

Same as setRowVAlign, but able to specify which section to act on.

=item setRowNoWrap(col_num, [0|1])

Sets the NoWrap attribute of the row.

=item setSectionRowNoWrap([tbody|thead|tfoot], section_num, row_num, [0|1])

Same as setRowNoWrap, but able to specify which section to act on.

=item setRowBGColor(row_num, [colorname|colortriplet])

Sets the BGColor attribute of the row.

=item setSectionRowBGColor([tbody|thead|tfoot], section_num, row_num, [colorname|colortriplet])

Same as setRowBGColor, but able to specify which section to act on.

=item setRowStyle (row_num, 'css style') 

Sets the Style attribute of the row.

=item setSectionRowStyle([tbody|thead|tfoot], section_num, row_num, 'css style')

Same as setRowStyle, but able to specify which section to act on.

=item setRowClass (row_num, 'css class') 

Sets the Class attribute of the row.

=item setSectionRowClass([tbody|thead|tfoot], section_num, row_num, 'css class')

Same as setRowClass, but able to specify which section to act on.

=item setRowAttr (row_num, 'user attribute') 

Sets the Attr attribute of the row.

=item setSectionRowAttr([tbody|thead|tfoot], section_num, row_num, 'user attribute')

Same as setRowAttr, but able to specify which section to act on.



=item setRCellsWidth(row_num, [pixels|percentoftable])

=item setRowWidth(row_num, [pixels|percentoftable])  ** Deprecated **

Applies setCellWidth over the entire row.

=item setSectionRCellsWidth([tbody|thead|tfoot], section_num, row_num, [pixels|percentoftable])

=item setSectionRowWidth([tbody|thead|tfoot], section_num, row_num, [pixels|percentoftable])   ** Deprecated **

Same as setRowWidth, but able to specify which section to act on.

=item setRCellsHeight(row_num, [pixels])

=item setRowHeight(row_num, [pixels])   ** Deprecated **

Applies setCellHeight over the entire row.

=item setSectionRCellsHeight([tbody|thead|tfoot], section_num, row_num, [pixels])

=item setSectionRowHeight([tbody|thead|tfoot], section_num, row_num, [pixels])  ** Deprecated **

Same as setRowHeight, but able to specify which section to act on.

=item setRCellsHead(row_num, [0|1])

=item setRowHead(row_num, [0|1])  ** Deprecated **

Applies setCellHead over the entire row.

=item setSectionRCellsHead([tbody|thead|tfoot], section_num, row_num, [0|1])

=item setSectionRowHead([tbody|thead|tfoot], section_num, row_num, [0|1])  ** Deprecated **

Same as setRowHead, but able to specify which section to act on.

=item setRCellsFormat(row_num, start_string, end_string)

=item setRowFormat(row_num, start_string, end_string)  ** Deprecated **

Applies setCellFormat over the entire row.

=item setSectionRCellsFormat([tbody|thead|tfoot], section_num, row_num, start_string, end_string)

=item setSectionRowFormat([tbody|thead|tfoot], section_num, row_num, start_string, end_string)  ** Deprecated **

Same as setRowFormat, but able to specify which section to act on.


=item setLastRow*

All of the setRow methods have a corresponding setLastRow method which 
does not accept the row_num parameter, but automatically applies
to the last row of the table.

NB.  Only works on the setRow* methods, not on the setSectionRow* methods.

=item getRowStyle(row_num)

Returns row's style attribute.

=item getSectionRowStyle([tbody|thead|tfoot], section_num, row_num)

Same as getRowStyle, but able to specify which section to act on.

=back

=head2 Output Methods

=over 4

=item getTable

Returns a string containing the HTML representation
of the table.

The same effect can also be achieved by using the object reference 
in a string scalar context.

For example...

	This code snippet:

		$table = new HTML::Table(2, 2);
		print '<p>Start</p>';
		print $table->getTable;
		print '<p>End</p>';

	would produce the same output as:

		$table = new HTML::Table(2, 2);
		print "<p>Start</p>$table<p>End</p>";

=item print

Prints HTML representation of the table to STDOUT

=back

=head1 CLASS VARIABLES

=head1 HISTORY

This module was originally created in 1997 by Stacy Lacy and whose last 
version was uploaded to CPAN in 1998.  The module was adopted in July 2000 
by Anthony Peacock in order to distribute a revised version.  This adoption 
took place without the explicit consent of Stacy Lacy as it proved impossible 
to contact them at the time.  Explicit consent for the adoption has since been 
received.

=head1 AUTHOR

Anthony Peacock, a.peacock@chime.ucl.ac.uk
Stacy Lacy (Original author)

=head1 CONTRIBUTIONS

Douglas Riordan <doug.riordan@gmail.com>
For get methods for Style attributes.

Jay Flaherty, fty@mediapulse.com
For ROW, COL & CELL HEAD methods. Modified the new method to allow hash of values.

John Stumbles, john@uk.stumbles.org
For autogrow behaviour of setCell, and allowing alignment specifications to be case insensitive

Arno Teunisse, Arno.Teunisse@Simac.nl
For the methods adding rules, styles and table alignment attributes.

Ville Skyttä, ville.skytta@iki.fi
For general fixes

Paul Vernaza, vernaza@stwing.upenn.edu
For the setLast... methods

David Link, dvlink@yahoo.com
For the sort method

Tommi Maekitalo, t.maekitalo@epgmbh.de
For adding the 'head' parameter to the new method and for adding the initialisation from an array ref 
to the new method.

Chris Weyl, cweyl@alumni.drew.edu
For adding the even/odd row class support.

=head1 COPYRIGHT

Copyright (c) 2000-2007 Anthony Peacock, CHIME.
Copyright (c) 1997 Stacy Lacy

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), CGI(3)

=cut

#-------------------------------------------------------
# Subroutine:  	new([num_rows, num_cols])
#            or new([-rows=>num_rows,
#                   -cols=>num_cols,
#                   -border=>border_width,
#                   -bgcolor=>back_colour,
#                   -width=>table_width,
#                   -spacing=>cell_spacing,
#                   -padding=>cell_padding]); 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     30 Mar 1998 - Jay Flaherty
# Modified:     13 Feb 2001 - Anthony Peacock
# Modified:     30 Aug 2002 - Tommi Maekitalo
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:     25 May 2007 - Chris Weyl (even/odd row class support) 
#-------------------------------------------------------
sub new {

# Creates new table instance
my $type = shift;
my $class = ref($type) || $type;
my $self = {};
bless( $self, $class); 

# If paramter list is a hash (of the form -param=>value, ...)
if (defined $_[0] && $_[0] =~ /^-/) {
    my %flags = @_;
    $self->{border} = defined $flags{-border} && _is_validnum($flags{-border}) ? $flags{-border} : undef;
    $self->{align} = $flags{-align} || undef;
    $self->{rules} = $flags{-rules} || undef;
    $self->{style} = $flags{-style} || undef;
    $self->{class} = $flags{-class} || undef;
    $self->{bgcolor} = $flags{-bgcolor} || undef;
    $self->{background} = $flags{-background} || undef;
    $self->{width} = $flags{-width} || undef;
    $self->{cellspacing} = defined $flags{-spacing} && _is_validnum($flags{-spacing}) ? $flags{-spacing} : undef;
    $self->{cellpadding} = defined $flags{-padding} && _is_validnum($flags{-padding}) ? $flags{-padding} : undef;
    $self->{last_col} = $flags{-cols} || 0;
    $self->{evenrowclass} = $flags{-evenrowclass} || undef;
    $self->{oddrowclass} = $flags{-oddrowclass} || undef;

    if ($flags{-head})
    {
      $self->addRow(@{$flags{-head}});
      $self->setRowHead(1);
    }

    if ($flags{-data})
    {
      foreach (@{$flags{-data}})
      {
        $self->addRow(@$_);
      }
    }

	if ($self->{tbody}[0]->{last_row}) {
		$self->{tbody}[0]->{last_row} = $flags{-rows} if (defined $flags{-rows} && $self->{tbody}[0]->{last_row} < $flags{-rows});
	} else {
	    $self->{tbody}[0]->{last_row} = $flags{-rows} || 0;
	}

}
elsif (ref $_[0])
{
    # Array-reference [ ['row0col0', 'row0col1'], ['row1col0', 'row1col1'] ]
    $self->{tbody}[0]->{last_row} = 0;
    $self->{last_col} = 0;
    foreach (@{$_[0]})
    {
      $self->addRow(@$_);
    }

}
else # user supplied row and col (or default to 0,0)
{
    $self->{tbody}[0]->{last_row} = shift || 0;
    $self->{last_col} = shift || 0;
}

# Table Auto-Grow mode (default on)
$self->{autogrow} = 1;

return $self;
}	

#-------------------------------------------------------
# Subroutine:  	getTable
# Author:       Stacy Lacy
# Date:			30 July 1997
# Modified:     19 Mar 1998 - Jay Flaherty
# Modified:     13 Feb 2001 - Anthony Peacock
# Modified:		23 Oct 2001 - Terence Brown
# Modified:		05 Jan 2002 - Arno Teunisse
# Modified:		10 Jan 2002 - Anthony Peacock
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:     25 May 2007 - Chris Weyl (add even/odd row class support)
# Modified:		10 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub getTable {
	my $self = shift;
	my $html="";

	# this sub returns HTML version of the table object
	if ((! $self->{tbody}[0]{last_row}) || (! $self->{last_col})) {
		return ;  # no rows or no cols
	}

	# Table tag
	$html .="\n<table";
	$html .=" border=\"$self->{border}\"" if defined $self->{border};
	$html .=" cellspacing=\"$self->{cellspacing}\"" if defined $self->{cellspacing};
	$html .=" cellpadding=\"$self->{cellpadding}\"" if defined $self->{cellpadding};
	$html .=" width=\"$self->{width}\"" if defined $self->{width};
	$html .=" bgcolor=\"$self->{bgcolor}\"" if defined $self->{bgcolor};
	$html .=" background=\"$self->{background}\"" if defined $self->{background};
	$html .=" rules=\"$self->{rules}\"" if defined $self->{rules} ;		# add rules for table
	$html .=" align=\"$self->{align}\"" if defined $self->{align} ; 		# alignment of the table
	$html .=" style=\"$self->{style}\"" if defined $self->{style} ; 		# style for the table
	$html .=" class=\"$self->{class}\"" if defined $self->{class} ; 		# class for the table
	$html .=" $self->{attr}" if defined $self->{attr} ;		 		# user defined attribute string
	$html .=">\n";
	if (defined $self->{caption}) {
		$html .="<caption";
		$html .=" align=\"$self->{caption_align}\"" if (defined $self->{caption_align});
		$html .=">$self->{caption}</caption>\n";
	}

	# thead tag (if defined)
	if (defined $self->{thead}) {
		$html .= $self->getSection ( 'thead', 0 );
	}
	
	# TFOOT tag (if defined)
	if (defined $self->{tfoot}) {
		$html .= $self->getSection ( 'tfoot', 0 );
	}
      
	# Body sections
	my $num_sections = @{$self->{tbody}} - 1;
	for my $j ( 0..$num_sections ) {
		$html .= $self->getSection ( 'tbody', $j );
	}
   
   	# Close TABLE tag
   	$html .="</table>\n";

   	return ($html);
}

#-------------------------------------------------------
# Subroutine:  	getRow
# Author:       Anthony Peacock
# Date:			10 September 2007
# Description:  Gets the HTML to form a row, based on code taken from getTable
#-------------------------------------------------------
sub getRow {
	my $self = shift;
	my $section = lc(shift);
	my $sect_num = shift;
	my $row_num = shift;
	my $html="";

	# Print each row of the table   
	$html .="<tr" ;		

	# Set the row attributes (if any)
	$html .= ' bgcolor="' . $self->{$section}[$sect_num]->{rows}[$row_num]->{bgcolor} . '"' if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{bgcolor};
	$html .= ' align="' . $self->{$section}[$sect_num]->{rows}[$row_num]->{align} . '"'  if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{align};	
	$html .= ' valign="' . $self->{$section}[$sect_num]->{rows}[$row_num]->{valign} . '"'  if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{valign} ;
	$html .= ' style="' . $self->{$section}[$sect_num]->{rows}[$row_num]->{style} . '"'  if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{style} ;
	$html .= defined $self->{$section}[$sect_num]->{rows}[$row_num]->{class}             ? ' class="' . $self->{$section}[$sect_num]->{rows}[$row_num]->{class} . '"'  
              : defined $self->{evenrowclass} && ($row_num % 2 == 0) ? ' class="' .  $self->{evenrowclass} . '"'
              : defined $self->{oddrowclass}  && ($row_num % 2 == 1) ? ' class="' .  $self->{oddrowclass} . '"'
              :                                                  q{};
	$html .= ' nowrap="' . $self->{$section}[$sect_num]->{rows}[$row_num]->{nowrap} . '"'  if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{nowrap} ;
	$html .= " $self->{$section}[$sect_num]->{rows}[$row_num]->{attr}" if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{attr} ;
	$html .= ">" ; 	# Closing tr tag
		
	my $j;
	for ($j=1; $j <= ($self->{last_col}); $j++) {
          
		if (defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{colspan} && $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{colspan} eq "SPANNED"){
			$html.="<!-- spanned cell -->";
			next
		}
          
		# print cell
		# if head flag is set print <th> tag else <td>
		if (defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{head}) {
			$html .="<th";
		} else { 
			$html .="<td";
		}

		# if alignment options are set, add them in the cell tag
		$html .=' align="' . $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{align} . '"'
			if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{align};
          
		$html .=" valign=\"" . $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{valign} . "\""
			if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{valign};
          
		# apply custom height and width to the cell tag
		$html .=" width=\"" . $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{width} . "\""
			if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{width};
                
		$html .=" height=\"" . $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{height} . "\""
			if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{height};
                    
		# apply background color if set
		$html .=" bgcolor=\"" . $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{bgcolor} . "\""
			if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{bgcolor};

		# apply style if set
		$html .=" style=\"" . $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{style} . "\""
			if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{style};

		# apply class if set
		$html .=" class=\"" . $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{class} . "\""
            if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{class};

		# User defined attribute
		$html .=" " . $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{attr}
            if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{attr};

		# if nowrap mask is set, put it in the cell tag
		$html .=" nowrap" if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{nowrap};
          
		# if column/row spanning is set, put it in the cell tag
		# also increment to skip spanned rows/cols.
		if (defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{colspan}) {
           	$html .=" colspan=\"" . $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{colspan} ."\"";
       	}
       	if (defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{rowspan}){
           	$html .=" rowspan=\"" . $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{rowspan} ."\"";
       	}
          
       	# Finish up Cell by ending cell start tag, putting content and cell end tag
       	$html .=">";
       	$html .= $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{startformat} if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{startformat} ;
       	$html .= $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{contents} if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{contents};
	  	$html .= $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{endformat} if defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{endformat} ;
         
       	# if head flag is set print </th> tag else </td>
       	if (defined $self->{$section}[$sect_num]->{rows}[$row_num]->{cells}[$j]->{head}) {
	       	$html .= "</th>";
       	} else {
           	$html .= "</td>";
       	}
	}
    $html .="</tr>\n";

   	return ($html);
}

#-------------------------------------------------------
# Subroutine:  	getSection
# Author:       Anthony Peacock
# Date:			10 April 2008
# Description:  Gets the HTML to form a section
#-------------------------------------------------------
sub getSection {
	my $self = shift;
	my $section = lc(shift);
	my $sect_num = shift;
	my $html="";

	# Create section HTML	
	$html .= "<$section";
		
	# Set the section attributes (if any)
	$html .= ' id="' . $self->{$section}[$sect_num]->{id} . '"' if defined $self->{$section}[$sect_num]->{id};
	$html .= ' title="' . $self->{$section}[$sect_num]->{title} . '"' if defined $self->{$section}[$sect_num]->{title};
	$html .= ' class="' . $self->{$section}[$sect_num]->{class} . '"' if defined $self->{$section}[$sect_num]->{class};
	$html .= ' style="' . $self->{$section}[$sect_num]->{style} . '"' if defined $self->{$section}[$sect_num]->{style};
	$html .= ' align="' . $self->{$section}[$sect_num]->{align} . '"' if defined $self->{$section}[$sect_num]->{align};
	$html .= ' valign="' . $self->{$section}[$sect_num]->{valign} . '"' if defined $self->{$section}[$sect_num]->{valign};
	$html .= ' attr="' . $self->{$section}[$sect_num]->{attr} . '"' if defined $self->{$section}[$sect_num]->{attr};
	
	$html .= ">\n";
	
	for my $i ( 1..($self->{$section}[$sect_num]->{last_row})){
		# Print each row   
		$html .= $self->getRow($section, $sect_num, $i);
	}	
	$html .= "</$section>\n";
	

   	return ($html);
}
	
#-------------------------------------------------------
# Subroutine:  	print
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
#-------------------------------------------------------
sub print {
   my $self = shift;
   print $self->getTable;
}

#-------------------------------------------------------
# Subroutine:  	autoGrow([1|on|true|0|off|false]) 
# Author:       John Stumbles
# Date:		08 Feb 2001
# Description:  switches on (default) or off auto-grow mode
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub autoGrow {
    my $self = shift;
    $self->{autogrow} = shift;
	if ( defined $self->{autogrow} && $self->{autogrow} =~ /^(?:no|off|false|disable|0)$/i ) {
	    $self->{autogrow} = 0;
	} else {
		$self->{autogrow} = 1;
	}
}


#-------------------------------------------------------
# Table config methods
# 
#-------------------------------------------------------

#-------------------------------------------------------
# Subroutine:  	setBorder([pixels]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     12 Jul 2000 - Anthony Peacock (To allow zero values)
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setBorder {
    my $self = shift;
    $self->{border} = shift;
    $self->{border} = 1 unless ( &_is_validnum($self->{border}) ) ;
}

#-------------------------------------------------------
# Subroutine:  	setBGColor([colorname|colortriplet]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setBGColor {
   my $self = shift;
   $self->{bgcolor} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	setStyle(css style) 
# Author:       Anthony Peacock
# Date:		6 Mar 2002
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setStyle {
   my $self = shift;
   $self->{style} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	setClass(css class) 
# Author:       Anthony Peacock
# Date:			22 July 2002
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setClass {
   my $self = shift;
   $self->{class} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	setEvenRowClass(css class) 
# Author:       Chris Weyl
# Date:			25 May 2007
#-------------------------------------------------------
sub setEvenRowClass {
   my $self = shift;
   $self->{evenrowclass} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	setOddRowClass(css class) 
# Author:       Chris Weyl
# Date:			25 May 2007
#-------------------------------------------------------
sub setOddRowClass {
   my $self = shift;
   $self->{oddrowclass} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	setWidth([pixels|percentofscreen]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setWidth {
   my $self = shift;
   my $value = shift;
   
   if ( $value !~ /^\s*\d+%?/ ) {
      print STDERR "$0:setWidth:Invalid value $value\n";
      return 0;
   } else {
      $self->{width} = $value;
   }    
}

#-------------------------------------------------------
# Subroutine:  	setCellSpacing([pixels]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     12 Jul 2000 - Anthony Peacock (To allow zero values)
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setCellSpacing {
    my $self = shift;
    $self->{cellspacing} = shift;
    $self->{cellspacing} = 1 unless ( &_is_validnum($self->{cellspacing}) ) ;
}

#-------------------------------------------------------
# Subroutine:  	setCellPadding([pixels]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     12 Jul 2000 - Anthony Peacock (To allow zero values)
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setCellPadding {
    my $self = shift;
    $self->{cellpadding} = shift;
    $self->{cellpadding} = 1 unless ( &_is_validnum($self->{cellpadding}) ) ;
}

#-------------------------------------------------------
# Subroutine:  	setCaption("CaptionText" [, "TOP|BOTTOM]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setCaption {
   my $self = shift;
   $self->{caption} = shift ;
   my $align = lc(shift);
   if (defined $align && (($align eq 'top') || ($align eq 'bottom')) ) {
      $self->{caption_align} = $align;
   } else {
      $self->{caption_align} = 'top';
   }
}

#-------------------------------------------------------
# Subroutine:  	setAlign([left|right|center]) 
# Author:         Arno Teunisse	 ( freely copied from setBGColor
# Date:		      05 Jan 2002
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setAlign {
   my $self = shift;
   $self->{align} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	setRules([left|right|center]) 
# Author:         Arno Teunisse	 ( freely copied from setBGColor
# Date:		      05 Jan 2002
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# parameter  	[ none | groups | rows| cols | all ]
#-------------------------------------------------------
sub setRules {
   my $self = shift;
   $self->{rules} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	setAttr("attribute string") 
# Author:         Anthony Peacock
# Date:		      10 Jan 2002
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setAttr {
   my $self = shift;
   $self->{attr} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	getSectionTableRows ('section', section_num')
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:     getTableRows
#-------------------------------------------------------
sub getSectionTableRows {
    my $self = shift;
    my $section = shift;
	my $section_num = shift;
   
	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\ngetSectionTableRows: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\ngetSectionTableRows: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
    
    return $self->{$section}[$section_num]->{last_row};
}

#-------------------------------------------------------
# Subroutine:  	getTableRows 
# Author:       Joerg Jaspert
# Date:			4 Aug 2001
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub getTableRows{
    my $self = shift;
    return $self->getSectionTableRows ( 'tbody', 0 );
}

#-------------------------------------------------------
# Subroutine:  	getTableCols 
# Author:       Joerg Jaspert
# Date:			4 Aug 2001
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub getTableCols{
    my $self = shift;
    return $self->{last_col};
}

#-------------------------------------------------------
# Subroutine:   getStyle
# Author:       Douglas Riordan
# Date:         30 Nov 2005
# Description:  getter for table style
#-------------------------------------------------------

sub getStyle {
    return shift->{style} || undef;
}

#-------------------------------------------------------
# Subroutine:  	sort (sort_col_num, [ALPHA|NUMERIC], [ASC|DESC], 
#                         num_rows_to_skip)
#               sort (	-section=>'section',
#						-section_num=>number,
#						-sort_col=>sort_col_num, 
#                       -sort_type=>[ALPHA|NUMERIC], 
#                       -sort_order=>[ASC|DESC], 
#                       -skip_rows=>num_rows_to_skip,
#                       -strip_html=>[0|1],         # default 1
#                       -strip_non_numeric=>[0|1],  # default 1 
#                                                   # for sort_type=NUMERIC
#                       -presort_func=>\&filter,
#                     )
# Author:       David Link
# Date:		28 Jun 2002
# Modified: 09 Apr 2003 -- dl  Added options: -strip_html, 
#                                  -strip_non_numeric, and -presort_func.
# Modified: 23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:	12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub sort {
  my $self = shift;
  my ($sort_col, $sort_type, $sort_order, $skip_rows, 
      $strip_html, $strip_non_numeric, $presort_func, $section, $section_num);
  $strip_html = 1;
  $strip_non_numeric = 1;
  
  # Set the default section to the first 'tbody'
  $section = 'tbody';
  $section_num = 0;
  
  if (defined $_[0] && $_[0] =~ /^-/) {
      my %flag = @_;
      $section = $flag{-section} || 'tbody';
      $section_num = $flag{-section_num} || 0;
      $sort_col = $flag{-sort_col} || 1;
      $sort_type = $flag{-sort_type} || "alpha";
      $sort_order = $flag{-sort_order} || "asc";
      $skip_rows = $flag{-skip_rows} || 0;
      $strip_html = $flag{-strip_html} if defined($flag{-strip_html});
      $strip_non_numeric = $flag{-strip_non_numeric} 
          if defined($flag{-strip_non_numeric});
      $presort_func = $flag{-presort_func} || undef;
  }
  else {
      $sort_col = shift || 1;
      $sort_type = shift || "alpha";
      $sort_order = shift || "asc";
      $skip_rows = shift || 0;
      $presort_func = undef;
  }
  my $cmp_symbol = lc($sort_type) eq "alpha" ? "cmp" : "<=>";
  my ($first, $last) = lc($sort_order) eq "asc"?("\$a", "\$b"):("\$b", "\$a");
  my $piece1 = qq/\$self->{$section}[$section_num]->{rows}[$first]->{cells}[$sort_col]->{contents}/;
  my $piece2 = qq/\$self->{$section}[$section_num]->{rows}[$last]->{cells}[$sort_col]->{contents}/;
  if ($strip_html) {
      $piece1 = qq/&_stripHTML($piece1)/;
      $piece2 = qq/&_stripHTML($piece2)/;
  }
  if ($presort_func) {
      $piece1 = qq/\&{\$presort_func}($piece1)/;
      $piece2 = qq/\&{\$presort_func}($piece2)/;
  } 
  if (lc($sort_type) ne 'alpha' && $strip_non_numeric) {
      $piece1 = qq/&_stripNonNumeric($piece1)/;
      $piece2 = qq/&_stripNonNumeric($piece2)/;
  }
  my $sortfunc = qq/sub { $piece1 $cmp_symbol $piece2 }/;
  my $sorter = eval($sortfunc);
  my @sortkeys = sort $sorter (($skip_rows+1)..$self->{$section}[$section_num]->{last_row});

	my @holdtable = @{$self->{$section}[$section_num]->{rows}};
	my $i = $skip_rows+1;
	for my $k (@sortkeys) {
		$self->{$section}[$section_num]->{rows}[$i++] = $holdtable[$k];
	}
}

#-------------------------------------------------------
# Subroutine:   _stripHTML (html_string)
# Author:       David Link
# Date:         12 Feb 2003
#-------------------------------------------------------
sub _stripHTML {
    $_ = $_[0]; 
    s/ \< [^>]* \> //gx;
    s/\&nbsp;/ /g;
    return $_;  	
}	

#-------------------------------------------------------
# Subroutine:   _stripNonNumeric (string)
# Author:       David Link
# Date:         04 Apr 2003
# Description:  Remove all non-numeric char from a string
#                 For efficiency does not deal with:
#                 1. nested '-' chars.,  2. multiple '.' chars.
#-------------------------------------------------------
sub _stripNonNumeric {
    $_ = $_[0]; 
    s/[^0-9.+-]//g;
    return 0 if !$_;
    return $_;
}

#-------------------------------------------------------
# Section config methods
# 
#-------------------------------------------------------

#-------------------------------------------------------
# Subroutine:  	setSectionAlign('Section', section_num, [left|right|center]) 
# Author:       Anthony Peacock
# Date:			10 Septmeber 2007
#-------------------------------------------------------
sub setSectionAlign {
   my $self = shift;
   	my $section = lc(shift);
	my $section_num = shift;

	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionAlign: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionAlign: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
	
   $self->{$section}[$section_num]->{align} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	setSectionId('Section', section_num, 'Id') 
# Author:       Anthony Peacock
# Date:			10 Septmeber 2007
#-------------------------------------------------------
sub setSectionId {
   my $self = shift;
   	my $section = lc(shift);
	my $section_num = shift;

	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionId: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionId: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
	
   $self->{$section}[$section_num]->{id} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	setSectionClass('Section', section_num, 'Class') 
# Author:       Anthony Peacock
# Date:			10 Septmeber 2007
#-------------------------------------------------------
sub setSectionClass {
   my $self = shift;
   	my $section = lc(shift);
	my $section_num = shift;

	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionClass: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionClass: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
	
   $self->{$section}[$section_num]->{class} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	setSectionStyle('Section', section_num, 'style') 
# Author:       Anthony Peacock
# Date:			10 Septmeber 2007
#-------------------------------------------------------
sub setSectionStyle {
   my $self = shift;
   	my $section = lc(shift);
	my $section_num = shift;

	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionStyle: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionStyle: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
	
   $self->{$section}[$section_num]->{style} = shift || undef;
}

#-------------------------------------------------------
# Subroutine:  	setSectionValign('Section', section_num, [center|top|bottom|middle|baseline]) 
# Author:       Anthony Peacock
# Date:			10 Septmeber 2007
#-------------------------------------------------------
sub setSectionValign {
   my $self = shift;
   	my $section = lc(shift);
	my $section_num = shift;
	my $valign = lc(shift);

	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionValign: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionValign: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
	
	if (! (($valign eq "center") || ($valign eq "top") || 
    	    ($valign eq "bottom")  || ($valign eq "middle") ||
			($valign eq "baseline")) ) {
		print STDERR "$0:setSectionVAlign:Invalid alignment type\n";
		return 0;
	}
	
	$self->{$section}[$section_num]->{valign} = $valign;
}

#-------------------------------------------------------
# Subroutine:  	setSectionAttr('Section', section_num, 'attr') 
# Author:       Anthony Peacock
# Date:			10 Septmeber 2007
#-------------------------------------------------------
sub setSectionAttr {
   my $self = shift;
   	my $section = lc(shift);
	my $section_num = shift;

	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionAttr: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionAttr: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
	
	$self->{$section}[$section_num]->{attr} = shift;
}

#-------------------------------------------------------
# Cell config methods
# 
#-------------------------------------------------------

#-------------------------------------------------------
# Subroutine:  	setSectionCell("section", section_num, row_num, col_num, "content") 
# Author:       Anthony Peacock
# Date:			10 September 2007
#-------------------------------------------------------
sub setSectionCell {
	my $self = shift;
	my $section = lc(shift);
	my $section_num = shift;
	(my $row = shift) || return 0;
	(my $col = shift) || return 0;
   
	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCell: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCell: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   if ($row < 1) {
      print STDERR "$0:setSectionCell:Invalid table row reference $row:$col\n";
      return 0;
   }
   if ($col < 1) {
      print STDERR "$0:setSectionCell:Invalid table column reference $row:$col\n";
      return 0;
   }
   if ($row > $self->{$section}[$section_num]{last_row}) {
      if ($self->{autogrow}) {
        $self->{$section}[$section_num]{last_row} = $row ;
      } else {
        print STDERR "$0:setSectionCell:Invalid table row reference $row:$col\n";
      }
   }
   if ($col > $self->{last_col}) {
      if ($self->{autogrow}) {
        $self->{last_col} = $col ;
      } else {
        print STDERR "$0:setSectionCell:Invalid table column reference $row:$col\n";
      }
   }
	$self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{contents} = shift;
   return ($row, $col);

}

#-------------------------------------------------------
# Subroutine:  	setCell(row_num, col_num, "content") 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     08 Feb 2001 - John Stumbles to allow auto-growing of table
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setCell {
	my $self = shift;
	(my $row = shift) || return 0;
	(my $col = shift) || return 0;
	my $contents = shift;

	return $self->setSectionCell ( 'tbody', 0, $row, $col, $contents );
}

#-------------------------------------------------------
# Subroutine:  	getSectionCell('section', section_num, row_num, col_num) 
# Author:       Anthony Peacock	
# Date:			12 Sept 2007
# Based on:     getCell
#-------------------------------------------------------
sub getSectionCell {
	my $self = shift;
	my $section = shift;
	my $section_num = shift;		
	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\ngetSectionCell: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\ngetSectionCell: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   	if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
    	print STDERR "$0:getSectionCell:Invalid table reference $row:$col\n";
      	return 0;
   	}
   	if (($col > $self->{last_col}) || ($col < 1) ) {
      	print STDERR "$0:getSectionCell:Invalid table reference $row:$col\n";
      	return 0;
   	}

   	return $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{contents} ;
}

#-------------------------------------------------------
# Subroutine:  	getCell(row_num, col_num) 
# Author:       Anthony Peacock	
# Date:			27 Jul 1998
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub getCell {
   	my $self = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	
	return $self->getSectionCell ( 'tbody', 0, $row, $col) ;
}

#-------------------------------------------------------
# Subroutine:   getSectionCellStyle('section', section_num, $row_num, $col_num)
# Author:       Anthony Peacock
# Date:         12 Sept 2007
# Description:  getter for cell style
# Based on:		getCellStyle
#-------------------------------------------------------
sub getSectionCellStyle {
	my $self = shift;
    my $section = shift;
	my $section_num = shift;
    my ($row, $col) = @_;
    
    if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\ngetSectionCellStyle: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\ngetSectionCellStyle: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

    return $self->_checkRowAndCol('getSectionCellStyle', $section, $section_num, {row => $row, col => $col})
        ? $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{style}
        : undef;
}

#-------------------------------------------------------
# Subroutine:   getCellStyle($row_num, $col_num)
# Author:       Douglas Riordan
# Date:         30 Nov 2005
# Description:  getter for cell style
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub getCellStyle {
    my ($self, $row, $col) = @_;

    return $self->getSectionCellStyle('tbody', 0, $row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellAlign('section', section_num, row_num, col_num, [center|right|left]) 
# Author:       Anthony Peacock	
# Date:			12 Sept 2007
# Based on:     setCellAlign
#-------------------------------------------------------
sub setSectionCellAlign {
   	my $self = shift;
	my $section = shift;
   	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
	my $align = lc(shift);
	
	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellAlign: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellAlign: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
      print STDERR "$0:setSectionCellAlign:Invalid table reference\n";
      return 0;
   }
   if (($col > $self->{last_col}) || ($col < 1) ) {
      print STDERR "$0:setSectionCellAlign:Invalid table reference\n";
      return 0;
   }

   if (! $align) {
      #return to default alignment if none specified
      undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{align};
      return ($row, $col);
   }

   if (! (($align eq 'center') || ($align eq 'right') || 
          ($align eq 'left'))) {
      print STDERR "$0:setCellAlign:Invalid alignment type\n";
      return 0;
   }

   # We have a valid alignment type so let's set it for the cell
   $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{align} = $align;
   return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellAlign(row_num, col_num, [center|right|left]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     13 Feb 2001 - Anthony Peacock for case insensitive
#                             alignment parameters
#                             (suggested by John Stumbles)
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setCellAlign {
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
	my $align = lc(shift);

   return $self->setSectionCellAlign ( 'tbody', 0, $row, $col, $align );
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellVAlign('section', section_num, row_num, col_num, [center|top|bottom|middle|baseline]) 
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:     setCellVAlign
#-------------------------------------------------------
sub setSectionCellVAlign {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	my $valign = lc(shift);
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellVAlign: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellVAlign: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
   
	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

	if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
    	print STDERR "$0:setSectionCellVAlign:Invalid table reference\n";
      	return 0;
   	}
   	if (($col > $self->{last_col}) || ($col < 1) ) {
      	print STDERR "$0:setSectionCellVAlign:Invalid table reference\n";
      	return 0;
   	}

   	if (! $valign) {
    	#return to default alignment if none specified
      	undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{valign};
      	return ($row, $col);
   	}

   	if (! (($valign eq "center") || ($valign eq "top") || 
    		($valign eq "bottom")  || ($valign eq "middle") ||
		  	($valign eq "baseline")) ) {
      	print STDERR "$0:setSectionCellVAlign:Invalid alignment type\n";
      	return 0;
   	}

   	# We have a valid valignment type so let's set it for the cell
   	$self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{valign} = $valign;
   	return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellVAlign(row_num, col_num, [center|top|bottom|middle|baseline]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     13 Feb 2001 - Anthony Peacock for case insensitive
#                             alignment parameters
#                             (suggested by John Stumbles)
# Modified:		22 Aug 2003 - Alejandro Juarez to add MIDDLE and BASELINE
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007
#-------------------------------------------------------
sub setCellVAlign {
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   my $valign = lc(shift);
   
   return $self->setSectionCellVAlign ( 'tbody', 0, $row, $col, $valign );
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellHead('section', section_num, row_num, col_num, [0|1]) 
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:     setCellHead
#-------------------------------------------------------
sub setSectionCellHead {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	my $value = shift || 1;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellHead: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellHead: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
      print STDERR "$0:setSectionCellHead:Invalid table reference\n";
      return 0;
   }
   if (($col > $self->{last_col}) || ($col < 1) ) {
      print STDERR "$0:setSectionCellHead:Invalid table reference\n";
      return 0;
   }

   $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{head} = $value;
   return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellHead(row_num, col_num, [0|1]) 
# Author:       Jay Flaherty
# Date:			19 Mar 1998
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setCellHead{
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   my $value = shift || 1;

   $self->setSectionCellHead ( 'tbody', 0, $row, $col, $value );
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellNoWrap('section', section_num, row_num, col_num, [0|1]) 
# Author:       Anthony Peacock	
# Date:			12 Sept 2007
# Based on:     setCellNoWrap
#-------------------------------------------------------
sub setSectionCellNoWrap {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	(my $value = shift);
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellNoWrap: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellNoWrap: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
      print STDERR "$0:setSectionCellNoWrap:Invalid table reference\n";
      return 0;
   }
   if (($col > $self->{last_col}) || ($col < 1) ) {
      print STDERR "$0:setSectionCellNoWrap:Invalid table reference\n";
      return 0;
   }

   $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{nowrap} = $value;
   return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellNoWrap(row_num, col_num, [0|1]) 
# Author:       Stacy Lacy	
# Date:			30 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setCellNoWrap {
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   (my $value = shift);

   $self->setSectionCellNoWrap ( 'tbody', 0, $row, $col, $value );
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellWidth('section', section_num, row_num, col_num, [pixels|percentoftable]) 
# Author:       Anthony Peacock	
# Date:			12 Sept 2007
# Based on:     setCellWidth
#-------------------------------------------------------
sub setSectionCellWidth {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	(my $value = shift);
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellWidth: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellWidth: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
      print STDERR "$0:setSectionCellWidth:Invalid table reference\n";
      return 0;
   }
   if (($col > $self->{last_col}) || ($col < 1) ) {
      print STDERR "$0:setSectionCellWidth:Invalid table reference\n";
      return 0;
   }

   if (! $value) {
      #return to default alignment if none specified
      undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{width};
      return ($row, $col);
   }

   if ( $value !~ /^\s*\d+%?/ ) {
      print STDERR "$0:setSectionCellWidth:Invalid value $value\n";
      return 0;
   } else {
      $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{width} = $value;
      return ($row, $col);
   }
}

#-------------------------------------------------------
# Subroutine:  	setCellWidth(row_num, col_num, [pixels|percentoftable]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007
#-------------------------------------------------------
sub setCellWidth {
   	my $self = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	(my $value = shift);

   	$self->setSectionCellWidth ( 'tbody', 0, $row, $col, $value );
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellHeight('section', section_num, row_num, col_num, [pixels]) 
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:     setCellHeight
#-------------------------------------------------------
sub setSectionCellHeight {
   	my $self = shift;
	my $section = shift;
	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	(my $value = shift);
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellHeight: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellHeight: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
      print STDERR "$0:setSectionCellHeight:Invalid table reference\n";
      return 0;
   }
   if (($col > $self->{last_col}) || ($col < 1) ) {
      print STDERR "$0:setSectionCellHeight:Invalid table reference\n";
      return 0;
   }

   if (! $value) {
      #return to default alignment if none specified
      undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{height};
      return ($row, $col);
   }

   $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{height} = $value;
   return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellHeight(row_num, col_num, [pixels]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified: 	12 Sept 2007
#-------------------------------------------------------
sub setCellHeight {
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   (my $value = shift);

   $self->setSectionCellHeight ( 'tbody', 0, $row, $col, $value );
   return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellBGColor('section', section_num, row_num, col_num, [colorname|colortrip]) 
# Author:       Anthony Peacock	
# Date:			12 Sept 2007
# Based on:     setCellBGColor
#-------------------------------------------------------
sub setSectionCellBGColor {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	(my $value = shift);
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellBGColor: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellBGColor: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
      print STDERR "$0:setSectionCellBGColor:Invalid table reference\n";
      return 0;
   }
   if (($col > $self->{last_col}) || ($col < 1) ) {
      print STDERR "$0:setSectionCellBGColor:Invalid table reference\n";
      return 0;
   }

   if (! $value) {
      #return to default alignment if none specified
      undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{bgcolor};
   }

   # BG colors are too hard to verify, let's assume user
   # knows what they are doing
   $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{bgcolor} = $value;
   return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellBGColor(row_num, col_num, [colorname|colortrip]) 
# Author:       Stacy Lacy	
# Date:			30 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setCellBGColor {
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   (my $value = shift);

   $self->setSectionCellBGColor ( 'tbody', 0, $row, $col, $value );
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellSpan('section', section_num, row_num, col_num, num_rows, num_cols)
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:     setCellSpan
#-------------------------------------------------------
sub setSectionCellSpan {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	(my $num_rows = shift);
   	(my $num_cols = shift);
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellSpan: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellSpan: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
      print STDERR "$0:setSectionCellSpan:Invalid table reference\n";
      return 0;
   }
   if (($col > $self->{last_col}) || ($col < 1) ) {
      print STDERR "$0:setSectionCellSpan:Invalid table reference\n";
      return 0;
   }

   if (! $num_cols || ! $num_rows) {
      #return to default if none specified
      undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{colspan};
      undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{rowspan};
   }

   $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{colspan} = $num_cols;
   $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{rowspan} = $num_rows;

   $self->_updateSpanGrid($section, $section_num, $row,$col);
   
   return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellSpan(row_num, col_num, num_rows, num_cols)
# Author:       Anthony Peacock
# Date:			22 July 2002
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setCellSpan {
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   (my $num_rows = shift);
   (my $num_cols = shift);

   return $self->setSectionCellSpan ('tbody', 0, $row, $col, $num_rows, $num_cols);
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellRowSpan('section', section_num, row_num, col_num, num_cells)
# Author:       Anthony Peacock	
# Date:			10 September 2007
# Based on:		setCellRowSpan
#-------------------------------------------------------
sub setSectionCellRowSpan {
   my $self = shift;
   my $section = lc(shift);
   my $section_num = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   (my $value = shift);
   
   if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellRowSpan: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellRowSpan: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
      print STDERR "$0:setSectionCellRowSpan:Invalid table reference\n";
      return 0;
   }
   if (($col > $self->{last_col}) || ($col < 1) ) {
      print STDERR "$0:setSectionCellRowSpan:Invalid table reference\n";
      return 0;
   }

   if (! $value) {
      #return to default alignment if none specified
      undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{rowspan};
   }

   $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{rowspan} = $value;
   
   $self->_updateSpanGrid($section, $section_num, $row,$col);
   
   return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellRowSpan(row_num, col_num, num_cells)
# Author:       Stacy Lacy	
# Date:		31 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		10 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setCellRowSpan {
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   (my $value = shift);

   return $self->setSectionCellRowSpan( 'tbody', 0, $row, $col, $value);
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellColSpan(row_num, col_num, num_cells)
# Author:       Anthony Peacock	
# Date:			12 Sept 2007
# Based on:     setCellColSpan
#-------------------------------------------------------
sub setSectionCellColSpan {
   	my $self = shift;
	my $section = shift;
	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	(my $value = shift);
	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellColSpan: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellColSpan: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
	
	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
      print STDERR "$0:setSectionCellColSpan:Invalid table reference\n";
      return 0;
   }

   if (($col > $self->{last_col}) || ($col < 1) ) {
      print STDERR "$0:setSectionCellColSpan:Invalid table reference\n";
      return 0;
   }

   if (! $value) {
      #return to default alignment if none specified
      undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{colspan};
   }

   $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{colspan} = $value;

   $self->_updateSpanGrid($section, $section_num, $row,$col);
   
   return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellColSpan(row_num, col_num, num_cells)
# Author:       Stacy Lacy	
# Date:		31 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setCellColSpan {
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   (my $value = shift);

   return $self->setSectionCellColSpan ( 'tbody', 0, $row, $col, $value );
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellFormat('section', section_num, row_num, col_num, start_string, end_string) 
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Description:	Sets start and end HTML formatting strings for
#               the cell content
# Based on:     setCellFormat
#-------------------------------------------------------
sub setSectionCellFormat {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	(my $start_string = shift);
   	(my $end_string = shift);
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellFormat: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellFormat: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   	if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
    	print STDERR "$0:setSectionCellFormat:Invalid table reference\n";
      	return 0;
   	}
   	if (($col > $self->{last_col}) || ($col < 1) ) {
      	print STDERR "$0:setSectionCellFormat:Invalid table reference\n";
      	return 0;
   	}

   	if (! $start_string) {
      	#return to default format if none specified
      	undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{startformat};
      	undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{endformat};
   	}
	else
	{
		# No checks will be made on the validity of these strings
		# User must take responsibility for results...
		$self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{startformat} = $start_string;
		$self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{endformat} = $end_string;
   	}
   	return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellFormat(row_num, col_num, start_string, end_string) 
# Author:       Anthony Peacock
# Date:			21 Feb 2001
# Description:	Sets start and end HTML formatting strings for
#               the cell content
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setCellFormat {
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   (my $start_string = shift);
   (my $end_string = shift);

	return $self->setSectionCellFormat ( 'tbody', 0, $row, $col, $start_string, $end_string );
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellStyle('section', section_num, row_num, col_num, "Style") 
# Author:       Anthony Peacock	
# Date:			12 Sept 2007
# Based on:     setCellStyle
#-------------------------------------------------------
sub setSectionCellStyle {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	(my $value = shift);
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellStyle: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellStyle: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   	if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
      	print STDERR "$0:setSectionCellStyle:Invalid table reference\n";
      	return 0;
   	}
   	if (($col > $self->{last_col}) || ($col < 1) ) {
      	print STDERR "$0:setSectionCellStyle:Invalid table reference\n";
      	return 0;
   	}

   	if (! $value) {
      	#return to default style if none specified
      	undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{style};
      	return ($row, $col);
   	}

   	$self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{style} = $value;
   	return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellStyle(row_num, col_num, "Style") 
# Author:       Anthony Peacock	
# Date:			10 Jan 2002
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setCellStyle {
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   (my $value = shift);

   return $self->setSectionCellStyle ( 'tbody', 0, $row, $col, $value );
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellClass('section', section_num, row_num, col_num, "class") 
# Author:       Anthony Peacock	
# Date:			12 Sept 2007
# Based on:     setCellClass
#-------------------------------------------------------
sub setSectionCellClass {
    my $self = shift;
	my $section = shift;
	my $section_num = shift;
    (my $row = shift) || return 0;
    (my $col = shift) || return 0;
    (my $value = shift);

    if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellClass: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellClass: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
    
	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

    if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
       print STDERR "$0:setSectionCellClass:Invalid table reference\n";
       return 0;
    }
    if (($col > $self->{last_col}) || ($col < 1) ) {
       print STDERR "$0:setSectionCellClass:Invalid table reference\n";
       return 0;
    }

    if (! $value) {
       #return to default class if none specified
       undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{class};
       return ($row, $col);
    }

    $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{class} = $value;
    return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellClass(row_num, col_num, "class") 
# Author:       Anthony Peacock	
# Date:			22 July 2002
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setCellClass {
   	my $self = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	(my $value = shift);

	$self->setSectionCellClass ( 'tbody', 0, $row, $col, $value );
}

#-------------------------------------------------------
# Subroutine:  	setSectionCellAttr('section', section_num, row_num, col_num, "cell attribute string") 
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:     setCellAttr
#-------------------------------------------------------
sub setSectionCellAttr {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $row = shift) || return 0;
   	(my $col = shift) || return 0;
   	(my $value = shift);
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionCellAttr: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionCellAttr: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in either the row or col parameter, use the last row or cell
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;
	$col = $self->{last_col} if $col == -1;

   	if (($row > $self->{$section}[$section_num]->{last_row}) || ($row < 1) ) {
    	print STDERR "$0:setSectionCellAttr:Invalid table reference\n";
      	return 0;
   	}
   	if (($col > $self->{last_col}) || ($col < 1) ) {
      	print STDERR "$0:setSectionCellAttr:Invalid table reference\n";
      	return 0;
   	}

   	if (! $value) {
      	undef $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{attr};
   	}

   	$self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{attr} = $value;
   	return ($row, $col);
}

#-------------------------------------------------------
# Subroutine:  	setCellAttr(row_num, col_num, "cell attribute string") 
# Author:       Anthony Peacock
# Date:			10 Jan 2002
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setCellAttr {
   my $self = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;
   (my $value = shift);

   return $self->setSectionCellAttr ( 'tbody', 0, $row, $col, $value );
}

#-------------------------------------------------------
# Row config methods
# 
#-------------------------------------------------------


#-------------------------------------------------------
# Subroutine:  	addSectionRow("Section", section_num, "cell 1 content" [, "cell 2 content",  ...]) 
# Author:       Anthony Peacock
# Date:			10 August 2007
# Modified:     
#-------------------------------------------------------
sub addSectionRow {
   my $self = shift;
   my $section = lc(shift);
   my $section_num = shift;
   
   if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\naddSectionRow: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\naddSectionRow: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

   # this sub should add a row, using @_ as contents
   my $count = @_;
   # if number of cells is greater than cols, let's assume
   # we want to add a column.
   $self->{last_col} = $count if ($count > $self->{last_col});
   
   $self->{$section}[$section_num]->{last_row}++;  # increment number of rows
   for (my $i = 1; $i <= $count; $i++) {
      # Store each value in cell on row
         $self->{$section}[$section_num]->{rows}[$self->{$section}[$section_num]{last_row}]->{cells}[$i]->{contents} = shift;
   }
   return $self->{$section}[$section_num]{last_row};
   
}

#-------------------------------------------------------
# Subroutine:  	addRow("cell 1 content" [, "cell 2 content",  ...]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub addRow {
   my $self = shift;

   my $last_row = $self->addSectionRow ( 'tbody', 0, @_ );
   return $last_row;
}

#-------------------------------------------------------
# Subroutine:  	delSectionRow("Section", section_num, row_num) 
# Author:       Anthony Peacock
# Date:			10 April 2008
# Modified:     
#-------------------------------------------------------
sub delSectionRow {
   my $self = shift;
   my $section = lc(shift);
   my $section_num = shift;
   my $row_num = shift;
   
   if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\ndelSectionRow: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\ndelSectionRow: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
	
	# If -1 is used in the row parameter, use the last row
	$row_num = $self->{$section}[$section_num]->{last_row} if $row_num == -1;
	
	# Deleting the last row
	#if ( $row_num == $self->{$section}[$section_num]->{last_row} ) {
	#	$self->{$section}[$section_num]->{rows}[$row_num] = undef;
	#}
	
	splice ( @{$self->{$section}[$section_num]->{rows}}, $row_num, 1 );
	
	$self->{$section}[$section_num]->{last_row}--;  # decrement number of rows
	return $self->{$section}[$section_num]{last_row};
   
}

#-------------------------------------------------------
# Subroutine:  	delRow(row_num) 
# Author:       Anthony Peacock	
# Date:			10 April 2008
# Modified:     
#-------------------------------------------------------
sub delRow {
   my $self = shift;
   my $row_num = shift;

   my $last_row = $self->delSectionRow ( 'tbody', 0, $row_num );
   return $last_row;
}

#-------------------------------------------------------
# Subroutine:  	setSectionRowAlign('section', section_num, row_num, [center|right|left]) 
# Author:       Anthony Peacock
# Date:			11 Sept 2007
# Based on:		setRowAlign
#-------------------------------------------------------
sub setSectionRowAlign {
	my $self = shift;
	my $section = shift;
   	my $section_num = shift;
	(my $row = shift) || return 0;
	my $align = shift;
	
	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionRowAlign: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionRowAlign: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the row parameter, use the last row
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;

	if ( $row > $self->{$section}[$section_num]->{last_row} || $row < 1 ) {
		print STDERR "\n$0:setSectionRowAlign: Invalid table reference" ;
		return 0;
	} elsif ( $align !~ /left|right|center/i ) {
		print STDERR "\nsetSectionRowAlign: Alignment can be : 'left | right | center' : Cur value: $align\n";
		return 0;
	}
	
   $self->{$section}[$section_num]->{rows}[$row]->{align} = $align  ;
}

#-------------------------------------------------------
# Subroutine:  	setRowAlign(row_num, [center|right|left]) 
# Author:       Stacy Lacy
# Date:			30 Jul 1997
# Modified:		05 Jan 2002 - Arno Teunisse
# Modified:		10 Jan 2002 - Anthony Peacock
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		11 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setRowAlign {
	my $self = shift;
	(my $row = shift) || return 0;
	my $align = shift;

	$self->setSectionRowAlign ( 'tbody', 0, $row, $align  );
}

#-------------------------------------------------------
# Subroutine:	setSectionRowStyle
# Comment:		to insert a css style the <tr > Tag
# Author:		Anthony Peacock
# Date:			11 Sept 2007
# Based on: 	setRowStyle by Arno Teunisse
#-------------------------------------------------------
sub setSectionRowStyle {
	my $self = shift;
	my $section = shift;
   	my $section_num = shift;
	(my $row = shift) || return 0;
	my $html_str = shift;
	
	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionRowStyle: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionRowStyle: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the row parameter, use the last row
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;

	if ( $row > $self->{$section}[$section_num]->{last_row} || $row < 1 ) {
		print STDERR "\n$0:setSectionRowStyle: Invalid table reference" ;
		return 0;
	}
	
	$self->{$section}[$section_num]->{rows}[$row]->{style} = $html_str  ;
}

#-------------------------------------------------------
# Subroutine:	setRowStyle
# Comment:		to insert a css style the <tr > Tag
# Author:		Arno Teunisse
# Date:			05 Jan 2002
# Modified: 	10 Jan 2002 - Anthony Peacock
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified: 	11 Sept 2007 - Anthony Peaock
#-------------------------------------------------------
sub setRowStyle {
	my $self = shift;
	(my $row = shift) || return 0;
	my $html_str = shift;

	$self->setSectionRowStyle ( 'tbody', 0, $row, $html_str  );
}

#-------------------------------------------------------
# Subroutine:	setSectionRowClass
# Comment:		to insert a css class in the <tr > Tag
# Author:		Anthony Peacock (based on setRowStyle by Arno Teunisse)
# Date:			11 Sept 2007
# Based on:     setRowClass
#-------------------------------------------------------
sub setSectionRowClass {
	my $self = shift;
	my $section = shift;
	my $section_num = shift;
	(my $row = shift) || return 0;
	my $html_str = shift;
	
	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionRowClass: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionRowClass: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the row parameter, use the last row
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;

	if ( $row > $self->{$section}[$section_num]->{last_row} || $row < 1 ) {
		print STDERR "\n$0:setSectionRowClass: Invalid table reference" ;
		return 0;
	}
	
	$self->{$section}[$section_num]->{rows}[$row]->{class} = $html_str ;
}

#-------------------------------------------------------
# Subroutine:	setRowClass
# Comment:		to insert a css class in the <tr > Tag
# Author:		Anthony Peacock (based on setRowStyle by Arno Teunisse)
# Date:			22 July 2002
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		11 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setRowClass {
	my $self = shift;
	(my $row = shift) || return 0;
	my $html_str = shift;
	
	$self->setSectionRowClass ( 'tbody', 0, $row, $html_str );
}


#-------------------------------------------------------
# Subroutine:  	setSectionRowVAlign('section', section_num, row_num, [center|top|bottom]) 
# Author:       Anthony Peacock	
# Date:			11 Sept 2007
# Based on:		setRowVAlign
#-------------------------------------------------------
sub setSectionRowVAlign {
   my $self = shift;
   my $section = shift;
   my $section_num = shift;
   (my $row = shift) || return 0;
   my $valign = shift;

   if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionRowVAlign: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionRowVAlign: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
   
	# If -1 is used in the row parameter, use the last row
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;

	if ( $row > $self->{$section}[$section_num]->{last_row} || $row < 1 ) {
		print STDERR "\n$0:setSectionRowVAlign: Invalid table reference" ;
		return 0;
	}
	
	$self->{$section}[$section_num]->{rows}[$row]->{valign} = $valign ;
}

#-------------------------------------------------------
# Subroutine:  	setRowVAlign(row_num, [center|top|bottom]) 
# Author:       Stacy Lacy	
# Date:			30 Jul 1997
# Modified:		23 Oct 2003 - Anthony Peacock
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		11 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setRowVAlign {
   	my $self = shift;
   	(my $row = shift) || return 0;
   	my $valign = shift;
	
	$self->setSectionRowVAlign ( 'tbody', 0, $row, $valign );
}

#-------------------------------------------------------
# Subroutine:  	setSectionRowNoWrap('section', section_num, row_num, [0|1]) 
# Author:       Anthony Peacock
# Date:			11 September 2007
# Based on:		setRowNoWrap
#-------------------------------------------------------
sub setSectionRowNoWrap {
   	my $self = shift;
   	my $section = shift;
   	my $section_num = shift;
   	(my $row = shift) || return 0;
   	my $value = shift;
   
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionRowNoWrap: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionRowNoWrap: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
   
	# If -1 is used in the row parameter, use the last row
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;

	if ( $row > $self->{$section}[$section_num]->{last_row} || $row < 1 ) {
		print STDERR "\n$0:setSectionRowNoWrap: Invalid table reference" ;
		return 0;
	}
	
	$self->{$section}[$section_num]->{rows}[$row]->{nowrap} = $value ;
}

#-------------------------------------------------------
# Subroutine:  	setRowNoWrap(row_num, [0|1]) 
# Author:       Anthony Peacock
# Date:			22 Feb 2001
# Modified:		23 Oct 2003 - Anthony Peacock
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:     11 September 2007 - Anthony Peacock
#-------------------------------------------------------
sub setRowNoWrap {
   	my $self = shift;
   	(my $row = shift) || return 0;
   	my $value = shift;
	
   	$self->setSectionRowNoWrap ( 'tbody', 0, $row, $value ) ;
}

#-------------------------------------------------------
# Subroutine:  	setSectionRowBGColor('section', section_num, row_num, [colorname|colortriplet]) 
# Author:		Anthony Peacock 	
# Date:			10 Sep 2007
# Based On:		setRowBGColor
#-------------------------------------------------------
sub setSectionRowBGColor {
	my $self = shift;
	my $section = lc(shift);
   	my $section_num = shift;
	(my $row = shift) || return 0;
	my $value = shift;
	
	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionRowBGColor: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionRowBGColor: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the row parameter, use the last row
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;

	# You cannot set a nonexistent row
	if ( $row > $self->{$section}[$section_num]->{last_row} || $row < 1 ) {
		print STDERR "\n$0:setSectionRowBGColor: Invalid table reference" ;
		return 0;
	}
	
	$self->{$section}[$section_num]->{rows}[$row]->{bgcolor} = $value  ;
}

#-------------------------------------------------------
# Subroutine:  	setRowBGColor(row_num, [colorname|colortriplet]) 
# Author:		Arno Teunisse 	
# Date:			08 Jan 2002
# Modified:		10 Jan 2002 - Anthony Peacock
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		10 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setRowBGColor {
	my $self = shift;
	(my $row = shift) || return 0;
	my $value = shift;
	
	$self->setSectionRowBGColor ( 'tbody', 0, $row, $value );
}

#-------------------------------------------------------
# Subroutine:	setSectionRowAttr('section', section_num, row, "Attribute string")
# Comment:		To add user defined attribute to specified row in a section
# Author:		Anthony Peacock
# Date:			10 September 2007
# Modified:     
#-------------------------------------------------------
sub setSectionRowAttr {
	my $self = shift;
	my $section = lc(shift);
	my $section_num = shift;
	(my $row = shift) || return 0;
	my $html_str = shift;

	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionRowAttr: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionRowAttr: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
	
	# If -1 is used in the row parameter, use the last row
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;

	# You cannot set a nonexistent row
	if ( $row > $self->{$section}[$section_num]->{last_row} || $row < 1 ) {
		print STDERR "\n$0:setRowAttr: Invalid table reference" ;
		return 0;
	}
	
	$self->{$section}[$section_num]->{rows}[$row]->{attr} = $html_str;
}

#-------------------------------------------------------
# Subroutine:	setRowAttr(row, "Attribute string")
# Comment:		To add user defined attribute to specified row
# Author:		Anthony Peacock
# Date:			10 Jan 2002
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub setRowAttr {
	my $self = shift;
	(my $row = shift) || return 0;
	my $html_str = shift;

	$self->setSectionRowAttr ( 'tbody', 0, $row, $html_str );
}

# ----- Routines that work across a Row's Cells

#-------------------------------------------------------
# Subroutine:  	setSectionRCellsHead('section', section_num, row_num, [0|1]) 
# Author:       Anthony Peacock
# Date:			10 April 2008
# Based on:     setRowHead
#-------------------------------------------------------
sub setSectionRCellsHead {
   my $self = shift;
   my $section = shift;
   my $section_num = shift;
   (my $row = shift) || return 0;
   my $value = shift || 1;
   
   if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nasetSectionRowHead: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionRowHead: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the row parameter, use the last row
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;

	if ( $row > $self->{$section}[$section_num]->{last_row} || $row < 1 ) {
		print STDERR "\n$0:setSectionRowHead: Invalid table reference" ;
		return 0;
	}

   # this sub should change the head flag of a row;
   my $i;
   for ($i=1;$i <= $self->{last_col};$i++) {
      $self->setSectionCellHead($section, $section_num, $row, $i, $value);
   }
}

#-------------------------------------------------------
# Subroutine:  	setSectionRowHead('section', section_num, row_num, [0|1]) 
# Author:       Anthony Peacock
# Date:			10 April 2008
# Based on:     setRowHead
# Status:		Deprecated by setSectionRCellsHead
#-------------------------------------------------------
sub setSectionRowHead {
   my $self = shift;
   my $section = shift;
   my $section_num = shift;
   (my $row = shift) || return 0;
   my $value = shift || 1;
   
   return $self->setSectionRCellsHead ( $section, $section_num, $row, $value );
}

#-------------------------------------------------------
# Subroutine:  	setRCellsHead(row_num, [0|1]) 
# Author:       Anthony Peacock
# Date:			10 April 2008
#-------------------------------------------------------
sub setRCellsHead {
   	my $self = shift;
   	(my $row = shift) || return 0;
   	my $value = shift || 1;

	$self->setSectionRCellsHead ( 'tbody', 0, $row, $value);
}

#-------------------------------------------------------
# Subroutine:  	setRowHead(row_num, [0|1]) 
# Author:       Stacy Lacy	
# Date:			30 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		10 April 2008 - Anthony Peacock
# Status:		Deprecated by setRCellsHead
#-------------------------------------------------------
sub setRowHead {
   	my $self = shift;
   	(my $row = shift) || return 0;
   	my $value = shift || 1;

	$self->setSectionRCellsHead ( 'tbody', 0, $row, $value);
}

#-------------------------------------------------------
# Subroutine:  	setSectionRCellsWidth('Section', section_num', row_num, [pixels|percentoftable]) 
# Author:       Anthony Peacock
# Date:			10 April 2008
# Based on:     setRowWidth
#-------------------------------------------------------
sub setSectionRCellsWidth {
   my $self = shift;
   my $section = lc(shift);
   my $section_num = shift;
   (my $row = shift) || return 0;
   my $value = shift;
   
   if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionRCellsWidth: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionRCellsWidth: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
   
	# If -1 is used in the row parameter, use the last row
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;

	if ( $row > $self->{$section}[$section_num]->{last_row} || $row < 1 ) {
		print STDERR "\n$0:setSectionRCellsWidth: Invalid table reference" ;
		return 0;
	}

   # this sub should change the cell width of a row;
   my $i;
   for ($i=1;$i <= $self->{last_col};$i++) {
      $self->setSectionCellWidth($section, $section_num, $row, $i, $value);
   }
}

#-------------------------------------------------------
# Subroutine:  	setSectionRowWidth('Section', section_num', row_num, [pixels|percentoftable]) 
# Author:       Anthony Peacock
# Date:			10 Sept 2007
# Modified:		10 April 2008
# Based on:     setRowWidth
# Status:		Deprecated by setSectionRCellsWidth
#-------------------------------------------------------
sub setSectionRowWidth {
   my $self = shift;
   my $section = lc(shift);
   my $section_num = shift;
   (my $row = shift) || return 0;
   my $value = shift;

   return $self->setSectionRCellsWidth ( $section, $section_num, $row, $value );
}

#-------------------------------------------------------
# Subroutine:  	setRCellsWidth(row_num, [pixels|percentoftable]) 
# Author:       Anthony Peacock
# Date:			22 Feb 2001
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		10 April 2008 - Anthony Peacock
#-------------------------------------------------------
sub setRCellsWidth {
   my $self = shift;
   (my $row = shift) || return 0;
   my $value = shift;
   
   $self->setSectionRCellsWidth( 'tbody', 0, $row, $value);
}

#-------------------------------------------------------
# Subroutine:  	setRowWidth(row_num, [pixels|percentoftable]) 
# Author:       Anthony Peacock
# Date:			22 Feb 2001
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		10 April 2008 - Anthony Peacock
# Status:		Deprecated by setRCellsWidth
#-------------------------------------------------------
sub setRowWidth {
   my $self = shift;
   (my $row = shift) || return 0;
   my $value = shift;
   
   $self->setSectionRCellsWidth( 'tbody', 0, $row, $value);
}

#-------------------------------------------------------
# Subroutine:  	setSectionRCellsHeight("Section", section_num, row_num, [pixels]) 
# Author:       Anthony Peacock
# Date:			10 April 2008
# Based on:		setRowHeight
#-------------------------------------------------------
sub setSectionRCellsHeight {
   my $self = shift;
   my $section = lc(shift);
   my $section_num = shift;
   (my $row = shift) || return 0;
   my $value = shift;
   
   if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionRCellsHeight: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionRCellsHeight: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
   
	# If -1 is used in the row parameter, use the last row
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;

	if ( $row > $self->{$section}[$section_num]->{last_row} || $row < 1 ) {
		print STDERR "\n$0:setSectionRCellsHeight: Invalid table reference" ;
		return 0;
	}

   # this sub should change the cell height of a row;
   my $i;
   for ($i=1;$i <= $self->{last_col};$i++) {
      $self->setSectionCellHeight($section, $section_num, $row, $i, $value);
   }
}

#-------------------------------------------------------
# Subroutine:  	setSectionRowHeight("Section", section_num, row_num, [pixels]) 
# Author:       Anthony Peacock
# Date:			10 Sept 2007
# Modified:		10 April 2008
# Based on:		setRowHeight
# Status:		Deprecated by setSectionRCellsHeight
#-------------------------------------------------------
sub setSectionRowHeight {
   my $self = shift;
   my $section = lc(shift);
   my $section_num = shift;
   (my $row = shift) || return 0;
   my $value = shift;
   
   return $self->setSectionRCellsHeight ( $section, $section_num, $row, $value );
}

#-------------------------------------------------------
# Subroutine:  	setRCellsHeight(row_num, [pixels]) 
# Author:       Anthony Peacock
# Date:			10 April 2008
# Based on:		setRowHeight
#-------------------------------------------------------
sub setRCellsHeight {
   my $self = shift;
   (my $row = shift) || return 0;
   my $value = shift;
   
   $self->setSectionRCellsHeight('tbody', 0, $row, $value);
}

#-------------------------------------------------------
# Subroutine:  	setRowHeight(row_num, [pixels]) 
# Author:       Anthony Peacock
# Date:			22 Feb 2001
# Modified:     10 April 2008
# Status:		Deprecated by setRCellsHeight
#-------------------------------------------------------
sub setRowHeight {
   my $self = shift;
   (my $row = shift) || return 0;
   my $value = shift;
   
   $self->setSectionRCellsHeight('tbody', 0, $row, $value);
}


#-------------------------------------------------------
# Subroutine:  	setSectionRCellsFormat('section', section_num, row_num, start_string, end_string) 
# Author:       Anthony Peacock
# Date:			10 April 2008
# Base on:		setSectionRowFormat
#-------------------------------------------------------
sub setSectionRCellsFormat {
   	my $self = shift;
	my $section = lc(shift);
	my $section_num = shift;   
   	(my $row = shift) || return 0;
   	my ($start_string, $end_string) = @_;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionRCellsFormat: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionRCellsFormat: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
   
	# If -1 is used in the row parameter, use the last row
	$row = $self->{$section}[$section_num]->{last_row} if $row == -1;

	# You cannot set a nonexistent row
	if ( $row > $self->{$section}[$section_num]->{last_row} || $row < 1 ) {
		print STDERR "\n$0:setSectionRCellsFormat: Invalid table reference" ;
		return 0;
	}

   # this sub should set format strings for each
   # cell in a row given a row number;
   my $i;
   for ($i=1;$i <= $self->{last_col};$i++) {
      $self->setSectionCellFormat($section, $section_num, $row,$i, $start_string, $end_string);
   }
}

#-------------------------------------------------------
# Subroutine:  	setSectionRowFormat('section', section_num, row_num, start_string, end_string) 
# Author:       Anthony Peacock
# Date:			10 September 2007
# Modified:		10 April 2008
# Status:		Deprecated by setSectionRCellsFormat
#-------------------------------------------------------
sub setSectionRowFormat {
   	my $self = shift;
	my $section = lc(shift);
	my $section_num = shift;   
   	(my $row = shift) || return 0;
   	my ($start_string, $end_string) = @_;

   	return $self->setSectionRCellsFormat ( $section, $section_num, $row, $start_string, $end_string );
}

#-------------------------------------------------------
# Subroutine:  	setRCellsFormat(row_num, start_string, end_string) 
# Author:       Anthony Peacock
# Date:			21 Feb 2001
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		10 April 2008 - Anthony Peacock
#-------------------------------------------------------
sub setRCellsFormat {
   my $self = shift;
   (my $row = shift) || return 0;
   my ($start_string, $end_string) = @_;
   
   $self->setSectionRCellsFormat( 'tbody', 0, $row, $start_string, $end_string);
}

#-------------------------------------------------------
# Subroutine:  	setRowFormat(row_num, start_string, end_string) 
# Author:       Anthony Peacock
# Date:			21 Feb 2001
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		10 September 2007 - Anthony Peacock
# Status:		Deprecated by setRCellsFormat
#-------------------------------------------------------
sub setRowFormat {
   my $self = shift;
   (my $row = shift) || return 0;
   my ($start_string, $end_string) = @_;
   
   $self->setSectionRCellsFormat( 'tbody', 0, $row, $start_string, $end_string);
}

#-------------------------------------------------------
# Subroutine:   getSectionRowStyle('section', section_num, $row_num)
# Author:       Anthony Peacock
# Date:         10 September 2007
# Description:  getter for row style, using sections
# Based on:		getRowStyle
#-------------------------------------------------------
sub getSectionRowStyle {
    my ($self, $section, $section_num, $row) = @_;
    
   if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\ngetSectionRowStyle: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\ngetSectionRowStyle: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

    return $self->_checkRowAndCol('getRowStyle', $section, $section_num, {row => $row})
        ? $self->{$section}[$section_num]->{rows}[$row]->{style}
        : undef;
}

#-------------------------------------------------------
# Subroutine:   getRowStyle($row_num)
# Author:       Douglas Riordan
# Date:         1 Dec 2005
# Description:  getter for row style
# Modified:		10 September 2007 - Anthony Peacock
#-------------------------------------------------------
sub getRowStyle {
    my ($self, $row) = @_;

    return $self->getSectionRowStyle ( 'tbody', 0, $row );
}

#-------------------------------------------------------
# Col config methods
# 
#-------------------------------------------------------

#-------------------------------------------------------
# Subroutine:  	addSectionCol('section', section_num, "cell 1 content" [, "cell 2 content",  ...]) 
# Author:       Anthony Peacock	
# Date:			11 Sept 2007
# Based on:     addCol
#-------------------------------------------------------
sub addSectionCol {
   	my $self = shift;
	my $section = shift;
   	my $section_num = shift;
   
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\naddSectionCol: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\naddSectionCol: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
      
   	# this sub should add a column, using @_ as contents
   	my $count= @_;
   	# if number of cells is greater than rows, let's assume
   	# we want to add a row.
   	$self->{$section}[$section_num]->{last_row} = $count if ($count >$self->{$section}[$section_num]->{last_row});
   	$self->{last_col}++;  # increment number of rows
   	my $i;
   	for ($i=1;$i <= $count;$i++) {
    	# Store each value in cell on row
      	$self->{$section}[$section_num]->{rows}[$i]->{cells}[$self->{last_col}]->{contents} = shift;
   	}
   	return $self->{last_col};

}

#-------------------------------------------------------
# Subroutine:  	addCol("cell 1 content" [, "cell 2 content",  ...]) 
# Author:       Stacy Lacy	
# Date:			30 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
# Modified:		11 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub addCol {
	my $self = shift;
	return $self->addSectionCol ( 'tbody', 0, @_ );
}

#-------------------------------------------------------
# Subroutine:  	setSectionColAlign('section', section_num, col_num, [center|right|left]) 
# Author:       Anthony Peacock	
# Date:			11 Sept 2007
# Based on:		setColAlign
#-------------------------------------------------------
sub setSectionColAlign {
   	my $self = shift;
   	my $section = shift;
   	my $section_num = shift;
   	(my $col = shift) || return 0;
   	my $align = shift;
   
	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionColAlign: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionColAlign: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the col parameter, use the last col
	$col = $self->{last_col} if $col == -1;

	# You cannot set a nonexistent row
	if ( $col > $self->{last_col} || $col < 1 ) {
		print STDERR "\n$0:setSectionColAlign: Invalid table reference" ;
		return 0;
	}

   	# this sub should align a col given a col number;
   	my $i;
   	for ($i=1;$i <= $self->{$section}[$section_num]->{last_row};$i++) {
    	$self->setSectionCellAlign($section, $section_num, $i, $col, $align);
   	}
}

#-------------------------------------------------------
# Subroutine:  	setColAlign(col_num, [center|right|left]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:		11 Sept 2007 Anthony Peacock
#-------------------------------------------------------
sub setColAlign {
   	my $self = shift;
   	(my $col = shift) || return 0;
	my $align = shift;

	$self->setSectionColAlign ( 'tbody', 0, $col, $align );
}

#-------------------------------------------------------
# Subroutine:  	setSectionColVAlign('section', section_num, col_num, [center|top|bottom])
# Author:       Anthony Peacock
# Date:			11 Sept 2007
# Based on:		setColVAlign
#-------------------------------------------------------
sub setSectionColVAlign {
	my $self = shift;
	my $section = shift;
	my $section_num = shift;
   	(my $col = shift) || return 0;
   	my $valign = shift;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionColVAlign: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionColVAlign: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the col parameter, use the last col
	$col = $self->{last_col} if $col == -1;

	# You cannot set a nonexistent row
	if ( $col > $self->{last_col} || $col < 1 ) {
		print STDERR "\n$0:setSectionColVAlign: Invalid table reference" ;
		return 0;
	}

   	# this sub should align a all rows given a column number;
   	my $i;
   	for ($i=1;$i <= $self->{$section}[$section_num]->{last_row};$i++) {
   		$self->setSectionCellVAlign($section, $section_num, $i,$col, $valign);
   	}
}

#-------------------------------------------------------
# Subroutine:  	setColVAlign(col_num, [center|top|bottom])
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:		11 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setColVAlign {
   	my $self = shift;
   	(my $col = shift) || return 0;
   	my $valign = shift;

	$self->setSectionColVAlign( 'tbody', 0, $col, $valign);
}

#-------------------------------------------------------
# Subroutine:  	setSectionColHead('section', section_num, col_num, [0|1]) 
# Author:       Anthony Peacock
# Date:			11 Sept 2007
# Based on:		setColHead
#-------------------------------------------------------
sub setSectionColHead {
   	my $self = shift;
   	my $section = shift;
   	my $section_num = shift;
   	(my $col = shift) || return 0;
   	my $value = shift || 1;

   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionColHead: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionColHead: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the col parameter, use the last col
	$col = $self->{last_col} if $col == -1;

	# You cannot set a nonexistent row
	if ( $col > $self->{last_col} || $col < 1 ) {
		print STDERR "\n$0:setSectionColHead: Invalid table reference" ;
		return 0;
	}

   # this sub should set the head attribute of a col given a col number;
   my $i;
   for ($i=1;$i <= $self->{$section}[$section_num]->{last_row};$i++) {
      $self->setSectionCellHead($section, $section_num, $i, $col, $value);
   }
}

#-------------------------------------------------------
# Subroutine:  	setColHead(col_num, [0|1]) 
# Author:       Jay Flaherty
# Date:			30 Mar 1998
# Modified:		11 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setColHead {
   	my $self = shift;
   	(my $col = shift) || return 0;
   	my $value = shift || 1;
   
	$self->setSectionColHead( 'tbody', 0, $col, $value);
}

#-------------------------------------------------------
# Subroutine:  	setSectionColNoWrap('section', section_num, row_num, col_num, [0|1]) 
# Author:       Anthony Peacock
# Date:			11 Sept 2007
# Based on:		setColNoWrap
#-------------------------------------------------------
sub setSectionColNoWrap {
	my $self = shift;
	my $section = shift;
   	my $section_num = shift;
   	(my $col = shift) || return 0;
   	my $value = shift;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionColNoWrap: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionColNoWrap: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the col parameter, use the last col
	$col = $self->{last_col} if $col == -1;

	# You cannot set a nonexistent row
	if ( $col > $self->{last_col} || $col < 1 ) {
		print STDERR "\n$0:setSectionColNoWrap: Invalid table reference" ;
		return 0;
	}

   # this sub should change the wrap flag of a column;
   my $i;
   for ($i=1;$i <= $self->{$section}[$section_num]->{last_row};$i++) {
      $self->setSectionCellNoWrap($section, $section_num, $i,$col, $value);
   }
}

#-------------------------------------------------------
# Subroutine:  	setColNoWrap(row_num, col_num, [0|1]) 
# Author:       Stacy Lacy	
# Date:		30 Jul 1997
# Modified:		11 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setColNoWrap {
   my $self = shift;
   (my $col = shift) || return 0;
   my $value = shift;

	$self->setSectionColNoWrap( 'tbody', 0, $col, $value);
}

#-------------------------------------------------------
# Subroutine:  	setSectionColWidth('section', section_num, col_num, [pixels|percentoftable]) 
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:		setColWidth
#-------------------------------------------------------
sub setSectionColWidth {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $col = shift) || return 0;
   	my $value = shift;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionColWidth: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionColWidth: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the col parameter, use the last col
	$col = $self->{last_col} if $col == -1;

	# You cannot set a nonexistent row
	if ( $col > $self->{last_col} || $col < 1 ) {
		print STDERR "\n$0:setSectionColWidth: Invalid table reference" ;
		return 0;
	}

   # this sub should change the cell width of a col;
   my $i;
   for ($i=1;$i <= $self->{$section}[$section_num]->{last_row};$i++) {
      $self->setSectionCellWidth($section, $section_num, $i, $col, $value);
   }
}

#-------------------------------------------------------
# Subroutine:  	setColWidth(col_num, [pixels|percentoftable]) 
# Author:       Anthony Peacock
# Date:			22 Feb 2001
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setColWidth {
   	my $self = shift;
   	(my $col = shift) || return 0;
   	my $value = shift;

	$self->setSectionColWidth('tbody', 0, $col, $value);
}

#-------------------------------------------------------
# Subroutine:  	setSectionColHeight('section', section_num, col_num, [pixels]) 
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:		setColHeight
#-------------------------------------------------------
sub setSectionColHeight {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $col = shift) || return 0;
   	my $value = shift;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionColHeight: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionColHeight: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
   
	# If -1 is used in the col parameter, use the last col
	$col = $self->{last_col} if $col == -1;

	# You cannot set a nonexistent row
	if ( $col > $self->{last_col} || $col < 1 ) {
		print STDERR "\n$0:setSectionColHeight: Invalid table reference" ;
		return 0;
	}

   # this sub should change the cell height of a col;
   my $i;
   for ($i=1;$i <= $self->{$section}[$section_num]->{last_row};$i++) {
      $self->setSectionCellHeight($section, $section_num, $i, $col, $value);
   }
}

#-------------------------------------------------------
# Subroutine:  	setColHeight(col_num, [pixels]) 
# Author:       Anthony Peacock
# Date:			22 Feb 2001
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setColHeight {
   my $self = shift;
   (my $col = shift) || return 0;
   my $value = shift;

	$self->setSectionColHeight('tbody', 0, $col, $value);
}

#-------------------------------------------------------
# Subroutine:  	setSectionColBGColor('section', section_num, col_num, [colorname|colortriplet]) 
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:		setColBGColor
#-------------------------------------------------------
sub setSectionColBGColor{
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $col = shift) || return 0;
   	my $value = shift || 1;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionColBGColor: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionColBGColor: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the col parameter, use the last col
	$col = $self->{last_col} if $col == -1;

	# You cannot set a nonexistent row
	if ( $col > $self->{last_col} || $col < 1 ) {
		print STDERR "\n$0:setSectionColBGColor: Invalid table reference" ;
		return 0;
	}

   	# this sub should set bgcolor for each
   	# cell in a col given a col number;
   	my $i;
   	for ($i=1;$i <= $self->{$section}[$section_num]->{last_row};$i++) {
   		$self->setSectionCellBGColor($section, $section_num, $i, $col, $value);
   	}
}

#-------------------------------------------------------
# Subroutine:  	setColBGColor(col_num, [colorname|colortriplet]) 
# Author:       Jay Flaherty
# Date:			16 Nov 1998
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setColBGColor{
   my $self = shift;
   (my $col = shift) || return 0;
   my $value = shift || 1;

      $self->setSectionColBGColor( 'tbody', 0, $col, $value);
}

#-------------------------------------------------------
# Subroutine:  	setSectionColStyle('section', section_num, col_num, "style") 
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:		setColStyle
#-------------------------------------------------------
sub setSectionColStyle{
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $col = shift) || return 0;
   	my $value = shift || 1;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionColStyle: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionColStyle: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the col parameter, use the last col
	$col = $self->{last_col} if $col == -1;

	# You cannot set a nonexistent row
	if ( $col > $self->{last_col} || $col < 1 ) {
		print STDERR "\n$0:setSectionColStyle: Invalid table reference" ;
		return 0;
	}

   # this sub should set style for each
   # cell in a col given a col number;
   my $i;
   for ($i=1;$i <= $self->{$section}[$section_num]->{last_row};$i++) {
      $self->setSectionCellStyle($section, $section_num, $i,$col, $value);
   }
}

#-------------------------------------------------------
# Subroutine:  	setColStyle(col_num, "style") 
# Author:       Anthony Peacock
# Date:			10 Jan 2002
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setColStyle{
   	my $self = shift;
   	(my $col = shift) || return 0;
   	my $value = shift || 1;

	$self->setSectionColStyle( 'tbody', 0, $col, $value);
}

#-------------------------------------------------------
# Subroutine:  	setSectionColClass('section', section_num, col_num, 'class') 
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:		setColClass
#-------------------------------------------------------
sub setSectionColClass{
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $col = shift) || return 0;
   	my $value = shift || 1;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionColClass: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionColClass: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the col parameter, use the last col
	$col = $self->{last_col} if $col == -1;

	# You cannot set a nonexistent row
	if ( $col > $self->{last_col} || $col < 1 ) {
		print STDERR "\n$0:setSectionColClass: Invalid table reference" ;
		return 0;
	}

   	# this sub should set class for each
   	# cell in a col given a col number;
   	my $i;
   	for ($i=1;$i <= $self->{$section}[$section_num]->{last_row};$i++) {
    	$self->setSectionCellClass($section, $section_num, $i,$col, $value);
   	}
}

#-------------------------------------------------------
# Subroutine:  	setColClass(col_num, 'class') 
# Author:       Anthony Peacock
# Date:			22 July 2002
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setColClass{
   	my $self = shift;
   	(my $col = shift) || return 0;
   	my $value = shift || 1;

   	$self->setSectionColClass( 'tbody', 0, $col, $value);
}

#-------------------------------------------------------
# Subroutine:  	setSectionColFormat('section', section_num, row_num, start_string, end_string) 
# Author:       Anthony Peacock
# Date:			12 Sept 2007
# Based on:		setColFormat
#-------------------------------------------------------
sub setSectionColFormat{
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $col = shift) || return 0;
   	my ($start_string, $end_string) = @_;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionColFormat: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionColFormat: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}
   
	# If -1 is used in the col parameter, use the last col
	$col = $self->{last_col} if $col == -1;

	# You cannot set a nonexistent row
	if ( $col > $self->{last_col} || $col < 1 ) {
		print STDERR "\n$0:setSectionColFormat: Invalid table reference" ;
		return 0;
	}

   # this sub should set format strings for each
   # cell in a col given a col number;
   my $i;
   for ($i=1;$i <= $self->{$section}[$section_num]->{last_row};$i++) {
      $self->setSectionCellFormat($section, $section_num, $i,$col, $start_string, $end_string);
   }
}

#-------------------------------------------------------
# Subroutine:  	setColFormat(row_num, start_string, end_string) 
# Author:       Anthony Peacock
# Date:			21 Feb 2001
# Modified:		12 Sept 2007
#-------------------------------------------------------
sub setColFormat{
   my $self = shift;
   (my $col = shift) || return 0;
   my ($start_string, $end_string) = @_;

	$self->setSectionColFormat( 'tbody', 0, $col, $start_string, $end_string);
}

#-------------------------------------------------------
# Subroutine:	setSectionColAttr('section', section_num, col, "Attribute string")
# Author:		Anthony Peacock
# Date:			12 Sept 2007
# Based on:		setColAttr
#-------------------------------------------------------
sub setSectionColAttr {
   	my $self = shift;
   	my $section = shift;
	my $section_num = shift;
   	(my $col = shift) || return 0;
   	my $html_str = shift;
   	
   	if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\nsetSectionColAttr: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\nsetSectionColAttr: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

	# If -1 is used in the col parameter, use the last col
	$col = $self->{last_col} if $col == -1;

	# You cannot set a nonexistent row
	if ( $col > $self->{last_col} || $col < 1 ) {
		print STDERR "\n$0:setSectionColAttr: Invalid table reference" ;
		return 0;
	}

   	# this sub should set attribute string for each
   	# cell in a col given a col number;
   	my $i;
   	for ($i=1;$i <= $self->{$section}[$section_num]->{last_row};$i++) {
    	$self->setSectionCellAttr($section, $section_num, $i,$col, $html_str);
   	}
}

#-------------------------------------------------------
# Subroutine:	setColAttr(col, "Attribute string")
# Author:		Benjamin Longuet
# Date:			27 Feb 2002
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub setColAttr {
   	my $self = shift;
   	(my $col = shift) || return 0;
   	my $html_str = shift;

	$self->setSectionColAttr( 'tbody', 0,$col, $html_str);
}

#-------------------------------------------------------
# Subroutine:   getSectionColStyle('section', section_num, $col_num)
# Author:       Anthony Peacock
# Date:         12 Sept 2007
# Description:  getter for col style
# Based on:		getColStyle
#-------------------------------------------------------
sub getSectionColStyle {
    my ($self, $section, $section_num, $col) = @_;
    
    if ( $section !~ /thead|tbody|tfoot/i ) {
		print STDERR "\ngetSectionColStyle: Section can be : 'thead | tbody | tfoot' : Cur value: $section\n";
		return 0;
	} elsif ( $section =~ /thead|tfoot/i && $section_num > 0 ) {
		print STDERR "\ngetSectionColStyle: Section number for Head and Foot can only be 0 : Cur value: $section_num\n";
		return 0;
	}

    if ($self->_checkRowAndCol('getSectionColStyle', $section, $section_num, {col => $col})) {
        my $last_row = $self->{$section}[$section_num]->{last_row};
        return $self->{$section}[$section_num]->{rows}->[$last_row]->{cells}[$col]->{style};
    }
    else {
        return undef;
    }
}

#-------------------------------------------------------
# Subroutine:   getColStyle($col_num)
# Author:       Douglas Riordan
# Date:         1 Dec 2005
# Description:  getter for col style
# Modified:		12 Sept 2007 - Anthony Peacock
#-------------------------------------------------------
sub getColStyle {
    my ($self, $col) = @_;

    return $self->getSectionColStyle ( 'tbody', 0, $col );
}

#-------------------------------------------------------
#*******************************************************
#
# End of public methods
# 
# The following methods are internal to this package
#
#*******************************************************
#-------------------------------------------------------

#-------------------------------------------------------
# Subroutine:  	_updateSpanGrid('section', section_num, row_num, col_num)
# Author:       Stacy Lacy	
# Date:		31 Jul 1997
# Modified:     23 Oct 2003 - Anthony Peacock (Version 2 new data structure)
#-------------------------------------------------------
sub _updateSpanGrid {
   my $self = shift;
   my $section = shift;
   my $section_num = shift;
   (my $row = shift) || return 0;
   (my $col = shift) || return 0;

   my $colspan = $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{colspan} || 0;
   my $rowspan = $self->{$section}[$section_num]->{rows}[$row]->{cells}[$col]->{rowspan} || 0;

	if ($self->{autogrow}) {
		$self->{last_col} = $col + $colspan - 1 unless $self->{last_col} > ($col + $colspan - 1 );
		$self->{$section}[$section_num]->{last_row} = $row + $rowspan - 1 unless $self->{$section}[$section_num]->{last_row} > ($row + $rowspan - 1 );
	}

   my ($i, $j);
   if ($colspan) {
      for ($j=$col+1;(($j <= $self->{last_col}) && ($j <= ($col +$colspan -1))); $j++ ) {
			$self->{$section}[$section_num]->{rows}[$row]->{cells}[$j]->{colspan} = "SPANNED";
      }
   }
   if ($rowspan) {
      for ($i=$row+1;(($i <= $self->{$section}[$section_num]->{last_row}) && ($i <= ($row +$rowspan -1))); $i++) {
			$self->{$section}[$section_num]->{rows}[$i]->{cells}[$col]->{colspan} = "SPANNED";
      }
   }

   if ($colspan && $rowspan) {
      # Spanned Grid
      for ($i=$row+1;(($i <= $self->{$section}[$section_num]->{last_row}) && ($i <= ($row +$rowspan -1))); $i++) {
         for ($j=$col+1;(($j <= $self->{last_col}) && ($j <= ($col +$colspan -1))); $j++ ) {
			$self->{$section}[$section_num]->{rows}[$i]->{cells}[$j]->{colspan} = "SPANNED";
         }
      }
   }
}

#-------------------------------------------------------
# Subroutine:  	_getTableHashValues(tablehashname)
# Author:       Stacy Lacy	
# Date:		31 Jul 1997
#-------------------------------------------------------
sub _getTableHashValues {
   my $self = shift;
   (my $hashname = shift) || return 0;

   my ($i, $j, $retval);
   for ($i=1; $i <= ($self->{last_row}); $i++) {
      for ($j=1; $j <= ($self->{last_col}); $j++) {
         $retval.= "|$i:$j| " . ($self->{"$hashname"}{"$i:$j"}) . " ";
      }
      $retval.=" |<br />";
   }

   return $retval;
}

#-------------------------------------------------------
# Subroutine:  	_is_validnum(string_value)
# Author:       Anthony Peacock	
# Date:			12 Jul 2000
# Description:	Checks the string value passed as a parameter
#               and returns true if it is >= 0
# Modified:		23 Oct 2001 - Terence Brown
# Modified:     30 Aug 2002 - Tommi Maekitalo
#-------------------------------------------------------
sub _is_validnum {
	my $str = shift;

	if ( defined($str) && $str =~ /^\s*\d+\s*$/ && $str >= 0 ) {
		return 1;
	} else {
		return;
	}
}

#----------------------------------------------------------------------
# Subroutine: _install_stateful_set_method
# Author: Paul Vernaza
# Date: 1 July 2002
# Description: Generates and installs a stateful version of the given
# setter method (in the sense that it 'remembers' the last row or 
# column in the table and passes it as an implicit argument).
#----------------------------------------------------------------------
sub _install_stateful_set_method {
    my ($called_method, $real_method) = @_;

    my $row_andor_cell = $real_method =~ /^setCell/ ?
	'($self->getTableRows, $self->getTableCols)' :
	$real_method =~ /^setRow/ ? '$self->getTableRows' :
	$real_method =~ /^setCol/ ? '$self->getTableCols' :
	die 'can\'t determine argument type(s)';
    
    { no strict 'refs';
      *$called_method = sub {
	  my $self = shift();
	  return &$real_method($self, eval ($row_andor_cell), @_);
      }; }
}

#----------------------------------------------------------------------
# Subroutine: AUTOLOAD
# Author: Paul Vernaza
# Date: 1 July 2002
# Description: Intercepts calls to setLast* methods, generates them 
# if possible from existing set-methods that require explicit row/column.
# Modified: 23 January 2006 - Suggestion by Gordon Lack
# Modified: 1 February 2006 - Made the "Usupported method" code more flexible.
#----------------------------------------------------------------------

sub AUTOLOAD {
    (my $called_method = $AUTOLOAD ) =~ s/.*:://;
    (my $real_method = $called_method) =~ s/^setLast/set/;

    return if ($called_method eq 'DESTROY');

    die sprintf("Unsupported method $called_method call in %s\n", __PACKAGE__) unless defined(&$real_method);

    _install_stateful_set_method($called_method, $real_method);
    goto &$called_method;
}


#----------------------------------------------------------------------
# Subroutine:   _checkRowAndCol($caller_method, $hsh_ref)
# Author:       Douglas Riordan
# Date:         30 Nov 2005
# Description:  validates row and col coordinates
# Modified:		12 Sept 2007 - Anthony Peacock
#----------------------------------------------------------------------
sub _checkRowAndCol {
    my ($self, $method, $section, $section_num, $attrs) = @_;

    if (defined $attrs->{row}) {
        my $row = $attrs->{row};
        # if -1 is used in the row parameter, use the last row
        $row = $self->{$section}[$section_num]->{last_row} if $row == -1;
        if ($row > $self->{$section}[$section_num]->{last_row} || $row < 1) {
            print STDERR "$0: $method - Invalid table row reference\n";
            return 0;
        }
    }

    if (defined $attrs->{col}) {
        my $col = $attrs->{col};
        # if -1 is used in the col parameter, use the last col
        $col = $self->{last_col} if $col == -1;
        if ($col > $self->{last_col} || $col < 1) {
            print STDERR "$0: $method - Invalid table col reference\n";
            return 0;
        }
    }

    return 1;
}

1;

__END__


