import pandas as pd

def generate_html_report(results_df: pd.DataFrame, output_path: str):
    """
    given a dataframe of results
    generates a clean HTML report with embedded styles
    """
    html_content = f"""
    <html>
    <head>
        <title>BioBeat Model Leaderboard</title>
        <style>
            body {{ font-family: Arial; margin: 40px; background: #f4f4f4; }}
            table {{ border-collapse: collapse; width: 100%; background: white; }}
            th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }}
            th {{ background-color: #276DC3; color: white; }}
            tr:hover {{ background-color: #f5f5f5; }}
            .winner {{ background-color: #d4edda; font-weight: bold; }}
        </style>
    </head>
    <body>
        <h1>Model Comparison Leaderboard</h1>
        {results_df.to_html(index=False, classes='table')}
    </body>
    </html>
    """
    with open(output_path, 'w') as f:
        f.write(html_content)
