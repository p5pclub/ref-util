#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#if defined(cv_set_call_checker) && defined(XopENTRY_set)
# define USE_CUSTOM_OPS 1
#else
# define USE_CUSTOM_OPS 0
#endif

/* Boolean expression that considers an SV* named "ref" */
#define COND(expr) (SvROK(ref) && expr)

#define PLAIN         (!sv_isobject(ref))
#define REFTYPE(tail) (SvTYPE(SvRV(ref)) tail)
#define REFREF        (SvROK( SvRV(ref) ))

#define XSUB_BODY(cond) COND(cond) ? XSRETURN_YES : XSRETURN_NO

#define FUNC_BODY(cond)                                 \
    dSP;                                                \
    SV *ref = POPs;                                     \
    PUSHs( COND(cond) ? &PL_sv_yes : &PL_sv_no )

#if USE_CUSTOM_OPS

#define DECL_RUNTIME_FUNC(x, cond)              \
    static void                                 \
    THX_xsfunc_ ## x (pTHX_ CV *cv)             \
    {                                           \
        FUNC_BODY(cond);                        \
    }

#define DECL_XOP(x) \
    static XOP x ## _xop;

#define DECL_MAIN_FUNC(x, cond)                 \
    static inline OP *                          \
    x ## _pp(pTHX)                              \
    {                                           \
        FUNC_BODY(cond);                        \
        return NORMAL;                          \
    }

#define DECL_CALL_CHK_FUNC(x)                                                       \
    static OP *                                                                     \
    THX_ck_entersub_args_ ## x(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)         \
    {                                                                               \
        entersubop = ck_entersub_args_proto(entersubop, namegv, ckobj);             \
        OP *arg = cLISTOPx( cUNOPx( entersubop )->op_first )->op_first->op_sibling; \
        arg->op_sibling = NULL;                                                     \
        OP *newop = newUNOP( OP_NULL, 0, arg );                                     \
        newop->op_type   = OP_CUSTOM;                                               \
        newop->op_ppaddr = x ## _pp;                                                \
        return newop;                                                               \
    }

#define DECL(x, cond)                           \
    DECL_RUNTIME_FUNC(x, cond)                  \
    DECL_XOP(x)                                 \
    DECL_MAIN_FUNC(x, cond)                     \
    DECL_CALL_CHK_FUNC(x)

DECL(is_ref,             1)
DECL(is_scalarref,       REFTYPE(<  SVt_PVAV) && !REFREF)
DECL(is_arrayref,        REFTYPE(== SVt_PVAV))
DECL(is_hashref,         REFTYPE(== SVt_PVHV))
DECL(is_coderef,         REFTYPE(== SVt_PVCV))
DECL(is_globref,         REFTYPE(== SVt_PVGV))
DECL(is_formatref,       REFTYPE(== SVt_PVFM))
DECL(is_ioref,           REFTYPE(== SVt_PVIO))
DECL(is_refref,          REFREF)

DECL(is_plain_ref,       PLAIN)
DECL(is_plain_scalarref, REFTYPE(<  SVt_PVAV) && !REFREF && PLAIN)
DECL(is_plain_arrayref,  REFTYPE(== SVt_PVAV) && PLAIN)
DECL(is_plain_hashref,   REFTYPE(== SVt_PVHV) && PLAIN)
DECL(is_plain_coderef,   REFTYPE(== SVt_PVCV) && PLAIN)
DECL(is_plain_globref,   REFTYPE(== SVt_PVGV) && PLAIN)
DECL(is_plain_formatref, REFTYPE(== SVt_PVFM) && PLAIN)
DECL(is_plain_ioref,     REFTYPE(== SVt_PVIO) && PLAIN)
DECL(is_plain_refref,    REFREF && PLAIN)

#define FUNC_BODY_REGEXP()       \
    dSP;                         \
    SV *ref = POPs;              \
    PUSHs(                       \
        SvRXOK(ref)              \
        ? &PL_sv_yes : &PL_sv_no \
    )

/*
    is_regexpref is a special case in which we shouldn't use the
    type (SVt_REGEXP) because there's a special macro for it.

    Previously:
    DECL(is_regexpref, SvTYPE(ref) == SVt_REGEXP, 1)

    And we're rewriting the following specific macro:
    DECL_RUNTIME_FUNC(x, cond)

    Once Devel::PPPort provides a reimplementation of SvRXOK() for older
    Perls, we can merely add this above:

        DECL(is_regexpref, SvRXOK(ref))

*/
static void
THX_xsfunc_is_regexpref (pTHX_ CV *cv)
{
    FUNC_BODY_REGEXP();
}

static inline OP *
is_regexpref_pp(pTHX)
{
    FUNC_BODY_REGEXP();
    return NORMAL;
}

DECL_XOP(is_regexpref)
DECL_CALL_CHK_FUNC(is_regexpref)

#endif /* USE_CUSTOM_OPS */

MODULE = Ref::Util		PACKAGE = Ref::Util

#if USE_CUSTOM_OPS

#define SET_OP(x, ref)                                                \
    {                                                                 \
        XopENTRY_set(& x ##_xop, xop_name, #x "_xop");                \
        XopENTRY_set(& x ##_xop, xop_desc, "'" ref "' ref check");    \
        Perl_custom_op_register(aTHX_ x ##_pp, & x ##_xop);           \
        CV *cv = newXSproto_portable(                                 \
            "Ref::Util::" #x, THX_xsfunc_ ## x, __FILE__, "$"         \
        );                                                            \
        cv_set_call_checker(cv, THX_ck_entersub_args_ ## x, (SV*)cv); \
    }


BOOT:
    {
        SET_OP( is_ref, "" )
        SET_OP( is_scalarref, "SCALAR" )
        SET_OP( is_arrayref,  "ARRAY"  )
        SET_OP( is_hashref,   "HASH"   )
        SET_OP( is_coderef,   "CODE"   )
        SET_OP( is_regexpref, "REGEXP" )
        SET_OP( is_globref,   "GLOB"   )
        SET_OP( is_formatref, "FORMAT" )
        SET_OP( is_ioref,     "IO"     )
        SET_OP( is_refref,    "REF"    )
        SET_OP( is_plain_ref, "plain" )
        SET_OP( is_plain_scalarref, "plain SCALAR" )
        SET_OP( is_plain_arrayref,  "plain ARRAY"  )
        SET_OP( is_plain_hashref,   "plain HASH"   )
        SET_OP( is_plain_coderef,   "plain CODE"   )
        SET_OP( is_plain_globref,   "plain GLOB"   )
        SET_OP( is_plain_formatref, "plain FORMAT"   )
        SET_OP( is_plain_refref,    "plain REF"   )
    }

#else /* not USE_CUSTOM_OPS */

SV *
is_ref(SV *ref)
    PPCODE:
        XSUB_BODY(1);

SV *
is_scalarref(SV *ref)
    PPCODE:
        XSUB_BODY( REFTYPE(< SVt_PVAV) && !REFREF );

SV *
is_arrayref(SV *ref)
    PPCODE:
        XSUB_BODY(REFTYPE(== SVt_PVAV));

SV *
is_hashref(SV *ref)
    PPCODE:
        XSUB_BODY(REFTYPE(== SVt_PVHV));

SV *
is_coderef(SV *ref)
    PPCODE:
        XSUB_BODY(REFTYPE(== SVt_PVCV));

SV *
is_regexpref(SV *ref)
    PPCODE:
        /*
           it's okay to do the #if checks here
           (instead of the implementation above for both opcode and xsub)
           because opcodes aren't supported in such old perls anyway
        */
/* 5.9.x and under */
#if PERL_VERSION < 10
        if ( !SvROK(ref) ) {
            XSRETURN_NO;
            return;
        }

        SV*  val  = SvRV(ref);
        U32 type = SvTYPE(val); /* XXX: Data::Dumper uses U32, correct? */
        char* refval;

        if ( SvOBJECT(val) )
            refval = HvNAME( SvSTASH(val) ); /* originally HvNAME_get */
        else
            refval = Nullch;

        if (refval && *refval == 'R' && strEQ(refval, "Regexp"))
            XSRETURN_YES;
        else
            XSRETURN_NO;
#else
    /* 5.10.x and above */
    /* SvRXOK() introduced by AEvar in:
       f7e711955148e1ce710988aa3010c41ca8085a03
    */
    SvRXOK(ref) ? XSRETURN_YES : XSRETURN_NO;
#endif

SV *
is_globref(SV *ref)
    PPCODE:
        XSUB_BODY(REFTYPE(== SVt_PVGV));

SV *
is_formatref(SV *ref)
    PPCODE:
#if PERL_VERSION < 7
        croak("is_formatref() isn't available on Perl 5.6.x and under");
#else
        XSUB_BODY(REFTYPE(== SVt_PVFM));
#endif

SV *
is_ioref(SV *ref)
    PPCODE:
        XSUB_BODY(REFTYPE(== SVt_PVIO));

SV *
is_refref(SV *ref)
    PPCODE:
        XSUB_BODY(REFREF);

SV *
is_plain_ref(SV *ref)
    PPCODE:
        XSUB_BODY(PLAIN);

SV *
is_plain_scalarref(SV *ref)
    PPCODE:
        XSUB_BODY(REFTYPE(< SVt_PVAV) && !REFREF && PLAIN);

SV *
is_plain_arrayref(SV *ref)
    PPCODE:
        XSUB_BODY(REFTYPE(== SVt_PVAV) && PLAIN);

SV *
is_plain_hashref(SV *ref)
    PPCODE:
        XSUB_BODY(REFTYPE(== SVt_PVHV) && PLAIN);

SV *
is_plain_coderef(SV *ref)
    PPCODE:
        XSUB_BODY(REFTYPE(== SVt_PVCV) && PLAIN);

SV *
is_plain_globref(SV *ref)
    PPCODE:
        XSUB_BODY(REFTYPE(== SVt_PVGV) && PLAIN);

SV *
is_plain_formatref(SV *ref)
    PPCODE:
#if PERL_VERSION < 7
        croak("is_plain_formatref() isn't available on Perl 5.6.x and under");
#else
        XSUB_BODY(REFTYPE(== SVt_PVFM) && PLAIN);
#endif

SV *
is_plain_refref(SV *ref)
    PPCODE:
        XSUB_BODY(REFREF && PLAIN);

#endif /* not USE_CUSTOM_OPS */
