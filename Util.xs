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

#define CODE_SUB(ref, op, type)       \
    (                                 \
        SvROK(ref) && (               \
            SvTYPE(SvRV(ref)) op type \
            || SvROK(SvRV(ref))       \
        )                             \
    )

#define XSUB_BODY(ref, op, type) \
    CODE_SUB(ref, op, type)      \
    ? XSRETURN_YES : XSRETURN_NO

#define FUNC_BODY(op, type)      \
    dSP;                         \
    SV *ref = POPs;              \
    PUSHs(                       \
        CODE_SUB(ref, op, type)  \
        ? &PL_sv_yes : &PL_sv_no \
    )

#if USE_CUSTOM_OPS

#define DECL_RUNTIME_FUNC(x, op, type) \
    static void                        \
    THX_xsfunc_ ## x (pTHX_ CV *cv)    \
    {                                  \
        FUNC_BODY(op, type);           \
    }

#define DECL_XOP(x) \
    static XOP x ## _xop;

#define DECL_MAIN_FUNC(x,op,type) \
    static inline OP *            \
    x ## _pp(pTHX)                \
    {                             \
        FUNC_BODY(op, type);      \
        return NORMAL;            \
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

#define DECL(x,op,type)            \
    DECL_RUNTIME_FUNC(x, op, type) \
    DECL_XOP(x)                    \
    DECL_MAIN_FUNC(x,op,type)      \
    DECL_CALL_CHK_FUNC(x)

DECL(is_scalarref, <,  SVt_PVAV)
DECL(is_arrayref,  ==, SVt_PVAV)
DECL(is_hashref,   ==, SVt_PVHV)
DECL(is_coderef,   ==, SVt_PVCV)
DECL(is_regexpref, ==, SVt_REGEXP)
DECL(is_globref,   ==, SVt_PVGV)
DECL(is_formatref, ==, SVt_PVFM)
DECL(is_ioref,     ==, SVt_PVIO)
DECL(is_refref,    ==, SVt_LAST+1) /* cannot match a real svtype value */

/* start is_ref */

/* this is the equivalent of DECL_RUNTIME_FUNC */
static void
THX_xsfunc_is_ref (pTHX_ CV *cv)
{
    dSP;
    SV *ref = POPs;
    PUSHs( SvROK(ref) ? &PL_sv_yes : &PL_sv_no );
}

DECL_XOP(is_ref)

/* this is the equivalent of DECL_MAIN_FUNC */

static inline OP *
is_ref_pp(pTHX)
{
    dSP;
    SV *ref = POPs;
    PUSHs( SvROK(ref) ? &PL_sv_yes : &PL_sv_no );
    return NORMAL;
}

DECL_CALL_CHK_FUNC(is_ref)

/* end is_ref */

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
    }

#else /* not USE_CUSTOM_OPS */

SV *
is_ref(SV *ref)
    PPCODE:
        SvROK(ref) ? XSRETURN_YES : XSRETURN_NO;

SV *
is_scalarref(SV *ref)
    PPCODE:
        XSUB_BODY( ref, <, SVt_PVAV );

SV *
is_arrayref(SV *ref)
    PPCODE:
        XSUB_BODY( ref, ==, SVt_PVAV );

SV *
is_hashref(SV *ref)
    PPCODE:
        XSUB_BODY( ref, ==, SVt_PVHV );

SV *
is_coderef(SV *ref)
    PPCODE:
        XSUB_BODY( ref, ==, SVt_PVCV );

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
    /* 5.11.x and under */
    /* SvRXOK() introduced by AEvar in:
       f7e711955148e1ce710988aa3010c41ca8085a03
    */
#   if PERL_VERSION < 12
        SvRXOK(ref) ? XSRETURN_YES : XSRETURN_NO;
#   else
    /* 5.12.x and up, SVt_REGEXP available */
        XSUB_BODY( ref, ==, SVt_REGEXP );
#   endif
#endif

SV *
is_globref(SV *ref)
    PPCODE:
        XSUB_BODY( ref, ==, SVt_PVGV );

SV *
is_formatref(SV *ref)
    PPCODE:
#if PERL_VERSION < 7
        croak("is_formatref() isn't available on Perl 5.6.x and under");
#else
        XSUB_BODY( ref, ==, SVt_PVFM );
#endif

SV *
is_ioref(SV *ref)
    PPCODE:
        XSUB_BODY( ref, ==, SVt_PVIO );

SV *
is_refref(SV *ref)
    PPCODE:
        /*
           There's SVt_RV but it's aliased to SVt_IV,
           so that would mean any check for reference
           would also match any reference to an integer.
           Instead we provide an integer which will explicitly NOT MATCH.
           That will force the macro above to also check for reference
           to reference.
           If you find this awkward, Please teach me a better way. :)
        */
        XSUB_BODY( ref, ==, SVt_LAST+1 );

#endif /* not USE_CUSTOM_OPS */
