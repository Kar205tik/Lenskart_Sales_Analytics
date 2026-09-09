import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("lenskart dataset.csv")

df['order_date'] = pd.to_datetime(df['order_date'])
df['month'] = df['order_date'].dt.to_period('M')
monthly_sales = df.groupby('month')['net_sales_amount'].sum().reset_index()

print(monthly_sales)

from sklearn.linear_model import LinearRegression
import numpy as np

monthly_sales['month_number'] = range(len(monthly_sales))

X = monthly_sales[['month_number']]   
y = monthly_sales['net_sales_amount']  

model = LinearRegression()
model.fit(X, y)


future_months = np.array([[len(monthly_sales)], [len(monthly_sales)+1], [len(monthly_sales)+2]])
predictions = model.predict(future_months)

print("\nAgle 3 mahine ka predicted sales:")
for i, pred in enumerate(predictions, start=1):
    print(f"Month +{i}: {pred:,.2f}")

# graph plot karne ke liye
plt.figure(figsize=(10,5))
plt.plot(monthly_sales['month'].astype(str), monthly_sales['net_sales_amount'], label='Actual Sales')

# Future predictions plot karo
future_labels = ['2026-01', '2026-02', '2026-03']
plt.plot(future_labels, predictions, label='Predicted Sales', marker='o', linestyle='--', color='red')

plt.xticks(rotation=90)
plt.xlabel('Month')
plt.ylabel('Net Sales Amount')
plt.title('Lenskart Monthly Sales Forecast')
plt.legend()
plt.tight_layout()
plt.show()
