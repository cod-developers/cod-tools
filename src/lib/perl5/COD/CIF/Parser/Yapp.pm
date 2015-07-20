####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package COD::CIF::Parser::Yapp;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 15 "Yapp.yp"

use warnings;
use COD::ShowStruct;
use FileHandle;
use COD::Precision;

$COD::CIF::Parser::Yapp::version = '1.0';

my $SVNID = '$Id: Yapp.yp 3563 2015-07-20 18:27:55Z antanas $';

# 0 - no debug
# 1 - only YAPP output (type -> value)
# 2 - lex & yapp output
# 3 - generated array dump
$COD::CIF::Parser::Yapp::debug = 0;

sub merge_data_lists($$$)
{
    my $parser = $_[0];
    my $list = $_[1];
    my $item = $_[2];

    for my $tag (@{$item->{tags}}) {

        if( exists $list->{values}{$tag} )  {
            $_[0]->YYData->{VARS}{lines}--;
            if( ( $_[0]->{USER}{OPTIONS}{fix_errors} ||
                  $_[0]->{USER}{OPTIONS}{fix_duplicate_tags_with_same_values} ) &&
                @{$list->{values}{$tag}} == 1 &&
                @{$item->{values}{$tag}} == 1 &&
                $item->{values}{$tag}[0] eq $list->{values}{$tag}[0] ) {
                $parser->YYData->{ERRMSG} =
                    "tag $tag appears more than once with the same value";
                _Warning( $parser );
                next
            } elsif( ( $_[0]->{USER}{OPTIONS}{fix_errors} ||
                       $_[0]->{USER}{OPTIONS}{fix_duplicate_tags_with_empty_values} ) &&
                     @{$list->{values}{$tag}} == 1 &&
                     @{$item->{values}{$tag}} == 1 &&
                     $item->{values}{$tag}[0] =~ /^(\s*\?\s*)$/ ) {
                $parser->YYData->{ERRMSG} =
                    "tag $tag appears more than once, the second occurence " .
                    "'$1' is ignored";
                _Warning( $parser );
                next
            } elsif( ( $_[0]->{USER}{OPTIONS}{fix_errors} ||
                       $_[0]->{USER}{OPTIONS}{fix_duplicate_tags_with_empty_values} ) &&
                     @{$list->{values}{$tag}} == 1 &&
                     @{$item->{values}{$tag}} == 1 &&
                     $list->{values}{$tag}[0] =~ /^(\s*\?\s*)$/ ) {
                $parser->YYData->{ERRMSG} =
                    "tag $tag appears more than once, " .
                    "the previous value '$1' is overwritten";
                _Warning( $parser );
            } else {
                $parser->YYData->{ERRMSG} =
                    "tag $tag appears more than once";
                # Don't call $parser->YYError() since it clears the Yapp stack.
                # For now, let's call _Error() directly:
                _Error( $parser, { line => $_[0]->YYData->{VARS}{token_prev_line} } );
            }
            $_[0]->YYData->{VARS}{lines}++;
        }

        push( @{$list->{tags}}, $tag );

        $list->{values}{$tag} = $item->{values}{$tag};
        $list->{types}{$tag}  = $item->{types}{$tag};

        if( exists $item->{precisions}{$tag} ) {
            $list->{precisions}{$tag} = $item->{precisions}{$tag};
        }
    }

    if( exists $item->{loops} ) {
        if( defined $list->{loops} ) {
            push( @{$list->{loops}}, $item->{loops}[0] );
        } else {
            $list->{loops} = [ $item->{loops}[0] ];
        }
    }

    if( exists $item->{inloop} ) {
        my $loop_nr = $#{$list->{loops}};
        for my $key (keys %{$item->{inloop}} ) {
            $list->{inloop}{$key} = $loop_nr;
        }
    }

    if( exists $item->{save_blocks} ) {
        if( defined $list->{save_blocks} ) {
            push( @{$list->{save_blocks}}, $item->{save_blocks}[0] );
        } else {
            $list->{save_blocks} = [ $item->{save_blocks}[0] ];
        }
    }

    return $list;
}



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'TEXT_FIELD' => 17,
			'TAG' => 3,
			'INT' => 18,
			'DQSTRING' => 5,
			'SAVE_HEAD' => 9,
			'SQSTRING' => 8,
			'DATA_' => 12,
			'textfield' => 13,
			'LOOP_' => 14,
			'UQSTRING' => 15,
			'FLOAT' => 16
		},
		DEFAULT => -1,
		GOTOS => {
			'save_block' => 1,
			'data_item' => 4,
			'number' => 2,
			'cif_value' => 7,
			'string' => 6,
			'cif_file' => 19,
			'data_block_list' => 11,
			'loop' => 10,
			'data_block' => 20,
			'cif_entry' => 21,
			'data_block_head' => 22,
			'headerless_data_block' => 23,
			'stray_cif_value_list' => 24,
			'save_item' => 25
		}
	},
	{#State 1
		DEFAULT => -22
	},
	{#State 2
		DEFAULT => -39
	},
	{#State 3
		ACTIONS => {
			'TEXT_FIELD' => 17,
			'textfield' => 13,
			'UQSTRING' => 15,
			'INT' => 18,
			'DQSTRING' => 5,
			'FLOAT' => 16,
			'SQSTRING' => 8
		},
		GOTOS => {
			'number' => 2,
			'cif_value' => 26,
			'string' => 6
		}
	},
	{#State 4
		DEFAULT => -12,
		GOTOS => {
			'@2-1' => 27
		}
	},
	{#State 5
		DEFAULT => -42
	},
	{#State 6
		DEFAULT => -38
	},
	{#State 7
		ACTIONS => {
			'' => -7,
			'DATA_' => -7
		},
		DEFAULT => -8,
		GOTOS => {
			'@1-1' => 28
		}
	},
	{#State 8
		DEFAULT => -41
	},
	{#State 9
		ACTIONS => {
			'LOOP_' => 14,
			'TAG' => 3
		},
		GOTOS => {
			'cif_entry' => 21,
			'save_item_list' => 29,
			'save_item' => 30,
			'loop' => 10
		}
	},
	{#State 10
		DEFAULT => -26
	},
	{#State 11
		ACTIONS => {
			'DATA_' => 12
		},
		DEFAULT => -2,
		GOTOS => {
			'data_block' => 31,
			'data_block_head' => 22
		}
	},
	{#State 12
		ACTIONS => {
			'' => -18,
			'TAG' => -18,
			'SAVE_HEAD' => -18,
			'DATA_' => -18,
			'LOOP_' => -18
		},
		DEFAULT => -19,
		GOTOS => {
			'@3-1' => 32
		}
	},
	{#State 13
		DEFAULT => -40
	},
	{#State 14
		ACTIONS => {
			'TAG' => 34
		},
		GOTOS => {
			'loop_tags' => 33
		}
	},
	{#State 15
		DEFAULT => -43
	},
	{#State 16
		DEFAULT => -45
	},
	{#State 17
		DEFAULT => -44
	},
	{#State 18
		DEFAULT => -46
	},
	{#State 19
		ACTIONS => {
			'' => 35
		}
	},
	{#State 20
		DEFAULT => -11
	},
	{#State 21
		DEFAULT => -25
	},
	{#State 22
		ACTIONS => {
			'LOOP_' => 14,
			'TAG' => 3,
			'SAVE_HEAD' => 9
		},
		DEFAULT => -15,
		GOTOS => {
			'save_block' => 1,
			'cif_entry' => 21,
			'data_item' => 36,
			'data_item_list' => 37,
			'save_item' => 25,
			'loop' => 10
		}
	},
	{#State 23
		ACTIONS => {
			'DATA_' => 12
		},
		DEFAULT => -3,
		GOTOS => {
			'data_block' => 20,
			'data_block_head' => 22,
			'data_block_list' => 38
		}
	},
	{#State 24
		ACTIONS => {
			'DATA_' => 12
		},
		DEFAULT => -5,
		GOTOS => {
			'data_block' => 20,
			'data_block_head' => 22,
			'data_block_list' => 39
		}
	},
	{#State 25
		DEFAULT => -21
	},
	{#State 26
		ACTIONS => {
			'' => -27,
			'TAG' => -27,
			'SAVE_HEAD' => -27,
			'DATA_' => -27,
			'LOOP_' => -27,
			'SAVE_FOOT' => -27
		},
		DEFAULT => -28,
		GOTOS => {
			'@4-2' => 40
		}
	},
	{#State 27
		ACTIONS => {
			'LOOP_' => 14,
			'TAG' => 3,
			'SAVE_HEAD' => 9
		},
		GOTOS => {
			'save_block' => 1,
			'cif_entry' => 21,
			'data_item' => 36,
			'data_item_list' => 41,
			'save_item' => 25,
			'loop' => 10
		}
	},
	{#State 28
		ACTIONS => {
			'TEXT_FIELD' => 17,
			'textfield' => 13,
			'UQSTRING' => 15,
			'INT' => 18,
			'DQSTRING' => 5,
			'FLOAT' => 16,
			'SQSTRING' => 8
		},
		GOTOS => {
			'number' => 2,
			'cif_value' => 42,
			'string' => 6,
			'cif_value_list' => 43
		}
	},
	{#State 29
		ACTIONS => {
			'LOOP_' => 14,
			'TAG' => 3,
			'SAVE_FOOT' => 44
		},
		GOTOS => {
			'cif_entry' => 21,
			'save_item' => 45,
			'loop' => 10
		}
	},
	{#State 30
		DEFAULT => -24
	},
	{#State 31
		DEFAULT => -10
	},
	{#State 32
		ACTIONS => {
			'TEXT_FIELD' => 17,
			'textfield' => 13,
			'UQSTRING' => 15,
			'INT' => 18,
			'DQSTRING' => 5,
			'FLOAT' => 16,
			'SQSTRING' => 8
		},
		GOTOS => {
			'number' => 2,
			'cif_value' => 42,
			'string' => 6,
			'cif_value_list' => 46
		}
	},
	{#State 33
		ACTIONS => {
			'TEXT_FIELD' => 17,
			'TAG' => 47,
			'INT' => 18,
			'DQSTRING' => 5,
			'SQSTRING' => 8,
			'textfield' => 13,
			'UQSTRING' => 15,
			'FLOAT' => 16
		},
		GOTOS => {
			'number' => 2,
			'loop_values' => 48,
			'cif_value' => 49,
			'string' => 6
		}
	},
	{#State 34
		DEFAULT => -34
	},
	{#State 35
		DEFAULT => 0
	},
	{#State 36
		DEFAULT => -17
	},
	{#State 37
		ACTIONS => {
			'LOOP_' => 14,
			'TAG' => 3,
			'SAVE_HEAD' => 9
		},
		DEFAULT => -14,
		GOTOS => {
			'save_block' => 1,
			'cif_entry' => 21,
			'data_item' => 50,
			'save_item' => 25,
			'loop' => 10
		}
	},
	{#State 38
		ACTIONS => {
			'DATA_' => 12
		},
		DEFAULT => -4,
		GOTOS => {
			'data_block' => 31,
			'data_block_head' => 22
		}
	},
	{#State 39
		ACTIONS => {
			'DATA_' => 12
		},
		DEFAULT => -6,
		GOTOS => {
			'data_block' => 31,
			'data_block_head' => 22
		}
	},
	{#State 40
		ACTIONS => {
			'TEXT_FIELD' => 17,
			'textfield' => 13,
			'UQSTRING' => 15,
			'INT' => 18,
			'DQSTRING' => 5,
			'FLOAT' => 16,
			'SQSTRING' => 8
		},
		GOTOS => {
			'number' => 2,
			'cif_value' => 42,
			'string' => 6,
			'cif_value_list' => 51
		}
	},
	{#State 41
		ACTIONS => {
			'LOOP_' => 14,
			'TAG' => 3,
			'SAVE_HEAD' => 9
		},
		DEFAULT => -13,
		GOTOS => {
			'save_block' => 1,
			'cif_entry' => 21,
			'data_item' => 50,
			'save_item' => 25,
			'loop' => 10
		}
	},
	{#State 42
		DEFAULT => -30
	},
	{#State 43
		ACTIONS => {
			'TEXT_FIELD' => 17,
			'INT' => 18,
			'DQSTRING' => 5,
			'SQSTRING' => 8,
			'textfield' => 13,
			'UQSTRING' => 15,
			'FLOAT' => 16
		},
		DEFAULT => -9,
		GOTOS => {
			'number' => 2,
			'cif_value' => 52,
			'string' => 6
		}
	},
	{#State 44
		DEFAULT => -37
	},
	{#State 45
		DEFAULT => -23
	},
	{#State 46
		ACTIONS => {
			'TEXT_FIELD' => 17,
			'INT' => 18,
			'DQSTRING' => 5,
			'SQSTRING' => 8,
			'textfield' => 13,
			'UQSTRING' => 15,
			'FLOAT' => 16
		},
		DEFAULT => -20,
		GOTOS => {
			'number' => 2,
			'cif_value' => 52,
			'string' => 6
		}
	},
	{#State 47
		DEFAULT => -33
	},
	{#State 48
		ACTIONS => {
			'TEXT_FIELD' => 17,
			'INT' => 18,
			'DQSTRING' => 5,
			'SQSTRING' => 8,
			'textfield' => 13,
			'UQSTRING' => 15,
			'FLOAT' => 16
		},
		DEFAULT => -32,
		GOTOS => {
			'number' => 2,
			'cif_value' => 53,
			'string' => 6
		}
	},
	{#State 49
		DEFAULT => -36
	},
	{#State 50
		DEFAULT => -16
	},
	{#State 51
		ACTIONS => {
			'TEXT_FIELD' => 17,
			'INT' => 18,
			'DQSTRING' => 5,
			'SQSTRING' => 8,
			'textfield' => 13,
			'UQSTRING' => 15,
			'FLOAT' => 16
		},
		DEFAULT => -29,
		GOTOS => {
			'number' => 2,
			'cif_value' => 52,
			'string' => 6
		}
	},
	{#State 52
		DEFAULT => -31
	},
	{#State 53
		DEFAULT => -35
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'cif_file', 0,
sub
#line 125 "Yapp.yp"
{
            $_[0]->{USER}->{CIFfile} =
                            [ { name => undef, values => {}, tags => [] } ];
        }
	],
	[#Rule 2
		 'cif_file', 1,
sub
#line 130 "Yapp.yp"
{
            if($COD::CIF::Parser::Yapp::debug >= 3)
            {
                showRef($_[1]);
            }
            $_[0]->{USER}->{CIFfile} = $_[1];
        }
	],
	[#Rule 3
		 'cif_file', 1,
sub
#line 138 "Yapp.yp"
{
            my $val = $_[1];
            if($COD::CIF::Parser::Yapp::debug >= 3)
            {
                showRef($_[1]);
            }
            $_[0]->{USER}->{CIFfile} = [ $val ];
        }
	],
	[#Rule 4
		 'cif_file', 2,
sub
#line 147 "Yapp.yp"
{
            my $val = $_[2];
            unshift( @{$val}, $_[1] );
            if($COD::CIF::Parser::Yapp::debug >= 3)
            {
                showRef($_[1]);
            }
            $_[0]->{USER}->{CIFfile} = $val;
        }
	],
	[#Rule 5
		 'cif_file', 1,
sub
#line 158 "Yapp.yp"
{
            $_[0]->{USER}->{CIFfile} = [
                            { name => "", values => {}, tags => [] }
                        ];
        }
	],
	[#Rule 6
		 'cif_file', 2,
sub
#line 165 "Yapp.yp"
{
            $_[0]->{USER}->{CIFfile} = $_[2];
        }
	],
	[#Rule 7
		 'stray_cif_value_list', 1,
sub
#line 172 "Yapp.yp"
{
            $_[0]->YYData->{ERRMSG} = "stray CIF values at the " .
                            "beginning of the input file";
            unless( $_[0]->{USER}{OPTIONS}{fix_errors} ||
                    $_[0]->{USER}{OPTIONS}{fix_data_header} )
            {
                $_[0]->_Error();
            } else {
                $_[0]->_Warning();
            }
        }
	],
	[#Rule 8
		 '@1-1', 0,
sub
#line 184 "Yapp.yp"
{
            $_[0]->YYData->{ERRMSG} = "stray CIF values at the " .
                            "beginning of the input file";
            unless( $_[0]->{USER}{OPTIONS}{fix_errors} ||
                    $_[0]->{USER}{OPTIONS}{fix_data_header} )
            {
                $_[0]->_Error();
            } else {
                $_[0]->_Warning();
            }
        }
	],
	[#Rule 9
		 'stray_cif_value_list', 3, undef
	],
	[#Rule 10
		 'data_block_list', 2,
sub
#line 205 "Yapp.yp"
{
            my $val = $_[1];
            push( @{$val}, $_[2] );
            return $val;
        }
	],
	[#Rule 11
		 'data_block_list', 1,
sub
#line 211 "Yapp.yp"
{
            return [ $_[1] ];
        }
	],
	[#Rule 12
		 '@2-1', 0,
sub
#line 218 "Yapp.yp"
{
            $_[0]->YYData->{ERRMSG} = "no data block heading (i.e." .
                " data_somecif) found";
            $_[0]->YYData->{VARS}{lines}--;
            unless( $_[0]->{USER}{OPTIONS}{fix_errors} ||
                    $_[0]->{USER}{OPTIONS}{fix_data_header} )
            {
                $_[0]->_Error();
            } else {
                $_[0]->_Warning();
            }
                $_[0]->YYData->{VARS}{lines}++;
                return $_[1];
            }
	],
	[#Rule 13
		 'headerless_data_block', 3,
sub
#line 233 "Yapp.yp"
{
            my $list = $_[3];
            my $item = $_[1];
            $list = merge_data_lists( $_[0], $list, $item );
            $list->{name} = "";
            return $list;
        }
	],
	[#Rule 14
		 'data_block', 2,
sub
#line 244 "Yapp.yp"
{
            my $name = $_[1];
            my $val = $_[2];
            $val->{name} = $name;
            return $val;
        }
	],
	[#Rule 15
		 'data_block', 1,
sub
#line 251 "Yapp.yp"
{
            return { name => $_[1], values => {}, tags => [] };
        }
	],
	[#Rule 16
		 'data_item_list', 2,
sub
#line 258 "Yapp.yp"
{
            my $list = $_[1];
            my $item = $_[2];
            $list = merge_data_lists( $_[0], $list, $item );
            return $list;
        }
	],
	[#Rule 17
		 'data_item_list', 1,
sub
#line 265 "Yapp.yp"
{
            my $val = $_[1];
            return $val;
        }
	],
	[#Rule 18
		 'data_block_head', 1,
sub
#line 273 "Yapp.yp"
{
            $_[1] =~ m/^(data_)(.*)/si;
            $_[0]->{USER}->{CURRENT_DATABLOCK} = $2;
            return $2;
        }
	],
	[#Rule 19
		 '@3-1', 0,
sub
#line 279 "Yapp.yp"
{
            $_[1] =~ m/^(data_)(.*)/si;
            $_[0]->{USER}->{CURRENT_DATABLOCK} = $2;
            unless( $_[0]->{USER}{OPTIONS}{fix_errors} ||
                    $_[0]->{USER}{OPTIONS}{fix_datablock_names} ) {
                $_[0]->_Error();
            }
        }
	],
	[#Rule 20
		 'data_block_head', 3,
sub
#line 288 "Yapp.yp"
{
            my $extra_values = join( "_", @{$_[3]} );
            my $datablock_name = $_[0]->{USER}->{CURRENT_DATABLOCK} .
                            "_" . $extra_values;
            $_[0]->{USER}->{CURRENT_DATABLOCK} = $datablock_name;
            if( $_[0]->{USER}{OPTIONS}{fix_errors} ||
                $_[0]->{USER}{OPTIONS}{fix_string_quotes} ) {
                    $_[0]->YYData->{ERRMSG} =
                                "the dataname apparently had spaces in it - " .
                                "replaced spaces by underscores";
                    $_[0]->_Warning(
                                { line =>
                                    $_[0]->YYData->{VARS}{token_prev_line} } );
                }
            return $datablock_name;
        }
	],
	[#Rule 21
		 'data_item', 1,
sub
#line 308 "Yapp.yp"
{
            return $_[1];
        }
	],
	[#Rule 22
		 'data_item', 1,
sub
#line 312 "Yapp.yp"
{
            return $_[1];
        }
	],
	[#Rule 23
		 'save_item_list', 2,
sub
#line 320 "Yapp.yp"
{
            my $list = $_[1];
            my $item = $_[2];
            $list = merge_data_lists( $_[0], $list, $item );
            return $list;
        }
	],
	[#Rule 24
		 'save_item_list', 1,
sub
#line 327 "Yapp.yp"
{
            my $val = $_[1];
            return $val;
        }
	],
	[#Rule 25
		 'save_item', 1,
sub
#line 335 "Yapp.yp"
{
            # Here we convert to new structure:
            my $entry = $_[1];
            my $item = {
                values => {
                    $entry->{name} => [ $entry->{value} ]
                },
                types => {
                    $entry->{name} => [ $entry->{type} ]
                },
                    tags => [ $entry->{name} ]
            };
            if( exists $entry->{precision} ) {
                $item->{precisions} = {
                    $entry->{name} => [ $entry->{precision} ]
                }
            }
            return $item;
        }
	],
	[#Rule 26
		 'save_item', 1,
sub
#line 355 "Yapp.yp"
{
            return $_[1];
        }
	],
	[#Rule 27
		 'cif_entry', 2,
sub
#line 362 "Yapp.yp"
{
            my $val;
            if(defined $_[2]->{precision})
            {
                $val = { name => $_[1],
                         kind => 'TAG',
                         value => $_[2]->{value},
                         type => $_[2]->{type},
                         precision => $_[2]->{precision}
                };
            } else {
                $val = { name => $_[1],
                         kind => 'TAG',
                         value => $_[2]->{value},
                         type => $_[2]->{type}
                };
            }
            if( $COD::CIF::Parser::Yapp::debug >= 1 &&
                $COD::CIF::Parser::Yapp::debug <= 2)
            {
                showRef($val);
            }
            return $val;
        }
	],
	[#Rule 28
		 '@4-2', 0,
sub
#line 388 "Yapp.yp"
{
            unless( $_[0]->{USER}{OPTIONS}{fix_errors} ||
                    $_[0]->{USER}{OPTIONS}{fix_string_quotes} ) {
                $_[0]->_Error();
            }
        }
	],
	[#Rule 29
		 'cif_entry', 4,
sub
#line 395 "Yapp.yp"
{
            if( $_[0]->{USER}{OPTIONS}{fix_errors} ||
                $_[0]->{USER}{OPTIONS}{fix_string_quotes} ) {
                $_[0]->YYData->{ERRMSG} = "string with spaces without quotes";
                $_[0]->_Warning( { line => $_[0]->YYData->{VARS}{token_prev_line} } );
            }
            my $val = { name => $_[1],
                        kind => 'TAG',
                        value => join( " ", $_[2]->{value}, @{$_[4]} ),
                        type => 'SQSTRING'
                      };
            if( $COD::CIF::Parser::Yapp::debug >= 1 &&
                $COD::CIF::Parser::Yapp::debug <= 2 ) {
                showRef($val);
            }
            return $val;
        }
	],
	[#Rule 30
		 'cif_value_list', 1,
sub
#line 416 "Yapp.yp"
{
        my $values = [ $_[1]->{value} ];
        return $values;
    }
	],
	[#Rule 31
		 'cif_value_list', 2,
sub
#line 421 "Yapp.yp"
{
        my $values = [ @{$_[1]}, $_[2]->{value} ];
        return $values;
    }
	],
	[#Rule 32
		 'loop', 3,
sub
#line 429 "Yapp.yp"
{
            my $val = {};
            my $tags = $_[2];
            my @values = @{$_[3]};
            my %has_precisions;

            ## push( @{$val->{loops}}, $tags );
            $val->{loops} = [ [ @{$tags} ] ];
            $val->{tags} = $tags;

        VALUES:
            while( int( @values ) > 0 ) {
                for my $tag (@{$tags}) {
                    my $value = shift( @values );
                    if( defined $value ) {
                        push( @{$val->{values}{$tag}}, $value->{value} );
                        push( @{$val->{types}{$tag}},  $value->{type} );
                        if( exists $value->{precision} ) {
                            push( @{$val->{precisions}{$tag}},
                                  $value->{precision} );
                            $has_precisions{$tag} = 1;
                        } else {
                            push( @{$val->{precisions}{$tag}}, undef );
                        }
                        $val->{inloop}{$tag} = 0;
                    } else {
                        $_[0]->YYData->{ERRMSG} =
                            "wrong number of elements in the " .
                            "loop block starting in line " .
                        $_[0]->YYData->{VARS}{loop_begin};
                        $_[0]->YYError();
                        last VALUES;
                    }
                }
            }

            foreach my $tag (@{$tags}) {
                if ( !defined $has_precisions{$tag} ) {
                    $val->{precisions}{$tag} = undef;
                }
            }

        return $val;
        }
	],
	[#Rule 33
		 'loop_tags', 2,
sub
#line 477 "Yapp.yp"
{
            my $val = $_[1];
            push( @{$val}, $_[2] );
            return $val;
        }
	],
	[#Rule 34
		 'loop_tags', 1,
sub
#line 483 "Yapp.yp"
{
            my $val = [ $_[1] ];
            return $val;
        }
	],
	[#Rule 35
		 'loop_values', 2,
sub
#line 491 "Yapp.yp"
{
            my $arr = $_[1];
            my $val = $_[2];
            push( @{$arr}, $val );
            return $arr;
        }
	],
	[#Rule 36
		 'loop_values', 1,
sub
#line 498 "Yapp.yp"
{
            my $val = $_[1];
            return [ $val ];
    }
	],
	[#Rule 37
		 'save_block', 3,
sub
#line 506 "Yapp.yp"
{
            my $val = {
                save_blocks => [
                    {
                        name => $_[1],
                        %{$_[2]}
                    }
                ]
            };
            return $val;
        }
	],
	[#Rule 38
		 'cif_value', 1,
sub
#line 521 "Yapp.yp"
{
            if( $COD::CIF::Parser::Yapp::debug >= 1 &&
                $COD::CIF::Parser::Yapp::debug <= 2 )
            {
                print $_[1]->{type} . "\t->\t"
                    . $_[1]->{value} . "\n"
            }
            $_[1];
        }
	],
	[#Rule 39
		 'cif_value', 1,
sub
#line 531 "Yapp.yp"
{
            if( $COD::CIF::Parser::Yapp::debug >= 1 &&
                $COD::CIF::Parser::Yapp::debug <= 2 )
            {
                print $_[1]->{type} . "\t\t->\t"
                    . $_[1]->{value} . " -- "
                    . $_[1]->{precision}
                    . "\n" ;
            }
            $_[1];
        }
	],
	[#Rule 40
		 'cif_value', 1,
sub
#line 543 "Yapp.yp"
{
            if( $COD::CIF::Parser::Yapp::debug >= 1 &&
                $COD::CIF::Parser::Yapp::debug <= 2 )
            {
                print "TFIELD\t\t->\t"
                     . $_[1]->{value} . "\n"
            }
            $_[1];
        }
	],
	[#Rule 41
		 'string', 1,
sub
#line 556 "Yapp.yp"
{
            $_[1] =~ m/^(')(.*)(')$/si;
            return { value => $2,
                     type => 'SQSTRING' };
        }
	],
	[#Rule 42
		 'string', 1,
sub
#line 562 "Yapp.yp"
{
            $_[1] =~ m/^(")(.*)(")$/si;
            return { value => $2,
                     type => 'DQSTRING' };
        }
	],
	[#Rule 43
		 'string', 1,
sub
#line 567 "Yapp.yp"
{{ value => $_[1],
                    type => 'UQSTRING'} }
	],
	[#Rule 44
		 'string', 1,
sub
#line 569 "Yapp.yp"
{{ value => $_[1],
                      type => 'TEXTFIELD' };
        }
	],
	[#Rule 45
		 'number', 1,
sub
#line 576 "Yapp.yp"
{
            if( $_[1] =~ m/^(.*)( \( ([0-9]+) \) )$/six )
            {
                my $precision = unpack_precision( $1, $3 );
                {   type => 'FLOAT',
                    value => $_[1],
                    precision => $precision
                }
            } else {
                {   type => 'FLOAT',
                    value => $_[1],
                    precision => undef
                }
            }
        }
	],
	[#Rule 46
		 'number', 1,
sub
#line 592 "Yapp.yp"
{
            if( $_[1] =~ m/^(.*)( \( ([0-9]+) \) )$/sx)
            {
                {   type => 'INT',
                    value => $_[1],
                    precision => $3
                }
            } else {
                {   type => 'INT',
                    value => $_[1],
                    precision => undef
                }
            }
        }
	]
],
                                  @_);
    bless($self,$class);
}

#line 608 "Yapp.yp"

# --------------------------------------------------------------
# begin of footer
# --------------------------------------------------------------

sub _Error
{
    my $script = $0 eq '-e' ? "perl -e '...'" : "$0";
    my $filename = $_[0]->YYData->{FILENAME};
    my $dataname = defined $_[0]->{USER}->{CURRENT_DATABLOCK} ? " data_"
                         . $_[0]->{USER}->{CURRENT_DATABLOCK} : "";

    my $line = $_[0]->YYData->{VARS}{lines};
    my $pos  = $_[0]->YYData->{VARS}{token_prev_pos} + 1;
    my $ppos = $_[0]->YYData->{VARS}{token_prev_pos};

    my $options = $_[1];
    if (defined $options) {
        $line = $options->{line} if exists $options->{line};
        if ( exists $options->{pos} ) {
            $pos  = $options->{pos};
            $ppos = $options->{pos};
        }
    }

    $_[0]->YYData->{ERRCOUNT}++;

    my $message = "$script: $filename";
    if ( exists $_[0]->YYData->{ERRMSG} ) {
        $message .= "($line)" . "$dataname: ";
        $message .= "ERROR, " . $_[0]->YYData->{ERRMSG} . "\n";
        delete $_[0]->YYData->{ERRMSG};
    } else {
        $message .= "($line,$pos)" . "$dataname: ";
        $message .= "ERROR, incorrect CIF syntax\n"
                   . $_[0]->YYData->{VARS}{current_line}
                   . "\n";
        $message .= " " x $ppos;
        $message .= "^\n";
    }

    push $_[0]->{YYData}->{ERROR_MESSAGES}, $message;
    print STDERR $message if $_[0]->{USER}{OPTIONS}{print_error_messages};
}

sub _Warning
{
    if( exists $_[0]->YYData->{ERRMSG} ) {
        my $script = $0 eq '-e' ? "perl -e '...'" : "$0";
        my $filename = $_[0]->YYData->{FILENAME};
        my $dataname = defined $_[0]->{USER}->{CURRENT_DATABLOCK} ? " data_"
                             . $_[0]->{USER}->{CURRENT_DATABLOCK} : "";

        my $options = ( defined $_[1] ) ? $_[1] : {};

        my $line = defined $options->{line} ? $options->{line}
                                            : $_[0]->YYData->{VARS}{lines};

        my $message = "$script: $filename($line)" . "$dataname: ";
        $message .= "WARNING, " . $_[0]->YYData->{ERRMSG} . "\n";
        delete $_[0]->YYData->{ERRMSG};
        push   $_[0]->{YYData}->{ERROR_MESSAGES}, $message;
        print STDERR $message if $_[0]->{USER}{OPTIONS}{print_error_messages};
    }
}

sub _Lexer
{
    my($parser) = shift;

    #trimming tokenized comments
    if( defined $parser->YYData->{INPUT} &&
        $parser->YYData->{INPUT} =~ s/^(\s*#.*)$//s )
    {
        advance_token($parser, length($1), 1);
    }

    if( !defined $parser->YYData->{INPUT} ||
        $parser->YYData->{INPUT} =~ m/^\s*$/ )
    {
        do
        {
            $parser->YYData->{INPUT} = <$COD::CIF::Parser::Yapp::FILEIN>;
            $parser->YYData->{VARS}{lines}++;
            if( defined $parser->{reporter} &&
                $parser->YYData->{VARS}{lines} % 100 == 0 )
            {
                &{$parser->{reporter}}( $parser->{USER}{FILENAME},
                                        $parser->YYData->{VARS}{lines},
                                        $parser->{USER}{CURRENT_DATABLOCK} );
            }
        } until ( !defined $parser->YYData->{INPUT} ||
        $parser->YYData->{INPUT} !~ m/^(\s*(#.*)?)$/s );
        if( defined $parser->YYData->{INPUT} )
        {
            chomp $parser->YYData->{INPUT};
            $parser->YYData->{INPUT}=~s/\r$//g;
            $parser->YYData->{INPUT}=~s/\t/    /g;
            $parser->YYData->{VARS}{current_line} = $parser->YYData->{INPUT};
            $parser->YYData->{VARS}{token_pos} = 0;
            if( $parser->YYData->{INPUT} =~ /\x{001A}/ ) {
                if( $parser->{USER}{OPTIONS}{fix_ctrl_z} ||
                    $parser->{USER}{OPTIONS}{fix_errors} )
                {
                    $parser->YYData->{ERRMSG} = "DOS EOF symbol " .
                        "^Z was encountered and ignored";
                    $parser->_Warning();
                    $parser->YYData->{INPUT} =~ s/\x{001A}/ /g;
                } else {
                    $parser->YYData->{ERRMSG} = "DOS EOF symbol " .
                        "^Z was encountered, " .
                        "it is not permitted in CIFs";
                    ## $parser->_Error();
                }
            }
        } else {
            return('',undef);
        }
    }

    if( $parser->YYData->{INPUT} !~ /^[\x10-\x7F]*$/ &&
        ( $parser->{USER}{OPTIONS}{fix_errors} ||
          $parser->{USER}{OPTIONS}{fix_non_ascii_symbols} ))
        {
        $parser->YYData->{ERRMSG} = "non-ascii symbols encountered in the text:\n'" .
        $parser->YYData->{INPUT} . "'";
        $parser->_Warning();
        $parser->YYData->{INPUT} =~ s/([^\x10-\x7F])/sprintf("&#x%04X;",ord($1))/eg;
    }

#scalars storing regular expressions, common to several matches
my $ORDINARY_CHAR   =
    qr/[a-zA-Z0-9!%&\(\)\*\+,-\.\/\:<=>\?@\\\^`{\|}~]/is;
my $SPECIAL_CHAR    =   qr/["#\$'_\[\]]/is;
my $NON_BLANK_CHAR  =   qr/(?:$ORDINARY_CHAR|$SPECIAL_CHAR|;)/is;
my $TEXT_LEAD_CHAR  =   qr/(?:$ORDINARY_CHAR|$SPECIAL_CHAR|\s)/s;
my $ANY_PRINT_CHAR  =   qr/(?:$NON_BLANK_CHAR|\s)/is;
my $INTEGER         =   qr/[-+]?[0-9]+/s;
my $EXPONENT        =   qr/e[-+]?[0-9]+/is;
my $FLOAT11         =   qr/(?: $INTEGER $EXPONENT)/ix;
my $FLOAT21         =   qr/(?: [+-]? [0-9]* \. [0-9]+ $EXPONENT ?)/ix;
my $FLOAT31         =   qr/(?: $INTEGER \. $EXPONENT ?)/ix;
my $FLOAT           =   qr/(?: (?: $FLOAT11 | $FLOAT21 | $FLOAT31))/six;
my $UQSTRING_FIRSTPOS   =       qr/^(?:
                                        $ORDINARY_CHAR
                                        ${NON_BLANK_CHAR} *
                                    )/six;
my $UQSTRING_INLINE     =       qr/^(?:
                                        (?:$ORDINARY_CHAR | ;)
                                        ${NON_BLANK_CHAR} *
                                    )/six;

    if( $parser->{USER}{OPTIONS}{fix_errors} ||
        $parser->{USER}{OPTIONS}{allow_uqstring_brackets} ) {
        $UQSTRING_FIRSTPOS = qr/^(?:
                                (?:$ORDINARY_CHAR | \[)
                                ${NON_BLANK_CHAR} *
                            )/six;
        $UQSTRING_INLINE   = qr/^(?:
                                (?:$ORDINARY_CHAR | ; | \[)
                                ${NON_BLANK_CHAR} *
                            )/six;
    }

    #matching white space characters
    if( $parser->YYData->{INPUT} =~ s/(\s*)//s )
    {
        advance_token($parser, length($1), 1);
    }

    if( $COD::CIF::Parser::Yapp::debug >= 2 &&
        $COD::CIF::Parser::Yapp::debug < 3 )
    {
        print ">>> '", $parser->YYData->{INPUT}, "'\n";
    }

    for ($parser->YYData->{INPUT})
    {
        #matching floats:
        if(s/^($FLOAT (?:\([0-9]+\))?)(\s|$)//six)
        {
            advance_token($parser, length($1 . $2));
            return('FLOAT', $1);
        }
        #matching integers:
        if(s/^($INTEGER (?:\([0-9]+\))?)(\s|$)//sx)
        {
            advance_token($parser, length($1 . $2));
            return('INT', $1);
        }
        #matching double quoted strings
        if(s/^("${ANY_PRINT_CHAR}*?")(\s|$)//s)
        {
            advance_token($parser, length($1 . $2));
            return('DQSTRING', $1);
        }
        #matching single quoted strings
        if(s/^('${ANY_PRINT_CHAR}*?')(\s|$)//s)
        {
            advance_token($parser, length($1 . $2));
            return('SQSTRING', $1);
        }
        #matching single quoted strings without a closing quote
        if( ( $parser->{USER}{OPTIONS}{fix_errors} ||
              $parser->{USER}{OPTIONS}
                      {fix_missing_closing_double_quote} ) &&
                    s/^("${ANY_PRINT_CHAR}*?)(\s|$)//s)
        {
            my $value = $1;
            my $space = $2;

            $parser->YYData->{ERRMSG} =
                        "double-quoted string is missing a closing quote -- fixed";
            $parser->_Warning();

            advance_token($parser, length($value . $space));
            return('DQSTRING', $value . '"');
        }
        #matching single quoted strings without a closing quote
        if ( ( $parser->{USER}{OPTIONS}{fix_errors} ||
               $parser->{USER}{OPTIONS}{fix_missing_closing_single_quote} ) &&
                    s/^('${ANY_PRINT_CHAR}*?)(\s|$)//s )
        {
            my $value = $1;
            my $space = $2;

            $parser->YYData->{ERRMSG} =
                        "single-quoted string is missing a closing quote -- fixed";
            $parser->_Warning();

            advance_token($parser, length($value . $space));
            return('SQSTRING', $value . "'");
        }
        #matching text field
        if( $parser->YYData->{VARS}{token_pos} == 0 )
        {
            if( s/^;(${ANY_PRINT_CHAR}*)$//s )
            {
                my $eotf = 0;
                my $tfield; #all textfield
                my $tf_line_begin =
                    $parser->YYData->{VARS}{lines};
                $tfield = $1;
                while( 1 )
                {
                    my $line = <$COD::CIF::Parser::Yapp::FILEIN>;
                    if( defined $line )
                    {
                        chomp $line;
                        $line=~s/\r$//g;
                        $line=~s/\t/    /g;
                        $parser->YYData->{VARS}{current_line} = $line;
                        $parser->YYData->{VARS}{lines}++;
                        if( $line =~ s/^;//s )
                        {
                            if( defined $line )
                            {
                                $parser->YYData->{INPUT} = $line;
                                $parser->YYData->{VARS}{token_pos} = 1;
                            }
                            if( $line && $line !~ /^\s/ )
                            {
                                $parser->YYError();
                            }
                            last;
                        } else {
                            $tfield .= "\n" . $line;
                        }
                    } else {
                        undef $parser->YYData->{INPUT};
                        last;
                    }
                }
                if( !defined $parser->YYData->{INPUT} )
                {
                    $parser->YYData->{ERRMSG} = <<END_M;
end of file encountered while in text field starting in line $tf_line_begin.
Possible runaway closing semicolon (';')
END_M
                    $parser->YYError();
                }
                if( $tfield !~ /^[\x08-\x7F]*$/ ) {
                    if( $parser->{USER}{OPTIONS}{fix_errors} ||
                        $parser->{USER}{OPTIONS}{fix_non_ascii_symbols} )
                    {
                        $parser->YYData->{ERRMSG} =
                            "non-ascii symbols encountered in the text field, "
                          . "replaced by XML entities:\n;"
                          . $tfield . "\n;\n";
                        $parser->_Warning();
                        $tfield =~ s/([^\x08-\x7F])/sprintf("&#x%04X;",ord($1))/eg;
                    } else {
                        $parser->YYData->{ERRMSG} =
                            "non-ascii symbols encountered in the text field:\n;"
                           . $tfield . "\n;\n";
                        $parser->_Error();
                    }
                }
                if( !$parser->{USER}{OPTIONS}{do_not_unprefix_text} ) {
                    if( $tfield =~ /^(.+?)\\(\\)?\n/ ) {
                        my $prefix = $1;
                        $tfield =~ s/^\Q${prefix}\E\\\n//;
                        $tfield =~ s/^\Q${prefix}\E\\\\\n/\\\n/;
                        $tfield =~ s/^\Q${prefix}\E//mg;
                    }
                }
                if( !$parser->{USER}{OPTIONS}{do_not_unfold_text} ) {
                    if( $tfield =~ /^\\\n/ ) {
                        $tfield =~ s/\\\n//mg;
                    }
                }
                return('TEXT_FIELD', $tfield);
            }
        }
        #matching GLOBAL_ field
        if( s/^(global_)(\s+|$)//si ) {
            advance_token($parser, length($1 . $2));
            $parser->YYData->{ERRMSG} = "GLOBAL_ symbol detected"
                . " in line "
                . $parser->YYData->{VARS}{lines}
                . ", pos. "
                . $parser->YYData->{VARS}{token_prev_pos}
                . ":\n--\n"
                . $parser->YYData->{VARS}{current_line}
                . "\n--\n"
                . "it is not acceptable in this version";
            $parser->YYError();
            return('GLOBAL_', $1);
        }
        #matching SAVE_ head
        if( s/^(save_${NON_BLANK_CHAR}+)//si )
        {
            advance_token($parser, length($1));
            return('SAVE_HEAD', $1);
        }
        #matching SAVE_ foot
        if( s/^(save_)//si )
        {
            advance_token($parser, length($1));
            return('SAVE_FOOT', $1);
        }
        #matching STOP_ field
        if( s/^(stop_)(\s+|$)//si )
        {
            advance_token($parser, length($1 . $2));
            $parser->YYData->{ERRMSG} = "STOP_ symbol detected" .
                " in line " .
                $parser->YYData->{VARS}{lines} .
                ", pos. " .
                $parser->YYData->{VARS}{token_prev_pos} .
                ":\n--\n" .
                $parser->YYData->{VARS}{current_line} .
                "\n--\n" .
                "it is not acceptable in this version";
            $parser->YYError();
            return('STOP_', $1);
        }
        #matching DATA_ field
        if( s/^(data_${NON_BLANK_CHAR}+)//si )
        {
            advance_token($parser, length($1));
            return('DATA_', $1);
        }
        #matching LOOP_ begining
        if( s/^(loop_)(\s+|$)//si )
        {
            advance_token($parser, length($1 . $2));
            $parser->YYData->{VARS}{loop_begin} =
                $parser->YYData->{VARS}{lines};
            return('LOOP_', $1);
        }
        #matching TAG's
        if( s/^(_${NON_BLANK_CHAR}+)//si )
        {
            advance_token($parser, length($1));
            return('TAG', lc($1));
        }
        #matching unquoted strings
        if( $parser->YYData->{VARS}{token_pos} == 0 )
        { #UQSTRING at first pos. of line
            if( s/^(${UQSTRING_FIRSTPOS})//s)
            {
                advance_token($parser, length($1));
                return('UQSTRING', $1);
            }
        } else { #UQSTRING in line
            if( s/^(${UQSTRING_INLINE})//sx )
            {
                advance_token($parser, length($1));
                return('UQSTRING', $1);
            }
        }
        #matching any still unmatched symbol:
        if( s/^(.)//m )
        {
            advance_token($parser, length($1), 1);
            return($1,$1);
        }
    }
}

sub advance_token
{
    my ($parser, $length, $do_not_remember) = @_;
    if( !defined $do_not_remember ||
        $do_not_remember == 0 ) {
        if( exists $parser->YYData->{VARS}{token_this_line} ) {
            $parser->YYData->{VARS}{token_prev_line} =
                $parser->YYData->{VARS}{token_this_line};
        }
        $parser->YYData->{VARS}{token_this_line} =
            $parser->YYData->{VARS}{lines};
    }
    $parser->YYData->{VARS}{token_prev_pos} =
        $parser->YYData->{VARS}{token_pos};
    $parser->YYData->{VARS}{token_pos} += $length;
}

sub Run
{
    my ($self, $filename, $options ) = @_;

    if( ref $options eq "HASH" ) {
        $self->{USER}{OPTIONS} = $options;
        if ( exists $options->{reporter} ) {
            $self->{reporter} = $options->{reporter};
        }
    }

    # Default value of print_error_messages is to be discussed
    if (!defined $self->{USER}{OPTIONS}{print_error_messages}) {
        $self->{USER}{OPTIONS}{print_error_messages} = 1;
    }

    $filename = "-" unless $filename;

    $self->{USER}{FILENAME} = $filename;
    $self->{USER}->{CIFfile} = undef;
    $self->{YYData}->{ERROR_MESSAGES} = [];

    if( ref $options eq "HASH"  && defined $options->{filehandle} ) {
        $COD::CIF::Parser::Yapp::FILEIN = $options->{filehandle};
    } else {
        my $program = $0 eq '-e' ? "perl -e '...'" : $0;
        $COD::CIF::Parser::Yapp::FILEIN = new FileHandle $filename;
        if( !defined $COD::CIF::Parser::Yapp::FILEIN ) {
            print STDERR "$program: $filename: ERROR, "
                       . "unable to open file '$filename' for reading -- "
                       . lcfirst $! . "\n";
            return 1;
        }
    }

    $| = 1;
    if( $COD::CIF::Parser::Yapp::debug >= 2 &&
        $COD::CIF::Parser::Yapp::debug < 3)
    {
        $self->YYParse( yylex => \&_Lexer,
                        yyerror => \&_Error,
                        yydebug => 0x05 );
    } else {
        $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );
    }
    if( $self->YYNberr() == 0 )
    {
        if( $COD::CIF::Parser::Yapp::debug >= 1 &&
            $COD::CIF::Parser::Yapp::debug < 3)
        {
            print "File syntax is CORRECT!\n";
        }
        undef $COD::CIF::Parser::Yapp::FILEIN;
    } else {
        if( $COD::CIF::Parser::Yapp::debug >= 1 &&
            $COD::CIF::Parser::Yapp::debug < 3)
        {
            print "Syntax check failed.\n";
        }
        undef $COD::CIF::Parser::Yapp::FILEIN;
    }
    return $self->{USER}->{CIFfile};
}

return 1;

1;
