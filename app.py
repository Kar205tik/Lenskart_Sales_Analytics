import streamlit as st
import pandas as pd
from sklearn.linear_model import LinearRegression
import numpy as np
import google.generativeai as genai
from dotenv import load_dotenv
import os
load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

st.title("📊 Lenskart Sales Forecast Dashboard")

# Data load
df = pd.read_csv("data/Lenskart_Sales_Dataset.csv")
df['order_date'] = pd.to_datetime(df['order_date'])
df['month'] = df['order_date'].dt.to_period('M')
monthly_sales = df.groupby('month')['net_sales_amount'].sum().reset_index()
monthly_sales['month_str'] = monthly_sales['month'].astype(str)

# KPIs
total_sales = df['net_sales_amount'].sum()
total_orders = df['order_id'].nunique()
avg_order_value = total_sales / total_orders

col1, col2, col3 = st.columns(3)
col1.metric("Total Sales", f"₹{total_sales:,.0f}")
col2.metric("Total Orders", f"{total_orders:,}")
col3.metric("Avg Order Value", f"₹{avg_order_value:,.2f}")

# Forecasting
monthly_sales['month_number'] = range(len(monthly_sales))
X = monthly_sales[['month_number']]
y = monthly_sales['net_sales_amount']
model = LinearRegression()
model.fit(X, y)

future_months = np.array([[len(monthly_sales)], [len(monthly_sales)+1], [len(monthly_sales)+2]])
predictions = model.predict(future_months)

st.subheader("Monthly Sales Trend")
st.line_chart(monthly_sales.set_index('month_str')['net_sales_amount'])
st.subheader("Next 3 Months Forecast")

for i, pred in enumerate(predictions, start=1):
    st.write(f"Month +{i}: ₹{pred:,.2f}")

# Forecast numbers ko text mein convert karo AI ko bhejne ke liye
forecast_text = ", ".join([f"Month +{i}: ₹{pred:,.2f}" for i, pred in enumerate(predictions, start=1)])
prompt = f"""
You are a business analyst. Here is Lenskart's monthly sales data trend and forecast:
Recent monthly sales history shows a seasonal dip every February.
Forecast for next 3 months: {forecast_text}

Write a 2-3 sentence business insight and one actionable recommendation for the business team.
"""

model = genai.GenerativeModel("gemini-3.6-flash")
response = model.generate_content(prompt)

st.info(response.text)
