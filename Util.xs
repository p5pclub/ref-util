#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* C functions */

#if defined(cv_set_call_checker) && defined(XopENTRY_set)
# define USE_CUSTOM_OPS 1
#else
# define USE_CUSTOM_OPS 0
#endif


#if USE_CUSTOM_OPS
/* C pre-processor mini tutorial:

    * The ## symbol below is the C preprocessor syntax for token concatenation.

    So in:

        #define foo(x) foo_ ## x

    foo(x) would turn into foo_x

    * The # symbol as a token prefix or sigil is the C preprocessor syntax for token
      stringification. So in:

        #define str(x) #x

    str(foo) would turn into "foo"

    * Strings in C/C preprocessor are concatenated when adjacent to each other:

        "foo" "bar" "baz"

    is exactly equivalent to

        "foobarbaz"

*/


#define DECL_CROAK_FUNC(x) \
    static void \
    THX_xsfunc_ ## x (pTHX_ CV *cv) \
    {\
        croak("Original " #x " called"); \
    }

#define DECL_XOP(x) \
    static XOP x ## _xop;

#define DECL_MAIN_FUNC(x,op,type)   \
    static inline OP *              \
    x ## _pp(pTHX)           \
    {                               \
        dSP;                        \
        SV *ref = POPs;             \
        PUSHs( SvROK(ref) && SvTYPE(SvRV(ref)) op type ? &PL_sv_yes : &PL_sv_no ); \
        return NORMAL;  \
    }

#define DECL(x,op,type) \
    DECL_CROAK_FUNC(x)  \
    DECL_XOP(x)         \
    DECL_MAIN_FUNC(x,op,type)


DECL(is_scalarref,    <,  SVt_PVAV)
DECL(is_arrayref,     ==, SVt_PVAV)
DECL(is_hashref,      ==, SVt_PVHV)
DECL(is_coderef,      ==, SVt_PVCV)
DECL(is_regexpref,    ==, SVt_REGEXP)
DECL(is_globref,      ==, SVt_PVGV)
DECL(is_formatref,    ==, SVt_PVFM)
DECL(is_ioref,        ==, SVt_PVIO)

static OP *
THX_ck_entersub_args_is_scalarref(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    /* replace with op */
    entersubop = ck_entersub_args_proto(entersubop, namegv, ckobj);

    /*
        move two ops forward:
        first should be pushmark()
        second should be the argument
    */

    /* get the first op, make a list of the next, get first element in it */
    OP *arg = cLISTOPx( cUNOPx( entersubop )->op_first )->op_first->op_sibling;

    /* no more instructions */
    arg->op_sibling = NULL;

    OP *newop = newUNOP( OP_NULL, 0, arg );
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = is_scalarref_pp;

    return newop;
}

static OP *
THX_ck_entersub_args_is_arrayref(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    /* replace with op */
    entersubop = ck_entersub_args_proto(entersubop, namegv, ckobj);

    /*
        move two ops forward:
        first should be pushmark()
        second should be the argument
    */

    /* get the first op, make a list of the next, get first element in it */
    OP *arg = cLISTOPx( cUNOPx( entersubop )->op_first )->op_first->op_sibling;

    /* no more instructions */
    arg->op_sibling = NULL;

    OP *newop = newUNOP( OP_NULL, 0, arg );
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = is_arrayref_pp;

    return newop;
}

static OP *
THX_ck_entersub_args_is_hashref(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    /* replace with op */
    entersubop = ck_entersub_args_proto(entersubop, namegv, ckobj);

    /*
        move two ops forward:
        first should be pushmark()
        second should be the argument
    */

    /* get the first op, make a list of the next, get first element in it */
    OP *arg = cLISTOPx( cUNOPx( entersubop )->op_first )->op_first->op_sibling;

    /* no more instructions */
    arg->op_sibling = NULL;

    OP *newop = newUNOP( OP_NULL, 0, arg );
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = is_hashref_pp;

    return newop;
}

static OP *
THX_ck_entersub_args_is_coderef(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    /* replace with op */
    entersubop = ck_entersub_args_proto(entersubop, namegv, ckobj);

    /*
        move two ops forward:
        first should be pushmark()
        second should be the argument
    */

    /* get the first op, make a list of the next, get first element in it */
    OP *arg = cLISTOPx( cUNOPx( entersubop )->op_first )->op_first->op_sibling;

    /* no more instructions */
    arg->op_sibling = NULL;

    OP *newop = newUNOP( OP_NULL, 0, arg );
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = is_coderef_pp;

    return newop;
}

static OP *
THX_ck_entersub_args_is_regexpref(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    /* replace with op */
    entersubop = ck_entersub_args_proto(entersubop, namegv, ckobj);

    /*
        move two ops forward:
        first should be pushmark()
        second should be the argument
    */

    /* get the first op, make a list of the next, get first element in it */
    OP *arg = cLISTOPx( cUNOPx( entersubop )->op_first )->op_first->op_sibling;

    /* no more instructions */
    arg->op_sibling = NULL;

    OP *newop = newUNOP( OP_NULL, 0, arg );
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = is_regexpref_pp;

    return newop;
}

static OP *
THX_ck_entersub_args_is_globref(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    /* replace with op */
    entersubop = ck_entersub_args_proto(entersubop, namegv, ckobj);

    /*
        move two ops forward:
        first should be pushmark()
        second should be the argument
    */

    /* get the first op, make a list of the next, get first element in it */
    OP *arg = cLISTOPx( cUNOPx( entersubop )->op_first )->op_first->op_sibling;

    /* no more instructions */
    arg->op_sibling = NULL;

    OP *newop = newUNOP( OP_NULL, 0, arg );
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = is_globref_pp;

    return newop;
}

static OP *
THX_ck_entersub_args_is_formatref(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    /* replace with op */
    entersubop = ck_entersub_args_proto(entersubop, namegv, ckobj);

    /*
        move two ops forward:
        first should be pushmark()
        second should be the argument
    */

    /* get the first op, make a list of the next, get first element in it */
    OP *arg = cLISTOPx( cUNOPx( entersubop )->op_first )->op_first->op_sibling;

    /* no more instructions */
    arg->op_sibling = NULL;

    OP *newop = newUNOP( OP_NULL, 0, arg );
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = is_formatref_pp;

    return newop;
}

static OP *
THX_ck_entersub_args_is_ioref(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    /* replace with op */
    entersubop = ck_entersub_args_proto(entersubop, namegv, ckobj);

    /*
        move two ops forward:
        first should be pushmark()
        second should be the argument
    */

    /* get the first op, make a list of the next, get first element in it */
    OP *arg = cLISTOPx( cUNOPx( entersubop )->op_first )->op_first->op_sibling;

    /* no more instructions */
    arg->op_sibling = NULL;

    OP *newop = newUNOP( OP_NULL, 0, arg );
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = is_ioref_pp;

    return newop;
}

#endif /* USE_CUSTOM_OPS */

MODULE = Ref::Util		PACKAGE = Ref::Util

#if USE_CUSTOM_OPS

BOOT:
    {
        XopENTRY_set(&is_scalarref_xop, xop_name, "is_scalarref_xop");
        XopENTRY_set(&is_scalarref_xop, xop_desc, "'SCALAR' ref check");
        Perl_custom_op_register(aTHX_ is_scalarref_pp, &is_scalarref_xop);
        CV *cv = newXSproto_portable(
            "Ref::Util::is_scalarref", THX_xsfunc_is_scalarref, __FILE__, "$"
        );
        cv_set_call_checker(cv, THX_ck_entersub_args_is_scalarref, (SV*)cv);
    }

    {
        XopENTRY_set(&is_arrayref_xop, xop_name, "is_arrayref_xop");
        XopENTRY_set(&is_arrayref_xop, xop_desc, "'ARRAY' ref check");
        Perl_custom_op_register(aTHX_ is_arrayref_pp, &is_arrayref_xop);
        CV *cv = newXSproto_portable(
            "Ref::Util::is_arrayref", THX_xsfunc_is_arrayref, __FILE__, "$"
        );
        cv_set_call_checker(cv, THX_ck_entersub_args_is_arrayref, (SV*)cv);
    }

    {
        XopENTRY_set(&is_hashref_xop, xop_name, "is_hashref_xop");
        XopENTRY_set(&is_hashref_xop, xop_desc, "'HASH' ref check");
        Perl_custom_op_register(aTHX_ is_hashref_pp, &is_hashref_xop);
        CV *cv = newXSproto_portable(
            "Ref::Util::is_hashref", THX_xsfunc_is_hashref, __FILE__, "$"
        );
        cv_set_call_checker(cv, THX_ck_entersub_args_is_hashref, (SV*)cv);
    }

    {
        XopENTRY_set(&is_coderef_xop, xop_name, "is_coderef_xop");
        XopENTRY_set(&is_coderef_xop, xop_desc, "'CODE' ref check");
        Perl_custom_op_register(aTHX_ is_coderef_pp, &is_coderef_xop);
        CV *cv = newXSproto_portable(
            "Ref::Util::is_coderef", THX_xsfunc_is_coderef, __FILE__, "$"
        );
        cv_set_call_checker(cv, THX_ck_entersub_args_is_coderef, (SV*)cv);
    }

    {
        XopENTRY_set(&is_regexpref_xop, xop_name, "is_regexpref_xop");
        XopENTRY_set(&is_regexpref_xop, xop_desc, "'REGEXP' ref check");
        Perl_custom_op_register(aTHX_ is_regexpref_pp, &is_regexpref_xop);
        CV *cv = newXSproto_portable(
            "Ref::Util::is_regexpref", THX_xsfunc_is_regexpref, __FILE__, "$"
        );
        cv_set_call_checker(cv, THX_ck_entersub_args_is_regexpref, (SV*)cv);
    }

    {
        XopENTRY_set(&is_globref_xop, xop_name, "is_globref_xop");
        XopENTRY_set(&is_globref_xop, xop_desc, "'GLOB' ref check");
        Perl_custom_op_register(aTHX_ is_globref_pp, &is_globref_xop);
        CV *cv = newXSproto_portable(
            "Ref::Util::is_globref", THX_xsfunc_is_globref, __FILE__, "$"
        );
        cv_set_call_checker(cv, THX_ck_entersub_args_is_globref, (SV*)cv);
    }

    {
        XopENTRY_set(&is_formatref_xop, xop_name, "is_formatref_xop");
        XopENTRY_set(&is_formatref_xop, xop_desc, "'FORMAT' ref check");
        Perl_custom_op_register(aTHX_ is_formatref_pp, &is_formatref_xop);
        CV *cv = newXSproto_portable(
            "Ref::Util::is_formatref", THX_xsfunc_is_formatref, __FILE__, "$"
        );
        cv_set_call_checker(cv, THX_ck_entersub_args_is_formatref, (SV*)cv);
    }

    {
        XopENTRY_set(&is_ioref_xop, xop_name, "is_ioref_xop");
        XopENTRY_set(&is_ioref_xop, xop_desc, "'IO' ref check");
        Perl_custom_op_register(aTHX_ is_ioref_pp, &is_ioref_xop);
        CV *cv = newXSproto_portable(
            "Ref::Util::is_ioref", THX_xsfunc_is_ioref, __FILE__, "$"
        );
        cv_set_call_checker(cv, THX_ck_entersub_args_is_ioref, (SV*)cv);
    }

#else /* not USE_CUSTOM_OPS */

SV *
is_scalarref(SV *ref)
    PPCODE:
        ( SvROK(ref) && SvTYPE(SvRV(ref)) < SVt_PVAV )
        ? XSRETURN_YES : XSRETURN_NO;

SV *
is_arrayref(SV *ref)
    PPCODE:
        ( SvROK(ref) && SvTYPE(SvRV(ref)) == SVt_PVAV )
        ? XSRETURN_YES : XSRETURN_NO;

SV *
is_hashref(SV *ref)
    PPCODE:
        ( SvROK(ref) && SvTYPE(SvRV(ref)) == SVt_PVHV )
        ? XSRETURN_YES : XSRETURN_NO;

SV *
is_coderef(SV *ref)
    PPCODE:
        ( SvROK(ref) && SvTYPE(SvRV(ref)) == SVt_PVCV )
        ? XSRETURN_YES : XSRETURN_NO;

SV *
is_regexpref(SV *ref)
    PPCODE:
        ( SvROK(ref) && SvTYPE(SvRV(ref)) == SVt_REGEXP )
        ? XSRETURN_YES : XSRETURN_NO;

SV *
is_globref(SV *ref)
    PPCODE:
        ( SvROK(ref) && SvTYPE(SvRV(ref)) == SVt_PVGV )
        ? XSRETURN_YES : XSRETURN_NO;

SV *
is_formatref(SV *ref)
    PPCODE:
        ( SvROK(ref) && SvTYPE(SvRV(ref)) == SVt_PVFM )
        ? XSRETURN_YES : XSRETURN_NO;

SV *
is_ioref(SV *ref)
    PPCODE:
        ( SvROK(ref) && SvTYPE(SvRV(ref)) == SVt_PVIO )
        ? XSRETURN_YES : XSRETURN_NO;

#endif /* not USE_CUSTOM_OPS */
