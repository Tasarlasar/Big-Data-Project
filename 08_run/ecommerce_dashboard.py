import dash
from dash import dcc, html
import plotly.graph_objects as go
import plotly.express as px
import pandas as pd
import os

DATA_DIR = os.path.join(os.path.dirname(__file__), 'python_outputs')

# Load all CSVs at startup
q1 = pd.read_csv(os.path.join(DATA_DIR, 'q1_total_orders_revenue.csv'))
q2 = pd.read_csv(os.path.join(DATA_DIR, 'q2_revenue_by_category.csv'))
q3 = pd.read_csv(os.path.join(DATA_DIR, 'q3_top_products_revenue.csv'))
q4 = pd.read_csv(os.path.join(DATA_DIR, 'q4_payment_methods.csv'))
q5 = pd.read_csv(os.path.join(DATA_DIR, 'q5_customer_clv.csv'))
q6 = pd.read_csv(os.path.join(DATA_DIR, 'q6_reviews_by_category.csv'))
q7 = pd.read_csv(os.path.join(DATA_DIR, 'q7_high_sales_poor_rating.csv'))
q8 = pd.read_csv(os.path.join(DATA_DIR, 'q8_monthly_trend.csv'))
q9 = pd.read_csv(os.path.join(DATA_DIR, 'q9_delivery_vs_score.csv'))
q10 = pd.read_csv(os.path.join(DATA_DIR, 'q10_delivery_rate.csv'))
q11 = pd.read_csv(os.path.join(DATA_DIR, 'q11_seller_performance.csv'))
q12 = pd.read_csv(os.path.join(DATA_DIR, 'q12_review_distribution.csv'))
q13 = pd.read_csv(os.path.join(DATA_DIR, 'q13_state_heatmap.csv'))

app = dash.Dash(__name__)
app.title = 'E-Commerce Analytics Dashboard'

# Color palette
bg_color = '#1a1a2e'
panel_color = '#16213e'
accent_color = '#0f3460'
accent_accent = '#e94560'

# KPI cards
kpi_cards = html.Div([
    html.Div([
        html.Div('📦', style={'fontSize': '32px'}),
        html.H3(f'{q1["total_orders"].iloc[0]:,}', style={'margin': '5px 0'}),
        html.P('Total Orders', style={'margin': 0, 'fontSize': '14px', 'color': '#aaa'})
    ], style={'backgroundColor': panel_color, 'borderRadius': '8px', 'padding': '20px', 'color': 'white', 'flex': '1', 'textAlign': 'center'}),
    html.Div([
        html.Div('💰', style={'fontSize': '32px'}),
        html.H3(f'R$ {q1["total_revenue"].iloc[0]:,.0f}', style={'margin': '5px 0'}),
        html.P('Total Revenue', style={'margin': 0, 'fontSize': '14px', 'color': '#aaa'})
    ], style={'backgroundColor': panel_color, 'borderRadius': '8px', 'padding': '20px', 'color': 'white', 'flex': '1', 'textAlign': 'center'}),
    html.Div([
        html.Div('📊', style={'fontSize': '32px'}),
        html.H3(f'R$ {q1["avg_order_value"].iloc[0]:.2f}', style={'margin': '5px 0'}),
        html.P('Avg Order Value', style={'margin': 0, 'fontSize': '14px', 'color': '#aaa'})
    ], style={'backgroundColor': panel_color, 'borderRadius': '8px', 'padding': '20px', 'color': 'white', 'flex': '1', 'textAlign': 'center'}),
    html.Div([
        html.Div('👥', style={'fontSize': '32px'}),
        html.H3(f'{q1["unique_customers"].iloc[0]:,}', style={'margin': '5px 0'}),
        html.P('Total Customers', style={'margin': 0, 'fontSize': '14px', 'color': '#aaa'})
    ], style={'backgroundColor': panel_color, 'borderRadius': '8px', 'padding': '20px', 'color': 'white', 'flex': '1', 'textAlign': 'center'})
], style={'display': 'flex', 'justifyContent': 'space-between', 'marginBottom': '30px'})

# Layout
app.layout = html.Div(style={'backgroundColor': bg_color, 'color': 'white', 'minHeight': '100vh'}, children=[
    # Header
    html.Div(style={'background': 'linear-gradient(135deg, #1a1a2e 0%, #16213e 100%)', 'padding': '30px 50px'}, children=[
        html.H1('E-Commerce Analytics Dashboard', style={'margin': '0 0 5px 0', 'fontSize': '28px'}),
        html.P('Brazilian Olist Dataset Analysis', style={'margin': 0, 'color': '#aaa'})
    ]),
    
    # KPI Cards
    html.Div(style={'padding': '20px 50px'}, children=[kpi_cards]),
    
    # Tabs
    dcc.Tabs(id='dashboard-tabs', value='tab-overview', style={'fontFamily': 'Arial'}, children=[
        # TAB 1 — Overview
        dcc.Tab(label='Overview', value='tab-overview', style={'backgroundColor': panel_color, 'color': '#aaa', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, selected_style={'backgroundColor': accent_accent, 'color': 'white', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                dcc.Loading(type='circle', children=[
                    html.Div(style={'display': 'flex', 'gap': '20px'}, children=[
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='monthly-orders', figure=px.line(q8, x='year_month', y='order_count', title='Monthly Orders Trend', template='plotly_dark').update_layout(height=400, showlegend=True))
                        ]),
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='monthly-revenue', figure=px.line(q8, x='year_month', y='monthly_revenue', title='Monthly Revenue Trend', template='plotly_dark').update_layout(height=400, showlegend=True))
                        ])
                    ])
                ])
            ])
        ]),
        
        # TAB 2 — Revenue
        dcc.Tab(label='Revenue', value='tab-revenue', style={'backgroundColor': panel_color, 'color': '#aaa', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, selected_style={'backgroundColor': accent_accent, 'color': 'white', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                dcc.Loading(type='circle', children=[
                    html.Div(style={'display': 'flex', 'gap': '20px'}, children=[
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='revenue-by-category', figure=px.bar(q2.sort_values('total_revenue', ascending=False), x='total_revenue', y='category', orientation='h', title='Revenue by Category', template='plotly_dark', labels={'total_revenue': 'Total Revenue', 'category': 'Category'}).update_layout(height=400, showlegend=True))
                        ]),
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='payment-distribution', figure=px.pie(q4[q4['payment_type'] != 'not_defined'], values='count', names='payment_type', title='Payment Method Distribution', template='plotly_dark').update_layout(height=400, showlegend=True))
                        ])
                    ])
                ])
            ])
        ]),
        
        # TAB 3 — Products
        dcc.Tab(label='Products', value='tab-products', style={'backgroundColor': panel_color, 'color': '#aaa', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, selected_style={'backgroundColor': accent_accent, 'color': 'white', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                dcc.Loading(type='circle', children=[
                    html.Div(style={'display': 'flex', 'gap': '20px'}, children=[
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='products-scatter', figure=px.scatter(q3, x='units_sold', y='total_revenue', color='category_en', size='avg_price', hover_name='product_id', title='Product Revenue vs Units Sold', template='plotly_dark', labels={'units_sold': 'Units Sold', 'total_revenue': 'Total Revenue', 'avg_price': 'Avg Price'}).update_layout(height=400, showlegend=True).update_traces(hovertemplate='Product: %{customdata}<br>Units: %{x}<br>Revenue: R$ %{y:,.0f}<br>Price: R$ %{marker.size:,.2f}'))
                        ]),
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='poor-rating-products', figure=px.bar(q7.head(20), x='product_id', y='avg_review_score', color='units_sold', title='Top 20 High-Sales-Poor-Rating Products', template='plotly_dark', labels={'product_id': 'Product ID', 'avg_review_score': 'Avg Review Score', 'units_sold': 'Units Sold'}, hover_data={'product_id': False}, category_orders={'product_id': q7.head(20)['product_id'].tolist()}).update_layout(height=400, showlegend=True, xaxis_tickangle=-45, xaxis={'tickformat': '.8s'}))
                        ])
                    ])
                ])
            ])
        ]),
        
        # TAB 4 — Payments
        dcc.Tab(label='Payments', value='tab-payments', style={'backgroundColor': panel_color, 'color': '#aaa', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, selected_style={'backgroundColor': accent_accent, 'color': 'white', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                dcc.Loading(type='circle', children=[
                    html.Div(style={'display': 'flex', 'gap': '20px'}, children=[
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='payment-value', figure=px.bar(q4[q4['payment_type'] != 'not_defined'], x='payment_type', y='total_value', title='Payment Method - Total Value', template='plotly_dark', labels={'payment_type': 'Payment Type', 'total_value': 'Total Value'}).update_layout(height=400, showlegend=True))
                        ]),
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='payment-comparison', figure=go.Figure(data=[
                                go.Bar(name='Transaction Count', x=q4[q4['payment_type'] != 'not_defined']['payment_type'], y=q4[q4['payment_type'] != 'not_defined']['count'], marker_color=accent_color),
                                go.Bar(name='Order Count', x=q4[q4['payment_type'] != 'not_defined']['payment_type'], y=q4[q4['payment_type'] != 'not_defined']['order_count'], marker_color=accent_accent)
                            ], layout=go.Layout(barmode='group', title='Payment Methods: Transactions vs Orders', template='plotly_dark', height=400, showlegend=True)))
                        ])
                    ])
                ])
            ])
        ]),
        
        # TAB 5 — Customers
        dcc.Tab(label='Customers', value='tab-customers', style={'backgroundColor': panel_color, 'color': '#aaa', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, selected_style={'backgroundColor': accent_accent, 'color': 'white', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                dcc.Loading(type='circle', children=[
                    html.Div(style={'display': 'flex', 'gap': '20px'}, children=[
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='top-customers-clv', figure=px.bar(q5.head(20), x='customer_id', y='total_clv', title='Top 20 Customers by CLV', template='plotly_dark', labels={'customer_id': 'Customer ID', 'total_clv': 'Total CLV'}).update_layout(height=400, showlegend=True, xaxis_tickangle=-45))
                        ]),
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='clv-histogram', figure=px.histogram(q5, x='total_clv', nbins=10, title='CLV Distribution', template='plotly_dark', labels={'total_clv': 'Customer Lifetime Value', 'count': 'Count'}).update_layout(height=400, showlegend=True))
                        ])
                    ])
                ])
            ])
        ]),
        
        # TAB 6 — Reviews
        dcc.Tab(label='Reviews', value='tab-reviews', style={'backgroundColor': panel_color, 'color': '#aaa', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, selected_style={'backgroundColor': accent_accent, 'color': 'white', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                dcc.Loading(type='circle', children=[
                    html.Div(style={'display': 'flex', 'gap': '20px'}, children=[
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='reviews-by-category', figure=px.bar(q6.nlargest(30, 'review_count'), x='avg_review_score', y='category', orientation='h', color='avg_review_score', title='Avg Review Score by Category (Top 30 by Review Count)', template='plotly_dark', labels={'avg_review_score': 'Avg Review Score', 'category': 'Category'}).update_layout(height=400, showlegend=True))
                        ]),
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='review-distribution', figure=px.pie(q12, values='review_count', names='review_score', title='Review Score Distribution', template='plotly_dark').update_layout(height=400, showlegend=True))
                        ])
                    ])
                ])
            ])
        ]),
        
        # TAB 7 — Delivery
        dcc.Tab(label='Delivery', value='tab-delivery', style={'backgroundColor': panel_color, 'color': '#aaa', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, selected_style={'backgroundColor': accent_accent, 'color': 'white', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                dcc.Loading(type='circle', children=[
                    html.Div(style={'display': 'flex', 'gap': '20px'}, children=[
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='delivery-vs-score', figure=px.bar(q9, x='review_score', y='avg_delivery_days', title='Average Delivery Days by Review Score', template='plotly_dark', labels={'review_score': 'Review Score', 'avg_delivery_days': 'Avg Delivery Days'}).update_layout(height=400, showlegend=True))
                        ]),
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='delivery-performance', figure=go.Figure(data=[
                                go.Bar(name='Order Count', x=q10['on_time'], y=q10['order_count'], marker_color=accent_color),
                                go.Bar(name='Avg Review Score', x=q10['on_time'], y=q10['avg_review_score'], marker_color=accent_accent)
                            ], layout=go.Layout(barmode='group', title='On-Time vs Late Delivery Performance', template='plotly_dark', height=400, showlegend=True, yaxis=dict(title='Order Count'), yaxis2=dict(title='Avg Review Score', overlaying='y', side='right'))))
                        ])
                    ])
                ])
            ])
        ]),
        
        # TAB 8 — Sellers
        dcc.Tab(label='Sellers', value='tab-sellers', style={'backgroundColor': panel_color, 'color': '#aaa', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, selected_style={'backgroundColor': accent_accent, 'color': 'white', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                dcc.Loading(type='circle', children=[
                    html.Div(style={'display': 'flex', 'flexDirection': 'column', 'gap': '20px'}, children=[
                        html.Div(style={'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='sellers-scatter', figure=px.scatter(q11, x='order_count', y='total_revenue', size='avg_review_score', hover_name='seller_id', title='Seller Performance: Orders vs Revenue', template='plotly_dark', labels={'order_count': 'Order Count', 'total_revenue': 'Total Revenue', 'avg_review_score': 'Avg Review Score'}).update_layout(height=450, showlegend=True).update_traces(hovertemplate='Seller: %{customdata}<br>Orders: %{x}<br>Revenue: R$ %{y:,.0f}<br>Rating: %{marker.size:.2f}'))
                        ]),
                        html.Div(style={'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='sellers-bar', figure=px.bar(q11.sort_values('total_revenue', ascending=False), x='seller_id', y='total_revenue', color='avg_review_score', title='Sellers by Total Revenue', template='plotly_dark', labels={'seller_id': 'Seller ID', 'total_revenue': 'Total Revenue', 'avg_review_score': 'Avg Review Score'}).update_layout(height=450, showlegend=True, xaxis_tickangle=-45))
                        ])
                    ])
                ])
            ])
        ]),
        
        # TAB 9 — Heatmap
        dcc.Tab(label='Heatmap', value='tab-heatmap', style={'backgroundColor': panel_color, 'color': '#aaa', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, selected_style={'backgroundColor': accent_accent, 'color': 'white', 'padding': '10px 20px', 'borderRadius': '5px 5px 0 0', 'border': 'none'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                dcc.Loading(type='circle', children=[
                    html.Div(style={'display': 'flex', 'gap': '20px'}, children=[
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='states-orders', figure=px.bar(q13.sort_values('order_count', ascending=False), x='order_count', y='customer_state', orientation='h', title='Orders by Brazilian State', template='plotly_dark', labels={'order_count': 'Order Count', 'customer_state': 'State'}).update_layout(height=400, showlegend=True))
                        ]),
                        html.Div(style={'flex': '1', 'backgroundColor': panel_color, 'borderRadius': '10px', 'padding': '20px'}, children=[
                            dcc.Graph(id='states-bubble', figure=px.scatter(q13, x='customer_state', y='total_revenue', size='order_count', hover_name='customer_state', hover_data={'avg_order_value': ':.2f'}, title='State Performance: Revenue vs Orders', template='plotly_dark', labels={'customer_state': 'State', 'total_revenue': 'Total Revenue', 'order_count': 'Order Count'}).update_layout(height=400, showlegend=True, xaxis_tickangle=-45))
                        ])
                    ])
                ])
            ])
        ])
    ])
])

if __name__ == '__main__':
    app.run(debug=False, port=8050)