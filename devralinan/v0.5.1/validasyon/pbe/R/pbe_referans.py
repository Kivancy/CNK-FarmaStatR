# =============================================================================
# CNK-FarmaStatR · PBE · BAĞIMSIZ referans uygulama (Python)
# Kaynak: FDA PSG_020929 (Aralık 2025), Appendix — Population Bioequivalence.
# Bu dosya R kodundan kopyalanmamıştır; PSG'deki adımlardan yazılmıştır.
#   m: kap başına aşama (life stage) sayısı; l: parti; n: parti başına kap
#   MSB = m·Σ(ȳ_kap − ȳ)² / (N_kap − 1);  MSW = ΣΣ(y − ȳ_kap)² / (N_kap·(m − 1))
#   σ² = MSB/m + (m−1)·MSW/m;  θ_P = ((ln 1.11)² + 0.01)/σ_T0²;  σ_T0 = 0.1
# =============================================================================
import math
from collections import defaultdict
from scipy.stats import t as tdist, chi2

def pbe(satirlar, log=False, tek_yonlu=False, sigma_T0=0.1, alfa=0.05):
    veri = {'TEST': defaultdict(list), 'REF': defaultdict(list)}
    asama = {'TEST': set(), 'REF': set()}
    for s in satirlar:
        y = math.log(s['score']) if log else s['score']
        veri[s['Product']][(s['Batches'], s['Container'])].append(y)
        asama[s['Product']].add(s['Stage'])
    if asama['TEST'] != asama['REF']: raise ValueError('Stage kümeleri eşleşmiyor')
    m = len(asama['TEST'])
    def kareler(kaplar):
        tum = [y for v in kaplar.values() for y in v]
        ort = sum(tum) / len(tum); N = len(kaplar)
        msb = m * sum((sum(v)/len(v) - ort) ** 2 for v in kaplar.values()) / (N - 1)
        msw = (sum((y - sum(v)/len(v)) ** 2 for v in kaplar.values() for y in v) / (N * (m - 1))) if m > 1 else 0.0
        return ort, msb, msw, N
    mT, msbT, mswT, NT = kareler(veri['TEST']); mR, msbR, mswR, NR = kareler(veri['REF'])
    th = (math.log(1.11) ** 2 + 0.01) / sigma_T0 ** 2
    aktif = tek_yonlu and mT < mR
    E = dict(D=0.0 if aktif else (mT - mR) ** 2, **{'1': msbT / m, '2': mswT * (m - 1) / m,
             '3s': -(1 + th) * msbR / m, '4s': -(1 + th) * mswR * (m - 1) / m,
             '3c': -msbR / m, '4c': -mswR * (m - 1) / m})
    tq = tdist.ppf(1 - alfa, NT + NR - 2)
    H = {'D': 0.0 if aktif else (math.sqrt(E['D']) + tq * math.sqrt(msbT / (NT * m) + msbR / (NR * m))) ** 2}
    H['1'] = (NT - 1) * E['1'] / chi2.ppf(alfa, NT - 1)
    H['3s'] = (NR - 1) * E['3s'] / chi2.ppf(1 - alfa, NR - 1)
    H['3c'] = (NR - 1) * E['3c'] / chi2.ppf(1 - alfa, NR - 1)
    if m > 1:
        H['2'] = NT * (m - 1) * E['2'] / chi2.ppf(alfa, NT * (m - 1))
        H['4s'] = NR * (m - 1) * E['4s'] / chi2.ppf(1 - alfa, NR * (m - 1))
        H['4c'] = NR * (m - 1) * E['4c'] / chi2.ppf(1 - alfa, NR * (m - 1))
    else:
        H['2'] = H['4s'] = H['4c'] = 0.0
    U = {k: (H[k] - E[k]) ** 2 for k in E}
    Eq_s = E['D'] + E['1'] + E['2'] + E['3s'] + E['4s']
    Eq_c = E['D'] + E['1'] + E['2'] + E['3c'] + E['4c'] - th * sigma_T0 ** 2
    Uq_s = U['D'] + U['1'] + U['2'] + U['3s'] + U['4s']
    Uq_c = U['D'] + U['1'] + U['2'] + U['3c'] + U['4c']
    sR = math.sqrt(msbR / m + (m - 1) * mswR / m)
    ref_olcekli = sR > sigma_T0
    Hf = Eq_s + math.sqrt(Uq_s) if ref_olcekli else Eq_c + math.sqrt(Uq_c)
    return dict(m=m, E_D=E['D'], E1=E['1'], E2=E['2'], E3s=E['3s'], E4s=E['4s'], E3c=E['3c'], E4c=E['4c'],
                H_D=H['D'], H1=H['1'], H2=H['2'], H3s=H['3s'], H4s=H['4s'], H3c=H['3c'], H4c=H['4c'],
                U_D=U['D'], U1=U['1'], U2=U['2'], U3s=U['3s'], U4s=U['4s'], U3c=U['3c'], U4c=U['4c'],
                Eq_Ref=Eq_s, Uq_Ref=Uq_s, H_eta_Ref=Eq_s + math.sqrt(Uq_s),
                Eq_Const=Eq_c, Uq_Const=Uq_c, H_eta_Const=Eq_c + math.sqrt(Uq_c),
                Sigma_R=sR, criterion='Reference-scaled' if ref_olcekli else 'Constant-scaled',
                pass_fail='PASS' if Hf <= 0 else 'FAIL', H_eta_final=Hf)
