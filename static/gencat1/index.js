(function() {

  window.main = function() {
    var colorify, height, path_generator, vis, width;
    width = 1024;
    height = 1280;
    vis = d3.select('#diagram');
    /* custom projection with flipped y axis
    */
    path_generator = d3.geo.path().projection(d3.geo.transform({
      point: function(x, y) {
        return this.stream.point(x, -y);
      }
    }));
    /* define a color scale for property general_ca
    */
    /* Colorbrewer color scheme: 7-class Set 3 qualitative
    */
    colorify = d3.scale.category10().domain(['L', 'M', 'N', 'P', 'S', 'Z', 'C']).range(['#80B1D3', '#BEBADA', '#8DD3C7', '#FB8072', '#FDB462', '#FFFFB3', '#B3DE69']);
    /* color the legend
    */
    d3.selectAll('#legend rect').style('fill', function(d) {
      return colorify(d3.select(this).attr('class'));
    });
    /* load topoJSON data
    */
    return d3.json('../../data/4_topojson/General cat 1.topo.json', function(error, data) {
      /* draw the result
      */      return vis.selectAll('.region').data(topojson.feature(data, data.objects['General cat 1']).features).enter().append('path').attr('class', 'region').attr('d', path_generator).attr('fill', function(d) {
        return colorify(d.properties.general_ca);
      });
    });
  };

}).call(this);
