# iv_validity_tests.py - IV工具变量有效性检验类

import pandas as pd
import numpy as np
from linearmodels.iv import IV2SLS, IVGMM
import statsmodels.api as sm
from typing import Dict, List, Optional
import warnings
warnings.filterwarnings('ignore')


class IVValidityTests:
    """
    工具变量有效性检验类

    参数:
    -------
    data : pd.DataFrame
        数据框
    outcome : str
        因变量名称
    endogenous : list
        内生变量列表
    instruments : list
        工具变量列表
    controls : list, optional
        控制变量列表
    additional_instruments : list, optional
        额外的工具变量列表（用于过度识别检验）
    """

    def __init__(self,
                 data: pd.DataFrame,
                 outcome: str,
                 endogenous: List[str],
                 instruments: List[str],
                 controls: Optional[List[str]] = None,
                 additional_instruments: Optional[List[str]] = None):

        self.data = data.copy()
        self.outcome = outcome
        self.endogenous = endogenous
        self.instruments = instruments
        self.controls = controls if controls else []
        self.additional_instruments = additional_instruments if additional_instruments else []

        # 所有工具变量（主要 + 额外）
        self.all_instruments = instruments + self.additional_instruments

        # 删除缺失值
        all_vars = [outcome] + endogenous + self.all_instruments + self.controls
        self.data = self.data[all_vars].dropna()

        print("\n" + "=" * 80)
        print("工具变量有效性检验系统初始化")
        print("=" * 80)
        print(f"\n数据维度: {self.data.shape}")
        print(f"因变量: {self.outcome}")
        print(f"内生变量: {self.endogenous}")
        print(f"主要工具变量: {self.instruments}")
        if self.additional_instruments:
            print(f"额外工具变量: {self.additional_instruments}")
        print(f"控制变量: {self.controls}")

        # 存储结果
        self.results = {}

    @staticmethod
    def _safe_float(x) -> float:
        """把 statsmodels/linearmodels 可能返回的 array/scalar 都转成 float"""
        try:
            return float(np.asarray(x).ravel()[0])
        except Exception:
            return float(x)

    def test_relevance(self, verbose: bool = True) -> Dict:
        """
        条件1: 相关性检验 (Relevance Test)

        理论要求:
        --------
        Cov(Z, D) ≠ 0
        工具变量必须与内生变量强相关

        检验标准:
        --------
        第一阶段F统计量 > 10 (Stock & Yogo 2005)
        """
        if verbose:
            print("\n" + "=" * 80)
            print("【条件1】RELEVANCE TEST - 相关性检验")
            print("=" * 80)
            print("\n理论要求: Cov(Z, D) ≠ 0")
            print("工具变量必须与内生变量强相关")
            print("判断标准: 第一阶段F统计量 > 10")

        relevance_results = {}

        for endog in self.endogenous:
            if verbose:
                print("\n" + "-" * 80)
                print(f"第一阶段回归: {endog} ~ Instruments + Controls")
                print("-" * 80)

            # 构建第一阶段回归
            X = sm.add_constant(self.data[self.all_instruments + self.controls])
            y = self.data[endog]

            # OLS回归
            first_stage_model = sm.OLS(y, X).fit()

            # 计算工具变量的联合F统计量
            r_matrix = np.zeros((len(self.all_instruments), len(first_stage_model.params)))
            for i, iv in enumerate(self.all_instruments):
                if iv in first_stage_model.params.index:
                    r_matrix[i, first_stage_model.params.index.get_loc(iv)] = 1

            f_test = first_stage_model.f_test(r_matrix)
            f_stat = self._safe_float(f_test.fvalue)
            f_pval = self._safe_float(f_test.pvalue)

            # 计算偏R²
            if self.controls:
                X_without_iv = sm.add_constant(self.data[self.controls])
                model_without_iv = sm.OLS(y, X_without_iv).fit()
                partial_r2 = first_stage_model.rsquared - model_without_iv.rsquared
            else:
                partial_r2 = first_stage_model.rsquared

            is_relevant = f_stat > 10

            if verbose:
                print(f"\n整体拟合:")
                print(f"  R-squared: {first_stage_model.rsquared:.4f}")
                print(f"  Partial R² (工具变量独立解释力): {partial_r2:.4f}")

                print(f"\n工具变量联合显著性检验:")
                print(f"  F统计量: {f_stat:.4f}")
                print(f"  P-value: {f_pval:.6f}")

                print(f"\n判断:")
                if f_stat > 10:
                    print(f"  [PASS] 强工具变量 (F = {f_stat:.2f} > 10)")
                    print("  结论: 满足相关性条件")
                elif f_stat > 5:
                    print(f"  [WARN] 中等强度工具变量 (F = {f_stat:.2f}, 介于5-10之间)")
                    print("  建议: 寻找更强的工具变量")
                else:
                    print(f"  [FAIL] 弱工具变量 (F = {f_stat:.2f} < 5)")
                    print("  问题: 不满足相关性条件，IV估计将严重有偏")

                print(f"\n各工具变量系数:")
                for iv in self.all_instruments:
                    if iv in first_stage_model.params.index:
                        coef = first_stage_model.params[iv]
                        se = first_stage_model.bse[iv]
                        t_stat = first_stage_model.tvalues[iv]
                        p_val = first_stage_model.pvalues[iv]
                        sig = "***" if p_val < 0.01 else "**" if p_val < 0.05 else "*" if p_val < 0.1 else ""
                        print(f"  {iv}: β={coef:.4f} (SE={se:.4f}), t={t_stat:.3f}, p={p_val:.4f} {sig}")

            relevance_results[endog] = {
                'f_statistic': f_stat,
                'f_pvalue': f_pval,
                'is_relevant': is_relevant,
                'r_squared': first_stage_model.rsquared,
                'partial_r2': partial_r2,
                'first_stage_model': first_stage_model
            }

        self.results['relevance'] = relevance_results
        return relevance_results


    def test_exclusion_restriction(self, verbose: bool = True) -> Dict:
        """
        条件2: 排他性约束检验 (Exclusion Restriction Test)

        理论要求:
        --------
        Cov(Z, ε) = 0
        工具变量只能通过内生变量影响结果变量，不能有直接路径

        检验方法:
        --------
        1. 过度识别检验 (Hansen J test via IVGMM) - 对异方差稳健
        2. 直接效应检验 (Placebo test)
        """
        if verbose:
            print("\n" + "=" * 80)
            print("【条件2】EXCLUSION RESTRICTION TEST - 排他性约束检验")
            print("=" * 80)
            print("\n理论要求: Cov(Z, ε) = 0")
            print("工具变量只能通过内生变量影响结果变量")

        exclusion_results = {}

        # ========== 测试2.1: 过度识别检验 (Hansen J via IVGMM) ==========
        if verbose:
            print("\n" + "-" * 80)
            print("测试2.1: 过度识别检验 (Hansen J Test via IVGMM)")
            print("-" * 80)

        n_instruments = len(self.all_instruments)
        n_endog = len(self.endogenous)

        if n_instruments > n_endog:
            if verbose:
                print(f"\n工具变量数量 ({n_instruments}) > 内生变量数量 ({n_endog})")
                print("可以进行过度识别检验")

            # 准备数据
            dependent = self.data[self.outcome]
            if self.controls:
                exog = sm.add_constant(self.data[self.controls])
            else:
                exog = sm.add_constant(pd.DataFrame(index=self.data.index))
            endog = self.data[self.endogenous]
            instruments_df = self.data[self.all_instruments]

            # 2SLS估计（保留用于其他用途）
            model_2sls = IV2SLS(dependent, exog, endog, instruments_df).fit(cov_type='robust')

            # Hansen J 检验：使用 IVGMM 的 j_stat（异方差稳健）
            gmm_res = IVGMM(dependent, exog, endog, instruments_df).fit(cov_type='robust')
            j = gmm_res.j_stat

            hansen_stat = self._safe_float(j.stat)
            hansen_pval = self._safe_float(j.pval)

            if verbose:
                print(f"\nHansen J统计量 (GMM J-test): {hansen_stat:.4f}")
                print(f"P-value: {hansen_pval:.4f}")
                print(f"自由度: {n_instruments - n_endog}")

                if hansen_pval > 0.05:
                    print(f"\n[PASS] 不拒绝零假设 (p = {hansen_pval:.4f} > 0.05)")
                    print("  结论: 工具变量通过外生性检验")
                else:
                    print(f"\n[FAIL] 拒绝零假设 (p = {hansen_pval:.4f} < 0.05)")
                    print("  问题: 至少有一个工具变量可能违反排他性约束")

            exclusion_results['hansen_stat'] = hansen_stat
            exclusion_results['hansen_pvalue'] = hansen_pval
            exclusion_results['overidentified'] = True
            exclusion_results['model_2sls'] = model_2sls
            exclusion_results['model_gmm'] = gmm_res
        else:
            if verbose:
                print(f"\n工具变量数量 ({n_instruments}) = 内生变量数量 ({n_endog})")
                print("恰好识别，无法进行过度识别检验")
            exclusion_results['overidentified'] = False

        # ========== 测试2.2: 直接效应检验 ==========
        if verbose:
            print("\n" + "-" * 80)
            print("测试2.2: 直接效应检验 (Placebo Test)")
            print("-" * 80)
            print("\n说明: 在控制内生变量后，工具变量应该不显著")

        # 回归: Y ~ D + Z + X
        X_direct = sm.add_constant(self.data[self.endogenous + self.all_instruments + self.controls])
        y_direct = self.data[self.outcome]
        direct_effect_model = sm.OLS(y_direct, X_direct).fit()

        if verbose:
            print(f"\n回归: {self.outcome} ~ Endogenous + Instruments + Controls")
            print(f"R-squared: {direct_effect_model.rsquared:.4f}")

            print(f"\n内生变量系数:")
            for endog in self.endogenous:
                if endog in direct_effect_model.params.index:
                    coef = direct_effect_model.params[endog]
                    t_stat = direct_effect_model.tvalues[endog]
                    p_val = direct_effect_model.pvalues[endog]
                    sig = "***" if p_val < 0.01 else "**" if p_val < 0.05 else "*" if p_val < 0.1 else ""
                    print(f"  {endog}: β={coef:.4f}, t={t_stat:.3f}, p={p_val:.4f} {sig}")

            print(f"\n工具变量的直接效应（理想状态：不显著）:")

        direct_effect_significant = False
        for iv in self.all_instruments:
            if iv in direct_effect_model.params.index:
                coef = direct_effect_model.params[iv]
                t_stat = direct_effect_model.tvalues[iv]
                p_val = direct_effect_model.pvalues[iv]
                is_sig = p_val < 0.05
                status = "[FAIL] 显著" if is_sig else "[PASS] 不显著"
                sig = "***" if p_val < 0.01 else "**" if p_val < 0.05 else "*" if p_val < 0.1 else ""

                if verbose:
                    print(f"  {iv}: β={coef:.4f}, t={t_stat:.3f}, p={p_val:.4f} {sig} [{status}]")

                if is_sig:
                    direct_effect_significant = True

        if verbose:
            if not direct_effect_significant:
                print("\n[PASS] 所有工具变量的直接效应都不显著")
                print("  结论: 支持排他性约束假设")
            else:
                print("\n[WARN] 存在显著的直接效应")
                print("  警告: 可能违反排他性约束")

        exclusion_results['direct_effect_model'] = direct_effect_model
        exclusion_results['direct_effect_significant'] = direct_effect_significant

        self.results['exclusion_restriction'] = exclusion_results
        return exclusion_results


    def test_exchangeability(self, verbose: bool = True) -> Dict:
        """
        条件3: 可交换性检验 (Exchangeability/Independence Test)

        理论要求:
        --------
        Z ⊥ U
        工具变量独立于未观测混杂因素

        检验方法:
        --------
        1. 平衡性检验: 工具变量应该与可观测协变量独立
        2. 残差预测检验: 工具变量不应预测OLS残差
        """
        if verbose:
            print("\n" + "=" * 80)
            print("【条件3】EXCHANGEABILITY TEST - 可交换性/独立性检验")
            print("=" * 80)
            print("\n理论要求: Z ⊥ U")
            print("工具变量独立于未观测混杂因素")

        exchangeability_results = {}

        # ========== 测试3.1: 平衡性检验 ==========
        if verbose:
            print("\n" + "-" * 80)
            print("测试3.1: 平衡性检验 (Balance Test)")
            print("-" * 80)
            print("\n说明: 检验工具变量是否与控制变量独立")

        if self.controls:
            balance_results = []

            if verbose:
                print("\n对每个控制变量进行回归检验:")
                print("回归: Control ~ Instruments")

            for control in self.controls:
                # 回归：控制变量 ~ 工具变量
                X_balance = sm.add_constant(self.data[self.all_instruments])
                y_balance = self.data[control]
                balance_model = sm.OLS(y_balance, X_balance).fit()

                # 联合F检验
                r_matrix = np.zeros((len(self.all_instruments), len(balance_model.params)))
                for i, iv in enumerate(self.all_instruments):
                    if iv in balance_model.params.index:
                        r_matrix[i, balance_model.params.index.get_loc(iv)] = 1

                f_test = balance_model.f_test(r_matrix)
                f_stat = self._safe_float(f_test.fvalue)
                f_pval = self._safe_float(f_test.pvalue)

                is_balanced = f_pval > 0.05

                if verbose:
                    status = "[PASS] 平衡" if is_balanced else "[FAIL] 不平衡"
                    print(f"\n  {control}:")
                    print(f"    F统计量: {f_stat:.4f}")
                    print(f"    P-value: {f_pval:.4f}")
                    print(f"    判断: {status}")

                balance_results.append({
                    'control': control,
                    'f_stat': f_stat,
                    'p_value': f_pval,
                    'is_balanced': is_balanced
                })

            all_balanced = all([r['is_balanced'] for r in balance_results])

            if verbose:
                print("\n平衡性总结:")
                if all_balanced:
                    print("  [PASS] 工具变量与所有控制变量都平衡")
                    print("  支持: 工具变量可能独立于未观测混杂因素")
                else:
                    print("  [WARN] 工具变量与某些控制变量不平衡")
                    print("  警告: 工具变量可能与混杂因素相关")

            exchangeability_results['balance_results'] = balance_results
            exchangeability_results['all_balanced'] = all_balanced
        else:
            if verbose:
                print("\n无控制变量，无法进行平衡性检验")
            exchangeability_results['balance_results'] = None

        # ========== 测试3.2: 残差预测检验 ==========
        if verbose:
            print("\n" + "-" * 80)
            print("测试3.2: 残差预测检验")
            print("-" * 80)
            print("\n说明: 工具变量不应预测OLS残差")

        # OLS回归获取残差
        X_ols = sm.add_constant(self.data[self.endogenous + self.controls])
        y_ols = self.data[self.outcome]
        ols_model = sm.OLS(y_ols, X_ols).fit()
        residuals = ols_model.resid

        # 检验：残差 ~ 工具变量
        X_resid = sm.add_constant(self.data[self.all_instruments])
        resid_model = sm.OLS(residuals, X_resid).fit()

        # 联合F检验
        r_matrix = np.zeros((len(self.all_instruments), len(resid_model.params)))
        for i, iv in enumerate(self.all_instruments):
            if iv in resid_model.params.index:
                r_matrix[i, resid_model.params.index.get_loc(iv)] = 1

        f_test = resid_model.f_test(r_matrix)
        f_stat = self._safe_float(f_test.fvalue)
        f_pval = self._safe_float(f_test.pvalue)

        if verbose:
            print(f"\n回归: OLS残差 ~ Instruments")
            print(f"F统计量: {f_stat:.4f}")
            print(f"P-value: {f_pval:.4f}")

            if f_pval > 0.05:
                print(f"\n[PASS] 工具变量不预测残差 (p = {f_pval:.4f} > 0.05)")
                print("  支持: 工具变量可能与未观测混杂因素无关")
            else:
                print(f"\n[WARN] 工具变量预测残差 (p = {f_pval:.4f} < 0.05)")
                print("  警告: 工具变量可能与混杂因素相关")

        exchangeability_results['residual_f_stat'] = f_stat
        exchangeability_results['residual_p_value'] = f_pval
        exchangeability_results['residual_independent'] = f_pval > 0.05

        self.results['exchangeability'] = exchangeability_results
        return exchangeability_results


    def run_all_tests(self, verbose: bool = True) -> Dict:
        """
        运行所有三个条件的检验

        返回:
        -------
        results : dict
            所有检验结果
        """
        print("\n" + "=" * 40)
        print("开始完整的工具变量有效性检验...")
        print("=" * 40)

        # 运行三个检验
        relevance_results = self.test_relevance(verbose=verbose)
        exclusion_results = self.test_exclusion_restriction(verbose=verbose)
        exchangeability_results = self.test_exchangeability(verbose=verbose)

        # 生成综合报告
        self.generate_comprehensive_report()

        return self.results


    def generate_comprehensive_report(self) -> None:
        """
        生成综合诊断报告
        """
        print("\n" + "=" * 80)
        print("【综合诊断报告】COMPREHENSIVE IV VALIDITY REPORT")
        print("=" * 80)

        relevance_results = self.results.get('relevance', {})
        exclusion_results = self.results.get('exclusion_restriction', {})
        exchangeability_results = self.results.get('exchangeability', {})

        print("\n工具变量有效性的三个核心条件:")
        print("-" * 80)

        # 条件1: 相关性
        print("\n1. RELEVANCE (相关性)")
        print("   要求: Cov(Z, D) ≠ 0 - 工具变量与内生变量相关")

        all_relevant = True
        for endog, res in relevance_results.items():
            if res['is_relevant']:
                print(f"   {endog}: [PASS] 通过 (F = {res['f_statistic']:.2f} > 10)")
            else:
                print(f"   {endog}: [FAIL] 未通过 (F = {res['f_statistic']:.2f} < 10)")
                all_relevant = False

        # 条件2: 排他性约束
        print("\n2. EXCLUSION RESTRICTION (排他性约束)")
        print("   要求: Cov(Z, ε) = 0 - 工具变量只通过内生变量影响结果")

        exclusion_pass = True

        if exclusion_results.get('overidentified'):
            if exclusion_results['hansen_pvalue'] > 0.05:
                print(f"   过度识别检验 (Hansen J): [PASS] 通过 (p = {exclusion_results['hansen_pvalue']:.4f})")
            else:
                print(f"   过度识别检验 (Hansen J): [FAIL] 未通过 (p = {exclusion_results['hansen_pvalue']:.4f})")
                exclusion_pass = False
        else:
            print("   过度识别检验: - 无法检验（恰好识别）")

        if not exclusion_results.get('direct_effect_significant', False):
            print("   直接效应检验: [PASS] 通过（无显著直接效应）")
        else:
            print("   直接效应检验: [WARN] 存在直接效应")
            exclusion_pass = False

        # 条件3: 可交换性
        print("\n3. EXCHANGEABILITY (可交换性/独立性)")
        print("   要求: Z ⊥ U - 工具变量独立于未观测混杂因素")

        exchangeability_pass = True

        if exchangeability_results.get('balance_results'):
            if exchangeability_results['all_balanced']:
                pass
            else:
                exchangeability_pass = False
        else:
            print("   平衡性检验: - 无控制变量")

        if exchangeability_results.get('residual_independent') is not None:
            if exchangeability_results['residual_independent']:
                print("   残差预测检验: [PASS] 通过（Z不预测残差）")
            else:
                print("   残差预测检验: [WARN] Z预测残差")
                exchangeability_pass = False

        # 总体结论
        print("\n" + "=" * 80)
        print("总体评估")
        print("=" * 80)

        all_conditions_met = all_relevant and exclusion_pass and exchangeability_pass

        if all_conditions_met:
            print("\n[PASS][PASS][PASS] 工具变量满足所有三个核心条件")
            print("\n结论: 工具变量是有效的，可以用于因果推断")
            print("建议: 继续进行2SLS估计，报告IV估计结果")
        else:
            print("\n[WARN][WARN][WARN] 工具变量未能满足所有条件")
            print("\n存在的问题:")

            if not all_relevant:
                print("  [FAIL] 弱工具变量问题：第一阶段F统计量过低")
                print("    建议：寻找更强的工具变量")

            if not exclusion_pass:
                print("  [FAIL] 排他性约束可能被违反")
                print("    建议：重新评估工具变量的选择")

            if not exchangeability_pass:
                print("  [FAIL] 可交换性假设可能不成立")
                print("    建议：控制不平衡的协变量")

            print("\n下一步:")
            print("  1. 重新评估工具变量的选择")
            print("  2. 考虑使用其他识别策略")
            print("  3. 进行敏感性分析")
            print("  4. 报告结果时说明潜在局限性")

        print("\n" + "=" * 80)


    def estimate_2sls(self, verbose: bool = True) -> IV2SLS:
        """
        进行2SLS估计

        返回:
        -------
        model_2sls : IV2SLS
            2SLS模型对象
        """
        if verbose:
            print("\n" + "=" * 80)
            print("【2SLS估计】Two-Stage Least Squares Estimation")
            print("=" * 80)

        # 准备数据
        dependent = self.data[self.outcome]
        if self.controls:
            exog = sm.add_constant(self.data[self.controls])
        else:
            exog = sm.add_constant(pd.DataFrame(index=self.data.index))
        endog = self.data[self.endogenous]
        instruments = self.data[self.all_instruments]

        # 2SLS估计
        model_2sls = IV2SLS(dependent, exog, endog, instruments).fit(cov_type='robust')

        if verbose:
            print(model_2sls.summary)

        self.results['model_2sls'] = model_2sls
        return model_2sls


    def get_summary_table(self) -> pd.DataFrame:
        """
        生成结果摘要表

        返回:
        -------
        summary_df : pd.DataFrame
            结果摘要表
        """
        summary_data = []

        # 相关性结果
        relevance_results = self.results.get('relevance', {})
        for endog, res in relevance_results.items():
            summary_data.append({
                '检验类型': 'Relevance',
                '变量': endog,
                '统计量': f"F = {res['f_statistic']:.2f}",
                'P-value': f"{res['f_pvalue']:.4f}",
                '判断': '[PASS] 通过' if res['is_relevant'] else '[FAIL] 未通过'
            })

        # 排他性约束结果 - 使用 Hansen J
        exclusion_results = self.results.get('exclusion_restriction', {})
        if exclusion_results.get('overidentified'):
            summary_data.append({
                '检验类型': 'Exclusion (Hansen J)',
                '变量': 'All IVs',
                '统计量': f"J = {exclusion_results['hansen_stat']:.2f}",
                'P-value': f"{exclusion_results['hansen_pvalue']:.4f}",
                '判断': '[PASS] 通过' if exclusion_results['hansen_pvalue'] > 0.05 else '[FAIL] 未通过'
            })

        # 可交换性结果
        exchangeability_results = self.results.get('exchangeability', {})
        if exchangeability_results.get('balance_results'):
            summary_data.append({
                '检验类型': 'Exchangeability (Balance)',
                '变量': 'All Controls',
                '统计量': '-',
                'P-value': '-',
                '判断': '[PASS] 通过' if exchangeability_results['all_balanced'] else '[WARN] 部分不平衡'
            })

        if exchangeability_results.get('residual_independent') is not None:
            summary_data.append({
                '检验类型': 'Exchangeability (Residual)',
                '变量': 'All IVs',
                '统计量': f"F = {exchangeability_results['residual_f_stat']:.2f}",
                'P-value': f"{exchangeability_results['residual_p_value']:.4f}",
                '判断': '[PASS] 通过' if exchangeability_results['residual_independent'] else '[WARN] 预测残差'
            })

        summary_df = pd.DataFrame(summary_data)
        return summary_df
