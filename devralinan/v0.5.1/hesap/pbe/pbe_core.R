
calc_pbe <- function(df, log_transform=FALSE, one_sided=FALSE) {
  names(df) <- c("Batches","Container","Stage","Product","score")
  df$score     <- as.numeric(df$score)
  df$Batches   <- as.character(df$Batches)
  df$Container <- as.character(df$Container)
  df$Product   <- as.character(df$Product)
  if (log_transform) df$score <- log(df$score)
  df_t <- df[df$Product=="TEST",]; df_r <- df[df$Product=="REF",]
  if (nrow(df_t)==0) stop("TEST grubu bos.")
  if (nrow(df_r)==0) stop("REF grubu bos.")
  if (anyNA(df$score)) stop("score'da NA veya gecersiz deger var. Log donusumu aktifse ham deger sifir veya negatif olamaz.")
  stages_t <- sort(unique(df_t$Stage))
  stages_r <- sort(unique(df_r$Stage))
  if (!identical(stages_t, stages_r)) {
  stop(paste0("TEST ve REF Stage kumeleri eslesmiyor. TEST: ",
              paste(stages_t, collapse=", "), " | REF: ",
              paste(stages_r, collapse=", ")))
    }
  m <- length(stages_t)
  l_t <- length(unique(df_t$Batches))
  l_r <- length(unique(df_r$Batches))
  bpb_t <- sapply(unique(df_t$Batches),function(b) length(unique(df_t$Container[df_t$Batches==b])))
  bpb_r <- sapply(unique(df_r$Batches),function(b) length(unique(df_r$Container[df_r$Batches==b])))
  n_t     <- mean(bpb_t); n_r     <- mean(bpb_r)
  total_t <- sum(bpb_t);  total_r <- sum(bpb_r)
  bal_t   <- (max(bpb_t)==min(bpb_t)); bal_r <- (max(bpb_r)==min(bpb_r))
  alpha <- 0.05; SigmaT0 <- 0.1
  Theta_p <- ((log(1.11))^2 + 0.01) / SigmaT0^2
  calc_ms <- function(ds, m_val, tot) {
    bm <- aggregate(score ~ Batches + Container, data=ds, FUN=mean)
    names(bm)[3] <- "mean_score"
    pop_mean <- mean(ds$score)
    ssb <- m_val * sum((bm$mean_score - pop_mean)^2)
    msb <- ssb / (tot - 1)
    if (m_val > 1) {
      mg  <- merge(ds, bm, by=c("Batches","Container"))
      ssw <- sum((mg$score - mg$mean_score)^2)
      msw <- ssw / (tot * (m_val - 1))
    } else { msw <- 0 }
    list(mean=pop_mean, msb=msb, msw=msw)
  }
  st <- calc_ms(df_t, m, total_t)
  sr <- calc_ms(df_r, m, total_r)
  # Modified One-Sided PBE: muT < muR ise E_D, H_D, U_D = 0
  one_sided_active <- one_sided && (st$mean < sr$mean)
  E_D <- if(one_sided_active) 0 else (st$mean-sr$mean)^2
  E1  <- st$msb/m
  E2  <- if(m>1) st$msw*(m-1)/m else 0
  E3s <- -(1+Theta_p)*sr$msb/m
  E4s <- if(m>1) -(1+Theta_p)*sr$msw*(m-1)/m else 0
  E3c <- -sr$msb/m
  E4c <- if(m>1) -sr$msw*(m-1)/m else 0
  Eq_Ref   <- E_D+E1+E2+E3s+E4s
  Eq_Const <- E_D+E1+E2+E3c+E4c-(Theta_p*SigmaT0^2)
  t_val <- qt(1-alpha, df=total_t+total_r-2)
  H_D   <- if(one_sided_active) 0 else
            (sqrt(E_D)+t_val*sqrt(st$msb/(total_t*m)+sr$msb/(total_r*m)))^2
  df_cT <- total_t-1; df_cR <- total_r-1
  H1  <- df_cT*E1/qchisq(alpha,    df=df_cT)
  H3s <- df_cR*E3s/qchisq(1-alpha, df=df_cR)
  H3c <- df_cR*E3c/qchisq(1-alpha, df=df_cR)
  if (m>1) {
    dT2 <- total_t*(m-1); dR2 <- total_r*(m-1)
    H2  <- dT2*E2/qchisq(alpha,    df=dT2)
    H4s <- dR2*E4s/qchisq(1-alpha, df=dR2)
    H4c <- dR2*E4c/qchisq(1-alpha, df=dR2)
  } else { H2<-0; H4s<-0; H4c<-0 }
  U_D  <- (H_D-E_D)^2;  U1  <- (H1-E1)^2;   U2  <- (H2-E2)^2
  U3s  <- (H3s-E3s)^2;  U4s <- (H4s-E4s)^2
  U3c  <- (H3c-E3c)^2;  U4c <- (H4c-E4c)^2
  Uq_Ref   <- U_D+U1+U2+U3s+U4s
  Uq_Const <- U_D+U1+U2+U3c+U4c
  H_eta_Ref   <- Eq_Ref   + sqrt(Uq_Ref)
  H_eta_Const <- Eq_Const + sqrt(Uq_Const)
  Sigma_R <- sqrt(sr$msb/m+(m-1)*sr$msw/m)
  Sigma_T <- sqrt(st$msb/m+(m-1)*st$msw/m)
  if (Sigma_R > SigmaT0) {
    criterion <- "Reference-scaled"
    H_eta_final <- H_eta_Ref; Eq_final <- Eq_Ref; Uq_final <- Uq_Ref
  } else {
    criterion <- "Constant-scaled"
    H_eta_final <- H_eta_Const; Eq_final <- Eq_Const; Uq_final <- Uq_Const
  }
  list(
    m=m, l_t=l_t, n_t=n_t, total_t=total_t, bal_t=bal_t,
         l_r=l_r, n_r=n_r, total_r=total_r, bal_r=bal_r,
    SigmaT0=SigmaT0, Theta_p=Theta_p, alpha=alpha,
    mean_t=st$mean, msb_t=st$msb, msw_t=st$msw,
    mean_r=sr$mean, msb_r=sr$msb, msw_r=sr$msw,
    E_D=E_D,E1=E1,E2=E2,E3s=E3s,E4s=E4s,E3c=E3c,E4c=E4c,
    H_D=H_D,H1=H1,H2=H2,H3s=H3s,H4s=H4s,H3c=H3c,H4c=H4c,
    U_D=U_D,U1=U1,U2=U2,U3s=U3s,U4s=U4s,U3c=U3c,U4c=U4c,
    Eq_Ref=Eq_Ref,Uq_Ref=Uq_Ref,H_eta_Ref=H_eta_Ref,
    Eq_Const=Eq_Const,Uq_Const=Uq_Const,H_eta_Const=H_eta_Const,
    Sigma_R=Sigma_R, Sigma_T=Sigma_T,
    GM_T=exp(st$mean), GM_R=exp(sr$mean), GMR=exp(st$mean)/exp(sr$mean),
    criterion=criterion, Eq_final=Eq_final, Uq_final=Uq_final,
    H_eta_final=H_eta_final,
    pass_fail=ifelse(H_eta_final<=0,"PASS","FAIL"),
    log_transform=log_transform,
    one_sided=one_sided,
    one_sided_active=one_sided_active
  )
}
