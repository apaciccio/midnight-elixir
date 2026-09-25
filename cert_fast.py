#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# cert_fast.py - Certificatore a varianza ridotta per MIDNIGHT ELIXIR.
# La probabilita' di trigger (4+ scatter su 30 celle i.i.d.) e' una BINOMIALE
# calcolata in forma ESATTA -> sparisce la fonte principale di rumore.
# Restano da simulare solo: RTP del gioco base, e il valore medio di un
# episodio di free spin per ciascun premio (10/15/20 giri).
#
# Uso:  python3 cert_fast.py [n_base] [m_fs_per_premio]

import sys, math, random
import elixir_sim as E

def binom_pmf(n, k, p):
    return math.comb(n, k) * (p**k) * ((1-p)**(n-k))

def certifica(n_base=3_000_000, m_fs=200_000):
    random.seed(20260922)

    # --- probabilita' scatter esatte ---
    p_scat = E.W_BASE[E.SCAT] / sum(E.W_BASE.values())
    P = [binom_pmf(E.CELLS, k, p_scat) for k in range(E.CELLS+1)]
    P4 = P[4]; P5 = P[5]; P6plus = sum(P[6:])
    P_trig = P4 + P5 + P6plus
    print(f"p(scatter per cella) = {p_scat:.5f}")
    print(f"P(4)={P4:.5e}  P(5)={P5:.5e}  P(>=6)={P6plus:.5e}")
    print(f"P(trigger free spin) = {P_trig:.5e}  ->  1 ogni {1/P_trig:,.0f} spin".replace(",", "."))
    print("-"*60)

    # --- RTP gioco base (senza FS) ---
    bs = 0.0; bs2 = 0.0
    for _ in range(n_base):
        w, _, _ = E.play_spin(False, 1)
        bs += w; bs2 += w*w
    base_mean = bs / n_base
    base_var = max(bs2/n_base - base_mean*base_mean, 0.0)
    se_base = math.sqrt(base_var / n_base)
    print(f"RTP base ............. {base_mean*100:6.3f}%  (+/-{1.96*se_base*100:.3f}) su {n_base:,} spin".replace(",", "."))

    # --- valore medio di un episodio FS per premio (10/15/20) ---
    # run_freespins(k) usa FS_AWARD[min(k,6)]: k=4->10, k=5->15, k=6->20 giri
    def fs_mean_for(krepr, m):
        s = 0.0; s2 = 0.0; maxg = 1
        for _ in range(m):
            tot, _, mg = E.run_freespins(krepr)
            s += tot; s2 += tot*tot
            if mg > maxg: maxg = mg
        mean = s/m; var = max(s2/m - mean*mean, 0.0)
        return mean, math.sqrt(var/m), maxg

    e10, se10, mg10 = fs_mean_for(4, m_fs)
    e15, se15, mg15 = fs_mean_for(5, m_fs)
    e20, se20, mg20 = fs_mean_for(6, m_fs)
    print(f"FS medio 10 giri ..... {e10:7.1f}x  (+/-{1.96*se10:.1f})   molt.max x{mg10}")
    print(f"FS medio 15 giri ..... {e15:7.1f}x  (+/-{1.96*se15:.1f})   molt.max x{mg15}")
    print(f"FS medio 20 giri ..... {e20:7.1f}x  (+/-{1.96*se20:.1f})   molt.max x{mg20}")
    print("-"*60)

    # --- combinazione ---
    fs_rtp = P4*e10 + P5*e15 + P6plus*e20
    # varianza del contributo FS (P esatte, quindi solo varianza dei valori medi)
    var_fs_rtp = (P4*se10)**2 + (P5*se15)**2 + (P6plus*se20)**2
    se_fs_rtp = math.sqrt(var_fs_rtp)

    rtp = base_mean + fs_rtp
    se_rtp = math.sqrt(se_base**2 + se_fs_rtp**2)
    ci = 1.96 * se_rtp * 100

    print(f"RTP base ............. {base_mean*100:6.3f}%   ({base_mean/rtp*100:.1f}%)")
    print(f"RTP free spin ........ {fs_rtp*100:6.3f}%   ({fs_rtp/rtp*100:.1f}%)")
    print("="*60)
    print(f"RTP TOTALE ........... {rtp*100:6.3f}%   (IC 95%: +/-{ci:.3f})")
    print(f"PAY_SCALE = {E.PAY_SCALE}")
    print("="*60)
    # suggerimento di taratura (RTP lineare in PAY_SCALE)
    for target in (94.8, 96.5):
        print(f"  per {target}%: PAY_SCALE = {E.PAY_SCALE * target/ (rtp*100):.4f}")
    return rtp, ci

if __name__ == "__main__":
    nb = int(sys.argv[1]) if len(sys.argv) > 1 else 3_000_000
    m  = int(sys.argv[2]) if len(sys.argv) > 2 else 200_000
    certifica(nb, m)
