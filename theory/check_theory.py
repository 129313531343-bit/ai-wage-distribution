"""Symbolic and high-precision numerical checks of every result in the theory box.

Run:  python theory/check_theory.py      (needs sympy; see tests/requirements.txt)

Model (notation as in Section 3 of the author's honours thesis):
    Y = [w V^rho + (1-w) X^rho]^(1/rho)
    V = [lam U^etaV + (1-lam) KM^etaV]^(1/etaV)      machinery with unskilled labour
    X = [mu  S^etaX + (1-mu)  KI^etaX]^(1/etaX)      ICT with skilled labour
    U = AU NU,  S = AS NS
    sigma_VX = 1/(1-rho), sigma_VU = 1/(1-etaV), sigma_XS = 1/(1-etaX)
Wages are marginal products of hours: wS = dY/dNS, wU = dY/dNU, and the premium is pi = wS/wU.

Each claim is checked two ways: (1) sympy simplification of LHS - RHS to zero, where it
completes; (2) evaluation of LHS - RHS at 25 random admissible parameter points with
50-digit precision. The script exits non-zero if any check fails.
"""
import random
import sys

import sympy as sp

random.seed(101)
sp.init_printing()
failures = []

w, lam, mu = sp.symbols("omega lambda mu", positive=True)
rho, eV, eX = sp.symbols("rho eta_V eta_X", real=True)
NS, NU, AS, AU, KI, KM, KA, zeta, psi, phi = sp.symbols(
    "N_S N_U A_S A_U K_I K_M K_A zeta psi phi", positive=True)
sVX, sVU, sXS = 1 / (1 - rho), 1 / (1 - eV), 1 / (1 - eX)
logR, c = sp.symbols("logR c", real=True)


def model(U, S, KIe, KMe):
    V = (lam * U**eV + (1 - lam) * KMe**eV) ** (1 / eV)
    X = (mu * S**eX + (1 - mu) * KIe**eX) ** (1 / eX)
    Y = (w * V**rho + (1 - w) * X**rho) ** (1 / rho)
    return V, X, Y


def rational(lo, hi):
    """An exact rational in [lo, hi], so 50-digit evaluation is not limited by float rounding."""
    return sp.Rational(random.randint(int(lo * 1000), int(hi * 1000)), 1000)


def random_point():
    """Admissible parameters: shares in (0,1); substitution parameters below 1 and away from 0."""
    def subst():
        return random.choice([rational(-3, -0.05), rational(0.05, 0.95)])
    return {w: rational(0.1, 0.9), lam: rational(0.1, 0.9), mu: rational(0.1, 0.9),
            rho: subst(), eV: subst(), eX: subst(),
            NS: rational(0.5, 3), NU: rational(0.5, 3), AS: rational(0.5, 3),
            AU: rational(0.5, 3), KI: rational(0.5, 3), KM: rational(0.5, 3),
            KA: rational(0.2, 3), zeta: rational(0.2, 2), psi: rational(0.2, 2),
            phi: rational(1.1, 5), logR: rational(-2, 2), c: rational(-2, 2)}


def check(name, lhs, rhs, try_symbolic=True):
    diff = lhs - rhs
    symbolic = "not attempted"
    if try_symbolic:
        try:
            s = sp.simplify(sp.powsimp(sp.expand_log(sp.together(diff), force=True), force=True))
            symbolic = "zero" if s == 0 else "did not reduce to zero"
        except Exception as e:  # noqa: BLE001
            symbolic = f"error ({type(e).__name__})"
    worst = 0
    for _ in range(25):
        val = abs(sp.N(diff.subs(random_point()), 50))
        worst = max(worst, val)
    ok = worst < sp.Float("1e-35")
    print(f"[{'PASS' if ok else 'FAIL'}] {name}: max |LHS-RHS| over 25 random points = {sp.N(worst, 3)}; symbolic: {symbolic}")
    if not ok:
        failures.append(name)


def premium(U, S, KIe, KMe, wrt_S, wrt_U):
    _, _, Y = model(U, S, KIe, KMe)
    return sp.diff(Y, wrt_S) / sp.diff(Y, wrt_U)


# ---------------------------------------------------------------------------------------
# 0. Thesis equation (8): pi = cpi * (V/X)^(1/sVX) (X/S)^(1/sXS) (U/V)^(1/sVU) * AS/AU
U0, S0 = AU * NU, AS * NS
V0, X0, Y0 = model(U0, S0, KI, KM)
pi0 = premium(U0, S0, KI, KM, NS, NU)
cpi = (1 - w) * mu / (w * lam)
R0 = (V0 / X0) ** (1 / sVX) * (X0 / S0) ** (1 / sXS) * (U0 / V0) ** (1 / sVU)
check("Thesis eq. (8): premium equals c_pi * R * A_S/A_U", sp.log(pi0), sp.log(cpi * R0 * AS / AU))

# Within-branch cost shares at the current point (exact CES shares).
sI = (1 - mu) * KI**eX / X0**eX          # ICT share of the skilled branch
sS = mu * S0**eX / X0**eX                # skilled-labour share of the skilled branch
sM = (1 - lam) * KM**eV / V0**eV         # machinery share of the unskilled branch
sU = lam * U0**eV / V0**eV               # unskilled-labour share of the unskilled branch

# 1. Proposition 1 (thesis benchmark): exact log-derivatives with respect to the capital stocks
check("P1a: dlog(pi)/dlog(K_I) = s_I (1/sXS - 1/sVX)",
      KI * sp.diff(sp.log(pi0), KI), sI * (1 / sXS - 1 / sVX))
check("P1b: dlog(pi)/dlog(K_M) = s_M (1/sVX - 1/sVU)",
      KM * sp.diff(sp.log(pi0), KM), sM * (1 / sVX - 1 / sVU))

# 2. Proposition 2 (scenario C): AI is ICT-type capital, K_I_eff = K_I + zeta K_A
KIe = KI + zeta * KA
VC, XC, _ = model(U0, S0, KIe, KM)
piC = premium(U0, S0, KIe, KM, NS, NU)
sIC = (1 - mu) * KIe**eX / XC**eX
check("P2: dlog(pi)/dlog(K_A) = [zeta K_A/(K_I + zeta K_A)] s_I (1/sXS - 1/sVX)",
      KA * sp.diff(sp.log(piC), KA), (zeta * KA / KIe) * sIC * (1 / sXS - 1 / sVX))

# 3. Proposition 3 (scenario D): AI performs skilled tasks, S = A_S N_S + psi K_A
SD = AS * NS + psi * KA
VD, XD, _ = model(U0, SD, KI, KM)
piD = premium(U0, SD, KI, KM, NS, NU)
sSD = mu * SD**eX / XD**eX
rhsD = -(psi * KA / SD) * (sSD / sVX + (1 - sSD) / sXS)
check("P3: dlog(pi)/dlog(K_A) = -[psi K_A/S] (s_S/sVX + (1-s_S)/sXS)",
      KA * sp.diff(sp.log(piD), KA), rhsD)
# Sign: the bracket is a convex combination of 1/sVX = 1-rho > 0 and 1/sXS = 1-etaX > 0.
bracket = sSD * (1 - rho) + (1 - sSD) * (1 - eX)
check("P3 sign: bracket equals s_S(1-rho) + (1-s_S)(1-etaX), positive for rho, etaX < 1",
      sSD / sVX + (1 - sSD) / sXS, bracket, try_symbolic=True)

# 4. Remark (AI performs unskilled tasks): U = A_U N_U + psi K_A
UE = AU * NU + psi * KA
VE, XE, _ = model(UE, S0, KI, KM)
piE = premium(UE, S0, KI, KM, NS, NU)
sUE = lam * UE**eV / VE**eV
check("Remark: dlog(pi)/dlog(K_A) = +[psi K_A/U] (s_U/sVX + (1-s_U)/sVU)",
      KA * sp.diff(sp.log(piE), KA), (psi * KA / UE) * (sUE / sVX + (1 - sUE) / sVU))

# 4b. Fully symbolic checks with the substitution parameters fixed at exact rationals.
#     With symbolic exponents sympy cannot always cancel the CES powers, so each proposition is
#     also checked symbolically in every quantity and share for three exponent combinations.
#     Shares are written as 1/(1+q), q > 0, so sympy knows they lie in (0, 1).
qw, ql, qm = sp.symbols("q_w q_l q_m", positive=True)
share_subs = {w: 1 / (1 + qw), lam: 1 / (1 + ql), mu: 1 / (1 + qm)}
combos = [(sp.Rational(1, 2), sp.Rational(1, 3), -1),
          (sp.Rational(-1, 2), sp.Rational(2, 3), sp.Rational(1, 4)),
          (sp.Rational(1, 3), -2, sp.Rational(-1, 3))]
claims = {
    "P1a": (KI * sp.diff(sp.log(pi0), KI), sI * (1 / sXS - 1 / sVX)),
    "P1b": (KM * sp.diff(sp.log(pi0), KM), sM * (1 / sVX - 1 / sVU)),
    "P2": (KA * sp.diff(sp.log(piC), KA), (zeta * KA / KIe) * sIC * (1 / sXS - 1 / sVX)),
    "P3": (KA * sp.diff(sp.log(piD), KA), rhsD),
    "Remark": (KA * sp.diff(sp.log(piE), KA), (psi * KA / UE) * (sUE / sVX + (1 - sUE) / sVU)),
}
for name, (lhs, rhs) in claims.items():
    results = []
    for r_, v_, x_ in combos:
        sub = {rho: r_, eV: v_, eX: x_, **share_subs}
        d = sp.simplify(sp.together((lhs - rhs).subs(sub)))
        results.append(d == 0)
    ok = all(results)
    print(f"[{'PASS' if ok else 'FAIL'}] {name}: symbolic in all quantities and shares, exponents fixed at "
          f"{len(combos)} rational combinations -> {'zero' if ok else results}")
    if not ok:
        failures.append(name + " (symbolic, fixed exponents)")

# 5. Directed technical change (thesis eq. 20): log(AS/AU) = [log R + log(NS/NU)]/(phi-1) + c
#    Substituting into log(pi) = log(cpi) + log(R) + log(AS/AU) scales log R by phi/(phi-1).
logpi_dtc = sp.log(cpi) + logR + (logR + sp.log(NS / NU)) / (phi - 1) + c
check("DTC: log(pi) = log(cpi) + c + phi/(phi-1) log R + log(NS/NU)/(phi-1)",
      logpi_dtc, sp.log(cpi) + c + phi / (phi - 1) * logR + sp.log(NS / NU) / (phi - 1))

# 6. Numbers with the thesis's production elasticities (after removing induced technology):
#    sigma_VX = 2.21, sigma_XS = 0.94, sigma_VU = 1.56 (as reported by the author).
num = {"sigma_VX": 2.21, "sigma_XS": 0.94, "sigma_VU": 1.56}
ict = 1 / num["sigma_XS"] - 1 / num["sigma_VX"]
mach = 1 / num["sigma_VX"] - 1 / num["sigma_VU"]
print(f"\nWith the thesis elasticities: 1/sXS - 1/sVX = {ict:.4f} (> 0: ICT raises the premium); "
      f"1/sVX - 1/sVU = {mach:.4f} (< 0: machinery lowers it).")
print(f"Scenario D bracket lies between 1/sVX = {1/num['sigma_VX']:.4f} and 1/sXS = {1/num['sigma_XS']:.4f} "
      f"for any skilled-labour share, so the effect is negative.")
if not (ict > 0 and mach < 0):
    failures.append("thesis sign pattern")

if failures:
    print("\nFAILED:", failures)
    sys.exit(1)
print("\nAll theory checks passed.")
