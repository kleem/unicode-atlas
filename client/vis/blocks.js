
/* this module handles the representation of Unicode blocks as geometric regions
*/

(function() {
  var fit_bounds, module, place_symbol;

  module = {};

  /* represent blocks' data within the given layer
  */

  module.draw = function(params) {
    var blocks, data, new_block;
    data = params.data;
    module.layer = params.layer;
    blocks = topojson.feature(data, data.objects.Blocks);
    new_block = module.layer.selectAll('.block').data(blocks.features).enter().append('g');
    /* the block's area (with tooltip)
    */
    new_block.append('path').attr('class', 'block').attr('d', index_module.path_generator).append('title').text(function(d) {
      return d.properties.name;
    });
    /* the block's symbol
    */
    new_block.append('text').attr('class', 'block_symbol').text(function(d) {
      return d.properties.symbol;
    }).call(place_symbol);
    /* blocks borders
    */
    return module.layer.append('path').datum(topojson.mesh(data, data.objects.Blocks)).attr('class', 'block_borders').attr('d', index_module.path_generator);
  };

  /* redraw the blocks' layer-specific stuff according to the current viewport
  */

  module.redraw = function(params) {
    var duration, easing;
    duration = params.duration != null ? params.duration : 0;
    easing = params.easing != null ? params.easing : 'linear';
    /* keep block borders 1-pixel thin
    */
    module.layer.selectAll('.block_borders').transition().duration(duration).ease(easing).attr('stroke-width', 1 / index_module.zoom.scale());
    /* fade block symbols when characters are shown
    */
    return module.layer.selectAll('.block_symbol').attr('opacity', index_module.zoom.scale() > index_module.ZOOM.characters ? 0.1 : 1);
  };

  /* return the size in pixels of a square that fits within the given datum's path bounds
  */

  fit_bounds = function(d) {
    var bounds;
    bounds = index_module.path_generator.bounds(d);
    return 0.8 * Math.min(bounds[1][0] - bounds[0][0], bounds[1][1] - bounds[0][1]);
  };

  /* translate and scale a symbol to fit its block's region
  */

  place_symbol = function() {
    return this.attr('transform', function(d) {
      var post, pre;
      /* custom placement for some block symbols
      */
      pre = '';
      post = '';
      if (d.properties.name === 'Hangul Syllables') {
        pre = "translate(0 " + (-2.2 * index_module.zoom.scale()) + ") ";
        post = ' scale(0.6)';
      } else if (d.properties.name === 'CJK Unified Ideographs Extension C') {
        pre = "translate(0 " + (-7 * index_module.zoom.scale()) + ") ";
        post = ' scale(0.6)';
      } else if (d.properties.name === 'Private Use Area') {
        pre = "translate(0 " + (1.8 * index_module.zoom.scale()) + ") ";
      }
      return "" + pre + "translate(" + (index_module.path_generator.centroid(d)) + ")" + post;
    }).attr('font-size', function(d) {
      return "" + (fit_bounds(d)) + "px";
    }).attr('dy', function(d) {
      return "" + (fit_bounds(d) * 0.3);
    });
  };

  window.blocks_module = module;

}).call(this);
