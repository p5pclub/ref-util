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

#define CODE_SUB(ref, op, type) \
    ( SvROK(ref) && SvTYPE(SvRV(ref)) op type )

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
    /* FIXME: is_refref ? */
    {
        SET_OP( is_scalarref, "SCALAR" )
        SET_OP( is_arrayref, "ARRAY" )
        SET_OP( is_hashref, "HASH" )
        SET_OP( is_coderef, "CODE" )
        SET_OP( is_regexpref, "REGEXP" )
        SET_OP( is_globref, "GLOB" )
        SET_OP( is_formatref, "FORMAT" )
        SET_OP( is_ioref, "IO" )
    }

#else /* not USE_CUSTOM_OPS */

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
        XSUB_BODY( ref, ==, SVt_REGEXP );

SV *
is_globref(SV *ref)
    PPCODE:
        XSUB_BODY( ref, ==, SVt_PVGV );

SV *
is_formatref(SV *ref)
    PPCODE:
        XSUB_BODY( ref, ==, SVt_PVFM );

SV *
is_ioref(SV *ref)
    PPCODE:
        XSUB_BODY( ref, ==, SVt_PVIO );

#endif /* not USE_CUSTOM_OPS */