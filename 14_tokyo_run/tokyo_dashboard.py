import dash
from dash import dcc, html, Input, Output
import plotly.graph_objects as go
import plotly.express as px
import pandas as pd
import zipfile
import io
import os
import glob

RAW_DIR = '/Users/home/College/Big Data Computing/E-commerce/09_tokyo_gtfsgenerator/raw'

GTFS_FILES = sorted(glob.glob(os.path.join(RAW_DIR, '*.gtfs.zip')))

def read_gtfs_file(zip_path, filename):
    """Read a specific file from a GTFS zip, return DataFrame or None."""
    try:
        with zipfile.ZipFile(zip_path, 'r') as z:
            if filename in z.namelist():
                with z.open(filename) as f:
                    return pd.read_csv(io.TextIOWrapper(f, encoding='utf-8'))
    except Exception:
        pass
    return None

def get_operator_name(zip_path):
    """Extract operator name from zip filename."""
    base = os.path.basename(zip_path)
    return base.replace('-Train.gtfs.zip', '').replace('.gtfs.zip', '')

# Route type mapping
ROUTE_TYPE_LABELS = {
    0: 'Tram',
    1: 'Subway/Metro',
    2: 'Rail',
    3: 'Bus',
    4: 'Ferry',
    5: 'Cable Car',
    6: 'Gondola',
    7: 'Funicular'
}

# Load and aggregate data from all operators
all_agencies = []
all_routes = []
all_stops = []
all_trips = []
all_stop_times = []
all_calendar = []

for zip_path in GTFS_FILES:
    operator = get_operator_name(zip_path)
    
    df = read_gtfs_file(zip_path, 'agency.txt')
    if df is not None:
        df['operator'] = operator
        all_agencies.append(df)
    
    df = read_gtfs_file(zip_path, 'routes.txt')
    if df is not None:
        df['operator'] = operator
        all_routes.append(df)
    
    df = read_gtfs_file(zip_path, 'stops.txt')
    if df is not None:
        df['operator'] = operator
        all_stops.append(df)
    
    df = read_gtfs_file(zip_path, 'trips.txt')
    if df is not None:
        df['operator'] = operator
        all_trips.append(df)
    
    # stop_times can be large — only load for summary stats
    df = read_gtfs_file(zip_path, 'stop_times.txt')
    if df is not None:
        df['operator'] = operator
        all_stop_times.append(df)
    
    df = read_gtfs_file(zip_path, 'calendar.txt')
    if df is not None:
        df['operator'] = operator
        all_calendar.append(df)

agencies_df = pd.concat(all_agencies, ignore_index=True) if all_agencies else pd.DataFrame()
routes_df = pd.concat(all_routes, ignore_index=True) if all_routes else pd.DataFrame()
stops_df = pd.concat(all_stops, ignore_index=True) if all_stops else pd.DataFrame()
trips_df = pd.concat(all_trips, ignore_index=True) if all_trips else pd.DataFrame()
stop_times_df = pd.concat(all_stop_times, ignore_index=True) if all_stop_times else pd.DataFrame()
calendar_df = pd.concat(all_calendar, ignore_index=True) if all_calendar else pd.DataFrame()

# Add route_type_label to routes_df if route_type exists
if 'route_type' in routes_df.columns:
    routes_df['route_type_label'] = routes_df['route_type'].map(ROUTE_TYPE_LABELS).fillna('Unknown')
else:
    routes_df['route_type_label'] = 'Unknown'

app = dash.Dash(__name__)

app.layout = html.Div(style={'backgroundColor': '#0f0f1a', 'color': '#ffffff', 'fontFamily': 'Arial'}, children=[
    html.Div(style={'textAlign': 'center', 'padding': '20px', 'borderBottom': '2px solid #00d4ff'}, children=[
        html.H1('Tokyo Railway Network Dashboard', style={'color': '#00d4ff', 'marginBottom': '5px'}),
        html.P('GTFS Multi-Operator Transit Analysis', style={'color': '#cccccc'})
    ]),
    
    dcc.Tabs(id='dashboard-tabs', value='tab-operators', style={'backgroundColor': '#0f0f1a'}, children=[
        # TAB 1 — Operators
        dcc.Tab(label='Operators', value='tab-operators', style={'backgroundColor': '#0f0f1a', 'color': '#ffffff'}, selected_style={'backgroundColor': '#00d4ff', 'color': '#0f0f1a'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                html.Div(style={'display': 'flex', 'justifyContent': 'space-around', 'marginBottom': '30px'}, children=[
                    html.Div(style={'backgroundColor': '#1a1a2e', 'padding': '20px', 'borderRadius': '10px', 'border': '2px solid #00d4ff', 'width': '20%'}, children=[
                        html.H3(len(GTFS_FILES), style={'color': '#00d4ff', 'margin': '0'}),
                        html.P('Total Operators', style={'margin': '5px 0 0 0', 'color': '#cccccc'})
                    ]),
                    html.Div(style={'backgroundColor': '#1a1a2e', 'padding': '20px', 'borderRadius': '10px', 'border': '2px solid #00d4ff', 'width': '20%'}, children=[
                        html.H3(len(routes_df) if not routes_df.empty else 0, style={'color': '#00d4ff', 'margin': '0'}),
                        html.P('Total Routes', style={'margin': '5px 0 0 0', 'color': '#cccccc'})
                    ]),
                    html.Div(style={'backgroundColor': '#1a1a2e', 'padding': '20px', 'borderRadius': '10px', 'border': '2px solid #00d4ff', 'width': '20%'}, children=[
                        html.H3(len(stops_df) if not stops_df.empty else 0, style={'color': '#00d4ff', 'margin': '0'}),
                        html.P('Total Stations', style={'margin': '5px 0 0 0', 'color': '#cccccc'})
                    ]),
                    html.Div(style={'backgroundColor': '#1a1a2e', 'padding': '20px', 'borderRadius': '10px', 'border': '2px solid #00d4ff', 'width': '20%'}, children=[
                        html.H3(len(trips_df) if not trips_df.empty else 0, style={'color': '#00d4ff', 'margin': '0'}),
                        html.P('Total Trips', style={'margin': '5px 0 0 0', 'color': '#cccccc'})
                    ])
                ]),
                
                html.Div(style={'display': 'flex', 'justifyContent': 'space-around', 'height': '400px'}, children=[
                    html.Div(style={'width': '48%'}, children=[
                        html.H3('Routes per Operator', style={'textAlign': 'center', 'color': '#ffffff'}),
                        dcc.Graph(id='routes-per-operator', 
                                  figure=px.bar(
                                      routes_df.groupby('operator').size().reset_index(name='count').sort_values('count', ascending=False),
                                      x='operator', y='count', template='plotly_dark',
                                      color_discrete_sequence=['#00d4ff']
                                  ).update_layout(height=400, showlegend=False))
                    ]),
                    html.Div(style={'width': '48%'}, children=[
                        html.H3('Stations per Operator', style={'textAlign': 'center', 'color': '#ffffff'}),
                        dcc.Graph(id='stations-per-operator', 
                                  figure=px.bar(
                                      stops_df.groupby('operator').size().reset_index(name='count').sort_values('count', ascending=False),
                                      x='operator', y='count', template='plotly_dark',
                                      color_discrete_sequence=['#ff6b6b']
                                  ).update_layout(height=400, showlegend=False))
                    ])
                ])
            ])
        ]),
        
        # TAB 2 — Routes
        dcc.Tab(label='Routes', value='tab-routes', style={'backgroundColor': '#0f0f1a', 'color': '#ffffff'}, selected_style={'backgroundColor': '#00d4ff', 'color': '#0f0f1a'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                html.Div(style={'display': 'flex', 'justifyContent': 'space-around', 'height': '400px'}, children=[
                    html.Div(style={'width': '48%'}, children=[
                        html.H3('Route Type Distribution', style={'textAlign': 'center', 'color': '#ffffff'}),
                        dcc.Graph(id='route-type-dist', 
                                  figure=px.pie(
                                      routes_df.groupby('route_type_label').size().reset_index(name='count'),
                                      names='route_type_label', values='count', template='plotly_dark',
                                      color_discrete_sequence=px.colors.qualitative.Set3
                                  ).update_layout(height=400))
                    ]),
                    html.Div(style={'width': '48%'}, children=[
                        html.H3('Top 15 Operators by Routes', style={'textAlign': 'center', 'color': '#ffffff'}),
                        dcc.Graph(id='top-operators-routes', 
                                  figure=go.Figure(
                                      data=[go.Bar(
                                          x=routes_df.groupby('operator').size().reset_index(name='count').sort_values('count', ascending=False).head(15)['count'].values,
                                          y=routes_df.groupby('operator').size().reset_index(name='count').sort_values('count', ascending=False).head(15)['operator'].values,
                                          orientation='h',
                                          marker_color='#00d4ff'
                                      )],
                                      layout=go.Layout(height=400, template='plotly_dark', yaxis={'categoryorder': 'total ascending'})
                                  )
                        )
                    ])
                ]),
                html.Div(style={'height': '400px', 'marginTop': '20px'}, children=[
                    html.H3('Route Types Across All Operators', style={'textAlign': 'center', 'color': '#ffffff'}),
                    dcc.Graph(id='route-types-all',
                              figure=px.histogram(
                                  routes_df, x='route_type_label', template='plotly_dark',
                                  color_discrete_sequence=['#00d4ff']
                              ).update_layout(height=400, showlegend=False))
                ])
            ])
        ]),
        
        # TAB 3 — Stations
        dcc.Tab(label='Stations', value='tab-stations', style={'backgroundColor': '#0f0f1a', 'color': '#ffffff'}, selected_style={'backgroundColor': '#00d4ff', 'color': '#0f0f1a'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                html.Div(style={'height': '500px'}, children=[
                    html.H3('Station Locations', style={'textAlign': 'center', 'color': '#ffffff'}),
                    html.P('Showing stations with coordinates (dark matter map)', style={'textAlign': 'center', 'color': '#cccccc'}),
                    html.Div(style={'height': '500px'}, children=[
                        dcc.Graph(id='stations-map',
                                  figure=(
                                      px.scatter_map(
                                          stops_df,
                                          lat='stop_lat',
                                          lon='stop_lon',
                                          hover_name='stop_name' if 'stop_name' in stops_df.columns else None,
                                          color='operator' if 'operator' in stops_df.columns else None,
                                          map_style='carto-darkmatter',
                                          center={'lat': 35.68, 'lon': 139.69},
                                          zoom=9
                                      ).update_layout(height=500, margin=dict(l=0, r=0, t=0, b=0))
                                      if not stops_df.empty and 'stop_lat' in stops_df.columns and 'stop_lon' in stops_df.columns
                                      else go.Figure(layout=go.Layout(height=500, template='plotly_dark', title='No station coordinate data available'))
                                  )
                        )
                    ])
                ]),
                html.Div(style={'height': '450px', 'marginTop': '20px'}, children=[
                    html.H3('Top 20 Most-Connected Stations', style={'textAlign': 'center', 'color': '#ffffff'}),
                    dcc.Graph(id='top-stations-connections', 
                              figure=go.Figure(
                                  data=[go.Bar(
                                      x=stop_times_df['stop_id'].value_counts().head(20).index.astype(str).values if not stop_times_df.empty else [],
                                      y=stop_times_df['stop_id'].value_counts().head(20).values if not stop_times_df.empty else [],
                                      marker_color='#ff6b6b'
                                  )],
                                  layout=go.Layout(
                                      height=450, 
                                      template='plotly_dark',
                                      xaxis_tickangle=-45
                                  )
                              )
                    )
                ])
            ])
        ]),
        
        # TAB 4 — Trips
        dcc.Tab(label='Trips', value='tab-trips', style={'backgroundColor': '#0f0f1a', 'color': '#ffffff'}, selected_style={'backgroundColor': '#00d4ff', 'color': '#0f0f1a'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                html.Div(style={'display': 'flex', 'justifyContent': 'space-around', 'height': '400px'}, children=[
                    html.Div(style={'width': '48%'}, children=[
                        html.H3('Trips per Operator', style={'textAlign': 'center', 'color': '#ffffff'}),
                        dcc.Graph(id='trips-per-operator', 
                                  figure=px.bar(
                                      trips_df.groupby('operator').size().reset_index(name='count').sort_values('count', ascending=False),
                                      x='operator', y='count', template='plotly_dark',
                                      color_discrete_sequence=['#00d4ff']
                                  ).update_layout(height=400, showlegend=False))
                    ]),
                    html.Div(style={'width': '48%'}, children=[
                        html.H3('Trips by Direction per Operator', style={'textAlign': 'center', 'color': '#ffffff'}),
                        dcc.Graph(id='trips-direction',
                                  figure=px.histogram(
                                      trips_df, x='operator', color='direction_id' if 'direction_id' in trips_df.columns else None,
                                      template='plotly_dark'
                                  ).update_layout(height=400, barmode='group'))
                    ])
                ]),
                html.Div(style={'height': '450px', 'marginTop': '20px'}, children=[
                    html.H3('Top 20 Service IDs by Trip Count', style={'textAlign': 'center', 'color': '#ffffff'}),
                    dcc.Graph(id='service-id-dist',
                              figure=go.Figure(
                                  data=[go.Bar(
                                      x=trips_df['service_id'].value_counts().head(20).index.astype(str).values if not trips_df.empty else [],
                                      y=trips_df['service_id'].value_counts().head(20).values if not trips_df.empty else [],
                                      marker_color='#ff6b6b'
                                  )],
                                  layout=go.Layout(height=450, template='plotly_dark', xaxis_tickangle=-45)
                              )
                    )
                ])
            ])
        ]),
        
        # TAB 5 — Schedule
        dcc.Tab(label='Schedule', value='tab-schedule', style={'backgroundColor': '#0f0f1a', 'color': '#ffffff'}, selected_style={'backgroundColor': '#00d4ff', 'color': '#0f0f1a'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                html.Div(style={'display': 'flex', 'justifyContent': 'space-around', 'height': '400px'}, children=[
                    html.Div(style={'width': '48%'}, children=[
                        html.H3('Service Availability by Day (Stacked)', style={'textAlign': 'center', 'color': '#ffffff'}),
                        dcc.Graph(id='schedule-by-day',
                                  figure=go.Figure(
                                      data=[go.Bar(
                                          name='Monday', x=[], y=[]),
                                          go.Bar(name='Tuesday', x=[], y=[]),
                                          go.Bar(name='Wednesday', x=[], y=[]),
                                          go.Bar(name='Thursday', x=[], y=[]),
                                          go.Bar(name='Friday', x=[], y=[]),
                                          go.Bar(name='Saturday', x=[], y=[]),
                                          go.Bar(name='Sunday', x=[], y=[])
                                      ],
                                      layout=go.Layout(height=400, template='plotly_dark', barmode='stack', xaxis={'categoryorder': 'category ascending'}))
                        )
                    ]),
                    html.Div(style={'width': '48%'}, children=[
                        html.H3('Weekday vs Weekend Service', style={'textAlign': 'center', 'color': '#ffffff'}),
                        dcc.Graph(id='weekday-weekend-pie',
                                  figure=go.Figure(
                                      data=[go.Pie(
                                          labels=['Weekday Services', 'Weekend Services'],
                                          values=[0, 0],
                                          marker_colors=['#00d4ff', '#ff6b6b']
                                      )],
                                      layout=go.Layout(height=400))
                        )
                    ])
                ])
            ])
        ]),
        
        # TAB 6 — Network
        dcc.Tab(label='Network', value='tab-network', style={'backgroundColor': '#0f0f1a', 'color': '#ffffff'}, selected_style={'backgroundColor': '#00d4ff', 'color': '#0f0f1a'}, children=[
            html.Div(style={'padding': '20px'}, children=[
                html.Div(style={'height': '500px'}, children=[
                    html.H3('Operator to Route Type Hierarchy', style={'textAlign': 'center', 'color': '#ffffff'}),
                    dcc.Graph(id='network-sunburst',
                              figure=px.sunburst(
                                  routes_df,
                                  path=['operator', 'route_type_label'],
                                  values=[1] * len(routes_df) if not routes_df.empty else [],
                                  template='plotly_dark'
                              ).update_layout(height=500))
                ]),
                html.Div(style={'height': '450px', 'marginTop': '20px'}, children=[
                    html.H3('Top 20 Stops by Visit Frequency', style={'textAlign': 'center', 'color': '#ffffff'}),
                    html.P('Based on stop_times.txt frequency (sampled if >500k rows)', style={'textAlign': 'center', 'color': '#cccccc'}),
                    dcc.Graph(id='stop-frequency',
                              figure=go.Figure(
                                  data=[go.Bar(
                                      x=stop_times_df['stop_id'].value_counts().head(20).index.astype(str).values if not stop_times_df.empty else [],
                                      y=stop_times_df['stop_id'].value_counts().head(20).values if not stop_times_df.empty else [],
                                      marker_color='#00d4ff'
                                  )],
                                  layout=go.Layout(height=450, template='plotly_dark', xaxis_tickangle=-45)
                              )
                    )
                ])
            ])
        ])
    ])
])

# Update Schedule tabs with actual data
@app.callback(
    Output('schedule-by-day', 'figure'),
    Output('weekday-weekend-pie', 'figure'),
    Input('dashboard-tabs', 'value')
)
def update_schedule_tabs(tab):
    if calendar_df.empty:
        return go.Figure(), go.Figure()
    
    # Find weekday columns
    day_columns = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
    available_days = [d for d in day_columns if d in calendar_df.columns]
    
    if not available_days:
        return go.Figure(), go.Figure()
    
    # Stacked bar: service availability per operator by day
    day_sums = []
    for day in available_days:
        day_sum = calendar_df.groupby('operator')[day].sum().reset_index()
        day_sums.append(go.Bar(name=day.capitalize(), x=day_sum['operator'], y=day_sum[day]))
    
    stacked_fig = go.Figure(data=day_sums, layout=go.Layout(
        height=400, template='plotly_dark', barmode='stack', xaxis={'categoryorder': 'category ascending'}
    ))
    
    # Weekday vs Weekend pie
    weekday_cols = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']
    weekend_cols = ['saturday', 'sunday']
    
    weekday_services = calendar_df[weekday_cols].sum().sum() if all(c in calendar_df.columns for c in weekday_cols) else 0
    weekend_services = calendar_df[weekend_cols].sum().sum() if all(c in calendar_df.columns for c in weekend_cols) else 0
    
    weekday_fig = go.Figure(
        data=[go.Pie(
            labels=['Weekday Services', 'Weekend Services'],
            values=[weekday_services, weekend_services],
            marker_colors=['#00d4ff', '#ff6b6b']
        )],
        layout=go.Layout(height=400)
    )
    
    return stacked_fig, weekday_fig

if __name__ == '__main__':
    app.run(debug=False, port=8051)
