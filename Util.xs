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

#define JUSTSCALAR (                            \
        REFTYPE(< SVt_PVAV)                     \
        && REFTYPE(!= SVt_PVGV)                 \
        && (SvTYPE(SvRV(ref)) != SVt_PVGV)      \
        && !REFREF                              \
        && !SvRXOK(ref)                         \
        )

#if PERL_VERSION >= 7
#define FORMATREF REFTYPE(== SVt_PVFM)
#else
#define FORMATREF (croak("is_formatref() isn't available on Perl 5.6.x and under"), 0)
#endif

#define FUNC_BODY(cond)                                 \
    SV *ref = POPs;                                     \
    PUSHs( COND(cond) ? &PL_sv_yes : &PL_sv_no )

#define DECL_RUNTIME_FUNC(x, cond)                              \
    static void                                                 \
    THX_xsfunc_ ## x (pTHX_ CV *cv)                             \
    {                                                           \
        dXSARGS;                                                \
        if (items != 1)                                         \
            Perl_croak(aTHX_ "Usage: Ref::Util::" #x "(ref)");  \
        FUNC_BODY(cond);                                        \
    }

#define DECL_XOP(x) \
    static XOP x ## _xop;

#define DECL_MAIN_FUNC(x, cond)                 \
    static inline OP *                          \
    x ## _pp(pTHX)                              \
    {                                           \
        dSP;                                    \
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

#if !USE_CUSTOM_OPS

#define DECL(x, cond) DECL_RUNTIME_FUNC(x, cond)
#define INSTALL(x, ref) \
    newXSproto("Ref::Util::" #x, THX_xsfunc_ ## x, __FILE__, "$");

#else

#define DECL(x, cond)                           \
    DECL_RUNTIME_FUNC(x, cond)                  \
    DECL_XOP(x)                                 \
    DECL_MAIN_FUNC(x, cond)                     \
    DECL_CALL_CHK_FUNC(x)

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

#endif

DECL(is_ref,             1)
DECL(is_scalarref,       JUSTSCALAR)
DECL(is_arrayref,        REFTYPE(== SVt_PVAV))
DECL(is_hashref,         REFTYPE(== SVt_PVHV))
DECL(is_coderef,         REFTYPE(== SVt_PVCV))
DECL(is_globref,         REFTYPE(== SVt_PVGV))
DECL(is_formatref,       FORMATREF)
DECL(is_ioref,           REFTYPE(== SVt_PVIO))
DECL(is_regexpref,       SvRXOK(ref))
DECL(is_refref,          REFREF)

DECL(is_plain_ref,       PLAIN)
DECL(is_plain_scalarref, JUSTSCALAR && PLAIN)
DECL(is_plain_arrayref,  REFTYPE(== SVt_PVAV) && PLAIN)
DECL(is_plain_hashref,   REFTYPE(== SVt_PVHV) && PLAIN)
DECL(is_plain_coderef,   REFTYPE(== SVt_PVCV) && PLAIN)
DECL(is_plain_globref,   REFTYPE(== SVt_PVGV) && PLAIN)
DECL(is_plain_formatref, FORMATREF && PLAIN)
DECL(is_plain_ioref,     REFTYPE(== SVt_PVIO) && PLAIN)
DECL(is_plain_refref,    REFREF && PLAIN)

DECL(is_blessed_ref,       !PLAIN)
DECL(is_blessed_scalarref, JUSTSCALAR && !PLAIN)
DECL(is_blessed_arrayref,  REFTYPE(== SVt_PVAV) && !PLAIN)
DECL(is_blessed_hashref,   REFTYPE(== SVt_PVHV) && !PLAIN)
DECL(is_blessed_coderef,   REFTYPE(== SVt_PVCV) && !PLAIN)
DECL(is_blessed_globref,   REFTYPE(== SVt_PVGV) && !PLAIN)
DECL(is_blessed_formatref, FORMATREF && !PLAIN)
DECL(is_blessed_ioref,     REFTYPE(== SVt_PVIO) && !PLAIN)
DECL(is_blessed_refref,    REFREF && !PLAIN)

MODULE = Ref::Util		PACKAGE = Ref::Util

PROTOTYPES: DISABLE

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
        INSTALL( is_blessed_ref, "blessed" )
        INSTALL( is_blessed_scalarref, "blessed SCALAR" )
        INSTALL( is_blessed_arrayref,  "blessed ARRAY"  )
        INSTALL( is_blessed_hashref,   "blessed HASH"   )
        INSTALL( is_blessed_coderef,   "blessed CODE"   )
        INSTALL( is_blessed_globref,   "blessed GLOB"   )
        INSTALL( is_blessed_formatref,   "blessed FORMAT"   )
        INSTALL( is_blessed_refref,   "blessed REF"   )
    }
