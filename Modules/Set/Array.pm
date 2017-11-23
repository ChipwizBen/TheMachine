package Set::Array;

use strict;
use attributes qw(reftype);
use subs qw(foreach pack push pop shift join rindex splice unpack unshift);

use Want;
use Carp;
use Try::Tiny;

# Some not documented/implemented.  Waiting for Want-0.06 to arrive.
use overload
   "=="  => "is_equal",
   "!="  => "not_equal",
   "+"   => "union",
   "&"   => "bag",
   "*"   => "intersection",
   "-"   => "difference",
   "%"   => "symmetric_difference",
   "<<"  => "push",
   ">>"  => "shift",
   "<<=" => "unshift",
   ">>=" => "pop",
   "fallback" => 1;

our $VERSION = '0.30';

sub new{
   my($class,@array) = @_;
   @array = @$class if !@array && ref($class);
   return bless \@array, ref($class) || $class;
}

# Turn array into a hash
sub as_hash{
   my($self,$order,@arg) = @_;

   if (! defined $order) {
      $order = 'even';
   }
   elsif (ref $order eq 'HASH') {
      $order = $$order{'key_option'};
   }
   elsif ($order eq 'key_option') {
      $order = $arg[0];
   }

   $order = lc $order;

   if ($order =~ /^(?:odd|even)$/) {
   }
   else {
      Carp::croak "Unrecognized option ($order) passed to 'as_hash()' method";
   }

   my %hash;

   if($order eq 'odd') {
      %hash = CORE::reverse(@$self);
   }
   else {
      %hash = @$self;
   }

   if(want('OBJECT')){ return $self } # This shouldn't happen

   return %hash if wantarray;
   return \%hash;
}
*to_hash = \&as_hash;

# Return element at specified index
sub at{
   my($self,$index) = @_;
   if(want('OBJECT')){ return bless \${$self}[$index] }
   return @$self[$index];
}

# Delete (or undef) contents of array
sub clear{
   my($self,$undef) = @_;
   if($undef){ @{$self} = map{ undef } @{$self} }
   else{ @{$self} = () }

   if(want('OBJECT')){ return $self }
   if(wantarray){ return @$self }
   if(defined wantarray){ return \@{$self} }
}

# Remove all undef elements. It can be chained.

sub compact{
   my($self) = @_;

   if( (want('OBJECT')) || (!defined wantarray) ){
      @$self = grep defined $_, @$self;
      return $self;
   }

   my @temp;
   CORE::foreach(@{$self}){ CORE::push(@temp,$_) if defined $_ }
   if(wantarray){ return @temp }
   if(defined wantarray){ return \@temp }
}

# Return the number of times the specified value appears within array
sub count{
   my($self,$val) = @_;

   my $hits = 0;

   # Count undefined elements
   unless(defined($val)){
      foreach(@$self){ $hits++ unless $_ }
      if(want('OBJECT')){ return bless \$hits }
      return $hits;
   }

   $hits = grep /^\Q$val\E$/, @$self;
   if(want('OBJECT')){ return bless \$hits }
   return $hits;
}

# Pops and returns /the object/. I.e it can be chained.

sub cpop{
   my($self) = @_;
   my $popped = CORE::pop(@$self);
   return $self;
}

# Shifts and returns /the object/. I.e it can be chained.

sub cshift{
   my($self) = @_;
   my $shifted = CORE::shift @$self;
   return $self;
}

# Delete all instances of the specified value within the array. It can be chained.

sub delete{
   my($self,@vals) = @_;

   unless(defined($vals[0])){
      Carp::croak "Undefined value passed to 'delete()' method";
   }

   foreach my $val(@vals){
      @$self = grep $_ !~ /^\Q$val\E$/, @$self;
   }

   if(want('OBJECT')){ return $self }
   if(wantarray){ return @$self }
   if(defined wantarray){ return \@$self }
}

# Deletes an element at a specified index, or range of indices
# I'm not sure I like the range behavior for this method and may change it
# (or remove it) in the future.
sub delete_at{
   my($self,$start_index, $end_index) = @_;

   unless(defined($start_index)){
      Carp::croak "No index passed to 'delete_at()' method";
   }

   unless(defined($end_index)){ $end_index = 0 }
   if( ($end_index eq 'end') || ($end_index == -1) ){ $end_index = $#$self }

   my $num = ($end_index - $start_index) + 1;

   CORE::splice(@{$self},$start_index,$num);

   if(want('OBJECT') || !(defined wantarray)){ return $self }
   if(wantarray){ return @$self }
   if(defined wantarray){ return \@{$self} }
}

# Returns a list of duplicate items in the array. It can be chained.

sub duplicates{
   my($self) = @_;

   my(@dups,%count);

   CORE::foreach(@$self){
      $count{$_}++;
      if($count{$_} > 1){ CORE::push(@dups,$_) }
   }

   if(want('OBJECT') || !(defined wantarray)){
      @$self = @dups;
      return $self;
   }

   if(wantarray){ return @dups }
   if(defined wantarray){ return \@dups }
}

# Tests to see if value exists anywhere within array
sub exists{
   my($self,$val) = @_;

   # Check specifically for undefined values
   unless(defined($val)){
      foreach(@$self){ unless($_){ return 1 } }
      return 0;
   }

   if(grep /^\Q$val\E$/, @$self){ return 1 }

   return 0;
}

*contains = \&exists;

# Fills the elements of the array.  Does not create new elements
sub fill{
   my($self,$val, $start, $length) = @_;  # Start may also be a range
   return unless(scalar(@{$self}) > 0);   # Test for empty array

   unless(defined($start)){ $start = 0 }

   if($length){ $length += $start }
   else{ $length = $#$self + 1}

   if($start =~ /^(\d+)\.\.(\d+)$/){
      CORE::foreach($1..$2){ @{$self}[$_] = $val }
      return $self;
   }

   CORE::foreach(my $n=$start; $n<$length; $n++){ @{$self}[$n] = $val }

   if(want('OBJECT')){ return $self }
   if(wantarray){ return @$self }
   if(defined wantarray){ return \@{$self} }
}

# Returns the first element of the array
sub first{
   my($self) = @_;
   if(want('OBJECT')){ return bless \@{$self}[0] }
   return @{$self}[0];
}

# Flattens any list references into a plain list
sub flatten{
   my($self) = @_;

   if( (want('OBJECT')) || (!defined wantarray) ){
      for(my $n=0; $n<=$#$self; $n++){
   if( ref($$self[$n]) eq 'ARRAY' ){
        CORE::splice(@$self,$n,1,@{$$self[$n]});
        $n--;
        next;
   }
         if( ref($$self[$n]) eq 'HASH' ){
            CORE::splice(@$self,$n,1,%{$$self[$n]});
            --$n;
            next;
         }
      }
      return $self
   }

   my @temp = @$self;
   for(my $n=0; $n<=$#temp; $n++){
      if( ref($temp[$n]) eq 'ARRAY' ){
         CORE::splice(@temp,$n,1,@{$temp[$n]});
         $n--;
         next;
      }
      if( ref($temp[$n]) eq 'HASH' ){
         CORE::splice(@temp,$n,1,%{$temp[$n]});
         --$n;
         next;
      }
   }
   if(wantarray){ return @temp }
   if(defined wantarray){ return \@temp }
}

# Loop mechanism
sub foreach{
   my($self,$coderef) = @_;

   unless(ref($coderef) eq 'CODE'){
      Carp::croak "Invalid code reference passed to 'foreach' method";
   }

   CORE::foreach (@$self){ &$coderef }

   if(want('OBJECT')){ return $self }
   if(wantarray){ return @$self }
   if(defined wantarray){ return \@{$self} }
}

# Append or prepend a string to each element of the array
sub impose{
   my($self,$placement,$string) = @_;

   # Set defaults
   unless($placement =~ /\bappend\b|\bprepend\b/i){
      $string = $placement;
      $placement = 'append';
   }

   unless(CORE::defined($string)){
      Carp::croak "No string supplied to 'impose()' method";
   }

   if(want('OBJECT') or !(defined wantarray)){
      if($placement =~ /append/){ foreach(@$self){ $_ = $_ . $string } }
      if($placement =~ /prepend/){ foreach(@$self){ $_ = $string . $_ } }
      return $self;
   }

   my @copy = @$self;
   if($placement =~ /append/){ foreach(@copy){ $_ = $_ . $string } }
   if($placement =~ /prepend/){ foreach(@copy){ $_ = $string . $_ } }

   if(wantarray){ return @copy }
   if(defined wantarray){ return \@copy }
}

# Returns the index of the first occurrence within the array
# of the specified value
sub index{
   my($self,$val) = @_;

   # Test for undefined value
   unless(defined($val)){
      for(my $n=0; $n<=$#$self; $n++){
         unless($self->[$n]){
            if(want('OBJECT')){ return bless \$n }
            if(defined wantarray){ return $n }
         }
      }
   }

   for(my $n=0; $n<=$#$self; $n++){
      next unless defined $self->[$n];
      if( $self->[$n] =~ /^\Q$val\E$/ ){
         if(want('OBJECT')){ return bless \$n }
         if(defined wantarray){ return $n }
      }
   }
   return undef;
}

# Given an index, or range of indices, returns the value at that index
# (or a list of values for a range).
sub indices{
   my($self,@indices) = @_;
   my @iArray;

   unless(defined($indices[0])){
      Carp::croak "No index/indices passed to 'indices' (aka 'get') method";
   }

   CORE::foreach(@indices){
      if($_ =~ /(\d+)\.\.(\d+)/){ for($1..$2){
         CORE::push(@iArray,@{$self}[$_]) };
         next;
      }
      if(@{$self}[$_]){ CORE::push(@iArray,@{$self}[$_]) }
      else{ CORE::push(@iArray,undef) }
   }

   if(scalar(@iArray) == 1){
      if(want('OBJECT')){ return bless \$iArray[0] }
      return $iArray[0];
   }

   if(want('OBJECT')){ return bless \@iArray }
   if(wantarray){ return @iArray }
   if(defined wantarray){ return \@iArray }
}

# Alias for 'indices()'
*get = \&indices;

# Tests to see if array contains any elements
sub is_empty{
   my($self) = @_;
   if( (scalar @{$self}) > 0){ return 0 }
   return 1;
}

# Set a specific index to a specific value
sub set{
   my($self,$index,$val) = @_;

   unless(defined($index) && $val){
      Carp::croak "No index or value passed to 'set()' method";
   }

   if(want('OBJECT')){
      $self->[$index] = $val;
      return $self;
   }

   my @copy = @$self;
   $copy[$index] = $val;

   if(wantarray){ return @copy }
   if(defined wantarray){ return \@copy }
}

# Joins the contents of the list with the specified string
sub join{
   my($self,$s) = @_;

   $s = ',' unless $s;

   my $string;

   if(want('OBJECT')){
      $string = CORE::join($s,@$self);
      return bless \$string;
   }

   $string = CORE::join($s,@$self);
   return $string;
}

# Returns the last element of the array
sub last{
   my($self) = @_;
   if(want('OBJECT')){ return bless \@{$self}[-1] }
   return @$self[-1];
}

# Returns the number of elements within the array
sub length{
   my($self) = @_;
   my $length = scalar(@$self);
   if(want('OBJECT')){ return bless \$length }
   return $length;
}

# Returns the maximum numerical value in the array
sub max{
   my($self) = @_;
   my $max;

   no warnings 'uninitialized';
   CORE::foreach(@{$self}){ $max = $_ if $_ > $max }

   if(want('OBJECT')){ return bless \$max }
   return $max;
}

sub pack{
   my($self,$template) = @_;

   Carp::croak "No template provided to 'pack()' method" unless $template;

   if(want('OBJECT') || !(defined wantarray)){
      $self->[0] = CORE::pack($template, @$self);
      $#$self = 0;
      return $self;
   }

   return CORE::pack($template,@$self);
}

# Pops and returns the last element off the array
sub pop{
   my($self) = @_;
   my $popped = CORE::pop(@$self);
   if(want('OBJECT')){ return bless \$popped }
   return $popped;
}

# Prints the contents of the array as a flat list. Optional newline
sub print{
   my($self,$nl) = @_;

   if(reftype($self) eq 'ARRAY'){
      if(wantarray){ return @$self }
      if(defined wantarray){ return \@{$self} }
      CORE::print @$self;
      if($nl){ CORE::print "\n" }
   }
   elsif(reftype($self) eq 'SCALAR'){
      if(defined wantarray){ return $$self }
      CORE::print $$self;
      if($nl){ CORE::print "\n" }
   }
   else{
      CORE::print @$self;
      if($nl){ CORE::print "\n" }
   }
   return $self;
}

# Pushes an element onto the end of the array
sub push{
   my($self,@list) = @_;

   CORE::push(@{$self},@list);

   if(want('OBJECT')){ return $self }
   if(wantarray){ return @$self }
   if(defined wantarray){ return \@{$self} };
}

# Randomizes the order of the contents of the array
# Taken from "The Perl Cookbook"
sub randomize{
   my($self) = @_;
   my($i,$ref,@temp);

   unless( (want('OBJECT')) || (!defined wantarray) ){
      @temp = @{$self};
      $ref = \@temp;
   }
   else{ $ref = $self }

   for($i = @$ref; --$i; ){
      my $j = int rand ($i+1);
      next if $i == $j;
      @$ref[$i,$j] = @$ref[$j,$i];
   }

   if(want('OBJECT')){ return $self }
   if(wantarray){ return @temp }
   if(defined wantarray){ return \@temp }
}

# Reverses the contents of the array
sub reverse{
   my($self) = @_;

   if( (want('OBJECT')) || (!defined wantarray) ){
      @$self = CORE::reverse @$self;
      return $self;
   }

   my @temp = CORE::reverse @$self;
   if(wantarray){ return @temp }
   if(defined wantarray){ return \@temp }
}

# Same as index, except that it returns the position of the
# last occurrence, instead of the first.
sub rindex{
   my($self,$val) = @_;

   # Test for undefined value
   unless(defined($val)){
      for(my $n = $#$self; $n >= 0; $n--){
         unless($self->[$n]){
            if(want('OBJECT')){ return bless \$n }
            if(defined wantarray){ return $n }
         }
      }
   }

   for(my $n = $#$self; $n >= 0; $n--){
      next unless defined $self->[$n];
      if( $self->[$n] =~ /^\Q$val\E$/ ){
         if(want('OBJECT')){ return bless \$n }
         if(defined wantarray){ return $n }
      }
   }
   return undef;

}

# Moves the last element of the array to the front, or vice-versa
sub rotate{
   my($self,$dir) = @_;

   if( (want('OBJECT')) || (!defined wantarray) ){
      unless(defined($dir) && $dir eq 'ftol'){
         CORE::unshift(@$self, CORE::pop(@$self));
         return $self;
      }
      CORE::push(@$self,CORE::shift(@$self));
      return $self;
   }

   my @temp = @$self;
   unless(defined($dir) && $dir eq 'ftol'){
      CORE::unshift(@temp, CORE::pop(@temp));
      if(wantarray){ return @temp }
      if(defined wantarray){ return \@temp }
   }
   CORE::push(@temp,CORE::shift(@temp));
   if(wantarray){ return @temp }
   if(defined wantarray){ return \@temp }
}

# Shifts and returns the first element off the array
sub shift{
   my($self) = @_;
   my $shifted = CORE::shift @$self;
   if(want('OBJECT')){ return bless \$shifted }
   return $shifted;
}

# Sorts the array alphabetically.
sub sort{
   my($self,$coderef) = @_;

   if($coderef){

      # Complements of Sean McAfee
      my $caller = caller();
      local(*a,*b) = do{
         no strict 'refs';
         (*{"${caller}::a"},*{"${caller}::b"});
      };

      if( (want('OBJECT')) || (!defined wantarray) ){
         @$self = CORE::sort $coderef @$self;
         return $self;
      }

      my @sorted = CORE::sort $coderef @$self;
      if(wantarray){ return @sorted }
      if(defined wantarray){ return \@sorted }
   }
   else{
      if( (want('OBJECT')) || (!defined wantarray) ){
         @$self = CORE::sort @$self;
         return $self;
      }
      my @sorted = CORE::sort @$self;
      if(wantarray){ return @sorted }
      if(defined wantarray){ return \@sorted }
   }
}

# Splices a value, or range of values, from the array
sub splice{
   my($self,$offset,$length,@list) = @_;

   no warnings 'uninitialized';

   my @deleted;
   unless(defined($offset)){
      @deleted = CORE::splice(@$self);
      if(want('OBJECT')){ return $self }
      if(wantarray){ return @deleted }
      if(defined wantarray){ return \@deleted }
   }
   unless(defined($length)){
      @deleted = CORE::splice(@$self,$offset);
      if(want('OBJECT')){ return $self }
      if(wantarray){ return @deleted }
      if(defined wantarray){ return \@deleted }
   }
   unless(defined($list[0])){
      @deleted = CORE::splice(@$self,$offset,$length);
      if(want('OBJECT')){ return $self }
      if(wantarray){ return @deleted }
      if(defined wantarray){ return \@deleted }
   }

   @deleted = CORE::splice(@$self,$offset,$length,@list);
   if(want('OBJECT')){ return $self }
   if(wantarray){ return @deleted }
   if(defined wantarray){ return \@deleted }
}

# Returns a list of unique items in the array. It can be chained.

sub unique{
   my($self) = @_;

   my %item;

   CORE::foreach(@$self){ $item{$_}++ }

   if(want('OBJECT') || !(defined wantarray)){
      @$self = keys %item;
      return $self;
   }

   my @temp = keys %item;

   if(wantarray){ return @temp }
   if(defined wantarray){ return \@temp }
}

# Unshifts a value to the front of the array
sub unshift{
   my($self,@list) = @_;
   CORE::unshift(@$self,@list);

   if(want('OBJECT')){ return $self }
   if(wantarray){ return @$self }
   if(defined wantarray){ return \@{$self} };
}

#### OVERLOADED OPERATOR METHODS ####

# Really just a 'push', but needs to handle ops
sub append{
   my($op1, $op2, $reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   CORE::push(@{$op1},@{$op2});

   if(want('OBJECT')){ return $op1 }
   return @$op1 if wantarray;
   return \@{$op1} if defined wantarray;
}

# A union that includes non-unique values (i.e. everything)
sub bag{
   my($op1, $op2, $reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   if(want('OBJECT') || !(defined wantarray)){
      CORE::push(@$op1,@$op2);
      return $op1;
   }
   my @copy = (@$op1,@$op2);
   return @copy if wantarray;
   return \@copy if defined wantarray;
}

# Needs work
sub complement{
   my($op1, $op2, $reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   my(%item1,%item2,@comp);
   CORE::foreach(@$op1){ $item1{$_}++ }
   CORE::foreach(@$op2){ $item2{$_}++ }

   CORE::foreach(keys %item2){
      if($item1{$_}){ next }
      CORE::push(@comp,$_);
   }

   if(want('OBJECT')){ return bless \@comp }
   if(wantarray){ return @comp }
   if(defined wantarray){ return \@comp }
}

# Returns elements in left set that are not in the right set
sub difference{
   my($op1, $op2, $reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   my(%item1,%item2,@diff);
   CORE::foreach(@$op1){ $item1{$_}=$_ }
   CORE::foreach(@$op2){ $item2{$_}=$_ }

   CORE::foreach(keys %item1){
      if(exists $item2{$_}){ next }
      CORE::push(@diff,$item1{$_});
   }

   try
   {
	   if (want('OBJECT') || ! defined wantarray)
	   {
		   @$op1 = @diff;
		   return $op1;
	   }
   };

   if(wantarray){ return @diff }
   if(defined wantarray){ return \@diff }
}

# Returns the elements common to both arrays
sub intersection{
   my($op1, $op2, $reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;
   my($result) = [];

   my($i1, $i2);
   my(%seen);

   CORE::foreach $i1 (0 .. $#$op1){
      CORE::foreach $i2 (0 .. $#$op2){
         # If we have matched this value in @$op2 before,
         # do not match it in the same place again in @$op1.

         next if (defined $seen{$$op2[$i2]} && ($seen{$$op2[$i2]} eq $i1) );

         if ($$op1[$i1] eq $$op2[$i2]){
            CORE::push @$result, $$op1[$i1];

            $seen{$$op2[$i2]} = $i1;
         }
      }
   }

   if(want('OBJECT') || !(defined wantarray)){
      return $result;
   }

   if(wantarray){ return @$result }
   if(defined wantarray){ return $result }
}

# Tests to see if arrays are equal (regardless of order)
sub is_equal{
   my($op1, $op2, $reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   my(%count1, %count2);

   if(scalar(@$op1) != scalar(@$op2)){ return 0 }

   CORE::foreach(@$op1){ $count1{$_}++ }
   CORE::foreach(@$op2){ $count2{$_}++ }

   CORE::foreach my $key(keys %count1){
      return 0 unless CORE::defined($count1{$key});
      return 0 unless CORE::defined($count2{$key});
      if($count1{$key} ne $count2{$key}){ return 0 }
   }
   return 1;
}

# Tests to see if arrays are not equal (order ignored)
sub not_equal{
   my($op1, $op2, $reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   my(%count1, %count2);

   if(scalar(@$op1) != scalar(@$op2)){ return 1 }

   CORE::foreach(@$op1){ $count1{$_}++ }
   CORE::foreach(@$op2){ $count2{$_}++ }

   CORE::foreach my $key(keys %count1){
      return 1 unless CORE::defined($count1{$key});
      return 1 unless CORE::defined($count2{$key});
      if($count1{$key} ne $count2{$key}){ return 1 }
   }
   return 0;
}

# Returns elements in one set or the other, but not both
sub symmetric_difference{
   my($op1, $op2, $reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   my(%count1,%count2,%count3,@symdiff);
   @count1{@$op1} = (1) x @$op1;
   @count2{@$op2} = (1) x @$op2;

   CORE::foreach(CORE::keys %count1,CORE::keys %count2){ $count3{$_}++ }

   if(want('OBJECT') || !(defined wantarray)){
      @$op1 = CORE::grep{$count3{$_} == 1} CORE::keys %count3;
      return $op1;
   }

   @symdiff = CORE::grep{$count3{$_} == 1} CORE::keys %count3;
   if(wantarray){ return @symdiff }
   if(defined wantarray){ return \@symdiff }
}

*sym_diff = \&symmetric_difference;

# Returns the union of two arrays, non-unique values excluded
sub union{
   my($op1, $op2, $reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   my %union;
   CORE::foreach(@$op1, @$op2){ $union{$_}++ }

   if(want('OBJECT') || !(defined wantarray)){
      @$op1 = CORE::keys %union;
      return $op1;
   }

   my @union = CORE::keys %union;

   if(wantarray){ return @union }
   if(defined wantarray){ return \@union }
}
1;
__END__

=head1 NAME

Set::Array - Arrays as objects with lots of handy methods

=head1 SYNOPSIS

C<< my $sao1 = Set::Array->new(1,2,4,"hello",undef); >>

C<< my $sao2 = Set::Array->new(qw(a b c a b c)); >>

C<< print $sao1->length; # prints 5 >>

C<< $sao2->unique->length->print; # prints 3 >>

=head1 PREREQUISITES

Perl 5.6 or later

The 'Want' module by Robin Houston.  Available on CPAN.

=head1 DESCRIPTION

Set::Array allows you to create arrays as objects and use OO-style methods
on them.  Many convenient methods are provided here that appear in the FAQs,
the Perl Cookbook or posts from comp.lang.perl.misc.
In addition, there are Set methods with corresponding (overloaded)
operators for the purpose of Set comparison, i.e. B<+>, B<==>, etc.

The purpose is to provide built-in methods for operations that people are
always asking how to do, and which already exist in languages like Ruby.  This
should (hopefully) improve code readability and/or maintainability.  The
other advantage to this module is method-chaining by which any number of
methods may be called on a single object in a single statement.

=head1 OBJECT BEHAVIOR

The exact behavior of the methods depends largely on the calling context.

B<Here are the rules>:

* If a method is called in void context, the object itself is modified.

* If the method called is not the last method in a chain (i.e. it is called
  in object context), the object itself is modified by that method regardless
  of the 'final' context or method call.

* If a method is called in list or scalar context, a list or list refererence
  is returned, respectively. The object itself is B<NOT> modified.

Here is a quick example:

C<< my $sao = Set::Array->new(1,2,3,2,3); >>

C<< my @uniq = $sao->unique(); # Object unmodified.  '@uniq' contains 3 values. >>

C<< $sao->unique(); # Object modified, now contains 3 values >>

B<Here are the exceptions>:

* Methods that report a value, such as boolean methods like I<exists()> or
  other methods such as I<at()> or I<as_hash()>, never modify the object.

* The methods I<clear()>, I<delete()>, I<delete_at()>, and I<splice> will
  B<always> modify the object. It seemed much too counterintuitive to call these
  methods in any context without actually deleting/clearing/substituting the items!

* The methods I<shift()> and I<pop()> will modify the object B<AND> return
  the value that was shifted or popped from the array.  Again, it seemed
  much too counterintuitive for something like C<$val = $sao-E<gt>shift> to
  return a value while leaving the object unchanged.  If you
  really want the first or last value without modifying the object, you
  can always use the I<first()> or I<last()> method, respectively.

* The methods I<cshift()> and I<cpop()> (for chainable-shift and chainable-pop)
  will modify the object B<and return the object>. I.e. the value shifted or popped
  is discarded. See the docs below or the code at the end of t/test.t for examples.

* The I<join()> method always returns a string and is really meant for use
  in conjunction with the I<print()> method.

=head1 BOOLEAN METHODS

In the following sections, the brackets in [val] indicate that val is a I<optional> parameter.

=head2 exists([val])

Returns 1 if I<val> exists within the array, 0 otherwise.

If no value (or I<undef>) is passed, then this method will test for the existence of undefined values within the array.

=head2 is_empty()

Returns 1 if the array is empty, 0 otherwise.  Empty is
defined as having a length of 0.

=head1 STANDARD METHODS

=head2 at(index)

Returns the item at the given index (or I<undef>).

A negative index may be used to count from the end of the array.

If no value (or I<undef>) is specified, it will look for the first item
that is not defined.

=head2 bag($other_set, $reverse)

Returns the union of both sets, including duplicates (i.e. everything).

Setting C<$reverse> to 1 reverses the sets as the first step in the method.

Note: It does not reverse the contents of the sets.

See L</General Notes> for the set of such methods, including a list of overloaded operators.

=head2 clear([1])

Empties the array (i.e. length becomes 0).

You may pass a I<1> to this method to set each element of the array to I<undef> rather
than truly empty it.

=head2 compact()

=over 4

=item o In scalar context

Returns an array ref of defined items.

The object is not modified.

=item o In list context

Returns an array of defined items.

The object is not modified.

=item o In chained context

Returns the object.

The object I<is> modified if it contains undefined items.

=back

=head2 count([val])

Returns the number of instances of I<val> within the array.

If I<val> is not specified (or is I<undef>), the method will return the number of undefined values within the array.

=head2 cpop()

The 'c' stands for 'chainable' pop.

Removes I<and discards> the last element of the array.

Returns I<the object>.

	Set::Array -> new(1, 2, 3, 4, 5) -> cpop -> join -> print;

prints 1,2,3,4.

See also cshift(), pop() and shift().

=head2 cshift()

The 'c' stands for 'chainable' shift.

Removes I<and discards> the first element of the array.

Returns I<the object>.

	Set::Array -> new(1, 2, 3, 4, 5) -> cshift -> join -> print;

prints 2,3,4,5.

See also cpop(), pop() and shift().

=head2 delete(@list)

Deletes all items within the object that match I<@list>.

This method will die if I<@list> is not defined.

If your goal is to delete undefined values from your object, use the L</compact()> method instead.

This method always modifies the object, if elements in @list match elements in the object.

=over 4

=item o In scalar context

Returns an array ref of unique items.

=item o In list context

Returns an array of unique items.

=item o In chained context

Returns the object.

=back

=head2 delete_at(index, [index])

Deletes the item at the specified index.

If a second index is specified, a range of items is deleted.

You may use -1 or the string 'end' to refer to the last element of the array.

=head2 difference($one, $two, $reverse)

Returns all elements in the left set that are not in the right set.

Setting C<$reverse> to 1 reverses the sets as the first step in the method.

Note: It does not reverse the contents of the sets.

See L</General Notes> for the set of such methods, including a list of overloaded operators.

Study the sample code below carefully, since all of $set1, $set8 and $set9 get changed, perhaps when you were not
expecting them to be.

There is a problem however, with 2 bugs in the Want module (V 0.20), relating to want('OBJECT') and wantref() both causing segfaults.

So, I have used Try::Tiny to capture a call to want('OBJECT') in sub difference().

If an error is thrown, I just ignore it. This is horribly tacky, but after waiting 7 years (it is now 2012-03-07)
I have given up on expecting patches to Want.

Sample code:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Set::Array;

	# -------------

	my($set1) = Set::Array -> new(qw(abc def ghi jkl mno) );
	my($set8) = Set::Array -> new(@$set1);           # Duplicate for later.
	my($set9) = Set::Array -> new(@$set1);           # Duplicate for later.
	my($set2) = Set::Array -> new(qw(def jkl pqr));
	my($set3) = $set1 - $set2;                       # Changes $set1. $set3 is a set.
	my($set4) = Set::Array -> new(@{$set8 - $set2}); # Changes $set8. $set4 is a set.
	my(@set5) = $set9 -> difference($set2);          # Changes $set9. $set5 is an array.

	print '1: ', join(', ', @$set3), ". \n";
	print '2: ', join(', ', @{$set4 -> print}), ". \n";
	print '3: ', join(', ', $set4 -> print), ". \n";
	print '4: ', join(', ', @set5), ". \n";

The last 4 lines all produce the same, correct, output, so any of $set3, $set4 or $set5 is what you want.

See t/difference.pl.

=head2 duplicates()

Returns a list of N-1 elements for each element which appears N times in the set.

For example, if you have set "X X Y Y Y", this method would return the list "X Y Y".

If you want the output to be "X Y", see L</unique()>.

=over 4

=item o In scalar context

Returns an array ref of duplicated items.

The object is not modified.

=item o In list context

Returns an array of duplicated items.

The object is not modified.

=item o In chained context

Returns the object.

The object I<is> modified if it contains duplicated items.

=back

=head2 fill(val, [start], [length])

Sets the selected elements of the array (which may be the entire array) to I<val>.

The default value for I<start> is 0.

If length is not specified the entire array, however long it may be, will be filled.

A range may also be used for the I<start> parameter. A range must be a quoted string in '0..999' format.

E.g. C<< $sao->fill('x', '3..65535'); >>

The array length/size may not be expanded with this call - it is only meant to
fill in already-existing elements.

=head2 first()

Returns the first element of the array (or undef).

=head2 flatten()

Causes a one-dimensional flattening of the array, recursively.

That is, for every element that is an array (or hash, or a ref to either an array or hash),
extract its elements into the array.

E.g. C<< my $sa = Set::Array-E<gt>new([1,3,2],{one=>'a',two=>'b'},x,y,z); >>

C<< $sao-E<gt>flatten->join(',')->print; # prints "1,3,2,one,a,two,b,x,y,z" >>

=head2 foreach(sub ref)

Iterates over an array, executing the subroutine for each element in the array.

If you wish to modify or otherwise act directly on the contents of the array, use B<$_> within
your sub reference.

E.g. To increment all elements in the array by one...

C<< $sao-E<gt>foreach(sub{ ++$_ }); >>

=head2 get()

This is an alias for the B<indices()> method.

=head2 index(val)

Returns the index of the first element of the array object that contains I<val>.

Returns I<undef> if no value is found.

Note that there is no dereferencing here so if you are looking for an item
nested within a ref, use the I<flatten> method first.

=head2 indices(val1, [val2], [valN])

Returns an array consisting of the elements at the specified indices, or I<undef> if the element
is out of range.

A range may also be used for each of the <valN> parameters. A range must be a quoted string in '0..999' format.

=head2 intersection($other_set)

Returns all elements common to both sets.

Note: It does not eliminate duplicates. Call L</unique()> if that is what you want.

You are strongly encouraged to examine line 19 of both t/intersection.1.pl and t/intersection.2.pl.

Setting C<$reverse> to 1 reverses the sets as the first step in the method.

Note: It does not reverse the contents of the sets.

See L</General Notes> for the set of such methods, including a list of overloaded operators.

=head2 is_equal($other_set)

Tests to see if the 2 sets are equal (regardless of order). Returns 1 for equal and 0 for not equal.

Setting C<$reverse> to 1 reverses the sets as the first step in the method.

Since order is ignored, this parameter is irrelevant.

Note: It does not reverse the contents of the sets.

See L</General Notes> for the set of such methods, including a list of overloaded operators.

See also L</not_equal($other_set)>.

=head2 join([string])

Joins the elements of the list into a single string with the elements separated by the value of I<string>.

Useful in conjunction with the I<print()> method.

If no string is specified, then I<string> defaults to a comma.

e.g. C<< $sao-E<gt>join('-')-E<gt>print; >>

=head2 last()

Returns the last element of the array (or I<undef>).

=head2 length()

Returns the number of elements within the array.

=head2 max()

Returns the maximum value of an array.

No effort is made to check for non-numeric data.

=head2 new()

This is the constructor.

See L</difference($one, $two, $reverse)> for sample code.

See also L</flatten()> for converting arrayrefs and hashrefs into lists.

=head2 not_equal($other_set)

Tests to see if the 2 sets are not equal (regardless of order). Returns 1 for not equal and 0 for equal.

Setting C<$reverse> to 1 reverses the sets as the first step in the method.

Since order is ignored, this parameter is irrelevant.

Note: It does not reverse the contents of the sets.

See L</General Notes> for the set of such methods, including a list of overloaded operators.

See also L</is_equal($other_set)>.

=head2 pack(template)

Packs the contents of the array into a string (in scalar context) or a single array element (in object
or void context).

=head2 pop()

Removes the last element from the array.

Returns the popped element.

See also cpop(), cshift() and shift().

=head2 print([1])

Prints the contents of the array.

If a I<1> is provided as an argument, the output will automatically be terminated with a newline.

This also doubles as a 'contents' method, if you just want to make a copy
of the array, e.g. my @copy = $sao-E<gt>print;

Can be called in void or list context, e.g.

C<< $sao->print(); # or... >>
C<< print "Contents of array are: ", $sao->print(); >>

=head2 push(list)

Adds I<list> to the end of the array, where I<list> is either a scalar value or a list.

Returns an array or array reference in list or scalar context, respectively.

Note that it does B<not> return the length in scalar context. Use the I<length> method for that.

=head2 reverse()

=over 4

=item o In scalar context

Returns an array ref of the items in the object, reversed.

The object is not modified.

=item o In list context

Returns an array of the items in the object, reversed.

The object is not modified.

=item o In chained context

Returns the object.

The object I<is> modified, with its items being reversed.

=back

=head2 rindex(val)

Similar to the I<index()> method, except that it returns the index of the last I<val> found within the array.

Returns I<undef> if no value is found.

=head2 set(index, value)

Sets the element at I<index> to I<value>, replacing whatever may have already been there.

=head2 shift()

Shifts off the first element of the array and returns the shifted element.

See also cpop(), cshift() and pop().

=head2 sort([coderef])

Sorts the contents of the array in alphabetical order, or in the order specified by the optional I<coderef>.

=over 4

=item o In scalar context

Returns an array ref of the items in the object, sorted.

The object is not modified.

=item o In list context

Returns an array of the items in the object, sorted.

The object is not modified.

=item o In chained context

Returns the object.

The object I<is> modified by sorting its items.

=back

Use your standard I<$a> and I<$b> variables within your sort sub:

Program:

	#!/usr/bin/env perl

	use Set::Array;

	# -------------

	my $s = Set::Array->new(
		{ name => 'Berger', salary => 15000 },
		{ name => 'Berger', salary => 20000 },
		{ name => 'Vera', salary => 25000 },
	);

	my($subref) = sub{ $b->{name} cmp $a->{name} || $b->{salary} <=> $a->{salary} };
	my(@h)      = $s->sort($subref);

	for my $h (@h)
	{
		print "Name: $$h{name}. Salary: $$h{salary}. \n";
	}

Output (because the sort subref puts $b before $a for name and salary):

	Name: Vera. Salary: 25000.
	Name: Berger. Salary: 20000.
	Name: Berger. Salary: 15000.

=head2 splice([offset], [length], [list])

Splice the array starting at position I<offset> up to I<length> elements, and replace them with I<list>.

If no list is provided, all elements are deleted.

If length is omitted, everything from I<offset> onward is removed.

Returns an array or array ref in list or scalar context, respectively.

This method B<always> modifies the object, regardless of context.

If your goal was to grab a range of values without modifying the object, use the I<indices> method instead.

=head2 unique()

Returns a list of 1 element for each element which appears N times in the set.

For example, if you have set "X X Y Y Y", this method would return the list "X Y".

If you want the output to be "X Y Y", see L</duplicates()>.

=over 4

=item o In scalar context

Returns an array ref of unique items.

The object is not modified.

=item o In list context

Returns an array of unique items.

The object is not modified.

=item o In chained context

Returns the object.

The object I<is> modified if it contains duplicated items.

=back

=head2 unshift(list)

Prepends a scalar or list to array.

Note that this method returns an array or array reference in list or scalar context, respectively.

It does B<not> return the length of the array in scalar context. Use the I<length> method for that.

=head1 ODDBALL METHODS

=head2 as_hash([$option])

Returns a hash based on the current array, with each
even numbered element (including 0) serving as the key, and each odd element
serving as the value.

This can be switched by using $option, and setting it to I<odd>,
in which case the even values serve as the values, and the odd elements serve as the keys.

The default value of $option is I<even>.

Of course, if you do not care about insertion order, you could just as well
do something like, C<< $sao->reverse->as_hash; >>

This method does not actually modify the object itself in any way. It just returns a plain
hash in list context or a hash reference in scalar context. The reference
is not blessed, therefore if this method is called as part of a chain, it
must be the last method called.

I<$option> can be specified in various ways:

=over 4

=item undef

When you do not supply a value for this parameter, the default is I<even>.

=item 'odd' or 'even'

The value may be a string.

This possibility was added in V 0.18.

This is now the recommended alternative.

=item {key_option => 'odd'} or {key_option => 'even'}

The value may be a hash ref, with 'key_option' as the hash key.

This possibility was added in V 0.18.

=item (key_option => 'odd') or (key_option => 'even')

The value may be a hash, with 'key_option' as the hash key.

This was the original (badly-documented) alternative to undef, and it still supported in order to
make the code backwards-compatible.

=back

=head2 impose([append/prepend], string)

Appends or prepends the specified string to each element in the array.

Specify the method with either 'append' or 'prepend'.

The default is 'append'.

=head2 randomize()

Randomizes the order of the elements within the array.

=head2 rotate(direction)

Moves the last item of the list to the front and shifts all other elements one to the right, or vice-versa,
depending on what you pass as the direction - 'ftol' (first to last) or 'ltof' (last to first).

The default is 'ltof'.

e.g.
my $sao = Set::Array-E<gt>new(1,2,3);

$sao->rotate(); # order is now 3,1,2

$sao->rotate('ftol'); # order is back to 1,2,3

=head2 to_hash()

This is an alias for I<as_hash()>.


=head1 OVERLOADED (COMPARISON) OPERATORS

=head2 General Notes

For overloaded operators you may pass a Set::Array object, or just a normal
array reference (blessed or not) in any combination, so long as one is a
Set::Array object.  You may use either the operator or the equivalent method
call.

Warning: You should always experiment with these methods before using them in production.
Why? Because you may have unrealistic expectations that they I<automatially> eliminate duplicates, for example.
See the L</FAQ> for more.

Examples (using the '==' operator or 'is_equal' method):

my $sao1 = Set::Array->new(1,2,3,4,5);

my $sao2 = Set::Array->new(1,2,3,4,5);

my $ref1 = [1,2,3,4,5];

if($sao1 == $sao2)...         # valid

if($sao1 == $ref1)...         # valid

if($ref1 == $sao2)...         # valid

if($sao1->is_equal($sao2))... # valid

if($sao1->is_equal($ref1))... # valid

All of these operations return either a boolean value (for equality operators) or
an array (in list context) or array reference (in scalar context).

B<&> or B<bag> - The union of both sets, including duplicates.

B<-> or B<difference> - Returns all elements in the left set that are not in
the right set. See L</difference($one, $two)> for details.

B<==> or B<is_equal> - This tests for equality of the content of the sets,
though ignores order. Thus, comparing (1,2,3) and (3,1,2) will yield a I<true>
result.

B<!=> or B<not_equal> - Tests for inequality of the content of the sets.  Again,
order is ignored.

B<*> or B<intersection> - Returns all elements that are common to both sets.

Be warned that that line says 'all elements', not 'unique elements'. You can call L</unique>
is you need just the unique elements.

See t/intersection.*.pl for sample code with and without calling unique().

B<%> or B<symmetric_difference> or B<symm_diff> - Returns all elements that are in one set
or the other, but not both.  Opposite of intersection.

B<+> or B<union> - Returns the union of both sets.  Duplicates excluded.

=head1 FAQ

=head2 Why does the intersection() method include duplicates in the output?

Because it is documented to do that. The docs above say:

"Returns all elements that are common to both sets.

Be warned that that line says 'all elements', not 'unique elements'. You can call L</unique()>
is you need just the unique elements."

Those statements means what they says!

See t/intersection.*.pl for sample code with and without calling unique().

The following section, C<EXAMPLES>, contains other types of FAQ items.

=head1 EXAMPLES

For our examples, I will create 3 different objects

my $sao1 = Set::Array->new(1,2,3,a,b,c,1,2,3);

my $sao2 = Set::Array->new(1,undef,2,undef,3,undef);

my $sao3 = Set::Array->new(1,2,3,['a','b','c'],{name=>"Dan"});

B<How do I...>

I<get the number of unique elements within the array?>

C<$sao1-E<gt>unique()-E<gt>length();>

I<count the number of non-undef elements within the array?>

C<$sao2-E<gt>compact()-E<gt>length();>

I<count the number of unique elements within an array, excluding undef?>

C<$sao2-E<gt>compact()-E<gt>unique()-E<gt>length();>

I<print a range of indices?>

C<$sao1-E<gt>indices('0..2')-E<gt>print();>

I<test to see if two Set::Array objects are equal?>

C<if($sao1 == $sao2){ ... }>

C<if($sao1-E<gt>is_equal($sao2){ ... } # Same thing>

I<fill an array with a value, but only if it is not empty?>

C<if(!$sao1-E<gt>is_empty()){ $sao1-E<gt>fill('x') }>

I<shift an element off the array and return the shifted value?>

C<my $val = $sao1-E<gt>shift())>

I<shift an element off the array and return the array?>

C<my @array = $sao1-E<gt>delete_at(0)>

I<flatten an array and return a hash based on now-flattened array?, with odd
elements as the key?>

C<my %hash = $sao3-E<gt>flatten()-E<gt>reverse-E<gt>as_hash();>

I<delete all elements within an array?>

C<$sao3-E<gt>clear();>

C<$sao3-E<gt>splice();>

I<modify the object AND assign a value at the same time?>

C<my @unique = $sao1-E<gt>unique-E<gt>print;>

=head1 KNOWN BUGS

There is a bug in the I<Want-0.05> module that currently prevents the use of
most of the overloaded operators, though you can still use the corresponding
method names.  The equality operators B<==> and B<!=> should work, however.

There are still bugs in Want V 0.20. See the discussion of L</difference($one, $two)> for details.

=head1 FUTURE PLANS

Anyone want a built-in 'permute()' method?

I am always on the lookout for faster algorithms.  If you heve looked at the code
for a particular method and you know of a faster way, please email me.  Be
prepared to backup your claims with benchmarks (and the benchmark code you
used).  Tests on more than one operating system are preferable.  No, I<map> is
not always faster - I<foreach> loops usually are in my experience.

More flexibility with the foreach method (perhaps with iterators?).

More tests.

=head1 THANKS

Thanks to all the kind (and sometimes grumpy) folks at comp.lang.perl.misc who
helped me with problems and ideas I had.

Thanks also to Robin Houston for the 'Want' module!  Where would method
chaining be without it?

=head1 AUTHOR

Original author: Daniel Berger
djberg96 at hotmail dot com
imperator on IRC (freenode)

Maintainer since V 0.12: Ron Savage I<E<lt>ron@savage.net.auE<gt>> (in 2005).

Home page: http://savage.net.au/index.html

=cut
