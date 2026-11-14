import math

def polar_to_cartesian(cx, cy, r, angle_degrees):
    rad = math.radians(angle_degrees)
    return cx + r * math.cos(rad), cy + r * math.sin(rad)

def describe_donut_wedge(cx, cy, r_inner, r_outer, start_angle, end_angle):
    x1_out, y1_out = polar_to_cartesian(cx, cy, r_outer, start_angle)
    x2_out, y2_out = polar_to_cartesian(cx, cy, r_outer, end_angle)
    x1_in, y1_in = polar_to_cartesian(cx, cy, r_inner, end_angle)
    x2_in, y2_in = polar_to_cartesian(cx, cy, r_inner, start_angle)

    large_arc = 1 if (end_angle - start_angle) % 360 > 180 else 0

    return f"M {x1_out} {y1_out} A {r_outer} {r_outer} 0 {large_arc} 1 {x2_out} {y2_out} L {x1_in} {y1_in} A {r_inner} {r_inner} 0 {large_arc} 0 {x2_in} {y2_in} Z"

cx, cy = 600, 380
r_inner, r_outer = 130, 220
r_badge = 175

stages = [
    {
        "num": 1,
        "title": "Planning",
        "color": "#16A34A",
        "start": -86, "end": -18,
        "label_x": 920, "label_y": 120,
        "line_x": 780, "line_y": 200,
        "align": "start",
        "text": ["Problem validated;", "farmer and MAO admin", "needs identified"]
    },
    {
        "num": 2,
        "title": "Design",
        "color": "#0284C7",
        "start": -14, "end": 54,
        "label_x": 920, "label_y": 420,
        "line_x": 800, "line_y": 410,
        "align": "start",
        "text": ["Flowcharts, database,", "user interface, and", "advisory workflow"]
    },
    {
        "num": 3,
        "title": "Development",
        "color": "#1E293B",
        "start": 58, "end": 126,
        "label_x": 600, "label_y": 680,
        "line_x": 600, "line_y": 610,
        "align": "middle",
        "text": ["Machine Learning modules (RandomForest, ARIMA, ElasticNet, Ensemble), Supabase cloud database,", "Flutter web and mobile portals, and security features (RLS, encryption, activity logs) built in iterations"]
    },
    {
        "num": 4,
        "title": "Testing",
        "color": "#EA580C",
        "start": 130, "end": 198,
        "label_x": 280, "label_y": 420,
        "line_x": 400, "line_y": 410,
        "align": "end",
        "text": ["Functional, security,", "performance testing;", "defects fixed before", "each release"]
    },
    {
        "num": 5,
        "title": "Deployment",
        "color": "#D97706",
        "start": 202, "end": 270,
        "label_x": 280, "label_y": 120,
        "line_x": 420, "line_y": 200,
        "align": "end",
        "text": ["Released to users and", "evaluated with ISO/IEC", "25010:2011 quality", "model"]
    }
]

svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 760" width="1200" height="760" style="background-color: #ffffff; font-family: 'Segoe UI', Arial, sans-serif;">
  <defs>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="4" stdDeviation="6" flood-opacity="0.12" />
    </filter>
  </defs>

  <!-- Title -->
  <text x="600" y="45" text-anchor="middle" font-size="24" font-weight="bold" fill="#0F172A">AGILE METHODOLOGY WITH RAPID PROTOTYPING</text>
  <text x="600" y="70" text-anchor="middle" font-size="14" font-weight="600" fill="#64748B">PAGRI: Pagsanjan Agricultural Decision Support System</text>

  <!-- Center Circle -->
  <circle cx="{cx}" cy="{cy}" r="{r_inner - 5}" fill="#FFFFFF" filter="url(#shadow)" />
  <text x="{cx}" y="{cy - 12}" text-anchor="middle" font-size="22" font-weight="900" fill="#0284C7" letter-spacing="1">AGILE</text>
  <text x="{cx}" y="{cy + 10}" text-anchor="middle" font-size="14" font-weight="bold" fill="#334155">Methodology</text>
  <text x="{cx}" y="{cy + 28}" text-anchor="middle" font-size="11" font-weight="600" fill="#64748B">with rapid prototyping</text>

'''

for s in stages:
    path_d = describe_donut_wedge(cx, cy, r_inner, r_outer, s["start"], s["end"])
    mid_angle = (s["start"] + s["end"]) / 2
    bx, by = polar_to_cartesian(cx, cy, r_badge, mid_angle)
    tx, ty = polar_to_cartesian(cx, cy, (r_inner + r_outer) / 2, mid_angle)

    # Arc segment
    svg_content += f'  <path d="{path_d}" fill="{s["color"]}" />\n'

    # Title on Segment
    title_y = ty + (5 if s["num"] in [1, 5] else (-5 if s["num"] == 3 else 0))
    svg_content += f'  <text x="{tx}" y="{title_y}" text-anchor="middle" font-size="15" font-weight="bold" fill="#FFFFFF">{s["title"]}</text>\n'

    # Badge Circle
    svg_content += f'  <circle cx="{bx}" cy="{by}" r="16" fill="#FFFFFF" stroke="{s["color"]}" stroke-width="3" />\n'
    svg_content += f'  <text x="{bx}" y="{by + 5}" text-anchor="middle" font-size="13" font-weight="bold" fill="{s["color"]}">{s["num"]}</text>\n'

    # Dashed Leader Line
    if s["num"] != 3:
        svg_content += f'  <line x1="{bx}" y1="{by}" x2="{s["label_x"]}" y2="{by}" stroke="#94A3B8" stroke-width="1.5" stroke-dasharray="4,4" />\n'
    else:
        svg_content += f'  <line x1="{bx}" y1="{by}" x2="{bx}" y2="{s["line_y"]}" stroke="#94A3B8" stroke-width="1.5" stroke-dasharray="4,4" />\n'

    # Annotation Text Block
    align = s["align"]
    lx = s["label_x"]
    ly = s["label_y"]

    for idx, line_text in enumerate(s["text"]):
        svg_content += f'  <text x="{lx}" y="{ly + (idx * 18)}" text-anchor="{align}" font-size="12" fill="#334155">{line_text}</text>\n'

svg_content += '</svg>\n'

with open('sql/agile_methodology_diagram.svg', 'w', encoding='utf-8') as f:
    f.write(svg_content)

html_content = f'''<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>PAGRI - Agile Methodology Diagram</title>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #F8FAFC;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 40px;
            margin: 0;
        }}
        .card {{
            background: #FFFFFF;
            padding: 30px;
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.08);
            max-width: 1240px;
        }}
        .btn {{
            background-color: #0284C7;
            color: white;
            border: none;
            padding: 12px 24px;
            font-size: 14px;
            font-weight: bold;
            border-radius: 10px;
            cursor: pointer;
            margin-top: 20px;
            box-shadow: 0 4px 12px rgba(2, 132, 199, 0.3);
        }}
        .btn:hover {{
            background-color: #0369A1;
        }}
    </style>
</head>
<body>
    <div class="card">
        {svg_content}
    </div>
    <button class="btn" onclick="downloadSVG()">Download SVG Diagram for Thesis</button>

    <script>
        function downloadSVG() {{
            const svgData = document.querySelector('svg').outerHTML;
            const svgBlob = new Blob([svgData], {{type: 'image/svg+xml;charset=utf-8'}});
            const svgUrl = URL.createObjectURL(svgBlob);
            const downloadLink = document.createElement('a');
            downloadLink.href = svgUrl;
            downloadLink.download = 'pagri_agile_methodology_diagram.svg';
            document.body.appendChild(downloadLink);
            downloadLink.click();
            document.body.removeChild(downloadLink);
        }}
    </script>
</body>
</html>
'''

with open('sql/agile_methodology_diagram.html', 'w', encoding='utf-8') as f:
    f.write(html_content)

print("Diagram generated successfully as SVG and HTML!")
