"""Parse MT5 optimization XML report and extract best result."""
import re, sys

def parse_optimization(path):
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    # Extract header row
    rows = re.findall(r'<Row>(.*?)</Row>', text, re.DOTALL)
    if len(rows) < 2:
        print("No optimization results found")
        return

    # Parse header
    headers = re.findall(r'<Data[^>]*>([^<]+)</Data>', rows[0])

    # Parse first data row (best result — sorted by criterion)
    values = re.findall(r'<Data[^>]*>([^<]+)</Data>', rows[1])

    print(f"Total passes: {len(rows) - 1}")
    print(f"\nBest result (sorted by optimization criterion):")
    for h, v in zip(headers, values):
        print(f"  {h}: {v}")

    # Also show top 3
    if len(rows) > 3:
        print(f"\nTop 3:")
        for rank, row in enumerate(rows[1:4], 1):
            vals = re.findall(r'<Data[^>]*>([^<]+)</Data>', row)
            params = {h: v for h, v in zip(headers, vals)}
            print(f"  #{rank}: Sharpe={params.get('Sharpe Ratio','?')} PF={params.get('Profit Factor','?')} "
                  f"Profit={params.get('Profit','?')} Trades={params.get('Trades','?')} "
                  f"DD={params.get('Equity DD %','?')}%")
            # Print parameter values
            skip = {'Pass','Result','Profit','Expected Payoff','Profit Factor',
                    'Recovery Factor','Sharpe Ratio','Custom','Equity DD %','Trades'}
            param_str = " ".join(f"{h}={v}" for h, v in zip(headers, vals) if h not in skip)
            print(f"       {param_str}")

if __name__ == '__main__':
    parse_optimization(sys.argv[1])
