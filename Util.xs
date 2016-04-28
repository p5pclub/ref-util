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

/* This can go away once Devel::PPPort provides an implementation. The Perl
 * core first provided an implementation in 5.9.5; this is almost exactly
 * the logic used in relevant parts of the core as far back as at least
 * 5.005. Note also that this static function is likely to be inlined by the
 * compiler. */
#ifndef SvRXOK
#define SvRXOK(sv) refutil_sv_rxok(sv)
static int
refutil_sv_rxok(SV *ref)
{
    if (SvROK(ref)) {
        SV *sv = SvRV(ref);
        if (SvMAGICAL(sv)) {
            MAGIC *mg = mg_find(sv, PERL_MAGIC_qr);
            if (mg && mg->mg_obj) {
                return 1;
            }
        }
    }
    return 0;
}
#endif

/* Boolean expression that considers an SV* named "ref" */
#define COND(expr) (SvROK(ref) && expr)

#define PLAIN         (!sv_isobject(ref))
#define REFTYPE(tail) (SvTYPE(SvRV(ref)) tail)
#define REFREF        (SvROK( SvRV(ref) ))

#if PERL_VERSION >= 7
#define FORMATREF REFTYPE(== SVt_PVFM)
#else
#define FORMATREF (croak("is_formatref() isn't available on Perl 5.6.x and under"), 0)
#endif

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
DECL(is_formatref,       FORMATREF)
DECL(is_ioref,           REFTYPE(== SVt_PVIO))
DECL(is_regexpref,       SvRXOK(ref))
DECL(is_refref,          REFREF)

DECL(is_plain_ref,       PLAIN)
DECL(is_plain_scalarref, REFTYPE(<  SVt_PVAV) && !REFREF && PLAIN)
DECL(is_plain_arrayref,  REFTYPE(== SVt_PVAV) && PLAIN)
DECL(is_plain_hashref,   REFTYPE(== SVt_PVHV) && PLAIN)
DECL(is_plain_coderef,   REFTYPE(== SVt_PVCV) && PLAIN)
DECL(is_plain_globref,   REFTYPE(== SVt_PVGV) && PLAIN)
DECL(is_plain_formatref, FORMATREF && PLAIN)
DECL(is_plain_ioref,     REFTYPE(== SVt_PVIO) && PLAIN)
DECL(is_plain_refref,    REFREF && PLAIN)

#endif /* USE_CUSTOM_OPS */

MODULE = Ref::Util		PACKAGE = Ref::Util

#if USE_CUSTOM_OPS

#define INSTALL(x, ref)                                                \
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
        INSTALL( is_ref, "" )
        INSTALL( is_scalarref, "SCALAR" )
        INSTALL( is_arrayref,  "ARRAY"  )
        INSTALL( is_hashref,   "HASH"   )
        INSTALL( is_coderef,   "CODE"   )
        INSTALL( is_regexpref, "REGEXP" )
        INSTALL( is_globref,   "GLOB"   )
        INSTALL( is_formatref, "FORMAT" )
        INSTALL( is_ioref,     "IO"     )
        INSTALL( is_refref,    "REF"    )
        INSTALL( is_plain_ref, "plain" )
        INSTALL( is_plain_scalarref, "plain SCALAR" )
        INSTALL( is_plain_arrayref,  "plain ARRAY"  )
        INSTALL( is_plain_hashref,   "plain HASH"   )
        INSTALL( is_plain_coderef,   "plain CODE"   )
        INSTALL( is_plain_globref,   "plain GLOB"   )
        INSTALL( is_plain_formatref,   "plain FORMAT"   )
        INSTALL( is_plain_refref,   "plain REF"   )
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
        XSUB_BODY(SvRXOK(ref));

SV *
is_globref(SV *ref)
    PPCODE:
        XSUB_BODY(REFTYPE(== SVt_PVGV));

SV *
is_formatref(SV *ref)
    PPCODE:
        XSUB_BODY(FORMATREF);

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
        XSUB_BODY(FORMATREF && PLAIN);

SV *
is_plain_refref(SV *ref)
    PPCODE:
        XSUB_BODY(REFREF && PLAIN);

#endif /* not USE_CUSTOM_OPS */
