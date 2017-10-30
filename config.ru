require 'sqlite3'

run Proc.new { |env|
  db = SQLite3::Database.new 'db'

  exercises = db.execute 'SELECT name FROM exercises;'
  workouts  = db.execute 'SELECT date, weight FROM workouts;'

  cols = exercises.flatten.map { |name| "{label: '#{name}', type: 'number'}" }.join(',')
  rows = workouts.group_by { |w| w.first }.map do |d, weights|
    date   = Date.parse(d)
    values = weights.map { |w| w.last }.map { |w| "{v: #{w}}" }.join(',')
    "{c:[{v: new Date(#{date.year}, #{date.month-1}, #{date.day})}, #{values}]}"
  end.join(',')

  body = <<-HTML
    <!DOCTYPE html>
      <html>
        <head>
          <script async src="https://www.googletagmanager.com/gtag/js?id=UA-65950004-7"></script>
          <script>
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());

            gtag('config', 'UA-65950004-7');
          </script>
          <title>Andrii Ponomarov</title>
          <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
          <script type="text/javascript">
            google.charts.load('current', {'packages':['line']});
            google.charts.setOnLoadCallback(drawChart);

            function drawChart() {
              var data = new google.visualization.DataTable({
                cols: [{label: 'Date', type: 'date'}, #{cols}],
                rows: [#{rows}]
              });

              var options = {
                chart: {
                  title: 'Progressive overload',
                  subtitle: 'in lbs'
                }
              };

              var chart = new google.charts.Line(document.getElementById('linechart_material'));

              chart.draw(data, google.charts.Line.convertOptions(options));
            }
          </script>
          <style type="text/css">
            html {
              height: 100%;
            }

            body {
              display: flex;
              align-items: center;
              justify-content: center;
              height: 100%;
            }
          </style>
        </head>
      <body>
        <div id="linechart_material" style="width: 900px; height: 500px"></div>
      </body>
    </html>
  HTML

  [200, {'Content-Type' => 'text/html'}, [body]]
}
