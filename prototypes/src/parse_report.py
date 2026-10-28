"""Parse MT5 backtest HTML report and extract key metrics."""
import re, sys

def parse_report(path):
    with open(path, 'rb') as f:
        raw = f.read()
    text = raw.decode('utf-16-le', errors='ignore')
    cells = re.findall(r'<td[^>]*>(.*?)</td>', text, re.DOTALL)
    cells = [re.sub(r'<[^>]+>', '', c).strip() for c in cells if c.strip()]

    metrics = {}
    keys = [
        'Total Net Profit', 'Gross Profit', 'Gross Loss',
        'Profit Factor', 'Expected Payoff', 'Recovery Factor',
        'Sharpe Ratio', 'Total Trades', 'Short Trades (won %)',
        'Long Trades (won %)', 'Profit Trades (% of total)',
        'Loss Trades (% of total)', 'Largest profit trade',
        'Largest loss trade', 'Average profit trade',
        'Average loss trade', 'Balance Drawdown Maximal',
        'Equity Drawdown Maximal', 'Balance Drawdown Relative',
    ]

    for i, c in enumerate(cells):
        for k in keys:
            if c.startswith(k) and i + 1 < len(cells):
                metrics[k] = cells[i + 1]
                break
        # Some metrics are label:value in same cell pattern
        if ':' in c and i + 1 < len(cells):
            label = c.rstrip(':')
            if label in keys:
                metrics[label] = cells[i + 1]

    return metrics

if __name__ == '__main__':
    m = parse_report(sys.argv[1])
    for k, v in m.items():
        print(f"{k}: {v}")
