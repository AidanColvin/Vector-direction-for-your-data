suppressPackageStartupMessages({
  library(caret); library(readr); library(dplyr); library(ggplot2)
  library(pROC);  library(tidyr); library(randomForest)
  library(e1071); library(gbm);   library(naivebayes); library(xgboost)
})

VIZ  <- "data/processed/visualizations"
TBLS <- "data/processed/tables"
MODS <- "models"

vpath <- function(m,f) file.path(VIZ, m,f)
tpath <- function(m,f) file.path(TBLS,m,f)

for (m in c("logistic_regression","linear_regression","naive_bayes",
            "random_forest","gradient_boosting","xgboost","svm","comparison")) {
  dir.create(file.path(VIZ, m),  recursive=TRUE, showWarnings=FALSE)
  dir.create(file.path(TBLS,m),  recursive=TRUE, showWarnings=FALSE)
}
dir.create(MODS, showWarnings=FALSE)

wpng <- function(p,path,w=7,h=5){ggsave(path,plot=p,width=w,height=h,dpi=120);cat("  PNG:",path,"\n")}
wcsv <- function(df,path){write.csv(df,path,row.names=FALSE);cat("  CSV:",path,"\n")}

roc_plot <- function(actuals,probs,title,col){
  ro<-pROC::roc(actuals,probs,quiet=TRUE); auc<-round(pROC::auc(ro),3)
  df<-data.frame(fpr=1-ro$specificities,tpr=ro$sensitivities)
  ggplot(df,aes(fpr,tpr))+geom_line(colour=col,linewidth=1.2)+
    geom_abline(linetype="dashed",colour="grey60")+
    labs(title=title,subtitle=paste("AUC:",auc),x="False Positive Rate",y="True Positive Rate")+
    theme_minimal(base_size=13)
}
cm_plot <- function(actuals,preds,title,lo,hi){
  cm<-as.data.frame(table(Actual=actuals,Predicted=preds))
  ggplot(cm,aes(Predicted,Actual,fill=Freq))+geom_tile(colour="white",linewidth=0.8)+
    geom_text(aes(label=Freq),colour="white",size=7,fontface="bold")+
    scale_fill_gradient(low=lo,high=hi)+labs(title=title)+theme_minimal(base_size=14)
}
cal_plot <- function(actuals,probs,title,col,bins=10){
  df<-data.frame(prob=probs,actual=as.numeric(actuals=="yes"))
  df$bin<-cut(df$prob,breaks=bins,include.lowest=TRUE)
  cal<-aggregate(cbind(prob,actual)~bin,data=df,FUN=mean)
  ggplot(cal,aes(prob,actual))+geom_point(size=3.5,colour=col)+geom_line(colour=col,linewidth=1)+
    geom_abline(linetype="dashed",colour="grey60")+
    labs(title=title,x="Mean Predicted Probability",y="Fraction Positive")+theme_minimal(base_size=13)
}
imp_plot <- function(feat,score,title,col,xlab,top=20){
  df<-head(data.frame(feature=feat,score=score)[order(-score),],top)
  ggplot(df,aes(reorder(feature,score),score))+geom_col(fill=col)+coord_flip()+
    labs(title=title,x=NULL,y=xlab)+theme_minimal(base_size=12)
}
make_metrics <- function(name,auc,cm){
  data.frame(model=name,
    AUC      =round(auc,4),
    Accuracy =round(as.numeric(cm$overall["Accuracy"]), 4),
    Precision=round(as.numeric(cm$byClass["Precision"]),4),
    Recall   =round(as.numeric(cm$byClass["Recall"]),   4),
    F1       =round(as.numeric(cm$byClass["F1"]),       4),
    Kappa    =round(as.numeric(cm$overall["Kappa"]),    4),
    row.names=NULL)
}
make_clf <- function(actuals,preds){
  cm<-confusionMatrix(as.factor(preds),as.factor(actuals),positive="yes")
  data.frame(metric=names(cm$byClass),value=round(as.numeric(cm$byClass),4))
}

# ══════════════════════════════════════════════════════════════
# DATA — 30k sample, 3-fold CV, fast model settings
# Target total runtime: < 10 minutes
# ══════════════════════════════════════════════════════════════
cat("\n══════ DATA PREPARATION ══════\n")
source("src/pipelines/run_cleaning.R");  run_cleaning_pipeline(na_strategy="drop")
source("src/pipelines/run_encoding.R");  run_encoding_pipeline()
source("src/pipelines/run_scaling.R");   run_scaling_pipeline(exclude=c("id","diagnosed_diabetes"))

raw <- read_csv("data/processed/train_standardized.csv", show_col_types=FALSE)
cat("Full dataset:", nrow(raw), "rows\n")

raw$diagnosed_diabetes <- factor(
  ifelse(raw$diagnosed_diabetes==1,"yes","no"), levels=c("no","yes"))
raw <- raw %>% select(-id)

# ── Stratified sample to 30k rows ──
set.seed(42)
s_idx    <- createDataPartition(raw$diagnosed_diabetes, p=30000/nrow(raw), list=FALSE)
raw      <- raw[s_idx, ]
cat("Sampled:", nrow(raw), "rows | no:", sum(raw$diagnosed_diabetes=="no"),
    "| yes:", sum(raw$diagnosed_diabetes=="yes"), "\n")

# ── 80/20 split ──
set.seed(42)
idx      <- createDataPartition(raw$diagnosed_diabetes, p=0.8, list=FALSE)
train_df <- raw[ idx, ]
test_df  <- raw[-idx, ]
cat("Train:", nrow(train_df), "| Test:", nrow(test_df), "\n")

# ── 3-fold CV (fast) ──
cv3 <- trainControl(method="cv", number=3, classProbs=TRUE,
                    summaryFunction=twoClassSummary, savePredictions="final")

results <- list(); scorecard <- list()
t_start <- proc.time()

# ══════════════════════════════════════════════════════════════
# 1 — LOGISTIC REGRESSION  (~10 sec)
# ══════════════════════════════════════════════════════════════
cat("\n══════ 1/7  LOGISTIC REGRESSION ══════\n"); t1<-proc.time()
tryCatch({
  M<-"logistic_regression"; COL<-"#2196F3"
  m<-train(diagnosed_diabetes~.,data=train_df,method="glm",
            family="binomial",trControl=cv3,metric="ROC")
  saveRDS(m,file.path(MODS,"logistic_regression.rds"))
  probs<-predict(m,test_df,type="prob")[,"yes"]
  labels<-predict(m,test_df)
  ro<-pROC::roc(test_df$diagnosed_diabetes,probs,quiet=TRUE)
  auc<-round(pROC::auc(ro),4)
  cm<-confusionMatrix(labels,test_df$diagnosed_diabetes,positive="yes")

  wpng(roc_plot(test_df$diagnosed_diabetes,probs,"ROC Curve — Logistic Regression",COL),vpath(M,"roc_curve.png"))
  wpng(cm_plot(test_df$diagnosed_diabetes,labels,"Confusion Matrix — Logistic Regression","#90CAF9","#1565C0"),vpath(M,"confusion_matrix.png"),6,5)
  wpng(cal_plot(test_df$diagnosed_diabetes,probs,"Calibration Curve — Logistic Regression",COL),vpath(M,"calibration_curve.png"))
  cf<-as.data.frame(summary(m$finalModel)$coefficients)
  cf$feature<-rownames(cf); cf<-cf[cf$feature!="(Intercept)",]; colnames(cf)[1]<-"estimate"
  wpng(ggplot(cf,aes(reorder(feature,estimate),estimate,fill=estimate>0))+
    geom_col(show.legend=FALSE)+coord_flip()+
    scale_fill_manual(values=c("TRUE"="#42A5F5","FALSE"="#EF5350"))+
    labs(title="Coefficients — Logistic Regression",x=NULL,y="Estimate")+theme_minimal(base_size=10),
    vpath(M,"coefficients.png"),10,9)
  wcsv(make_metrics("Logistic Regression",auc,cm),tpath(M,"metrics.csv"))
  wcsv(make_clf(test_df$diagnosed_diabetes,labels),tpath(M,"classification_report.csv"))
  wcsv(m$results,tpath(M,"cv_results.csv"))
  wcsv(cf[order(-abs(cf$estimate)),],tpath(M,"coefficients.csv"))
  results[["Logistic"]]<<-list(actuals=test_df$diagnosed_diabetes,probs=probs,preds=labels)
  scorecard[["Logistic"]]<<-make_metrics("Logistic Regression",auc,cm)
  cat("  ✓ done in",round((proc.time()-t1)[3],1),"sec\n")
},error=function(e) cat("  ✗ FAILED:",conditionMessage(e),"\n"))

# ══════════════════════════════════════════════════════════════
# 2 — LINEAR REGRESSION  (~5 sec)
# ══════════════════════════════════════════════════════════════
cat("\n══════ 2/7  LINEAR REGRESSION ══════\n"); t1<-proc.time()
tryCatch({
  M<-"linear_regression"; COL<-"#42A5F5"
  tr_n<-train_df %>% mutate(diagnosed_diabetes=as.numeric(diagnosed_diabetes=="yes"))
  te_n<-test_df  %>% mutate(diagnosed_diabetes=as.numeric(diagnosed_diabetes=="yes"))
  m<-lm(diagnosed_diabetes~.,data=tr_n); prd<-predict(m,te_n)
  saveRDS(m,file.path(MODS,"linear_regression.rds"))
  avp<-data.frame(actual=te_n$diagnosed_diabetes,predicted=prd)
  wpng(ggplot(avp,aes(actual,predicted))+geom_point(alpha=0.3,colour=COL)+
    geom_abline(linetype="dashed",colour="grey50")+
    labs(title="Actual vs Predicted — Linear Regression",x="Actual",y="Predicted")+theme_minimal(base_size=13),
    vpath(M,"actual_vs_predicted.png"))
  res_df<-data.frame(fitted=fitted(m),residuals=residuals(m))
  wpng(ggplot(res_df,aes(fitted,residuals))+geom_point(alpha=0.3,colour=COL)+
    geom_hline(yintercept=0,linetype="dashed",colour="grey50")+
    geom_smooth(se=FALSE,colour="#EF5350",linewidth=0.8)+
    labs(title="Residuals vs Fitted — Linear Regression",x="Fitted",y="Residuals")+theme_minimal(base_size=13),
    vpath(M,"residuals_vs_fitted.png"))
  wpng(ggplot(data.frame(r=residuals(m)),aes(sample=r))+
    stat_qq(colour=COL,alpha=0.4)+stat_qq_line(colour="#EF5350")+
    labs(title="Q-Q Plot — Linear Regression")+theme_minimal(base_size=13),
    vpath(M,"qq_plot.png"),5,5)
  wpng(ggplot(data.frame(f=fitted(m),sr=sqrt(abs(rstandard(m)))),aes(f,sr))+
    geom_point(alpha=0.3,colour=COL)+geom_smooth(se=FALSE,colour="#EF5350",linewidth=0.8)+
    labs(title="Scale-Location — Linear Regression",x="Fitted",y="sqrt|Std Residuals|")+theme_minimal(base_size=13),
    vpath(M,"scale_location.png"))
  cf_lin<-as.data.frame(summary(m)$coefficients); cf_lin$feature<-rownames(cf_lin)
  cf_lin<-cf_lin[cf_lin$feature!="(Intercept)",]
  colnames(cf_lin)<-c("estimate","std_error","t_value","p_value","feature")
  cf_lin<-cf_lin[order(-abs(cf_lin$estimate)),]
  wpng(ggplot(head(cf_lin,20),aes(reorder(feature,estimate),estimate,fill=estimate>0))+
    geom_col(show.legend=FALSE)+coord_flip()+
    scale_fill_manual(values=c("TRUE"="#42A5F5","FALSE"="#EF5350"))+
    labs(title="Top Coefficients — Linear Regression",x=NULL,y="Estimate")+theme_minimal(base_size=10),
    vpath(M,"coefficients.png"),10,8)
  rmse<-sqrt(mean((prd-te_n$diagnosed_diabetes)^2))
  wcsv(data.frame(RMSE=round(rmse,4),R2=round(summary(m)$r.squared,4),
    Adj_R2=round(summary(m)$adj.r.squared,4)),tpath(M,"metrics.csv"))
  wcsv(cf_lin[,c("feature","estimate","std_error","t_value","p_value")],tpath(M,"coefficients.csv"))
  wcsv(avp,tpath(M,"predictions.csv"))
  cat("  ✓ done in",round((proc.time()-t1)[3],1),"sec\n")
},error=function(e) cat("  ✗ FAILED:",conditionMessage(e),"\n"))

# ══════════════════════════════════════════════════════════════
# 3 — NAIVE BAYES  (~15 sec)
# ══════════════════════════════════════════════════════════════
cat("\n══════ 3/7  NAIVE BAYES ══════\n"); t1<-proc.time()
tryCatch({
  M<-"naive_bayes"; COL<-"#AB47BC"
  m<-train(diagnosed_diabetes~.,data=train_df,method="naive_bayes",
            trControl=cv3,metric="ROC",tuneLength=2)
  saveRDS(m,file.path(MODS,"naive_bayes.rds"))
  probs<-predict(m,test_df,type="prob")[,"yes"]
  labels<-predict(m,test_df)
  ro<-pROC::roc(test_df$diagnosed_diabetes,probs,quiet=TRUE)
  auc<-round(pROC::auc(ro),4)
  cm<-confusionMatrix(labels,test_df$diagnosed_diabetes,positive="yes")
  wpng(roc_plot(test_df$diagnosed_diabetes,probs,"ROC Curve — Naive Bayes",COL),vpath(M,"roc_curve.png"))
  wpng(cm_plot(test_df$diagnosed_diabetes,labels,"Confusion Matrix — Naive Bayes","#CE93D8","#6A1B9A"),vpath(M,"confusion_matrix.png"),6,5)
  wpng(cal_plot(test_df$diagnosed_diabetes,probs,"Calibration Curve — Naive Bayes",COL),vpath(M,"calibration_curve.png"))
  tryCatch({
    nb<-if(!is.null(m$finalModel)) m$finalModel else m
    ap<-if(!is.null(nb$prior)) nb$prior
        else{v<-as.numeric(nb$apriori);names(v)<-names(nb$apriori);v}
    if(!is.numeric(ap)) ap<-as.numeric(ap)
    if(is.null(names(ap))) names(ap)<-paste0("class",seq_along(ap))
    pdf<-data.frame(class=names(ap),count=as.numeric(ap))
    pdf$prob<-round(pdf$count/sum(pdf$count),4)
    wpng(ggplot(pdf,aes(class,prob,fill=class))+geom_col(show.legend=FALSE)+
      scale_fill_manual(values=c("no"="#CE93D8","yes"="#7B1FA2"))+
      geom_text(aes(label=sprintf("%.1f%%",prob*100)),vjust=-0.4,size=5)+
      labs(title="Prior Probabilities — Naive Bayes",x="Class",y="Probability")+theme_minimal(base_size=13),
      vpath(M,"prior_probabilities.png"),5,4)
    wcsv(pdf,tpath(M,"prior_probabilities.csv"))
  },error=function(e) cat("  WARN prior:",conditionMessage(e),"\n"))
  wpng(ggplot(m$results,aes(x=factor(usekernel),y=ROC,fill=factor(usekernel)))+
    geom_col(show.legend=FALSE)+facet_wrap(~laplace)+
    labs(title="Naive Bayes Tuning",x="Use Kernel",y="Cross-Val AUC")+theme_minimal(base_size=12),
    vpath(M,"tuning_results.png"),7,5)
  wcsv(make_metrics("Naive Bayes",auc,cm),tpath(M,"metrics.csv"))
  wcsv(make_clf(test_df$diagnosed_diabetes,labels),tpath(M,"classification_report.csv"))
  wcsv(m$results,tpath(M,"cv_results.csv"))
  results[["NaiveBayes"]]<<-list(actuals=test_df$diagnosed_diabetes,probs=probs,preds=labels)
  scorecard[["NaiveBayes"]]<<-make_metrics("Naive Bayes",auc,cm)
  cat("  ✓ done in",round((proc.time()-t1)[3],1),"sec\n")
},error=function(e) cat("  ✗ FAILED:",conditionMessage(e),"\n"))

# ══════════════════════════════════════════════════════════════
# 4 — RANDOM FOREST  (~90 sec)  ntree=100, tune 2 mtry values
# ══════════════════════════════════════════════════════════════
cat("\n══════ 4/7  RANDOM FOREST ══════\n"); t1<-proc.time()
tryCatch({
  M<-"random_forest"; COL<-"#388E3C"
  m<-train(diagnosed_diabetes~.,data=train_df,method="rf",
            trControl=cv3,metric="ROC",tuneLength=2,
            ntree=100)                          # fast: 100 trees only
  saveRDS(m,file.path(MODS,"random_forest.rds"))
  probs<-predict(m,test_df,type="prob")[,"yes"]
  labels<-predict(m,test_df)
  ro<-pROC::roc(test_df$diagnosed_diabetes,probs,quiet=TRUE)
  auc<-round(pROC::auc(ro),4)
  cm<-confusionMatrix(labels,test_df$diagnosed_diabetes,positive="yes")
  wpng(roc_plot(test_df$diagnosed_diabetes,probs,"ROC Curve — Random Forest",COL),vpath(M,"roc_curve.png"))
  wpng(cm_plot(test_df$diagnosed_diabetes,labels,"Confusion Matrix — Random Forest","#A5D6A7","#1B5E20"),vpath(M,"confusion_matrix.png"),6,5)
  wpng(cal_plot(test_df$diagnosed_diabetes,probs,"Calibration Curve — Random Forest",COL),vpath(M,"calibration_curve.png"))
  imp<-randomForest::importance(m$finalModel)
  imp_df<-data.frame(feature=rownames(imp),MeanDecreaseGini=imp[,"MeanDecreaseGini"])
  imp_df<-imp_df[order(-imp_df$MeanDecreaseGini),]
  wpng(imp_plot(imp_df$feature,imp_df$MeanDecreaseGini,"Feature Importance — Random Forest","#66BB6A","Mean Decrease Gini"),vpath(M,"feature_importance.png"),9,7)
  oob_df<-data.frame(trees=seq_len(nrow(m$finalModel$err.rate)),oob=m$finalModel$err.rate[,"OOB"])
  wpng(ggplot(oob_df,aes(trees,oob))+geom_line(colour=COL,linewidth=1)+
    labs(title="OOB Error Curve — Random Forest",x="Trees",y="OOB Error Rate")+theme_minimal(base_size=13),
    vpath(M,"oob_error_curve.png"),7,4)
  wpng(ggplot(m$results,aes(mtry,ROC))+geom_line(colour=COL,linewidth=1)+geom_point(size=3,colour=COL)+
    labs(title="RF Tuning — mtry vs AUC",x="mtry",y="Cross-Val AUC")+theme_minimal(base_size=13),
    vpath(M,"tuning_mtry.png"),6,4)
  wcsv(make_metrics("Random Forest",auc,cm),tpath(M,"metrics.csv"))
  wcsv(make_clf(test_df$diagnosed_diabetes,labels),tpath(M,"classification_report.csv"))
  wcsv(imp_df,tpath(M,"feature_importance.csv"))
  wcsv(oob_df,tpath(M,"oob_error_by_trees.csv"))
  wcsv(m$results,tpath(M,"cv_results.csv"))
  results[["RandomForest"]]<<-list(actuals=test_df$diagnosed_diabetes,probs=probs,preds=labels)
  scorecard[["RandomForest"]]<<-make_metrics("Random Forest",auc,cm)
  cat("  ✓ done in",round((proc.time()-t1)[3],1),"sec\n")
},error=function(e) cat("  ✗ FAILED:",conditionMessage(e),"\n"))

# ══════════════════════════════════════════════════════════════
# 5 — GRADIENT BOOSTING  (~60 sec)  small grid
# ══════════════════════════════════════════════════════════════
cat("\n══════ 5/7  GRADIENT BOOSTING ══════\n"); t1<-proc.time()
tryCatch({
  M<-"gradient_boosting"; COL<-"#E64A19"
  gbm_grid<-expand.grid(n.trees=c(100,150), interaction.depth=2,
                         shrinkage=0.1, n.minobsinnode=10)
  m<-train(diagnosed_diabetes~.,data=train_df,method="gbm",
            trControl=cv3,metric="ROC",tuneGrid=gbm_grid,verbose=FALSE)
  saveRDS(m,file.path(MODS,"gradient_boosting.rds"))
  probs<-predict(m,test_df,type="prob")[,"yes"]
  labels<-predict(m,test_df)
  ro<-pROC::roc(test_df$diagnosed_diabetes,probs,quiet=TRUE)
  auc<-round(pROC::auc(ro),4)
  cm<-confusionMatrix(labels,test_df$diagnosed_diabetes,positive="yes")
  wpng(roc_plot(test_df$diagnosed_diabetes,probs,"ROC Curve — Gradient Boosting",COL),vpath(M,"roc_curve.png"))
  wpng(cm_plot(test_df$diagnosed_diabetes,labels,"Confusion Matrix — Gradient Boosting","#FFAB91","#BF360C"),vpath(M,"confusion_matrix.png"),6,5)
  wpng(cal_plot(test_df$diagnosed_diabetes,probs,"Calibration Curve — Gradient Boosting",COL),vpath(M,"calibration_curve.png"))
  imp_df<-as.data.frame(summary(m$finalModel,plotit=FALSE))
  colnames(imp_df)<-c("feature","rel_influence")
  imp_df<-imp_df[order(-imp_df$rel_influence),]
  wpng(imp_plot(imp_df$feature,imp_df$rel_influence,"Feature Importance — Gradient Boosting","#FF7043","Relative Influence"),vpath(M,"feature_importance.png"),9,7)
  lc_df<-data.frame(iteration=seq_len(m$finalModel$n.trees),train_loss=m$finalModel$train.error)
  wpng(ggplot(lc_df,aes(iteration,train_loss))+geom_line(colour=COL,linewidth=1)+
    labs(title="Learning Curve — Gradient Boosting",x="Iteration",y="Training Loss")+theme_minimal(base_size=13),
    vpath(M,"learning_curve.png"),7,4)
  wpng(ggplot(m$results,aes(factor(n.trees),ROC,fill=factor(n.trees)))+
    geom_col(show.legend=FALSE)+
    labs(title="GBM Tuning — Trees vs AUC",x="n.trees",y="Cross-Val AUC")+theme_minimal(base_size=12),
    vpath(M,"tuning_surface.png"),7,4)
  wcsv(make_metrics("Gradient Boosting",auc,cm),tpath(M,"metrics.csv"))
  wcsv(make_clf(test_df$diagnosed_diabetes,labels),tpath(M,"classification_report.csv"))
  wcsv(imp_df,tpath(M,"feature_importance.csv"))
  wcsv(lc_df,tpath(M,"boosting_log.csv"))
  wcsv(m$results,tpath(M,"cv_results.csv"))
  results[["GBM"]]<<-list(actuals=test_df$diagnosed_diabetes,probs=probs,preds=labels)
  scorecard[["GBM"]]<<-make_metrics("Gradient Boosting",auc,cm)
  cat("  ✓ done in",round((proc.time()-t1)[3],1),"sec\n")
},error=function(e) cat("  ✗ FAILED:",conditionMessage(e),"\n"))

# ══════════════════════════════════════════════════════════════
# 6 — XGBOOST  (~60 sec)  small grid
# ══════════════════════════════════════════════════════════════
cat("\n══════ 6/7  XGBOOST ══════\n"); t1<-proc.time()
tryCatch({
  M<-"xgboost"; COL<-"#0277BD"
  xgb_grid<-expand.grid(nrounds=100, max_depth=4, eta=0.1,
                          gamma=0, colsample_bytree=0.8,
                          min_child_weight=1, subsample=0.8)
  m<-train(diagnosed_diabetes~.,data=train_df,method="xgbTree",
            trControl=cv3,metric="ROC",tuneGrid=xgb_grid,verbosity=0)
  saveRDS(m,file.path(MODS,"xgboost.rds"))
  probs<-predict(m,test_df,type="prob")[,"yes"]
  labels<-predict(m,test_df)
  ro<-pROC::roc(test_df$diagnosed_diabetes,probs,quiet=TRUE)
  auc<-round(pROC::auc(ro),4)
  cm<-confusionMatrix(labels,test_df$diagnosed_diabetes,positive="yes")
  wpng(roc_plot(test_df$diagnosed_diabetes,probs,"ROC Curve — XGBoost",COL),vpath(M,"roc_curve.png"))
  wpng(cm_plot(test_df$diagnosed_diabetes,labels,"Confusion Matrix — XGBoost","#81D4FA","#01579B"),vpath(M,"confusion_matrix.png"),6,5)
  wpng(cal_plot(test_df$diagnosed_diabetes,probs,"Calibration Curve — XGBoost",COL),vpath(M,"calibration_curve.png"))
  imp<-xgboost::xgb.importance(model=m$finalModel)
  imp_df<-as.data.frame(imp)
  wpng(imp_plot(imp_df$Feature,imp_df$Gain,"Feature Importance (Gain) — XGBoost","#29B6F6","Gain"),vpath(M,"feature_importance.png"),9,7)
  wpng(ggplot(imp_df,aes(Gain,Cover))+geom_point(colour=COL,size=3,alpha=0.7)+
    labs(title="XGBoost: Gain vs Cover",x="Gain",y="Cover")+theme_minimal(base_size=12),
    vpath(M,"gain_vs_cover.png"),7,5)
  wcsv(make_metrics("XGBoost",auc,cm),tpath(M,"metrics.csv"))
  wcsv(make_clf(test_df$diagnosed_diabetes,labels),tpath(M,"classification_report.csv"))
  wcsv(imp_df,tpath(M,"feature_importance.csv"))
  wcsv(m$results,tpath(M,"cv_results.csv"))
  results[["XGBoost"]]<<-list(actuals=test_df$diagnosed_diabetes,probs=probs,preds=labels)
  scorecard[["XGBoost"]]<<-make_metrics("XGBoost",auc,cm)
  cat("  ✓ done in",round((proc.time()-t1)[3],1),"sec\n")
},error=function(e) cat("  ✗ FAILED:",conditionMessage(e),"\n"))

# ══════════════════════════════════════════════════════════════
# 7 — SVM  (~60 sec)  single C/sigma combo
# ══════════════════════════════════════════════════════════════
cat("\n══════ 7/7  SVM ══════\n"); t1<-proc.time()
tryCatch({
  M<-"svm"; COL<-"#F06292"
  svm_grid<-expand.grid(C=1, sigma=0.01)
  m<-train(diagnosed_diabetes~.,data=train_df,method="svmRadial",
            trControl=cv3,metric="ROC",tuneGrid=svm_grid)
  saveRDS(m,file.path(MODS,"svm.rds"))
  probs<-predict(m,test_df,type="prob")[,"yes"]
  labels<-predict(m,test_df)
  ro<-pROC::roc(test_df$diagnosed_diabetes,probs,quiet=TRUE)
  auc<-round(pROC::auc(ro),4)
  cm<-confusionMatrix(labels,test_df$diagnosed_diabetes,positive="yes")
  wpng(roc_plot(test_df$diagnosed_diabetes,probs,"ROC Curve — SVM",COL),vpath(M,"roc_curve.png"))
  wpng(cm_plot(test_df$diagnosed_diabetes,labels,"Confusion Matrix — SVM","#F48FB1","#880E4F"),vpath(M,"confusion_matrix.png"),6,5)
  wpng(cal_plot(test_df$diagnosed_diabetes,probs,"Calibration Curve — SVM",COL),vpath(M,"calibration_curve.png"))
  wpng(ggplot(m$results,aes(factor(C),ROC,fill=factor(C)))+geom_col(show.legend=FALSE)+
    labs(title="SVM Tuning — Cost vs AUC",x="Cost (C)",y="Cross-Val AUC")+theme_minimal(base_size=13),
    vpath(M,"tuning_C_sigma.png"),6,4)
  wcsv(make_metrics("SVM",auc,cm),tpath(M,"metrics.csv"))
  wcsv(make_clf(test_df$diagnosed_diabetes,labels),tpath(M,"classification_report.csv"))
  wcsv(m$results,tpath(M,"cv_results.csv"))
  wcsv(data.frame(C=m$bestTune$C,sigma=m$bestTune$sigma),tpath(M,"best_hyperparameters.csv"))
  results[["SVM"]]<<-list(actuals=test_df$diagnosed_diabetes,probs=probs,preds=labels)
  scorecard[["SVM"]]<<-make_metrics("SVM",auc,cm)
  cat("  ✓ done in",round((proc.time()-t1)[3],1),"sec\n")
},error=function(e) cat("  ✗ FAILED:",conditionMessage(e),"\n"))

# ══════════════════════════════════════════════════════════════
# COMPARISON
# ══════════════════════════════════════════════════════════════
cat("\n══════ COMPARISON ══════\n")
tryCatch({
  M<-"comparison"; master<-do.call(rbind,scorecard)
  wcsv(master,tpath(M,"master_scorecard.csv"))
  bar<-function(col,title,ylab){
    df<-data.frame(model=master$model,val=as.numeric(master[[col]]))
    ggplot(df,aes(reorder(model,val),val,fill=model))+geom_col(show.legend=FALSE)+
      geom_text(aes(label=sprintf("%.3f",val)),hjust=-0.1,size=4.5)+
      coord_flip()+ylim(0,1.13)+labs(title=title,x=NULL,y=ylab)+theme_minimal(base_size=13)
  }
  wpng(bar("AUC","AUC — All Models","AUC"),vpath(M,"bar_auc.png"),9,6)
  wpng(bar("Accuracy","Accuracy — All Models","Accuracy"),vpath(M,"bar_accuracy.png"),9,6)
  wpng(bar("F1","F1 Score — All Models","F1"),vpath(M,"bar_f1.png"),9,6)
  wpng(bar("Precision","Precision — All Models","Precision"),vpath(M,"bar_precision.png"),9,6)
  wpng(bar("Recall","Recall — All Models","Recall"),vpath(M,"bar_recall.png"),9,6)
  all_roc<-do.call(rbind,lapply(names(results),function(nm){
    r<-results[[nm]]; ro<-pROC::roc(r$actuals,r$probs,quiet=TRUE)
    data.frame(fpr=1-ro$specificities,tpr=ro$sensitivities,
               model=paste0(nm," (AUC=",round(pROC::auc(ro),3),")"))
  }))
  wpng(ggplot(all_roc,aes(fpr,tpr,colour=model))+geom_line(linewidth=1.1)+
    geom_abline(linetype="dashed",colour="grey60")+
    labs(title="ROC Overlay — All Models",x="False Positive Rate",y="True Positive Rate",colour=NULL)+
    theme_minimal(base_size=13)+theme(legend.position="bottom",legend.text=element_text(size=9)),
    vpath(M,"roc_overlay.png"),11,8)
  all_cm<-do.call(rbind,lapply(names(results),function(nm){
    r<-results[[nm]]; df<-as.data.frame(table(Actual=r$actuals,Predicted=r$preds))
    df$model<-nm; df
  }))
  wpng(ggplot(all_cm,aes(Predicted,Actual,fill=Freq))+geom_tile(colour="white")+
    geom_text(aes(label=Freq),colour="white",size=5,fontface="bold")+
    scale_fill_gradient(low="#90CAF9",high="#1565C0")+
    facet_wrap(~model,ncol=3)+labs(title="Confusion Matrix Grid — All Models")+theme_minimal(base_size=11),
    vpath(M,"confusion_matrix_grid.png"),14,10)
  long_df<-tidyr::pivot_longer(master[,c("model","AUC","Accuracy","Precision","Recall","F1")],
    cols=-model,names_to="metric",values_to="value")
  long_df$value<-as.numeric(long_df$value)
  wpng(ggplot(long_df,aes(value,reorder(model,value),colour=metric))+geom_point(size=4)+
    facet_wrap(~metric,scales="free_x",ncol=5)+
    labs(title="All Metrics — All Models",x="Value",y=NULL)+
    theme_minimal(base_size=11)+theme(legend.position="none"),
    vpath(M,"metric_dot_plot.png"),15,6)
  all_cal<-do.call(rbind,lapply(names(results),function(nm){
    r<-results[[nm]]; df<-data.frame(prob=r$probs,actual=as.numeric(r$actuals=="yes"))
    df$bin<-cut(df$prob,breaks=10,include.lowest=TRUE)
    cal<-aggregate(cbind(prob,actual)~bin,data=df,FUN=mean); cal$model<-nm; cal
  }))
  wpng(ggplot(all_cal,aes(prob,actual,colour=model))+geom_point(size=2)+geom_line()+
    geom_abline(linetype="dashed",colour="grey60")+
    labs(title="Calibration Overlay — All Models",
         x="Mean Predicted Probability",y="Fraction Positive",colour=NULL)+
    theme_minimal(base_size=13)+theme(legend.position="bottom"),
    vpath(M,"calibration_overlay.png"),10,6)
  cat("  ✓ comparison done\n")
},error=function(e) cat("  ✗ FAILED:",conditionMessage(e),"\n"))

total<-round((proc.time()-t_start)[3]/60,1)
cat("\n══════════════════════════════════════════\n")
cat(sprintf("  TOTAL RUNTIME: %s minutes\n", total))
cat("══════════════════════════════════════════\n")
cat(sprintf("  %-24s  %4s  %4s\n","Model","PNG","CSV"))
for(mod in c("logistic_regression","linear_regression","naive_bayes",
             "random_forest","gradient_boosting","xgboost","svm","comparison")){
  np<-length(list.files(file.path(VIZ,mod),pattern="\\.png$"))
  nc<-length(list.files(file.path(TBLS,mod),pattern="\\.csv$"))
  cat(sprintf("  %-24s  %4d  %4d\n",mod,np,nc))
}
if(length(scorecard)>0){cat("\nFINAL SCORECARD:\n");print(do.call(rbind,scorecard),row.names=FALSE)}
