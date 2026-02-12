# run_iv_tests.py - 运行三个场景的IV检验

import pandas as pd
import numpy as np
from iv_validity_tests import IVValidityTests


def prepare_data(data: pd.DataFrame) -> pd.DataFrame:
    """通用数据预处理"""
    data['review_group'] = pd.qcut(data['review_count'], q=[0, 2/3, 1], labels=['low', 'high'])
    data['review_high'] = (data['review_group'] == 'high').astype(int)
    data["memory_score_review_high"] = data['memory_score'] * data['review_high']
    data["average_hue_review_high"] = data['average_hue'] * data['review_high']
    data["sharpness_measure_review_high"] = data['sharpness_measure'] * data['review_high']
    data["person_total_count_review_high"] = data['person_total_count_x'] * data['review_high']
    data['log_review_count'] = np.log(data['review_count'])
    return data


def run_restaurant_iv_test():
    """运行餐厅数据的IV检验"""
    print("\n" + "#" * 80)
    print("# RESTAURANT IV TEST")
    print("#" * 80)

    data = pd.read_excel('data/output/study1_2_res_data.xlsx')
    data = prepare_data(data)

    tester = IVValidityTests(
        data=data,
        outcome='star_avg',
        endogenous=['memory_score', 'memory_score_review_high'],
        instruments=["sharpness_measure", "sharpness_measure_review_high", "person_total_count_x"],
        controls=[
            'categories_counts', 'average_hue', 'average_saturation', 'average_value',
            'food', 'drink', 'menu', 'inside',
            'var', 'person_exist', 'beauty_score', 'review_high', 'log_review_count'
        ]
    )

    results = tester.run_all_tests()
    model_2sls = tester.estimate_2sls()

    summary_table = tester.get_summary_table()
    print("\n\n检验结果摘要表:")
    print("=" * 80)
    print(summary_table.to_string(index=False))

    return tester, results, model_2sls


def run_business_iv_test():
    """运行商业数据的IV检验"""
    print("\n" + "#" * 80)
    print("# BUSINESS ALL IV TEST")
    print("#" * 80)

    data = pd.read_excel('data/output/study1_2_business_data.xlsx')
    data = prepare_data(data)

    tester = IVValidityTests(
        data=data,
        outcome='star_avg',
        endogenous=['memory_score', 'memory_score_review_high'],
        instruments=["sharpness_measure", "sharpness_measure_review_high", "person_total_count_x"],
        controls=[
            'categories_counts', 'average_hue', 'average_saturation', 'average_value',
            'food', 'drink', 'menu', 'inside',
            'var', 'person_exist', 'beauty_score', 'review_high', 'log_review_count'
        ]
    )

    results = tester.run_all_tests()
    model_2sls = tester.estimate_2sls()

    summary_table = tester.get_summary_table()
    print("\n\n检验结果摘要表:")
    print("=" * 80)
    print(summary_table.to_string(index=False))

    return tester, results, model_2sls


def run_drink_iv_test():
    """运行饮品数据的IV检验"""
    print("\n" + "#" * 80)
    print("# DRINK IV TEST")
    print("#" * 80)

    data = pd.read_excel('data/output/study1_2_drink_data.xlsx')
    data = prepare_data(data)

    tester = IVValidityTests(
        data=data,
        outcome='star_avg',
        endogenous=['memory_score', 'memory_score_review_high'],
        instruments=["person_total_count_review_high", "person_total_count_x", "average_hue"],
        controls=[
            'categories_counts', 'var', 'average_saturation', 'average_value',
            'food', 'drink', 'menu', 'inside',
            'person_exist', 'beauty_score', 'review_high', 'log_review_count', 'sharpness_measure'
        ]
    )

    results = tester.run_all_tests()
    model_2sls = tester.estimate_2sls()

    summary_table = tester.get_summary_table()
    print("\n\n检验结果摘要表:")
    print("=" * 80)
    print(summary_table.to_string(index=False))

    return tester, results, model_2sls


if __name__ == "__main__":
    import sys

    # 可以通过命令行参数选择运行哪个测试
    # python run_iv_tests.py restaurant
    # python run_iv_tests.py business
    # python run_iv_tests.py drink
    # python run_iv_tests.py all

    if len(sys.argv) > 1:
        scenario = sys.argv[1].lower()
    else:
        scenario = 'all'

    if scenario == 'restaurant' or scenario == 'res':
        run_restaurant_iv_test()
    elif scenario == 'business' or scenario == 'biz':
        run_business_iv_test()
    elif scenario == 'drink':
        run_drink_iv_test()
    elif scenario == 'all':
        run_restaurant_iv_test()
        run_business_iv_test()
        run_drink_iv_test()
    else:
        print(f"Unknown scenario: {scenario}")
        print("Available options: restaurant, business, drink, all")
