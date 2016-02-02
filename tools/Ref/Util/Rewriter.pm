package Ref::Util::Rewriter;
use strict;
use warnings;
use PPI;
use PPI::Dumper;
use Safe::Isa;
use List::Util 'first';

my %reftype_to_reffunc = (
    SCALAR => 'is_scalarref',
    ARRAY  => 'is_arrayref',
    HASH   => 'is_hashref',
    CODE   => 'is_coderef',
    Regexp => 'is_regexpref',
    GLOB   => 'is_globref',
    IO     => 'is_ioref',
    REF    => 'is_refref',
);

sub rewrite_string {
    my $string = shift;
    my $res = rewrite( PPI::Document->new(\$string) );
    return $res;
}

sub rewrite_file {
    my $file = shift;
    return rewrite( PPI::Document->new($file) );
}

sub rewrite {
    my $doc            = shift;
    my $all_statements = $doc->find('PPI::Statement');
    my @cond_ops       = qw<or || and &&>;
    my @new_statements;

    foreach my $statement ( @{$all_statements} ) {
        # if there's an "if()" statement, it appears as a Compound statement
        # and then each internal statement appears again,
        # causing duplication in results
        $statement->$_isa('PPI::Statement::Compound')
            and next;

        # find the 'ref' functions
        my $ref_subs = $statement->find( sub {
            $_[1]->isa('PPI::Token::Word') and $_[1]->content eq 'ref'
        }) or next;

        my $statement_def;

        REF_STATEMENT:
        foreach my $ref_sub ( @{$ref_subs} ) {
            # we want to pick up everything until we find a delimiter
            # effectively telling us we ended the parameters to "ref"
            my $sib = $ref_sub;
            my ( @func_args, $reffunc_doc, @rest_of_tokens );

            while ( $sib = $sib->next_sibling ) {
                # end of statement/expression
                my $content = $sib->content;
                $content eq ';' and last;

                # we might already have a statement
                # in this case collect all the rest of the tokens
                # (this could be in two separate loops)
                if ($statement_def) {
                    push @rest_of_tokens, $sib;
                    next;
                }

                # reasons to stop
                if ( ! $statement_def && $sib->$_isa('PPI::Token::Operator') ) {
                    # comparison operators
                    if ( $content eq 'eq' || $content eq 'ne' ) {
                        # "ARRAY" vs. $foo (which has "ARRAY" as value)
                        # we also move $sib to next significant sibling
                        my $val_token = $sib = $sib->snext_sibling;
                        my $val_str   = $val_token->$_isa('PPI::Token::Quote')
                                      ? $val_token->string
                                      : $val_token->content;

                        my $func = $reftype_to_reffunc{$val_str};
                        if ( !$func ) {
                            warn "Error: no match for $val_str\n";
                            next REF_STATEMENT;
                        }

                        $statement_def = [ $func, \@func_args, '' ];
                    } elsif ( first { $content eq $_ } @cond_ops ) {
                        # is_ref

                        # @func_args will now contain spaces too,
                        # which we will need to take out,
                        # in order to add them after the is_ref()
                        # reason those spaces don't appear in is_ref()
                        # we created is because we clean the function up
                        my $spaces_count = 0;
                        foreach my $idx ( reverse 0 .. $#func_args ) {
                            $func_args[$idx]->$_isa('PPI::Token::Whitespace')
                                ? $spaces_count++
                                : last;
                        }

                        # we should add these *and* the cond op
                        # to the statement
                        # technically we can just add them at the end
                        # but it seems easier to stick them as strings
                        # and have them parsed
                        # (wish i understood PPI better)

                        $statement_def = [
                            'is_ref',
                            \@func_args,
                            ' ' x $spaces_count . $content,
                        ];
                    } else {
                        warn "Warning: unknown operator: $sib\n";
                        next REF_STATEMENT;
                    }
                } else {
                    # otherwise, collect it as a parameter
                    push @func_args, $sib;
                }
            }

            # skip when failed (error or warnings should appear from above)
            $statement_def or next;

            my ( $func_name, $func_args, $rest ) = @{$statement_def};
            $rest .= $_ for @rest_of_tokens;
            $sib && $sib->content eq ';'
                and $rest .= ';';

            $reffunc_doc = _create_statement(
                $func_name, $func_args, $rest
            );

            # prevent garbage collection
            # FIXME: turn this into an interation that finds weaken
            # objects and unweakens them (Scalar::Util::unweaken)
            push @new_statements, $reffunc_doc;

            my $new_statement = ( $reffunc_doc->children )[0];

            $ref_sub->parent->insert_before($new_statement);
            $ref_sub->parent->remove;
        }
    }

    return "$doc";
}

sub _create_statement {
    my ( $func, $args, $rest ) = @_;
    my $args_str = join '', @{$args};
    $args_str =~ s/^\s+//;
    $args_str =~ s/\s+$//;
    $args_str =~ s/^\(+//;
    $args_str =~ s/\)+$//;
    defined $rest or $rest = '';
    return PPI::Document::Fragment->new(\"$func($args_str)$rest");
}

1;
