
/* this module handles a Level Of Detail rendering of Unicode codepoints and characters, as well as a labeled grid
*/

(function() {
  var module;

  module = {};

  /* draw the grid within the given layer
  */

  module.draw = function(params) {
    var new_digit;
    module.layer = params.layer;
    /* draw Unicode's "world borders"
    */
    module.layer.append('path').attr('class', 'world_border').attr('d', "M0 0 L1024 0 L1024 1024 L256 1024 L256 1280 L0 1280 z");
    /* create the world-level digits
    */
    new_digit = module.layer.selectAll('.world.digit').data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]).enter().append('text').attr('class', 'world digit').text(function(d) {
      return module.hex(d);
    }).attr('transform', function(d) {
      return "translate(" + (256 * (d % 4)) + " " + (256 * Math.floor(d / 4)) + ")";
    });
    return module.redraw({});
  };

  /* redraw the grid's layer-specific stuff according to the current viewport
  */

  module.redraw = function(params) {
    var b, bbox, bottom, bottom_square, characters, codepoints, coords, duration, easing, i, j, l, left, left_square, meridians, parallels, plane_digits, r, right, right_square, scale, square_coords, t, top, top_square, translate, x_domain, y_domain, _i, _j, _ref, _ref2, _results, _results2;
    duration = params.duration != null ? params.duration : 0;
    easing = params.easing != null ? params.easing : 'linear';
    /* convert the viewport back to domain coordinates
    */
    bbox = index_module.vis.node().getBoundingClientRect();
    translate = index_module.zoom.translate();
    scale = index_module.zoom.scale();
    l = -translate[0] / scale;
    t = -translate[1] / scale;
    r = (bbox.width - translate[0]) / scale;
    b = (bbox.height - translate[1]) / scale;
    left = Math.max(0, Math.floor(l));
    right = Math.min(Math.ceil(r), 1024);
    top = Math.max(0, Math.floor(t));
    bottom = Math.min(Math.ceil(b), 1280);
    /* filter the obtained domains according to the current zoom
    */
    x_domain = (function() {
      _results = [];
      for (var _i = _ref = left + 1; _ref <= right ? _i < right : _i > right; _ref <= right ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this).filter(function(d) {
      if (index_module.zoom.scale() <= 2) return d % 256 === 0;
      if (index_module.zoom.scale() <= 16) return d % 16 === 0;
      return true;
    });
    y_domain = (function() {
      _results2 = [];
      for (var _j = _ref2 = top + 1; _ref2 <= bottom ? _j < bottom : _j > bottom; _ref2 <= bottom ? _j++ : _j--){ _results2.push(_j); }
      return _results2;
    }).apply(this).filter(function(d) {
      if (index_module.zoom.scale() <= 2) return d % 256 === 0;
      if (index_module.zoom.scale() <= 16) return d % 16 === 0;
      return true;
    });
    /* draw or delete the meridians
    */
    meridians = module.layer.selectAll('.meridian').data(x_domain, function(d) {
      return d;
    });
    meridians.enter().insert('line', '.world_border').attr('class', 'meridian').classed('world', function(d) {
      return d % 256 === 0;
    }).classed('plane', function(d) {
      return d % 16 === 0 && !(d % 256 === 0);
    });
    meridians.attr('x1', function(d) {
      return d;
    }).attr('y1', 0).attr('x2', function(d) {
      return d;
    }).attr('y2', function(d) {
      if (d < 256) {
        return 1280;
      } else {
        return 1024;
      }
    });
    meridians.exit().remove();
    /* draw or delete the parallels
    */
    parallels = module.layer.selectAll('.parallel').data(y_domain, function(d) {
      return d;
    });
    parallels.enter().insert('line', '.world_border').attr('class', 'parallel').classed('world', function(d) {
      return d % 256 === 0;
    }).classed('plane', function(d) {
      return d % 16 === 0 && !(d % 256 === 0);
    });
    parallels.attr('x1', 0).attr('y1', function(d) {
      return d;
    }).attr('x2', function(d) {
      if (d < 1024) {
        return 1024;
      } else {
        return 256;
      }
    }).attr('y2', function(d) {
      return d;
    });
    parallels.exit().remove();
    /* keep grid borders 1-pixel thin
    */
    meridians.transition().duration(duration).ease(easing).attr('stroke-width', 1 / scale);
    parallels.transition().duration(duration).ease(easing).attr('stroke-width', 1 / scale);
    /* keep world borders 3-pixel thin
    */
    module.layer.select('.world_border').transition().duration(duration).ease(easing).attr('stroke-width', 3.0 / scale);
    /* ------
    */
    /* DIGITS
    */
    /* ------
    */
    /* scale the world-level digits
    */
    module.layer.selectAll('.world.digit').transition().duration(duration).ease(easing).attr('font-size', 12.0 / scale).attr('dx', 6.0 / scale).attr('dy', 16.0 / scale);
    /* hide world-level digits when displaying plane-level ones
    */
    module.layer.selectAll('.world.digit').attr('display', function() {
      if (scale > index_module.ZOOM.plane_level) {
        return 'none';
      } else {
        return 'display';
      }
    });
    /* draw or delete plane-level digits
    */
    square_coords = [];
    if (scale > index_module.ZOOM.plane_level && scale <= index_module.ZOOM.codepoints) {
      left_square = Math.floor(left / 16);
      right_square = Math.ceil(right / 16);
      top_square = Math.floor(top / 16);
      bottom_square = Math.ceil(bottom / 16);
      for (i = top_square; top_square <= bottom_square ? i < bottom_square : i > bottom_square; top_square <= bottom_square ? i++ : i--) {
        for (j = left_square; left_square <= right_square ? j < right_square : j > right_square; left_square <= right_square ? j++ : j--) {
          if (i < 64 || j < 16) {
            square_coords.push({
              i: i,
              j: j,
              code: (Math.floor(j / 16) + 4 * Math.floor(i / 16)) * 256 + (i % 16) * 16 + (j % 16)
            });
          }
        }
      }
    }
    plane_digits = module.layer.selectAll('.plane.digit').data(square_coords, function(d) {
      return d.code;
    });
    plane_digits.enter().append('text').attr('class', 'plane digit').text(function(d) {
      return module.three_digits_hex(d.code);
    });
    plane_digits.attr('x', function(d) {
      return 16 * d.j;
    }).attr('y', function(d) {
      return 16 * d.i;
    });
    plane_digits.exit().remove();
    /* scale the plane-level digits
    */
    plane_digits.transition().duration(duration).ease(easing).attr('font-size', 12.0 / scale).attr('dx', 6.0 / scale).attr('dy', 16.0 / scale);
    /* ----------
    */
    /* CODEPOINTS
    */
    /* ----------
    */
    /* draw or delete codepoints
    */
    coords = [];
    if (scale > index_module.ZOOM.characters) {
      for (i = top; top <= bottom ? i < bottom : i > bottom; top <= bottom ? i++ : i--) {
        for (j = left; left <= right ? j < right : j > right; left <= right ? j++ : j--) {
          /* skip coordinates in the bottom right corner, where there are no planes
          */
          if (i < 1024 || j < 256) {
            coords.push({
              i: i,
              j: j,
              code: (Math.floor(j / 256) + 4 * Math.floor(i / 256)) * 65536 + (Math.floor(i / 16) % 16) * 4096 + (Math.floor(j / 16) % 16) * 256 + (j % 16) * 16 + (i % 16)
            });
          }
        }
      }
    }
    codepoints = module.layer.selectAll('.codepoint').data((scale > index_module.ZOOM.codepoints ? coords : []), function(d) {
      return d.code;
    });
    codepoints.enter().append('text').attr('class', 'codepoint digit').text(function(d) {
      return module.five_digits_hex(d.code);
    });
    codepoints.attr('x', function(d) {
      return d.j + 0.5;
    }).attr('y', function(d) {
      return d.i + 1;
    });
    codepoints.exit().transition().delay(duration).remove();
    /* scale codepoints
    */
    codepoints.transition().duration(duration).ease(easing).attr('font-size', 9.0 / scale).attr('dy', -4.0 / scale);
    /* ----------
    */
    /* CHARACTERS
    */
    /* ----------
    */
    /* draw or delete characters
    */
    characters = module.layer.selectAll('.character').data(coords, function(d) {
      return d.code;
    });
    characters.enter().append('text').attr('class', 'character').text(function(d) {
      return String.fromCodePoint(d.code);
    });
    characters.attr('x', function(d) {
      return d.j + 0.5;
    }).attr('y', function(d) {
      return d.i + 0.7;
    });
    characters.exit().transition().delay(duration).remove();
    /* scale characters
    */
    return characters.transition().duration(duration).ease(easing).attr('font-size', 16.0 / index_module.ZOOM.characters);
  };

  /* hexadecimal formatters
  */

  module.hex = d3.format('X');

  module.three_digits_hex = d3.format('03X');

  module.five_digits_hex = d3.format('05X');

  window.gridchars_module = module;

}).call(this);
