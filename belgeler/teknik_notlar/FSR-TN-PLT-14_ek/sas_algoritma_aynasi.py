# Mirror of the SAS/IML logic (algorithm check only; not SAS syntax)
import sys, math, re, numpy as np
sas = open(sys.argv[1]).read(); csv = sys.argv[2]
def block(name):
    m = re.search(r'data %s; input x1-x&nP; datalines;\n(.*?)\n;' % name, sas, re.S)
    return np.array([[float(v) for v in l.split()] for l in m.group(1).splitlines()])
XT, XR = block('test_u'), block('ref_u')
mac = dict(re.findall(r'%let (\w+) = ([^;]+);', sas))
rule, mode, est = mac['rule'].strip(), mac['mode'].strip(), mac['est'].strip()
qa, qb, conf = float(mac['qa']), float(mac['qb']), float(mac['conf'])
rows = [l for l in open(csv) if l.strip() and not l.startswith(('#','r'))]
nT, nR = XT.shape[0], XR.shape[0]
V=[]; IT=[]; IR=[]
for l in rows:
    p = l.strip().split(','); V.append([float(x) if x else math.nan for x in p[1:5]])
    IT.append([int(x) for x in p[5:5+nT]]); IR.append([int(x) for x in p[5+nT:5+nT+nR]])
V=np.array(V); W=np.full(V.shape, np.nan)
for b in range(len(V)):
    xt = XT[np.array(IT[b])-1]; xr = XR[np.array(IR[b])-1]
    mT = np.round(xt.mean(0), 10); mR = np.round(xr.mean(0), 10); npt = XT.shape[1]
    if mode=='replika' and rule!='none':
        a = np.where((mT>85)|(mR>85))[0] if rule=='EMA' else np.where((mT>85)&(mR>85))[0]
        if len(a): npt = a[0]+1
    W[b,3]=npt
    if npt>=3:
        t=xt[:,:npt]; r=xr[:,:npt]; D=((t.mean(0)-r.mean(0))**2).sum()
        Vr=(t.var(0,ddof=1)/len(t)).sum()+(r.var(0,ddof=1)/len(r)).sum()
        W[b,0]=100-25*math.log10(1+D/npt); W[b,1]=100-25*math.log10(1+(D+Vr)/npt)
        if D>Vr: W[b,2]=100-25*math.log10(1+(D-Vr)/npt)
ok = ~np.isnan(W)&~np.isnan(V)
print('maxdiff', [np.nanmax(np.abs(W[:,k]-V[:,k])[ok[:,k]]) if ok[:,k].any() else 0 for k in range(4)],
      'nmiss', [(np.isnan(W[:,k])!=np.isnan(V[:,k])).sum() for k in range(4)])
col={'f2':0,'Ef2':1,'bcf2':2}[est]; v=np.sort(W[~np.isnan(W[:,col]),col]); n=len(v); a2=(1-conf)/2
q=[]
for p in (a2,1-a2):
    m=qa+p*(1-qa-qb); j=math.floor(n*p+m+4*2.2e-16); g=n*p+m-j
    if abs(g)<4*2.2e-16: g=0
    lo=max(1,min(n,j)); hi=max(1,min(n,j+1)); q.append((1-g)*v[lo-1]+g*v[hi-1])
print('q', q, 'platform', mac['p_lo'], mac['p_hi'])
