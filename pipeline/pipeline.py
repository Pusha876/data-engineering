import sys
from pathlib import Path

import pandas as pd

print('arguments', sys.argv)

month = int(sys.argv[1])

df = pd.DataFrame({"day": [1, 2, 3], "num_passengers": [4, 5, 6]})
df['month'] = month
print(df.head())
print('DataFrame created successfully')

output_path = Path(f'output/month={month}/data.parquet')
output_path.parent.mkdir(parents=True, exist_ok=True)
df.to_parquet(output_path, index=False)

print(f'Pipeline is running with Python version:, month={month}')